## A minimal SVG <style> parser that only looks for a subset of styling options that
## this library aims to support. This should probably be refactored into a more
## "real" parser solution, as I assume it's fragile in its current state.

import std/tables
import stylus, stylus/parser, results, chroma
import ./common

type
  SvgStyleParseError = object of CatchableError
  TokenAssertError = object of CatchableError

proc assertKind(tok: Token, kinds: varargs[TokenKind]) =
  ## If `tok` is not one of `kinds`, raise a `TokenAssertError`.
  for kind in kinds:
    if tok.kind == kind: return
  raise newException(TokenAssertError, "Unexpected token kind")

template multiAssertKind(pairings: openArray[(Token, seq[TokenKind])]) =
  ## If any of the tokens in `pairings` are not one of their respective
  ## possible kinds, raise a `TokenAssertError`.
  for pair in pairings:
    assertKind(pair[0].kind != pair[1])

proc nextTokenSkip*(t: Tokenizer): Token =
  ## Consume and ignore whitespace tokens, and return the first non-whitespace token.
  while true:
    let tok = t.nextToken()
    if tok.kind != tkWhitespace: return tok

func color(tok: Token): Color =
  ## Get a chroma color from the given token.
  case tok.kind:
    of tkIdent:
      if tok.ident == "none":
        return Color()
      else:
        return parseHtmlColor(tok.ident)
    of tkIDHash, tkHash:
      let val = if tok.kind == tkIDHash: tok.idHash else: tok.hash
      if val[0] != '#':
        return parseHtmlColor("#" & val)
      else:
        return parseHtmlColor(val)
    else: raise newException(SvgStyleParseError, "Unknown token type for color value")

func number(tok: Token): float64 =
  ## Get a number from the given numeric token.
  case tok.kind:
    of tkNumber: return tok.nValue
    of tkDimension: return tok.dValue
    else: raise newException(SvgStyleParseError, "Unknown token type for numeric value")

template apply(classMap: var ClassMap, classes: openArray[string], attr, value: untyped) =
  for class in classes:
    classMap = value

proc consumeAttributes(t: Tokenizer, classMap: var ClassMap, classNames: openArray[string], scale = Dpi300) =
  ## Tokenizer must start with first token after opening curly bracket.
  ## Loads consumed attributes into the `target` variable.
  while not t.isEof:
    let first = t.nextTokenSkip()
    if first.kind == tkCloseCurlyBracket: break
    assertKind(first, tkIdent)
    let
      colon = t.nextTokenSkip()
      second = t.nextTokenSkip()
    if not t.isEof: discard t.nextTokenSkip() # Consume semicolon if possible.
    if first.kind != tkIdent or colon.kind != tkColon:
      raise newException(SvgStyleParseError, "Bad structure while parsing class attributes")
    case first.ident:
      of "fill":
        for className in classNames: classMap[className].fill = second.color
      of "fill-opacity":
        for className in classNames: classMap[className].fill.a = second.number
      of "stroke":
        for className in classNames: classMap[className].stroke.color = second.color
      of "stroke-opacity":
        for className in classNames: classMap[className].stroke.color.a = second.number
      of "stroke-width":
        for className in classNames: classMap[className].stroke.width = second.number * scale
      else: discard

proc consumeClassNames(t: Tokenizer): seq[string] =
  ## Tokenizer must start with first delim token of class name list.
  while true:
    let
      before = t.nextTokenSkip()
      middle = t.nextTokenSkip()
      after = t.nextTokenSkip()
    if before.kind != tkDelim or middle.kind != tkIdent or (after.kind != tkComma and after.kind != tkCurlyBracketBlock):
      raise newException(SvgStyleParseError, "Bad structure while parsing class names")
    result.add(middle.ident)
    if after.kind == tkCurlyBracketBlock: break

proc parseStyleClasses*(classesStr: string): ClassMap =
  let t = newTokenizer(classesStr)
  while not t.isEof:
    let classNames = t.consumeClassNames()
    for className in classNames:
      if not result.contains(className):
        result[className] = Style()
    t.consumeAttributes(result, classNames)

proc parseStyle*(styleStr: string, scale = Dpi300): Style =
  ## Parse a single style string, e.g. from `<elem style="..."/>`
  let t = newTokenizer(styleStr)
  var singleMap = {"style": Style()}.toTable
  while not t.isEof:
    t.consumeAttributes(singleMap, ["style"])
  return singleMap["style"]