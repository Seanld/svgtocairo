import std/[parsexml, strutils, strformat]
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
    radius*: float64
  Path* = object
    shape*: Shape
    data*: string

func `$`(s: Stroke): string = fmt"color=<{s.color}>, width=<{s.width}>"
func `$`(s: Style): string = fmt"fill=<{s.fill}>, stroke=<{s.stroke}>"
func `$`(s: Shape): string = fmt"id=<{s.id}>, pos=<{s.x},{s.y}>, style=<{s.style}>"
func `$`(r: Rect): string = fmt"Rect[size=<{r.width},{r.height}>, shape=<{r.shape}>]"
func `$`(c: Circle): string = fmt"Circle[radius=<c.radius>, shape=<{c.shape}>]"
func `$`(p: Path): string = fmt"Path[data=<p.data>, shape=<{p.shape}>]"

func parseStyle*(styleStr: string): Style =
  for attrib in styleStr.split(';'):
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
      of xmlElementClose:
        p.next()
        break
      else: discard
  Rect(
    shape: initShape(id, x, y, styleStr),
    width: width,
    height: height,
  )

proc parseCircle*(p: var XmlParser): Circle =
  var
    id, styleStr: string
    x, y, radius: float64
  while true:
    p.next()
    case p.kind:
      of xmlAttribute:
        case p.attrKey:
          of "id": id = p.attrValue
          of "style": styleStr = p.attrValue
          of "cx": x = p.attrValue.parseFloat()
          of "cy": y = p.attrValue.parseFloat()
          of "r": radius = p.attrValue.parseFloat()
      of xmlElementClose:
        p.next()
        break
      else: discard
  Circle(
    shape: initShape(id, x, y, styleStr),
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
          of "id": id = p.attrValue
          of "x": x = p.attrValue.parseFloat()
          of "y": y = p.attrValue.parseFloat()
          of "style": styleStr = p.attrValue
          of "d": data = p.attrValue
      of xmlElementClose:
        p.next()
        break
      else: discard
  Path(
    shape: initShape(id, x, y, styleStr),
    data: data,
  )

template withNamedCtx(target: ptr Surface, ctx: untyped, body: untyped) =
  ## Creates a Cairo `Context` of a given symbol name for the given target surface,
  ## does the given drawing actions, then destroys the context when finished.
  let ctx = create target
  body
  destroy ctx

template withCtx(target: ptr Surface, body: untyped) =
  ## Short form of `withNamedCtx` that defines a `ctx` variable automatically.
  let ctx {.inject.} = create target
  body
  destroy ctx

proc draw*(r: Rect, target: ptr Surface) =
  withCtx target:
    ctx.setSourceRgba(r.shape.style.fill.r,
                      r.shape.style.fill.g,
                      r.shape.style.fill.b,
                      r.shape.style.fill.a)
    ctx.rectangle(r.shape.x, r.shape.y, r.width, r.height)
    ctx.fill()
