import unittest
import svgtocairo
import cairo

test "pathssvg":
  let pathsSfc = svgToSurface("tests/paths.svg", "paths_out.svg")
  pathsSfc.flush()
  pathsSfc.finish()
