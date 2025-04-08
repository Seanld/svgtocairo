import std/[unittest, paths, os]
import svgtocairo, cairo

const OutDir = paths.Path("tests/out/")

proc createIfNotExist(dir: paths.Path) =
  let
    (head, tail) = dir.splitPath
    headStr = $head
  if not dirExists(headStr):
    createDir(headStr)

template testSurface(sfcPathStr: string) =
  block:
    let
      sfcPath = Path(sfcPathStr)
      (_, sfcFileName) = sfcPath.splitPath
    createIfNotExist(sfcPathStr)
    let sfc = svgToSurface(sfcPathStr, $(Path("tests/out") / sfcFileName))
    sfc.flush()
    sfc.finish()

test "pathssvg":
  createIfNotExist(OutDir)
  let pathsSfc = svgToSurface("tests/img/paths.svg", "tests/out/paths_out.svg")
  pathsSfc.flush()
  pathsSfc.finish()

test "internal":
  createIfNotExist(OutDir)
  let pathsSfc = svgToSurface("/mnt/nfs/assets/art/cs27561/cs27561_cut.svg", "tests/out/cs27561_cut.svg")
  pathsSfc.flush()
  pathsSfc.finish()
