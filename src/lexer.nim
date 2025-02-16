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

import std/strutils

import types, logging

type Lexer* = object
  ## State container for lexical analysis process
  source: string         ## Input string being processed
  current: int               ## Current parsing position in the string
  line, col: int             ## Current line and column position
  curlyStack: seq[Position]  ## Stack of curly brace positions

proc newLexer*(source: string): Lexer =
  ## Initializes a new lexer with the given mathematical expression
  Lexer(source: source, current: 0, line: 1, col: 1)

proc next*(lexer: var Lexer): Token =
  ## Advances to the next token and returns it
  ## 
  ## Returns:
  ##   Token with either parsed value or error information
  
  template current(): char = lexer.source[lexer.current]
  template atEnd(): bool = lexer.current >= lexer.source.len
  template isEmpty(): bool = not atEnd and current in {' ', '\r', '\t'}
  template isDigit(): bool = not atEnd and current in {'0'..'9'}
  template isAlpha(): bool = not atEnd and current in {'a'..'z', 'A'..'Z', '_'}
  template isE(): bool = not atEnd and current in {'e', 'E'}
    
  template next() =
    lexer.current.inc
    lexer.col.inc
  template markError(msg: string) = 
    raise newBMathError(msg, Position(line: lexer.line, column: lexer.col - (lexer.current - start)))
  template makeToken(k: TokenKind): Token = 
    let len = lexer.current - start + 1
    Token(
      kind:k, 
      position: Position(line: lexer.line, column: lexer.col - (lexer.current - start))
    )  

  while not atEnd:
    # Skip whitespace characters
    if isEmpty:
      next()
      continue

    if current() == '\n':
      next()
      lexer.line += 1
      lexer.col = 1
      # On curly mode, skip EOE on newline
      if lexer.curlyStack.len == 0: 
        return Token(kind: tkEoe, position: Position(line: lexer.line, column: lexer.col))
      # Marker of end of sub-expression on block mode
      return Token(kind: tkNewline, position: Position(line: lexer.line, column: lexer.col))

    if current() == '#':
      while not atEnd and current() != '\n': next()
      continue

    let start = lexer.current
    
    # Number parsing
    if isDigit or current == '.':
      var isFloat = false
      # Consume number parts
      while not atEnd and isDigit: next()
      if not atEnd and current == '.': 
        isFloat = true
        next()
        while not atEnd and isDigit: next()
      if isE: 
        isFloat = true
        next()
        if not atEnd and current in {'+', '-'}: next()
        while not atEnd and isDigit: next()
      
      let numStr = lexer.source[start..<lexer.current]
      try:
        let value = if isFloat: Value(kind: vkFloat, fValue:parseFloat(numStr)) else: Value(kind: vkInt, iValue:parseInt(numStr))
        return Token(
          kind: tkNum,
          position: Position(line: lexer.line, column: lexer.col - numStr.len),
          value: value
        )
      except:
        markError("Invalid number format '" & numStr & "' is not a valid number")
    
    if isAlpha:
      while isAlpha or isDigit:
        next()
      let ident = lexer.source[start..<lexer.current]
      return Token(
        kind: tkIdent,
        position: Position(line: lexer.line, column: lexer.col - ident.len),
        name: ident
      )

    # Handle operators/parentheses
    defer: next()
    case current:
    of '+':
      return makeToken(tkAdd)
    of '-':
      return makeToken(tkSub)
    of '*':
      return makeToken(tkMul)
    of '/':
      return makeToken(tkDiv)
    of '^':
      return makeToken(tkPow)
    of '%':
      return makeToken(tkMod)
    of '(':
      return makeToken(tkLpar)
    of ')':
      return makeToken(tkRpar)
    of '=':
      return makeToken(tkAssign)
    of ',':
      return makeToken(tkComma)
    of '{':
      lexer.curlyStack.add(Position(line: lexer.line, column: lexer.col))
      return makeToken(tkLcur)
    of '}':
      discard lexer.curlyStack.pop
      return makeToken(tkRcur)
    of '|':
      return makeToken(tkLine)
    else:
      markError("Unexpected character '" & $current & "'")

  # Return EOF marker when done
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
        raise newBMathError("Unmatched '{' at " & $last, last)
      break
    result.add(token)