# Simple partial vector implementation for handling shape/path coordinates.

type Vec2* = object
  x*, y*: float64

func `+`*(v1, v2: Vec2): Vec2 = Vec2(x: v1.x + v2.x, y: v1.y + v2.y)
proc `+=`*(v1: var Vec2, v2: Vec2) =
  v1.x += v2.x
  v1.y += v2.y

func `+`*(v: Vec2, f: float64): Vec2 = Vec2(x: v.x + f, y: v.y + f)
proc `+=`*(v: var Vec2, f: float64) =
  v.x += f
  v.y += f

func `*`*(v1, v2: Vec2): Vec2 = Vec2(x: v1.x * v2.x, y: v1.y * v2.y)
proc `*=`*(v1: var Vec2, v2: Vec2) =
  v1.x *= v2.x
  v1.y *= v2.y

func `*`*(v: Vec2, f: float64): Vec2 = Vec2(x: v.x * f, y: v.y * f)
proc `*=`*(v: var Vec2, f: float64) =
  v.x *= f
  v.y *= f
