## A minimal SVG <style> parser that only looks for a subset of styling options that
## this library aims to support. This should probably be refactored into a more
## "real" parser solution, as I assume it's fragile in its current state.

import std/tables
import stylus, stylus/parser, results, chroma
import ./shapes

type
  SvgCssParseError* = object of CatchableError

template raiseParseError() = raise newException(SvgCssParseError, "Failed while parsing CSS classes")
template unexpectedToken(p: parser.Parser) = err(p.newBasicError(bpUnexpectedToken))

func applyUnit(value: float64, unit: string, pxPerInch = 300.0): float64 =
  case unit:
    of "px": return value
    else: raiseParseError()

const DefaultStyleScale* = 300.0 / 96.0

template ensureKind(p: parser.Parser, token: Token, targetKind: TokenKind) =
  if token.kind != targetKind: return err(p.newBasicError(bpUnexpectedToken))

proc parseAttributes(p: parser.Parser, clsNames: seq[string],
                     clsMap: var ClassMap, scale = DefaultStyleScale): Result[void, BasicParseError] =
  while true:
    let first = ? p.next()
    if first.kind == tkCloseCurlyBracket: return ok()
    p.ensureKind(first, tkIdent)
    let colon = ? p.next()
    p.ensureKind(colon, tkColon)
    let value = ? p.next()
    let semicolon = ? p.next()
    p.ensureKind(semicolon, tkSemicolon)
    case first.ident:
      of "stroke":
        var clr: Color
        case value.kind:
          of tkIdent:
            if value.ident == "none": clr = Color(a: 0, r: 0, g: 0, b: 0)
            else: clr = parseHtmlColor(value.ident)
          of tkIDHash: clr = parseHtmlColor("#" & value.idHash)
          else: return err(p.newBasicError(bpUnexpectedToken))
        for clsName in clsNames:
          clsMap[clsName].stroke.color = clr
      of "fill":
        var clr: Color
        case value.kind:
          of tkIdent:
            if value.ident == "none": clr = Color(a: 0, r: 0, g: 0, b: 0)
            else: clr = parseHtmlColor(value.ident)
          of tkIDHash: clr = parseHtmlColor("#" & value.idHash)
          else: return err(p.newBasicError(bpUnexpectedToken))
        for clsName in clsNames:
          clsMap[clsName].fill = clr
      of "stroke-width":
        for clsName in clsNames:
          clsMap[clsName].stroke.width = value.dValue * scale
      of "stroke-opacity":
        for clsName in clsNames:
          clsMap[clsName].stroke.color.a = value.dValue
      of "fill-opacity":
        for clsName in clsNames:
          clsMap[clsName].fill.a = value.dValue
      else:
        if first.kind != tkIdent: return err(p.newBasicError(bpUnexpectedToken))

proc parseClassNames(p: parser.Parser): Result[seq[string], BasicParseError] =
  var names: seq[string]
  while true:
    let delim = ? p.next()
    p.ensureKind(delim, tkDelim)
    let name = ? p.next()
    p.ensureKind(name, tkIdent)
    names.add(name.ident)
    let trailing = ? p.next()
    if trailing.kind == tkCurlyBracketBlock: return ok(names)
    elif trailing.kind == tkComma: continue
    else: return err(p.newBasicError(bpUnexpectedToken))

proc parseClasses*(p: parser.Parser, scale = DefaultStyleScale): Result[ClassMap, BasicParseError] =
  var clsMap = newTable[string, Style]()
  while not p.input.tokenizer.isEof:
    let clsNames = parseClassNames(p)
    if clsNames.isErr and clsNames.error.kind == bpEndOfInput: break
    for clsName in clsNames.value:
      if not clsMap.hasKey(clsName): clsMap[clsName] = Style()
    p.parseAttributes(clsNames.value, clsMap).isOkOr: return err(p.newBasicError(bpUnexpectedToken))
  ok(clsMap)
