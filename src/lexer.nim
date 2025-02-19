## lexer.nim - Lexical Analysis Module
##
## Converts raw input strings into structured tokens through:
## - Whitespace handling
## - Number literal recognition (int/float)
## - Operator identification
## - Position tracking for error reporting
##
## Implements error-resilient tokenization with precise error
## location reporting.

import std/[strutils, tables]

import types, logging

type Lexer* = object ## State container for lexical analysis process
  source: string ## Input string being processed
  current: int ## Current parsing position in the string
  line, col: int ## Current line and column position
  curlyStack: seq[Position] ## Stack of curly brace positions
  ifStack: seq[Position] ## Stack of if positions

proc newLexer*(source: string): Lexer =
  ## Initializes a new lexer with the given mathematical expression
  Lexer(source: source, current: 0, line: 1, col: 1)

const KEYWORDS: Table[string, TokenKind] = {
  "if": tkIf,
  "else": tkElse,
  "elif": tkElif,
  "endif": tkEndIf,
  "return": tkReturn,
  "local": tkLocal,
}.toTable

proc parseNumber*(lexer: var Lexer, start: int): Token =
  ## Parses a number literal (int or float) starting at `start`
  let startCol = lexer.col
  var isFloat = false
  while lexer.current < lexer.source.len and (lexer.source[lexer.current] in {'0' .. '9'}):
    lexer.current.inc
    lexer.col.inc
  if lexer.current < lexer.source.len and lexer.source[lexer.current] == '.':
    isFloat = true
    lexer.current.inc
    lexer.col.inc
    while lexer.current < lexer.source.len and (lexer.source[lexer.current] in {'0' .. '9'}):
      lexer.current.inc
      lexer.col.inc
  if lexer.current < lexer.source.len and (lexer.source[lexer.current] == 'e' or lexer.source[lexer.current] == 'E'):
    isFloat = true
    lexer.current.inc
    lexer.col.inc
    if lexer.current < lexer.source.len and lexer.source[lexer.current] in {'+', '-'}:
      lexer.current.inc
      lexer.col.inc
    while lexer.current < lexer.source.len and (lexer.source[lexer.current] in {'0' .. '9'}):
      lexer.current.inc
      lexer.col.inc
  let numStr = lexer.source[start ..< lexer.current]
  try:
    let value = if isFloat:
      Value(kind: vkFloat, fValue: parseFloat(numStr))
    else:
      Value(kind: vkInt, iValue: parseInt(numStr))
    return Token(
      kind: tkValue,
      position: Position(line: lexer.line, column: startCol),
      value: value,
    )
  except:
    raise newBMathError("Invalid number format '" & numStr & "' is not a valid number",
                        Position(line: lexer.line, column: startCol))

proc parseIdentifier*(lexer: var Lexer, start: int): Token =
  ## Parses an identifier starting at `start`
  let startCol = lexer.col
  while lexer.current < lexer.source.len and (lexer.source[lexer.current] in {'a'..'z', 'A'..'Z', '_'} or
                                                 lexer.source[lexer.current] in {'0'..'9'}):
    lexer.current.inc
    lexer.col.inc
  let ident = lexer.source[start ..< lexer.current]
  if ident == "true":
    return Token(
      kind: tkValue,
      position: Position(line: lexer.line, column: startCol),
      value: Value(kind: vkBool, bValue: true),
    )
  elif ident == "false":
    return Token(
      kind: tkValue,
      position: Position(line: lexer.line, column: startCol),
      value: Value(kind: vkBool, bValue: false),
    )
  if KEYWORDS.hasKey(ident):
    if KEYWORDS[ident] == tkIf:
      lexer.ifStack.add(Position(line: lexer.line, column: startCol))
    elif KEYWORDS[ident] == tkEndIf:
      if lexer.ifStack.len > 0:
        discard lexer.ifStack.pop
      else:
        raise newBMathError("Unmatched 'endif'", Position(line: lexer.line, column: startCol))
    return Token(
      kind: KEYWORDS[ident],
      position: Position(line: lexer.line, column: startCol),
    )
  return Token(
    kind: tkIdent,
    position: Position(line: lexer.line, column: startCol),
    name: ident,
  )

proc parseSymbol*(lexer: var Lexer): Token =
  ## Parses operator or punctuation symbols
  let startCol = lexer.col
  var kind: TokenKind
  case lexer.source[lexer.current]
  of '+':
    kind = tkAdd
  of '-':
    kind = tkSub
  of '*':
    kind = tkMul
  of '/':
    kind = tkDiv
  of '^':
    kind = tkPow
  of '%':
    kind = tkMod
  of '=':
    if lexer.current + 1 < lexer.source.len and lexer.source[lexer.current+1] == '=':
      kind = tkEq
      lexer.current.inc
      lexer.col.inc
    else:
      kind = tkAssign
  of '!':
    if lexer.current + 1 < lexer.source.len and lexer.source[lexer.current+1] == '=':
      kind = tkNe
      lexer.current.inc
      lexer.col.inc
    else:
      kind = tkNot
  of '<':
    if lexer.current + 1 < lexer.source.len and lexer.source[lexer.current+1] == '=':
      kind = tkLe
      lexer.current.inc
      lexer.col.inc
    else:
      kind = tkLt
  of '>':
    if lexer.current + 1 < lexer.source.len and lexer.source[lexer.current+1] == '=':
      kind = tkGe
      lexer.current.inc
      lexer.col.inc
    else:
      kind = tkGt
  of '&':
    kind = tkAnd
  of '|':
    kind = tkLine
  of '(':
    kind = tkLPar
  of ')':
    kind = tkRPar
  of ',':
    kind = tkComma
  of '{':
    lexer.curlyStack.add(Position(line: lexer.line, column: lexer.col))
    kind = tkLCurly
  of '}':
    if lexer.curlyStack.len > 0:
      discard lexer.curlyStack.pop
    else:
      raise newBMathError("Unmatched '}'", Position(line: lexer.line, column: lexer.col))
    kind = tkRCurly
  of '[':
    kind = tkLSquare
  of ']':
    kind = tkRSquare
  else:
    raise newBMathError("Unexpected character '" & $(lexer.source[lexer.current]) & "'",
                        Position(line: lexer.line, column: lexer.col))
  lexer.current.inc
  lexer.col.inc
  return Token(kind: kind, position: Position(line: lexer.line, column: startCol))

proc next*(lexer: var Lexer): Token =
  ## Advances to the next token by delegating to one of the specialized procs
  while lexer.current < lexer.source.len:
    # Skip whitespace, updating column
    if lexer.source[lexer.current] in {' ', '\r', '\t'}:
      lexer.current.inc
      lexer.col.inc
      continue
    # Handle newline: update line/column counters and emit either an EOE or newline token.
    if lexer.source[lexer.current] == '\n':
      lexer.current.inc
      lexer.line.inc
      lexer.col = 1
      if lexer.curlyStack.len == 0 and lexer.ifStack.len == 0:
        return Token(kind: tkEoe, position: Position(line: lexer.line, column: lexer.col))
      else:
        return Token(kind: tkNewline, position: Position(line: lexer.line, column: lexer.col))
    # Skip comments
    if lexer.source[lexer.current] == '#':
      while lexer.current < lexer.source.len and lexer.source[lexer.current] != '\n':
        lexer.current.inc
        lexer.col.inc
      continue
    let start = lexer.current
    # Check for number: digit or a dot with a digit following (as in '.5')
    if lexer.source[lexer.current] in {'0'..'9'} or
       (lexer.source[lexer.current] == '.' and lexer.current + 1 < lexer.source.len and
        lexer.source[lexer.current+1] in {'0'..'9'}):
      return parseNumber(lexer, start)
    # Check for identifiers
    if lexer.source[lexer.current] in {'a'..'z', 'A'..'Z', '_'}:
      return parseIdentifier(lexer, start)
    # Otherwise, parse as symbol/operator
    return parseSymbol(lexer)
  # End of input
  return Token(kind: tkEoe, position: Position(line: lexer.line, column: lexer.col))

proc atEnd*(lexer: Lexer): bool {.inline.} =
  ## Checks if the lexer has reached the end of the input
  lexer.current >= lexer.source.len

proc tokenizeExpression*(lexer: var Lexer): seq[Token] =
  ## Collects all tokens until end of input
  while true:
    let token = lexer.next()
    if token.kind == tkEoe:
      if lexer.curlyStack.len > 0:
        let last = lexer.curlyStack.pop
        raise (ref IncompleteInputError)(msg: "Unmatched '{' at " & $last, position: last)
      if lexer.ifStack.len > 0:
        let last = lexer.ifStack.pop
        raise (ref IncompleteInputError)(msg: "Unmatched 'if' at " & $last, position: last)
      break
    result.add(token)
