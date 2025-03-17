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

import ../types/[position, token, errors]

type
  StackableKind* = enum
    ## Discriminator for stackable elements
    skCurly ## Curly brace
    skSquare ## Square bracket
    skParen ## Parenthesis
    skIf ## If statement

  StackableElement* = object
    kind: StackableKind ## Type of stackable element
    position: Position ## Position of the element in the source

type Lexer* = object ## State container for lexical analysis process
  source: string ## Input string being processed
  current: int ## Current parsing position in the string
  line, col: int ## Current line and column position
  stack: seq[StackableElement] ## Stack for nested structures
  skipNewline: bool ## Flag to skip newline tokens

proc newLexer*(source: string): Lexer =
  ## Initializes a new lexer with the given mathematical expression
  Lexer(source: source, current: 0, line: 1, col: 1)

const KEYWORDS: Table[string, TokenKind] = {
  "if": tkIf,
  "else": tkElse,
  "elif": tkElif,
  "local": tkLocal,
  "true": tkTrue,
  "false": tkFalse,
}.toTable

proc atEnd*(lexer: Lexer): bool {.inline.} =
  ## Checks if the lexer has reached the end of the input
  lexer.current >= lexer.source.len

proc parseNumber*(lexer: var Lexer, start: int): Token =
  ## Parses a number literal (int or float) starting at `start`
  let startCol = lexer.col
  var isFloat = false
  while lexer.current < lexer.source.len and
      (lexer.source[lexer.current] in {'0' .. '9'}):
    lexer.current.inc
    lexer.col.inc
  if lexer.current < lexer.source.len and lexer.source[lexer.current] == '.':
    isFloat = true
    lexer.current.inc
    lexer.col.inc
    while lexer.current < lexer.source.len and
        (lexer.source[lexer.current] in {'0' .. '9'}):
      lexer.current.inc
      lexer.col.inc
  if lexer.current < lexer.source.len and
      (lexer.source[lexer.current] == 'e' or lexer.source[lexer.current] == 'E'):
    isFloat = true
    lexer.current.inc
    lexer.col.inc
    if lexer.current < lexer.source.len and lexer.source[lexer.current] in {'+', '-'}:
      lexer.current.inc
      lexer.col.inc
    while lexer.current < lexer.source.len and
        (lexer.source[lexer.current] in {'0' .. '9'}):
      lexer.current.inc
      lexer.col.inc
  let numStr = lexer.source[start ..< lexer.current]
  try:
    return
      if isFloat:
        newToken(parseFloat(numStr), Position(line: lexer.line, column: startCol))
      else:
        newToken(parseInt(numStr), Position(line: lexer.line, column: startCol))
  except:
    raise newBMathError(
      "Invalid number format '" & numStr & "' is not a valid number",
      Position(line: lexer.line, column: startCol),
    )

proc parseIdentifier*(lexer: var Lexer, start: int): Token =
  ## Parses an identifier starting at `start`
  let startCol = lexer.col
  while lexer.current < lexer.source.len and (
    lexer.source[lexer.current] in {'a' .. 'z', 'A' .. 'Z', '_'} or
    lexer.source[lexer.current] in {'0' .. '9'}
  )
  :
    lexer.current.inc
    lexer.col.inc
  let ident = lexer.source[start ..< lexer.current]
  let position = Position(line: lexer.line, column: startCol)
  result = Token(kind: tkIdent, position: position, name: ident)
  if KEYWORDS.hasKey(ident):
    result = Token(kind: KEYWORDS[ident], position: position)
  if result.kind == tkIf:
    lexer.stack.add(
      StackableElement(
        kind: skIf, position: Position(line: lexer.line, column: lexer.col)
      )
    )
  elif result.kind == tkElse:
    if lexer.stack.len == 0:
      raise newBMathError("Unexpected 'else' at " & $position, position)
    let last = lexer.stack.pop
    if last.kind != skIf:
      raise newBMathError("Unexpected 'else' at " & $position, position)

proc parseSymbol*(lexer: var Lexer): Token =
  ## Parses operator or punctuation symbols
  let startCol = lexer.col
  var kind: TokenKind
  case lexer.source[lexer.current]
  of '+':
    kind = tkAdd
  of '-':
    if lexer.current + 1 < lexer.source.len and lexer.source[lexer.current + 1] == '>':
      kind = tkChain
      lexer.current.inc
      lexer.col.inc
    else:
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
    if lexer.current + 1 < lexer.source.len and lexer.source[lexer.current + 1] == '=':
      kind = tkEq
      lexer.current.inc
      lexer.col.inc
    else:
      kind = tkAssign
  of '!':
    if lexer.current + 1 < lexer.source.len and lexer.source[lexer.current + 1] == '=':
      kind = tkNe
      lexer.current.inc
      lexer.col.inc
    else:
      kind = tkNot
  of '<':
    if lexer.current + 1 < lexer.source.len and lexer.source[lexer.current + 1] == '=':
      kind = tkLe
      lexer.current.inc
      lexer.col.inc
    else:
      kind = tkLt
  of '>':
    if lexer.current + 1 < lexer.source.len and lexer.source[lexer.current + 1] == '=':
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
    lexer.stack.add(
      StackableElement(
        kind: skParen, position: Position(line: lexer.line, column: lexer.col)
      )
    )
    kind = tkLPar
  of ')':
    if lexer.stack.len != 0:
      let stackable = lexer.stack.pop
      if stackable.kind == skParen:
        kind = tkRPar
      else:
        raise
          newBMathError("Unmatched '(' at " & $stackable.position, stackable.position)
    else:
      raise
        newBMathError("Unmatched ')'", Position(line: lexer.line, column: lexer.col))
  of ',':
    kind = tkComma
  of '{':
    lexer.stack.add(
      StackableElement(
        kind: skCurly, position: Position(line: lexer.line, column: lexer.col)
      )
    )
    kind = tkLCurly
  of '}':
    if lexer.stack.len != 0:
      let stackable = lexer.stack.pop
      if stackable.kind == skCurly:
        kind = tkRCurly
      else:
        raise
          newBMathError("Unmatched '{' at " & $stackable.position, stackable.position)
    else:
      raise
        newBMathError("Unmatched '}'", Position(line: lexer.line, column: lexer.col))
    kind = tkRCurly
  of '[':
    lexer.stack.add(
      StackableElement(
        kind: skSquare, position: Position(line: lexer.line, column: lexer.col)
      )
    )
    kind = tkLSquare
  of ']':
    if lexer.stack.len != 0:
      let stackable = lexer.stack.pop
      if stackable.kind == skSquare:
        kind = tkRSquare
      else:
        raise
          newBMathError("Unmatched '[' at " & $stackable.position, stackable.position)
    else:
      raise
        newBMathError("Unmatched ']'", Position(line: lexer.line, column: lexer.col))
  else:
    raise newBMathError(
      "Unexpected character '" & $(lexer.source[lexer.current]) & "'",
      Position(line: lexer.line, column: lexer.col),
    )
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
    if lexer.source[lexer.current] == '\\':
      # activate skipNewline
      lexer.skipNewline = true
      lexer.current.inc
      lexer.col.inc
      continue
    # Handle newline: update line/column counters and emit either an EOE or newline token.
    if lexer.source[lexer.current] == '\n':
      lexer.current.inc
      lexer.line.inc
      lexer.col = 1
      if lexer.skipNewline:
        lexer.skipNewline = false
        continue
      if lexer.stack.len == 0:
        return
          Token(kind: tkEoe, position: Position(line: lexer.line, column: lexer.col))
      else:
        return Token(
          kind: tkNewline, position: Position(line: lexer.line, column: lexer.col)
        )
    # Skip comments
    if lexer.source[lexer.current] == '#':
      while lexer.current < lexer.source.len and lexer.source[lexer.current] != '\n':
        lexer.current.inc
        lexer.col.inc
      continue
    let start = lexer.current
    # Check for number: digit or a dot with a digit following (as in '.5')
    if lexer.source[lexer.current] in {'0' .. '9'} or (
      lexer.source[lexer.current] == '.' and lexer.current + 1 < lexer.source.len and
      lexer.source[lexer.current + 1] in {'0' .. '9'}
    ):
      return parseNumber(lexer, start)
    # Check for identifiers
    if lexer.source[lexer.current] in {'a' .. 'z', 'A' .. 'Z', '_'}:
      return parseIdentifier(lexer, start)
    # Otherwise, parse as symbol/operator
    return parseSymbol(lexer)
  # End of input
  return Token(kind: tkEoe, position: Position(line: lexer.line, column: lexer.col))

proc tokenizeExpression*(lexer: var Lexer): seq[Token] =
  ## Collects all tokens until end of input
  while true:
    let token = lexer.next()
    if token.kind == tkEoe:
      if lexer.stack.len > 0:
        let last = lexer.stack.pop
        case last.kind
        of skCurly:
          raise (ref IncompleteInputError)(
            msg: "Unmatched '{' at " & $last.position, position: last.position
          )
        of skParen:
          raise (ref IncompleteInputError)(
            msg: "Unmatched '(' at " & $last.position, position: last.position
          )
        of skSquare:
          raise (ref IncompleteInputError)(
            msg: "Unmatched '[' at " & $last.position, position: last.position
          )
        of skIf:
          raise (ref IncompleteInputError)(
            msg: "Unmatched 'if' at " & $last.position, position: last.position
          )
      break
    result.add(token)
