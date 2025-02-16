## parser.nim - Syntax Analysis Module
##
## Transforms token streams into abstract syntax trees using
## a recursive descent approach. Features:
## - Operator precedence handling
## - Parenthesis grouping
## - Syntax error detection
## - Abstract syntax tree construction

import types, logging, value

type Parser = object
  tokens: seq[Token]  ## Sequence of tokens to parse
  current: int        ## Current position in token stream

template isAtEnd(parser: Parser): bool =
  ## Checks if parser has reached end of token stream
  parser.current >= parser.tokens.len

template peek(parser: Parser): Token =
  ## Returns token at current position but does not advance the parser
  if not parser.isAtEnd:
    parser.tokens[parser.current]
  else:
    Token(kind: tkEoe)

template previous(parser: Parser): Token =
  ## Returns token at previous position
  if parser.current > 0:
    parser.tokens[parser.current - 1]
  else:
    Token(kind: tkEoe)

template advance(parser: var Parser) =
  ## Moves to next token in stream
  if not parser.isAtEnd:
    parser.current += 1

template check(parser: Parser, kd: static[set[TokenKind]]): bool =
  ## Checks if current token matches given kind
  not parser.isAtEnd and parser.peek.kind in kd

template `match`(parser: var Parser, kind: set[TokenKind]): bool =
  ## Consumes current token if it matches given kind
  ## Returns true if matched, false otherwise
  if parser.check(kind):
    parser.advance()
    true
  else:
    false

proc newParser(tokens: seq[Token]): Parser {.inline.} =
  ## Creates new parser from token sequence
  Parser(tokens: tokens, current: 0)

proc parseExpression(parser: var Parser): AstNode {.inline.}

proc parseGroup(parser: var Parser): AstNode =
  ## Parses grouped expressions: (expression) and constant folding for groups
  let pos = parser.previous().position
  let expr = parser.parseExpression()
  if not parser.match({tkRpar}):
    raise newBMathError("Expected ')'", parser.previous().position)
  # Constant folding for groups: if the expression is a number, return it directly
  if expr.kind == nkNumber:
    return expr
  return AstNode(kind: nkGroup, child: expr, position: pos)

proc parseNumber(parser: var Parser): AstNode =
  ## Parses numeric literals
  let token = parser.previous()
  return AstNode(kind: nkNumber, value: token.value, position: token.position)

proc parseIdentifierOrFuncCall(parser: var Parser): AstNode =
  ## Parses identifiers and distinguishes between variable references and function calls.
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

proc parseFunction(parser: var Parser): AstNode =
  ## Parses function definitions with parameters and body.
  var params: seq[string] = @[]
  while not parser.match({tkLine}):
    if parser.match({tkIdent}):
      params.add(parser.previous().name)
    else:
      raise newBMathError("Expected identifier", parser.previous().position)
    if parser.match({tkLine}):
      break
    if not parser.match({tkComma}):
      raise newBMathError("Expected ','", parser.previous().position)
  return AstNode(kind: nkFunc, params: params, body: parser.parseExpression())

proc parsePrimary(parser: var Parser): AstNode =
  ## Parses primary expressions: numbers, groups, identifiers, and function definitions.
  if parser.match({tkLpar}):
    return parser.parseGroup()
  elif parser.match({tkNum}):
    return parser.parseNumber()
  elif parser.match({tkIdent}):
    return parser.parseIdentifierOrFuncCall()
  elif parser.match({tkLine}):
    return parser.parseFunction()
  else:
    let token = parser.peek()
    raise newBMathError("Unexpected token " & $token, token.position)

proc parseUnary(parser: var Parser): AstNode =
  ## Parses unary negations
  if parser.match({tkSub}):
    let pos = parser.previous().position
    let operand = parser.parseUnary()
    # Unary constant folding: if the operand is a number, return its negation directly
    if operand.kind == nkNumber:
      return AstNode(kind: nkNumber, value: -operand.value, position: pos)
    return AstNode(kind: nkNeg, operand: operand, position: pos)
  else:
    return parser.parsePrimary()

proc parsePower(parser: var Parser): AstNode =
  ## Parses power operations
  result = parser.parseUnary()
  while parser.match({tkPow}):
    let prev = parser.previous()
    let right = parser.parseUnary()
    # power constant folding: if both operands are numbers, return the result directly
    if result.kind == nkNumber and right.kind == nkNumber:
      result = AstNode(kind: nkNumber, value: result.value ^ right.value, position: prev.position)
    else:
      result = AstNode(kind: nkPow, left: result, right: right, position: prev.position)
  return result

proc parseFactor(parser: var Parser): AstNode =
  ## Parses multiplication/division operations
  result = parser.parsePower()
  while parser.match({tkMul, tkDiv, tkMod}):
    let prev = parser.previous()
    let right = parser.parsePower()
    case prev.kind
    of tkMul:
      # multiplication constant folding: if both operands are numbers, return the result directly
      if result.kind == nkNumber and right.kind == nkNumber:
        result = AstNode(kind: nkNumber, value: result.value * right.value, position: prev.position)
      else:
        result = AstNode(kind: nkMul, left: result, right: right, position: prev.position)
    of tkDiv:
      # division constant folding: if both operands are numbers, return the result directly
      if result.kind == nkNumber and right.kind == nkNumber:
        result = AstNode(kind: nkNumber, value: result.value / right.value, position: prev.position)
      else:
        result = AstNode(kind: nkDiv, left: result, right: right, position: prev.position)
    of tkMod:
      # modulus constant folding: if both operands are numbers, return the result directly
      if result.kind == nkNumber and right.kind == nkNumber:
        result = AstNode(kind: nkNumber, value: result.value % right.value, position: prev.position)
      else:
        result = AstNode(kind: nkMod, left: result, right: right, position: prev.position)
    else:
      discard # Should never happen, is unreachable

proc parseTerm(parser: var Parser): AstNode =
  ## Parses addition/subtraction
  result = parser.parseFactor()
  while parser.match({tkSub, tkAdd}):
    let prev = parser.previous()
    let right = parser.parseFactor()
    case prev.kind
    of tkSub:
      # subtraction constant folding: if both operands are numbers, return the result directly
      if result.kind == nkNumber and right.kind == nkNumber:
        result = AstNode(kind: nkNumber, value: result.value - right.value, position: prev.position)
      else:
        result = AstNode(kind: nkSub, left: result, right: right, position: prev.position)
    else:
      # addition constant folding: if both operands are numbers, return the result directly
      if result.kind == nkNumber and right.kind == nkNumber:
        result = AstNode(kind: nkNumber, value: result.value + right.value, position: prev.position)
      else:
        result = AstNode(kind: nkAdd, left: result, right: right, position: prev.position)

proc parseAssignment(parser: var Parser): AstNode =
  ## Parses assignment expressions
  result = parser.parseTerm()
  if result.kind != nkIdent:
    return result
  if parser.match({tkAssign}): # Assignment
    let prev = parser.previous()
    let value = parser.parseExpression()
    return
      AstNode(kind: nkAssign, ident: result.name, expr: value, position: prev.position)
  else:
    return result

proc parseBlock(parser: var Parser): AstNode =
  ## Parses block expressions
  let pos = parser.previous().position
  var expressions: seq[AstNode] = @[]
  while not parser.match({tkRcur}):
    while parser.match({tkNewline}):
      continue
    expressions.add(parser.parseExpression())
    while parser.match({tkNewline}):
      continue
    if parser.match({tkRcur}):
      break
  if expressions.len == 0:
    raise newBMathError("Blocks must contain at least one expression", pos)
  return AstNode(kind: nkBlock, expressions: expressions, position: pos)

proc parseExpression(parser: var Parser): AstNode {.inline.} =
  if parser.match({tkLcur}):
    return parser.parseBlock()
  else:
    return parser.parseAssignment()

proc parse*(tokens: seq[Token]): AstNode =
  var parser = newParser(tokens)
  result = parser.parseExpression()
  if not parser.isAtEnd:
    let token = parser.peek()
    raise newBMathError("Unexpected token " & $token, token.position)
