import std/[exitprocs, strformat, macros, tables, os]

proc loadAssets*(data: seq[Table[system.string, system.string]]): string =
  ## accepting output from *embedAssets* proc and load it on runtime to folder /tmp/ at linux and %temp% at windows
  ##
  ## Parameter:
  ## - `data`: sequence of table string from *embedAssets*.
  ##
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
        raise newException(OSError, "Failed to create temp folder")
    )

    return tempDir

  except OSError:
    raise newException(CatchableError, "Something went wrong when loading assetss to temp folder")

macro embedAssets*(src: static[string]): untyped =
  ## embedAssets proc
  ##
  ## Parameter:
  ## - `src`: valid path of the source, use *currentSourcePath()* function to resolve it.
  var elements = newSeq[NimNode]()
  for path in walkDirRec(src):
    let filename = fmt"{splitFile(path).name}{splitFile(path).ext}"
    let relPath = path[(src.len + 1) .. path.len - 1]

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
