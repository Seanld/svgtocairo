import std/[streams, parsexml, paths, strutils]
import cairo
import svgtocairo/shapes

type
  SvgToCairoError = object of CatchableError
  ViewBox = object
    x*, y*, w*, h*: float64
  MetaData = object
    viewBox*: ViewBox

func toViewBox(vbStr: string): ViewBox =
  let vbItems = vbStr.split(' ')
  ViewBox(
    x: vbItems[0].parseFloat(),
    y: vbItems[1].parseFloat(),
    w: vbItems[2].parseFloat(),
    h: vbItems[3].parseFloat(),
  )

proc parseMetaData(p: var XmlParser): MetaData =
  while true:
    p.next()
    case p.kind:
      of xmlAttribute:
        case p.attrKey:
          of "viewBox":
            result.viewBox = toViewBox(p.attrValue)
          of "version":
            if p.attrValue != "1.1":
              raise newException(SvgToCairoError, "Only SVG 1.1 is supported")
      of xmlElementClose:
        break
      else: discard

proc loadShape(p: var XmlParser, target: ptr Surface) =
  case p.elementName:
    of "rect": echo p.parseRect().shape.id
    of "circle": echo p.parseCircle().shape.id
    of "path": echo p.parsePath().shape.id
    else: discard

proc loadShapes(p: var XmlParser, target: ptr Surface) =
  let startName = p.elementName
  while true:
    p.next()
    case p.kind:
      of xmlElementOpen:
        if p.elementName == "path" or p.elementName == "rect" or p.elementName == "circle":
          loadShape(p, target)
      of xmlElementClose:
        # Only break if the closing tag has the same name
        # as the tag this function started with. This doesn't yet
        # account for nesting. In that case, this will need to use
        # recursion, or be refactored to use a stack.
        echo p.elementName
        if p.elementName == startName:
          break
      else: discard

proc svgToSurface*(s: var FileStream, inFile: string, outFile: cstring = nil): ptr Surface =
  var p: XmlParser
  p.open(s, inFile)
  while true:
    p.next()
    case p.kind:
      of xmlElementOpen:
        case p.elementName:
          of "svg":
            let metaData = parseMetaData(p)
            result = svgSurfaceCreate(outFile, metaData.viewBox.w, metaData.viewBox.h)
          of "defs":
            discard # TODO: Parse defs
          of "g":
            loadShapes(p, result)
      of xmlEof:
        break
      else: discard

proc svgToSurface*(inFile: string, outFile: cstring = nil): ptr Surface =
  var s = newFileStream(inFile)
  if s.isNil:
    raise newException(SvgToCairoError, "Failed to open SVG")
  s.svgToSurface(inFile, outFile)

proc svgToSurface*(p: paths.Path): ptr Surface = svgToSurface($p)
