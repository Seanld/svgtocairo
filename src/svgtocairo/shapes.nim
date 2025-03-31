import std/[parsexml, strutils, tables]
import cairo
import chroma

type
  Stroke* = object
    width*: float64
    color*: Color
  Style* = object
    fill*: Color
    stroke*: Stroke
  Shape* = object
    id*: string
    x*, y*: float64
    style*: Style
  Rect* = object
    shape*: Shape
    width*, height*: float64
  Circle* = object
    shape*: Shape
    cx*, cy*: float64
    radius*: float64
  Path* = object
    shape*: Shape
    data*: string

func parseStyle*(s: Shape): Style =
  for attrib in s.style.split(';'):
    let splits = attrib.split(":")
    case splits[0]:
      of "fill":
        result.fill = parseHtmlColor(splits[1])
      of "stroke-width":
        result.stroke.width = splits[1].parseFloat()
      else: discard

func initShape(id: string, x, y: float64, styleStr: string): Shape =
  Shape(
    id: id,
    x: x,
    y: y,
    style: parseStyle(styleStr),
  )

proc parseRect*(p: var XmlParser): Rect =
  var
    id, styleStr: string
    x, y, width, height: float64
  while true:
    p.next()
    case p.kind:
      of xmlAttribute:
        case p.attrKey:
          of "id": id = p.attrValue
          of "x": x = p.attrValue.parseFloat()
          of "y": y = p.attrValue.parseFloat()
          of "style": styleStr = p.attrValue
          of "width": width = p.attrValue.parseFloat()
          of "height": height = p.attrValue.parseFloat()
      of xmlElementClose: break
      else: discard
  Rect(
    shape: initShape(id, x, y, styleStr),
    width: width,
    height: height,
  )

proc parseCircle*(p: var XmlParser): Circle =
  var
    id, styleStr: string
    x, y, cx, cy, radius: float64
  while true:
    p.next()
    case p.kind:
      of xmlAttribute:
        case p.attrKey:
          of "id": shape.id = p.attrValue
          of "x": shape.x = p.attrValue.parseFloat()
          of "y": shape.y = p.attrValue.parseFloat()
          of "style": shape.style = p.attrValue
          of "cx": cx = p.attrValue.parseFloat()
          of "cy": cy = p.attrValue.parseFloat()
          of "r": radius = p.attrValue.parseFloat()
      of xmlElementClose: break
      else: discard
  Circle(
    shape: initShape(id, x, y, styleStr),
    cx: cx,
    cy: cy,
    radius: radius,
  )

proc parsePath*(p: var XmlParser): Path =
  var
    id, styleStr, data: string
    x, y: float64
  while true:
    p.next()
    case p.kind:
      of xmlAttribute:
        case p.attrKey:
          of "id": result.shape.id = p.attrValue
          of "x": result.shape.x = p.attrValue.parseFloat()
          of "y": result.shape.y = p.attrValue.parseFloat()
          of "style": result.shape.style = p.attrValue
          of "d": result.data = p.attrValue
      of xmlElementClose: break
      else: discard
  Path(
    shape: initShape(id, x, y, styleStr),
    data: data,
  )

# proc contextFrom*(s: Shape, target: ptr Surface): ptr Context =
#   let ctx = create target
#   ctx.set

proc draw*(r: Rect, target: ptr Surface) =
  let
    styling = r.shape.styleMap()
    ctx = create target
  ctx.setSourceRgb()
  ctx.rectangle(r.x, r.y, r.w, r.h)
