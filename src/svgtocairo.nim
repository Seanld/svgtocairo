import std/[streams, parsexml, os]
import cairo

proc svgToSurface*(stream: FileStream):
