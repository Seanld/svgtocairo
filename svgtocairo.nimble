# Package

version       = "0.3.1"
author        = "Sean Wilkerson"
description   = "A minimal library to convert SVGs to Cairo surfaces"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.2.2"
requires "cairo >= 1.1.1"
requires "chroma >= 0.2.7"
requires "stylus >= 0.1.2"
requires "pretty >= 0.2.0"


task cleantest, "Clean up test files (e.g. test output/bin)":
  try:
    exec "rm -rf tests/out"
    exec "rm -f tests/tload"
  except: discard
