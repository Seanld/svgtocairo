import std/tables
import ./vector
import chroma

type
  Stroke* = object
    width*: float64 = 1.0
    color*: Color
  Style* = object
    fill*: Color
    stroke*: Stroke
  ClassMap* = Table[string, Style]

const
  DefaultScale* = Vec2(x: 1.0, y: 1.0)
  Dpi300* = 300.0/96.0
