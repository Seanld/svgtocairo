import std/tables
import chroma

type
  Stroke* = object
    width*: float64 = 1.0
    color*: Color
  Style* = object
    fill*: Color
    stroke*: Stroke
  ClassMap* = Table[string, Style]

const Dpi300* = 300.0/96.0
