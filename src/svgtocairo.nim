import std/[streams, parsexml, strutils]
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
    of "rect": p.parseRect().draw(target)
    # of "circle": echo p.parseCircle().draw(target)
    # of "path": echo p.parsePath().draw(target)
    else: discard

proc loadShapes(p: var XmlParser, target: ptr Surface) =
  while true:
    # The token loadShapes starts with when called should be an xmlElementOpen.
    case p.kind:
      of xmlElementOpen:
        if p.elementName == "path" or p.elementName == "rect" or p.elementName == "circle":
          loadShape(p, target)
      of xmlElementEnd:
        break
      of xmlAttribute, xmlWhitespace: discard
      else: raise newException(SvgToCairoError, "Unexpected token when loading shapes")
    p.next()

template skipToKind(p: var XmlParser, targetKind: XmlEventKind) =
  ## Consumes and ignores tokens until hitting a token of `targetKind`. Using this
  ## by definition means ignoring potentially important information in the SVG data,
  ## which is a signal of incomplete SVG-to-Cairo implementation. Get away
  ## from using this eventually.
  p.next()
  while p.kind != targetKind: p.next()

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
            # Skip tokens until <g> is over hits first nested shape.
            p.skipToKind(xmlElementOpen)
            loadShapes(p, result)
      of xmlEof:
        break
      else: discard

proc svgToSurface*(inFile: string, outFile: cstring = nil): ptr Surface =
  var s = newFileStream(inFile)
  if s.isNil:
    raise newException(SvgToCairoError, "Failed to open SVG")
  s.svgToSurface(inFile, outFile)
