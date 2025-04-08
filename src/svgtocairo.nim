import std/[streams, parsexml, strutils]
import cairo
import stylus/parser, results
import svgtocairo/[shapes, vector, styleparse]

type
  SvgToCairoError = object of CatchableError
  ViewBox = object
    point*: Vec2
    w*, h*: float64
  MetaData = object
    viewBox*: ViewBox
    width*, height*: float64
    scale*: Vec2 = DefaultScale

func toViewBox(vbStr: string): ViewBox =
  let vbItems = vbStr.split(' ')
  ViewBox(
    point: Vec2(
      x: vbItems[0].parseFloat(),
      y: vbItems[1].parseFloat(),
    ),
    w: vbItems[2].parseFloat(),
    h: vbItems[3].parseFloat(),
  )

func deunitized(unitized: string): float64 =
  var val, unit: string
  for c in unitized:
    if (c >= '0' and c <= '9') or c == '.':
      val &= c
    else:
      unit &= c
  result = val.parseFloat()
  case unit:
    of "in":
      result *= 96
    else: discard

proc parseMetaData(p: var XmlParser): MetaData =
  var widthOrHeightGiven = false
  while true:
    p.next()
    case p.kind:
      of xmlAttribute:
        case p.attrKey:
          of "viewBox":
            result.viewBox = toViewBox(p.attrValue)
          of "width":
            result.width = p.attrValue.deunitized
            widthOrHeightGiven = true
          of "height":
            result.height = p.attrValue.deunitized
            widthOrHeightGiven = true
          of "version":
            if p.attrValue != "1.1":
              raise newException(SvgToCairoError, "Only SVG 1.1 is supported")
      of xmlElementClose:
        break
      else: discard
  if not widthOrHeightGiven:
    result.width = result.viewBox.w
    result.height = result.viewBox.h
  else:
    result.scale.x = result.width / result.viewBox.w
    result.scale.y = result.width / result.viewBox.h

proc loadShape(p: var XmlParser, target: ptr Surface,
               classMap: ClassMap, scale = DefaultScale) =
  case p.elementName:
    of "rect": p.parseRect(classMap, scale).draw(target)
    of "circle": p.parseCircle(classMap, scale).draw(target)
    of "path": p.parsePath(classMap, scale).draw(target, scale)
    else: discard

proc loadShapes(p: var XmlParser, target: ptr Surface,
                classMap: ClassMap, scale = DefaultScale) =
  while true:
    # The token loadShapes starts with when called should be an xmlElementOpen.
    case p.kind:
      of xmlElementOpen:
        if p.elementName == "path" or p.elementName == "rect" or p.elementName == "circle":
          loadShape(p, target, classMap, scale)
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

proc parseDefs(p: var XmlParser): ClassMap =
  while true:
    p.next()
    case p.kind:
      of xmlElementOpen, xmlElementStart:
        if p.elementName == "style":
          p.skipToKind(xmlCharData)
          let classes = parseClasses(newParser(newParserInput(p.charData)))
          if classes.isErr: raise newException(SvgToCairoError, "Failed to parse style tag")
          return classes.value
      of xmlElementClose: break
      else: discard

proc svgToSurface*(s: var FileStream, inFile: string, outFile: cstring = nil): ptr Surface =
  var
    p: XmlParser
    metaData: MetaData
    classMap: ClassMap
  p.open(s, inFile)
  while true:
    p.next()
    case p.kind:
      of xmlElementOpen, xmlElementStart:
        case p.elementName:
          of "svg":
            metaData = parseMetaData(p)
            result = svgSurfaceCreate(outFile, metaData.width, metaData.height)
          of "defs":
            classMap = parseDefs(p)
          of "g":
            # Skip tokens until <g> attributes are over and hits first nested shape.
            p.skipToKind(xmlElementOpen)
            loadShapes(p, result, classMap, metaData.scale)
          of "path", "rect", "circle":
            loadShape(p, result, classMap, metaData.scale)
      of xmlEof:
        break
      else: discard

proc svgToSurface*(inFile: string, outFile: cstring = nil): ptr Surface =
  var s = newFileStream(inFile)
  if s.isNil:
    raise newException(SvgToCairoError, "Failed to open SVG")
  s.svgToSurface(inFile, outFile)
