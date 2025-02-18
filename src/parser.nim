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
  tokens: seq[Token] ## Sequence of tokens to parse
  current: int ## Current position in token stream

template isAtEnd(parser: Parser): bool =
  ## Checks if parser has reached end of token stream
  parser.current >= parser.tokens.len

template previous(parser: Parser): Token =
  ## Returns token at previous position
  if parser.current > 0:
    parser.tokens[parser.current - 1]
  else:
    Token(kind: tkEoe)

template peek(parser: Parser): Token =
  ## Returns token at current position but does not advance the parser
  if not parser.isAtEnd:
    parser.tokens[parser.current]
  else:
    Token(kind: tkEoe, position: parser.previous().position)

template advance(parser: var Parser) =
  ## Moves to next token in stream
  if not parser.isAtEnd:
    parser.current += 1

template back(parser: var Parser) =
  ## Moves to previous token in stream
  if parser.current > 0:
    parser.current -= 1

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

template constantFolding(
    op: untyped, l: Expression, r: Expression, pos: Position, nk: ExpressionKind
): Expression =
  ## Helper template for constant folding
  try:
    if l.kind == ekValue and r.kind == ekValue:
      let val = op(l.value, r.value)
      Expression(kind: ekValue, value: val, position: pos)
    else:
      Expression(kind: nk, left: l, r: right, position: pos)
  except BMathError as e:
    e.position = pos
    raise e

proc newParser(tokens: seq[Token]): Parser {.inline.} =
  ## Creates new parser from token sequence
  Parser(tokens: tokens, current: 0)

proc parseExpression(parser: var Parser): Expression {.inline.}

proc parseGroup(parser: var Parser): Expression =
  ## Parses grouped expressions: (expression) and constant folding for groups
  let pos = parser.previous().position
  let expr = parser.parseExpression()
  if not parser.match({tkRpar}):
    raise newBMathError("Expected ')'", parser.previous().position)
  # Constant folding for groups: if the expression is a number, return it directly
  if expr.kind == ekValue:
    return expr
  return Expression(kind: ekGroup, child: expr, position: pos)

proc parseNumber(parser: var Parser): Expression =
  ## Parses numeric literals
  let token = parser.previous()
  return Expression(kind: ekValue, value: token.value, position: token.position)

proc parseIdentifierOrFuncCall(parser: var Parser): Expression =
  ## Parses identifiers and distinguishes between variable references and function calls.
  let token = parser.previous()
  if parser.match({tkLpar}):
    var args: seq[Expression] = @[]
    while not parser.match({tkRpar}):
      args.add(parser.parseExpression())
      if parser.match({tkRpar}):
        break
      if not parser.match({tkComma}):
        raise newBMathError("Expected ','", parser.previous().position)
    return Expression(
      kind: ekFuncCall, fun: token.name, args: args, position: token.position
    )
  else:
    return Expression(kind: ekIdent, name: token.name, position: token.position)

proc parseFunction(parser: var Parser): Expression =
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
  return Expression(kind: ekFunc, params: params, body: parser.parseExpression())

proc parseVector(parser: var Parser): Expression =
  ## Parses vector literals
  let pos = parser.previous().position
  var values: seq[Expression] = @[]
  while not parser.match({tkRSquare}):
    values.add(parser.parseExpression())
    if parser.match({tkRSquare}):
      break
    if not parser.match({tkComma}):
      raise newBMathError("Expected ','", parser.previous().position)
  return Expression(kind: ekVector, values: values, position: pos)

proc parsePrimary(parser: var Parser): Expression =
  ## Parses primary expressions: numbers, groups, identifiers, and function definitions.
  if parser.match({tkLpar}):
    return parser.parseGroup()
  elif parser.match({tkValue}):
    return parser.parseNumber()
  elif parser.match({tkIdent}):
    return parser.parseIdentifierOrFuncCall()
  elif parser.match({tkLine}):
    return parser.parseFunction()
  elif parser.match({tkLSquare}):
    return parser.parseVector()
  else:
    let token = parser.peek()
    raise newBMathError("Unexpected token " & $token, token.position)

proc parseUnary(parser: var Parser): Expression =
  ## Parses unary negations
  if parser.match({tkSub}):
    let pos = parser.previous().position
    let operand = parser.parseUnary()
    # Unary constant folding: if the operand is a number, return its negation directly
    if operand.kind == ekValue:
      return Expression(kind: ekValue, value: -operand.value, position: pos)
    return Expression(kind: ekNeg, operand: operand, position: pos)
  else:
    return parser.parsePrimary()

proc parsePower(parser: var Parser): Expression =
  ## Parses power operations
  result = parser.parseUnary()
  while parser.match({tkPow}):
    let prev = parser.previous()
    let right = parser.parseUnary()
    # power constant folding: if both operands are numbers, return the result directly
    result = constantFolding(`^`, result, right, prev.position, ekPow)
  return result

proc parseFactor(parser: var Parser): Expression =
  ## Parses multiplication/division operations
  result = parser.parsePower()
  while parser.match({tkMul, tkDiv, tkMod}):
    let prev = parser.previous()
    let right = parser.parsePower()
    case prev.kind
    of tkMul:
      # multiplication constant folding: if both operands are numbers, return the result directly
      result = constantFolding(`*`, result, right, prev.position, ekMul)
    of tkDiv:
      # division constant folding: if both operands are numbers, return the result directly
      result = constantFolding(`/`, result, right, prev.position, ekDiv)
    of tkMod:
      # modulus constant folding: if both operands are numbers, return the result directly
      result = constantFolding(`%`, result, right, prev.position, ekMod)
    else:
      discard # Should never happen, is unreachable

proc parseTerm(parser: var Parser): Expression =
  ## Parses addition/subtraction
  result = parser.parseFactor()
  while parser.match({tkSub, tkAdd}):
    let prev = parser.previous()
    let right = parser.parseFactor()
    case prev.kind
    of tkSub:
      # subtraction constant folding: if both operands are numbers, return the result directly
      result = constantFolding(`-`, result, right, prev.position, ekSub)
    else:
      # addition constant folding: if both operands are numbers, return the result directly
      result = constantFolding(`+`, result, right, prev.position, ekAdd)

proc parseComparison(parser: var Parser): Expression =
  ## Parses < <= > >= comparisons
  result = parser.parseTerm()
  while parser.match({tkLt, tkLe, tkGt, tkGe}):
    let prev = parser.previous()
    let right = parser.parseTerm()
    case prev.kind
    of tkLt:
      result = constantFolding(`<`, result, right, prev.position, ekLt)
    of tkLe:
      result = constantFolding(`<=`, result, right, prev.position, ekLe)
    of tkGt:
      result = constantFolding(`>`, result, right, prev.position, ekGt)
    of tkGe:
      result = constantFolding(`>=`, result, right, prev.position, ekGe)
    else:
      discard # Should never happen, is unreachable

proc parseEquality(parser: var Parser): Expression =
  ## Parses == and != operators
  result = parser.parseComparison()
  while parser.match({tkEq, tkNe}):
    let prev = parser.previous()
    let right = parser.parseComparison()
    case prev.kind
    of tkEq:
      result = constantFolding(`==`, result, right, prev.position, ekEq)
    of tkNe:
      result = constantFolding(`!=`, result, right, prev.position, ekNe)
    else:
      discard # Should never happen, is unreachable

proc parseBoolean(parser: var Parser): Expression =
  ## Parses & and | operators
  result = parser.parseEquality()
  while parser.match({tkAnd, tkLine}):
    let prev = parser.previous()
    let right = parser.parseEquality()
    case prev.kind
    of tkAnd:
      result = constantFolding(`and`, result, right, prev.position, ekAnd)
    of tkLine:
      result = constantFolding(`or`, result, right, prev.position, ekOr)
    else:
      discard # Should never happen, is unreachable

proc parseAssignment(parser: var Parser): Expression =
  ## Parses assignment expressions
  if parser.match({tkIdent, tkLocal}):
    let local = parser.previous().kind == tkLocal
    if local and not parser.match({tkIdent}):
      raise newBMathError("Expected identifier after 'local'", parser.previous().position)
    let name = parser.previous()
    if parser.match({tkAssign}):
      let value = parser.parseExpression()
      return Expression(
        kind: ekAssign, ident: name.name, expr: value, isLocal: local, position: name.position
      )
    elif not local: 
      parser.back()
    else:
      raise newBMathError("Expected '=' after local '" & name.name & "'", parser.previous().position)
  return parser.parseBoolean()

proc parseBlock(parser: var Parser): Expression =
  ## Parses block expressions
  let pos = parser.previous().position
  # Skip newlines after '{'
  while parser.match({tkNewline}):
    continue
  var expressions: seq[Expression] = @[]
  while true:
    expressions.add(parser.parseExpression())
    # After an expression, require at least one newline or a closing curly brace.
    if parser.match({tkRCurly}):
      break
    if not parser.match({tkNewline}):
      raise newBMathError(
        "Expected newline or '}' after expression", parser.peek().position
      )
    # Clear the rest of the newlines.
    while parser.match({tkNewline}):
      discard
    if parser.match({tkRCurly}):
      break
  if expressions.len == 0:
    raise newBMathError("Blocks must contain at least one expression", pos)
  return Expression(kind: ekBlock, expressions: expressions, position: pos)

proc parseIf(parser: var Parser): Expression =
  ## Parses if-elif-else-endif expressions
  template cleanUpNewlines() =
    while parser.match({tkNewline}):
      discard

  let pos = parser.previous().position
  cleanUpNewlines()
  var branches: seq[tuple[condition: Expression, thenBranch: Expression]] = @[]
  var elseBranch: Expression
  # Check ( after if
  if not parser.match({tkLpar}):
    raise newBMathError("Expected '(' after 'if'", parser.previous().position)
  cleanUpNewlines()
  let condition = parser.parseExpression()
  cleanUpNewlines()
  if not parser.match({tkRpar}):
    raise newBMathError("Expected ')' after condition", parser.previous().position)
  cleanUpNewlines()
  branches.add((condition: condition, thenBranch: parser.parseExpression()))

  # Parse elif conditions
  while parser.match({tkElif}):
    if not parser.match({tkLpar}):
      raise newBMathError("Expected '(' after 'elif'", parser.previous().position)
    cleanUpNewlines()
    let condition = parser.parseExpression()
    cleanUpNewlines()
    if not parser.match({tkRpar}):
      raise newBMathError("Expected ')' after condition", parser.previous().position)
    cleanUpNewlines()
    branches.add((condition: condition, thenBranch: parser.parseExpression()))

  # Parse else branch, else is always required
  cleanUpNewlines()
  if not parser.match({tkElse}):
    raise newBMathError(
      "Expected 'else' after if-elif conditions", parser.previous().position
    )
  cleanUpNewlines()
  elseBranch = parser.parseExpression()
  cleanUpNewlines()
  if not parser.match({tkEndIf}):
    raise
      newBMathError("Expected 'endif' after if-elif-else", parser.previous().position)
  result =
    Expression(kind: ekIf, branches: branches, elseBranch: elseBranch, position: pos)

proc parseExpression(parser: var Parser): Expression {.inline.} =
  if parser.match({tkLCurly}):
    return parser.parseBlock()
  elif parser.match({tkIf}):
    return parser.parseIf()
  else:
    return parser.parseAssignment()

proc parse*(tokens: seq[Token]): Expression =
  var parser = newParser(tokens)
  result = parser.parseExpression()
  if not parser.isAtEnd:
    let token = parser.peek()
    raise newBMathError("Unexpected token " & $token, token.position)
