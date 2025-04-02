import std/[unittest, paths, os]
import svgtocairo, cairo

const OutDir = paths.Path("tests/out/")

proc createIfNotExist(dir: paths.Path) =
  let
    (head, tail) = dir.splitPath
    headStr = $head
  if not dirExists(headStr):
    createDir(headStr)

test "pathssvg":
  createIfNotExist(OutDir)
  let pathsSfc = svgToSurface("tests/src/paths.svg", "tests/out/paths_out.svg")
  pathsSfc.flush()
  pathsSfc.finish()
