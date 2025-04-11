import std/[unittest, tables]
import svgtocairo/[styleparse, common]
import chroma

const style1Sample = """.st0 {
  stroke: #f60;
}

.st0, .st1, .st2 {
  fill: none;
  stroke-miterlimit: 10;
}

.st1 {
  stroke: blue;
}

.st1, .st2 {
  stroke-width: .25px;
}

.st2 {
  stroke: red;
}"""

test "style1":
  let classes = parseStyleClasses(style1Sample)
  assert classes["st0"].stroke.color == parseHtmlColor("#f60")
  assert classes["st0"].fill == Color(a: 0, r: 0, g: 0, b: 0)
  assert classes["st1"].stroke.width == 0.25 * Dpi300
  assert classes["st2"].stroke.width == 0.25 * Dpi300
  assert classes["st2"].stroke.color == parseHtmlColor("red")
  assert classes["st1"].stroke.color == parseHtmlColor("blue")
