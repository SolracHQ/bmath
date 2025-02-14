## parser.nim - Syntax Analysis Module
##
## Transforms token streams into abstract syntax trees using
## a recursive descent approach. Features:
## - Operator precedence handling
## - Parenthesis grouping
## - Syntax error detection
## - Abstract syntax tree construction

import types, logging

type
  Parser = object
    tokens: seq[Token]    ## Sequence of tokens to parse
    current: int          ## Current position in token stream

template isAtEnd(parser: Parser): bool =
  ## Checks if parser has reached end of token stream
  parser.current >= parser.tokens.len

template peek(parser: Parser): Token =
  ## Returns current token without consuming it
  if parser.current < parser.tokens.len:
    parser.tokens[parser.current]
  else:
    Token(kind: tkEoe)

template previous(parser: Parser): Token =
  ## Returns previous consumed token
  if parser.current > 0:
    parser.tokens[parser.current - 1]
  else:
    Token(kind: tkEoe)

proc advance(parser: var Parser) {.inline.} =
  ## Moves to next token in stream
  if not parser.isAtEnd:
    parser.current += 1

template check(parser: Parser, kd: set[TokenKind]): bool =
  ## Checks if current token matches given kind
  not parser.isAtEnd and parser.peek.kind in kd

template `match`(parser: var Parser, kind: set[TokenKind]): bool =
  ## Consumes current token if it matches given kind
  ## Returns true if matched, false otherwise
  if parser.check(kind):
    parser.advance()
    true
  else: false

proc newParser(tokens: seq[Token]): Parser {.inline.} =
  ## Creates new parser from token sequence
  Parser(tokens: tokens, current: 0)

proc parseExpression(parser: var Parser): AstNode {.inline.}

proc parsePrimary(parser: var Parser): AstNode =
  ## Parses primary expressions: numbers, groups
  if parser.match({tkLpar}):
    let pos = parser.previous().position
    let expr = parser.parseExpression()
    if not parser.match({tkRpar}):
      raise newBMathError("Expected ')'", parser.previous().position)
    return AstNode(kind: nkGroup, child: expr, position: pos)
  elif parser.match({tkNum}):
    let token = parser.previous()
    return AstNode(kind: nkNumber, value: token.value, position: token.position)
  elif parser.match({tkIdent}):
    let token = parser.previous()
    if parser.match({tkLpar}):
      var args: seq[AstNode] = @[]
      while not parser.match({tkRpar}):
        args.add(parser.parseExpression())
        if parser.match({tkRpar}):
          break
        if not parser.match({tkComma}):
          raise newBMathError("Expected ','", parser.previous().position)
      return AstNode(kind: nkFuncCall, fun: token.name, args: args, position: token.position)
    else:
      return AstNode(kind: nkIdent, name: token.name, position: token.position)
  else:
    let token = parser.peek()
    raise newBMathError("Unexpected token " & $token, token.position)

proc parseUnary(parser: var Parser): AstNode =
  ## Parses unary negations
  if parser.match({tkSub}):
    let pos = parser.previous().position
    let operand = parser.parseUnary()
    return AstNode(kind: nkNeg, operand: operand, position: pos)
  else:
    return parser.parsePrimary()

proc parsePower(parser: var Parser): AstNode =
  ## Parses power operations
  result = parser.parseUnary()
  while parser.match({tkPow}):
    let prev = parser.previous()
    let right = parser.parseUnary()
    result = AstNode(kind: nkPow, left: result, right: right, position: prev.position)
  return result

proc parseFactor(parser: var Parser): AstNode =
  ## Parses multiplication/division operations
  result = parser.parsePower()
  while parser.match({tkMul, tkDiv, tkMod}):
    let prev = parser.previous()
    let right = parser.parsePower()
    case prev.kind:
    of tkMul: result = AstNode(kind: nkMul, left: result, right: right, position: prev.position)
    of tkDiv: result = AstNode(kind: nkDiv, left: result, right: right, position: prev.position)
    of tkMod: result = AstNode(kind: nkMod, left: result, right: right, position: prev.position)
    else: discard # Should never happen, is unreachable

proc parseTerm(parser: var Parser): AstNode =
  # Parses addition/subtraction
  result = parser.parseFactor()
  while parser.match({tkSub, tkAdd}):
    let prev = parser.previous()
    let right = parser.parseFactor()
    case prev.kind:
    of tkSub: result = AstNode(kind: nkSub, left: result, right: right)
    else: result = AstNode(kind: nkAdd, left: result, right: right)

proc parseAssignment(parser: var Parser): AstNode =
  ## Parses assignment expressions
  result = parser.parseTerm()
  if result.kind != nkIdent:
    return result
  if parser.match({tkAssign}): # Assignment
    let prev = parser.previous()
    let value = parser.parseAssignment()
    return AstNode(kind: nkAssign, ident: result.name, expr: value, position: prev.position)
  else:
    return result

proc parseExpression(parser: var Parser): AstNode {.inline.} =
  result = parser.parseAssignment()

proc parse*(tokens: seq[Token]): AstNode =
  var parser = newParser(tokens)
  result = parser.parseExpression()
  if not parser.isAtEnd:
    let token = parser.peek()
    raise newBMathError("Unexpected token " & $token, token.position)