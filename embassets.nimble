# Package

version       = "0.0.4"
author        = "IDNatte"
description   = "simple assets embedding in binary"
license       = "BSD-3-Clause"
srcDir        = "src"

# debug
installExt    = @["nim"]
binDir        = "build"
bin           = @["embassets_coba"]

# Dependencies

requires "nim >= 2.2.4"
