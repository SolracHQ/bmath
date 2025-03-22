## lexer.nim - Lexical Analysis Module
##
## Converts raw input strings into structured tokens through:
## - Whitespace handling
## - Number literal recognition (int/float/complex)
## - Identifier and keyword parsing
## - Operator identification
## - Position tracking for error reporting
##
## Implements error-resilient tokenization with precise error
## location reporting.

import std/[strutils, tables, complex]

import ../../types/[position, token]
import errors

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
  ## Initializes a new lexer.
  ## 
  ## Params:
  ##   source: string - the mathematical expression to tokenize.
  ## Returns: Lexer - the new lexer instance.
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
  ## Checks if the end of the source string has been reached.
  ##
  ## Params:
  ##   lexer: Lexer - the current lexer instance.
  ## Returns: bool - true if all characters have been processed, false otherwise.
  lexer.current >= lexer.source.len

proc advance*(lexer: var Lexer, count: int = 1) =
  ## Advances the lexer by a given number of characters.
  ##
  ## Params:
  ##   lexer: var Lexer - the current lexer instance.
  ##   count: int - (optional) number of characters to advance (default is 1).
  ## Returns: void.
  for _ in 1 .. count:
    lexer.current.inc
    lexer.col.inc

proc readDigits*(lexer: var Lexer) =
  ## Reads consecutive digit characters from the source.
  ##
  ## Params:
  ##   lexer: var Lexer - the current lexer instance.
  ## Returns: void.
  while lexer.current < lexer.source.len and
      (lexer.source[lexer.current] in {'0' .. '9'}):
    lexer.advance()

proc isIdentChar*(c: char): bool =
  ## Checks whether a character is valid for an identifier.
  ##
  ## Params:
  ##   c: char - the character to test.
  ## Returns: bool - true if valid (alphabet, underscore, or digit), false otherwise.
  return c in {'a' .. 'z', 'A' .. 'Z', '_'} or (c in {'0' .. '9'})

proc readWhile*(lexer: var Lexer, condition: proc(c: char): bool) =
  ## Consumes characters from the source while a given condition is true.
  ##
  ## Params:
  ##   lexer: var Lexer - the current lexer instance.
  ##   condition: proc(c: char): bool - predicate to test each character.
  ## Returns: void.
  while lexer.current < lexer.source.len and condition(lexer.source[lexer.current]):
    lexer.advance()

proc currentIsIn*(lexer: Lexer, chars: set[char]): bool {.inline.} =
  ## Checks if the current character is within the specified set.
  ##
  ## Params:
  ##   lexer: Lexer - the current lexer instance.
  ##   chars: set[char] - a set of characters to check against.
  ## Returns: bool - true if the current character is in the set, false otherwise.
  lexer.current < lexer.source.len and lexer.source[lexer.current] in chars

proc handleClosing*(
    lexer: var Lexer,
    expected: StackableKind,
    openingChar, closingChar: char,
    closingTokenKind: TokenKind,
): TokenKind =
  ## Processes a closing character, ensuring it matches the expected opening.
  ##
  ## Params:
  ##   lexer: var Lexer - the current lexer instance.
  ##   expected: StackableKind - the expected stackable element type.
  ##   openingChar: char - the opening character.
  ##   closingChar: char - the closing character.
  ##   closingTokenKind: TokenKind - token kind to return upon successful match.
  ## Returns: TokenKind - the token kind corresponding to the closing.
  if lexer.stack.len != 0:
    let stackable = lexer.stack.pop
    if stackable.kind == expected:
      return closingTokenKind
    else:
      raise newIncompleteInputError(
        "Unmatched '" & $openingChar & "' at " & $stackable.position, stackable.position
      )
  else:
    raise newUnexpectedCharacterError(
      "Unmatched '" & $closingChar & "'", pos(lexer.line, lexer.col)
    )

proc parseNumber*(lexer: var Lexer, start: int): Token =
  ## Parses a numeric literal (integer, float, or complex).
  ##
  ## Params:
  ##   lexer: var Lexer - the current lexer instance.
  ##   start: int - the starting index of the number in the source.
  ## Returns: Token - a token representing the parsed number.
  let startCol = lexer.col
  var isFloat = false
  lexer.readDigits()
  if currentIsIn(lexer, {'.'}):
    isFloat = true
    lexer.advance()
    lexer.readDigits()
  if currentIsIn(lexer, {'e', 'E'}):
    isFloat = true
    lexer.advance()
    if currentIsIn(lexer, {'+', '-'}):
      lexer.advance()
    lexer.readDigits()
  let numStr = lexer.source[start ..< lexer.current]
  try:
    if currentIsIn(lexer, {'i', 'I'}):
      lexer.advance()
      if isFloat:
        return newToken(complex(0.0, parseFloat(numStr)), pos(lexer.line, startCol))
      else:
        return newToken(complex(0.0, parseInt(numStr).float), pos(lexer.line, startCol))
    else:
      if isFloat:
        return newToken(parseFloat(numStr), pos(lexer.line, startCol))
      else:
        return newToken(parseInt(numStr), pos(lexer.line, startCol))
  except:
    raise newInvalidNumberFormatError(
      "Invalid number format '" & numStr & "' is not a valid number",
      pos(lexer.line, startCol),
    )

proc parseIdentifier*(lexer: var Lexer, start: int): Token =
  ## Parses an identifier and checks for keywords.
  ##
  ## Params:
  ##   lexer: var Lexer - the current lexer instance.
  ##   start: int - the starting index of the identifier in the source.
  ## Returns: Token - a token representing the identifier or keyword.
  let startCol = lexer.col
  lexer.readWhile(isIdentChar)
  let ident = lexer.source[start ..< lexer.current]
  let position = pos(lexer.line, startCol)
  result = Token(kind: tkIdent, position: position, name: ident)
  if KEYWORDS.hasKey(ident):
    result = Token(kind: KEYWORDS[ident], position: position)
  if result.kind == tkIf:
    lexer.stack.add(StackableElement(kind: skIf, position: pos(lexer.line, lexer.col)))
  elif result.kind == tkElse:
    if lexer.stack.len == 0:
      raise newUnexpectedCharacterError("Unexpected 'else' at " & $position, position)
    let last = lexer.stack.pop
    if last.kind != skIf:
      raise newUnexpectedCharacterError("Unexpected 'else' at " & $position, position)

proc checkNext*(lexer: Lexer): char =
  ## Returns the next character in the source without advancing the lexer.
  ##
  ## Params:
  ##   lexer: Lexer - the current lexer instance.
  ## Returns: char - the next character, or '\0' if none exists.
  if lexer.current + 1 < lexer.source.len:
    return lexer.source[lexer.current + 1]
  return '\0'

proc parseSymbol*(lexer: var Lexer): Token =
  ## Parses a symbol or operator token.
  ##
  ## Params:
  ##   lexer: var Lexer - the current lexer instance.
  ## Returns: Token - a token representing the symbol or operator.
  let startCol = lexer.col
  var kind: TokenKind
  case lexer.source[lexer.current]
  of '+':
    kind = tkAdd
  of '-':
    if checkNext(lexer) == '>':
      kind = tkChain
      lexer.advance()
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
    if checkNext(lexer) == '=':
      kind = tkEq
      lexer.advance()
    else:
      kind = tkAssign
  of '!':
    if checkNext(lexer) == '=':
      kind = tkNe
      lexer.advance()
    else:
      kind = tkNot
  of '<':
    if checkNext(lexer) == '=':
      kind = tkLe
      lexer.advance()
    else:
      kind = tkLt
  of '>':
    if checkNext(lexer) == '=':
      kind = tkGe
      lexer.advance()
    else:
      kind = tkGt
  of '&':
    kind = tkAnd
  of '|':
    kind = tkLine
  of '(':
    lexer.stack.add(
      StackableElement(kind: skParen, position: pos(lexer.line, lexer.col))
    )
    kind = tkLPar
  of ')':
    kind = handleClosing(lexer, skParen, '(', ')', tkRPar)
  of ',':
    kind = tkComma
  of '{':
    lexer.stack.add(
      StackableElement(kind: skCurly, position: pos(lexer.line, lexer.col))
    )
    kind = tkLCurly
  of '}':
    kind = handleClosing(lexer, skCurly, '{', '}', tkRCurly)
  of '[':
    lexer.stack.add(
      StackableElement(kind: skSquare, position: pos(lexer.line, lexer.col))
    )
    kind = tkLSquare
  of ']':
    kind = handleClosing(lexer, skSquare, '[', ']', tkRSquare)
  else:
    raise newUnexpectedCharacterError(
      "Unexpected character '" & $(lexer.source[lexer.current]) & "'",
      pos(lexer.line, lexer.col),
    )
  lexer.advance()
  return Token(kind: kind, position: pos(lexer.line, startCol))

proc next*(lexer: var Lexer): Token =
  ## Retrieves the next token from the source.
  ##
  ## Params:
  ##   lexer: var Lexer - the current lexer instance.
  ## Returns: Token - the next token in the input sequence.
  while lexer.current < lexer.source.len:
    # Skip whitespace, updating column
    if lexer.source[lexer.current] in {' ', '\r', '\t'}:
      lexer.advance()
      continue
    if lexer.source[lexer.current] == '\\':
      # activate skipNewline
      lexer.skipNewline = true
      lexer.advance()
      continue
    # Handle newline: update line/column counters and emit either an EOE or newline token.
    if lexer.source[lexer.current] == '\n':
      lexer.advance()
      lexer.col = 1
      if lexer.skipNewline:
        lexer.skipNewline = false
        continue
      if lexer.stack.len == 0:
        return Token(kind: tkEoe, position: pos(lexer.line, lexer.col))
      else:
        return Token(kind: tkNewline, position: pos(lexer.line, lexer.col))
    # Skip comments
    if lexer.source[lexer.current] == '#':
      while lexer.current < lexer.source.len and lexer.source[lexer.current] != '\n':
        lexer.advance()
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
  return Token(kind: tkEoe, position: pos(lexer.line, lexer.col))

proc tokenizeExpression*(lexer: var Lexer): seq[Token] =
  ## Tokenizes the entire input into a sequence of tokens.
  ##
  ## Params:
  ##   lexer: var Lexer - the current lexer instance.
  ## Returns: seq[Token] - a sequence of tokens representing the input expression.
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
