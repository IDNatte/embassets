import std/[exitprocs, strformat, macros, tables, os]

proc loadAssets*(data: seq[Table[system.string, system.string]]): string =
  try:
    let tempDir = joinPath(getTempDir(), fmt"mapps-{getCurrentProcessId()}")
    if not dirExists(tempDir):
      createDir(tempDir)

    for assets in data:
      let relPath = assets["relative_path"]
      let fullPath = joinPath(tempDir, relPath)

      createDir(parentDir(fullPath))
      writeFile(joinPath(tempDir, assets["relative_path"]), assets["data"])

    addExitProc(proc() =
      try:
        removeDir(tempDir)
      except OSError:
        discard
    )

    return tempDir

  except OSError:
    discard

macro embedAssets*(src: static[string]): untyped =
  let cwd = currentSourcePath()
  let absPath = joinPath(parentDir(cwd), src)

  echo absPath

  var elements = newSeq[NimNode]()
  for path in walkDirRec(absPath):
    let filename = fmt"{splitFile(path).name}{splitFile(path).ext}"
    let relPath = path[(absPath.len + 1) .. path.len - 1]

    let meta = newCall(bindSym"toTable",
      nnkTableConstr.newTree(
        nnkExprColonExpr.newTree(
          newLit("filename"), newLit(filename)
        ),
        nnkExprColonExpr.newTree(
          newLit("relative_path"), newLit(relPath)
        ),
        nnkExprColonExpr.newTree(
          newLit("data"),
          newCall(bindSym"staticRead", newLit(path))
        )
      )
    )

    elements.add(meta)

  return newCall(bindSym"@", nnkBracket.newTree(elements))
