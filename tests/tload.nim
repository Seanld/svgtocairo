import unittest
import svgtocairo

test "pathssvg":
  let pathsSfc = svgToSurface("tests/paths.svg")
