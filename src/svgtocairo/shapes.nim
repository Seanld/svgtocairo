import std/[parsexml, strutils, strformat, math]
import cairo
import chroma
import ./[pathdata, vector]

type
  Stroke* = object
    width*: float64
    color*: Color
  Style* = object
    fill*: Color
    stroke*: Stroke
  Shape* = object
    id*: string
    point*: Vec2
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

const DefaultScale* = Vec2(x: 1.0, y: 1.0)

func `$`(s: Stroke): string = fmt"color=<{s.color}>, width=<{s.width}>"
func `$`(s: Style): string = fmt"fill=<{s.fill}>, stroke=<{s.stroke}>"
func `$`(s: Shape): string = fmt"id=<{s.id}>, pos=<{s.point.x},{s.point.y}>, style=<{s.style}>"
func `$`(r: Rect): string = fmt"Rect[size=<{r.width},{r.height}>, shape=<{r.shape}>]"
func `$`(c: Circle): string = fmt"Circle[radius=<c.radius>, shape=<{c.shape}>]"
func `$`(p: Path): string = fmt"Path[data=<p.data>, shape=<{p.shape}>]"

proc initStyle*(styleStr: string, scale = DefaultScale): Style =
  for attrib in styleStr.strip.split(';'):
    let splits = attrib.split(":")
    case splits[0]:
      of "fill":
        if splits[1] != "none":
          let parsedColor = splits[1].parseHtmlColor()
          result.fill.r = parsedColor.r
          result.fill.g = parsedColor.g
          result.fill.b = parsedColor.b
          result.fill.a = 1.0
        else:
          result.fill.a = 0.0
      of "fill-opacity":
        result.fill.a = splits[1].parseFloat()
      of "stroke-width":
        # This should scale non-axially as well. Using X scale for the time-being.
        result.stroke.width = splits[1].parseFloat() * scale.x
      of "stroke":
        let parsedColor = splits[1].parseHtmlColor()
        result.stroke.color.r = parsedColor.r
        result.stroke.color.g = parsedColor.g
        result.stroke.color.b = parsedColor.b
        result.stroke.color.a = 0.0
      of "stroke-opacity":
        result.stroke.color.a = splits[1].parseFloat()
      else: discard

# func initStyle*(p: var XmlParser): Style = discard

proc initShape(id: string, point: Vec2, styleStr: string, scale = DefaultScale): Shape =
  Shape(
    id: id,
    point: point,
    style: initStyle(styleStr, scale),
  )

proc parseRect*(p: var XmlParser, scale = DefaultScale): Rect =
  var
    id, styleStr: string
    point: Vec2
    width, height: float64
  while true:
    p.next()
    case p.kind:
      of xmlAttribute:
        case p.attrKey:
          of "id": id = p.attrValue
          of "x": point.x = p.attrValue.parseFloat() * scale.x
          of "y": point.y = p.attrValue.parseFloat() * scale.y
          of "style": styleStr = p.attrValue
          of "width": width = p.attrValue.parseFloat() * scale.x
          of "height": height = p.attrValue.parseFloat() * scale.y
      of xmlElementClose:
        p.next()
        break
      else: discard
  Rect(
    shape: initShape(id, point, styleStr, scale),
    width: width,
    height: height,
  )

proc parseCircle*(p: var XmlParser, scale = DefaultScale): Circle =
  var
    id, styleStr: string
    point: Vec2
    radius: float64
  while true:
    p.next()
    case p.kind:
      of xmlAttribute:
        case p.attrKey:
          of "id": id = p.attrValue
          of "style": styleStr = p.attrValue
          of "cx": point.x = p.attrValue.parseFloat() * scale.x
          of "cy": point.y = p.attrValue.parseFloat() * scale.y
          # TODO: What do you do in this situation? Radius is not bound to an axis, but should scale.
          of "r": radius = p.attrValue.parseFloat() * scale.x
      of xmlElementClose:
        p.next()
        break
      else: discard
  Circle(
    shape: initShape(id, point, styleStr, scale),
    radius: radius,
  )

proc parsePath*(p: var XmlParser, scale = DefaultScale): Path =
  var
    id, styleStr, data: string
    point: Vec2
  while true:
    p.next()
    case p.kind:
      of xmlAttribute:
        case p.attrKey:
          of "id": id = p.attrValue
          of "x": point.x = p.attrValue.parseFloat() * scale.x
          of "y": point.y = p.attrValue.parseFloat() * scale.y
          of "style": styleStr = p.attrValue
          of "d": data = p.attrValue
      of xmlElementClose:
        p.next()
        break
      else: discard
  Path(
    shape: initShape(id, point, styleStr, scale),
    data: data,
  )

template withCtx(target: ptr Surface, ctx: untyped, body: untyped) =
  ## Creates a Cairo `Context` of a given symbol name for the given target surface,
  ## does the given drawing actions, then destroys the context when finished.
  block:
    let ctx = create target
    body
    destroy ctx

proc apply(s: Stroke, ctx: ptr Context) =
  if s.width > 0.0:
    ctx.setLineWidth(s.width)
    ctx.setSourceRgba(s.color.r,
                      s.color.g,
                      s.color.b,
                      s.color.a)
    ctx.stroke()

proc draw*(r: Rect, target: ptr Surface) =
  withCtx(target, ctx):
    r.shape.style.stroke.apply(ctx)
    ctx.setSourceRgba(r.shape.style.fill.r,
                      r.shape.style.fill.g,
                      r.shape.style.fill.b,
                      r.shape.style.fill.a)
    ctx.rectangle(r.shape.point.x, r.shape.point.y, r.width, r.height)
    ctx.fillPreserve()
    ctx.rectangle(r.shape.point.x, r.shape.point.y, r.width, r.height)
    r.shape.style.stroke.apply(ctx)

proc draw*(c: Circle, target: ptr Surface) =
  withCtx(target, ctx):
    ctx.translate(c.shape.point.x, c.shape.point.y)
    ctx.arc(0, 0, c.radius, 0, 2*Pi)
    ctx.setSourceRgba(c.shape.style.fill.r,
                      c.shape.style.fill.g,
                      c.shape.style.fill.b,
                      c.shape.style.fill.a)
    ctx.fillPreserve()
    ctx.arc(0, 0, c.radius, 0, 2*Pi)
    c.shape.style.stroke.apply(ctx)

type UnimplementedPathCmdError = object of CatchableError

proc draw*(p: Path, target: ptr Surface, scale = DefaultScale) =
  ## All other shapes have scaling pre-calculated when the shape object is created,
  ## but paths are different because their line commands need to know scaling at draw
  ## time, not just at path object creation time. That is why `scale` is only an
  ## argument in this draw function.
  var point: Vec2
  withCtx(target, ctx):
    ctx.setSourceRgba(p.shape.style.fill.r,
                      p.shape.style.fill.g,
                      p.shape.style.fill.b,
                      p.shape.style.fill.a)
    ctx.newPath()
    for op in p.data.ops:
      case op.cmd:
        of 'M':
          for (group, idx) in op.groups:
            point = Vec2(x: group[0], y: group[1]) * scale
            if idx == 0:
              ctx.moveTo(point.x, point.y)
            else:
              ctx.lineTo(point.x, point.y)
        of 'm':
          for (group, idx) in op.groups:
            point += Vec2(x: group[0], y: group[1]) * scale
            if idx == 0:
              ctx.moveTo(point.x, point.y)
            else:
              ctx.lineTo(point.x, point.y)
        of 'L':
          for (group, _) in op.groups:
            point = Vec2(x: group[0], y: group[1]) * scale
            ctx.lineTo(point.x, point.y)
        of 'H':
          for (group, _) in op.groups:
            point.x = group[0] * scale.x
            ctx.lineTo(point.x, point.y)
        of 'V':
          for (group, _) in op.groups:
            point.y = group[0] * scale.y
            ctx.lineTo(point.x, point.y)
        of 'C':
          for (group, _) in op.groups:
            point = Vec2(x: group[4], y: group[5]) * scale
            ctx.curveTo(group[0], group[1], group[2], group[3], point.x, point.y)
        of 'c':
          for (group, _) in op.groups:
            let
              control1 = point + (Vec2(x: group[0], y: group[1]) * scale)
              control2 = point + (Vec2(x: group[2], y: group[3]) * scale)
            point += (Vec2(x: group[4], y: group[5]) * scale)
            ctx.curveTo(control1.x, control1.y, control2.x, control2.y, point.x, point.y)
        else:
          raise newException(UnimplementedPathCmdError, "Unimplemented path command")
    ctx.closePath()
    ctx.fillPreserve()
    p.shape.style.stroke.apply(ctx)