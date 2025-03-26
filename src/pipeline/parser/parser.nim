## parser.nim - Syntax Analysis Module
##
## Transforms token streams into abstract syntax trees using
## a recursive descent approach. Features:
## - Operator precedence handling
## - Parenthesis grouping
## - Syntax error detection
## - Abstract syntax tree construction
import ../../types/[expression, token, number]
import errors

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

template cleanUpNewlines(parser: var Parser) =
  ## Consumes newlines in token stream
  while parser.match({tkNewline}):
    discard

proc newParser(tokens: seq[Token]): Parser {.inline.} =
  ## Creates new parser from token sequence
  Parser(tokens: tokens, current: 0)

proc parseExpression(parser: var Parser): Expression {.inline.}

proc parseGroupOrFuncInvoke(parser: var Parser): Expression =
  ## Parses grouped expressions: (expression) and, if immediately followed by '(',
  ## parses function invocations on the grouped expression.
  let pos = parser.previous().position
  parser.cleanUpNewlines()
  let expr = parser.parseExpression()
  parser.cleanUpNewlines()
  if not parser.match({tkRpar}):
    raise newMissingTokenError("Expected ')'", pos)
  if parser.match({tkLpar}):
    var args: seq[Expression] = @[]
    while true:
      if parser.match({tkRpar}):
        break
      args.add(parser.parseExpression())
      if parser.match({tkRpar}):
        break
      if not parser.match({tkComma}):
        raise newMissingTokenError("Expected ','", parser.previous().position)
    result = Expression(kind: ekFuncInvoke, position: pos, fun: expr, arguments: args)
  else:
    result = expr

proc parseIdentifierOrFuncCall(parser: var Parser): Expression =
  ## Parses identifiers and distinguishes between variable references and function calls.
  let token = parser.previous()
  if parser.match({tkLpar}):
    var args: seq[Expression] = @[]
    while not parser.match({tkRpar}):
      parser.cleanUpNewlines()
      args.add(parser.parseExpression())
      parser.cleanUpNewlines()
      if parser.match({tkRpar}):
        break
      if not parser.match({tkComma}):
        raise newMissingTokenError("Expected ','", parser.previous().position)
    return newFuncCallExpr(token.position, token.name, args)
  else:
    return newIdentExpr(token.position, token.name)

proc parseFunction(parser: var Parser): Expression =
  ## Parses function definitions with parameters and body.
  var params: seq[string] = @[]
  while not parser.match({tkLine}):
    if parser.match({tkIdent}):
      params.add(parser.previous().name)
    else:
      raise newUnexpectedTokenError(
        "Expected identifier but got '" & $parser.previous().kind & "'",
        parser.previous().position,
      )
    if parser.match({tkLine}):
      break
    if not parser.match({tkComma}):
      raise newMissingTokenError("Expected ','", parser.previous().position)
  return newFuncExpr(parser.previous().position, params, parser.parseExpression())

proc parseVector(parser: var Parser): Expression =
  ## Parses vector literals
  template cleanUpNewlines() =
    while parser.match({tkNewline}):
      discard

  let pos = parser.previous().position
  var values: seq[Expression] = @[]
  while not parser.match({tkRSquare}):
    parser.cleanUpNewlines()
    values.add(parser.parseExpression())
    parser.cleanUpNewlines()
    if parser.match({tkRSquare}):
      break
    if not parser.match({tkComma}):
      raise newMissingTokenError("Expected ','", parser.previous().position)
  return newVectorExpr(pos, values)

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
      raise newMissingTokenError(
        "Expected newline or '}' after expression", parser.peek().position
      )
    # Clear the rest of the newlines.
    while parser.match({tkNewline}):
      discard
    if parser.match({tkRCurly}):
      break
  if expressions.len == 0:
    raise newInvalidExpressionError("Blocks must contain at least one expression", pos)
  return newBlockExpr(pos, expressions)

proc parseIf(parser: var Parser): Expression =
  ## Parses if-elif-else-endif expressions
  template cleanUpNewlines() =
    while parser.match({tkNewline}):
      discard

  let pos = parser.previous().position
  cleanUpNewlines()
  var branches: seq[Condition] = @[]
  var elseBranch: Expression
  # Check ( after if
  if not parser.match({tkLpar}):
    raise newMissingTokenError("Expected '(' after 'if'", parser.previous().position)
  cleanUpNewlines()
  let condition = parser.parseExpression()
  cleanUpNewlines()
  if not parser.match({tkRpar}):
    raise
      newMissingTokenError("Expected ')' after condition", parser.previous().position)
  cleanUpNewlines()
  branches.add(newCondition(condition, parser.parseExpression()))

  # Parse elif conditions
  while parser.match({tkElif}):
    if not parser.match({tkLpar}):
      raise
        newMissingTokenError("Expected '(' after 'elif'", parser.previous().position)
    cleanUpNewlines()
    let condition = parser.parseExpression()
    cleanUpNewlines()
    if not parser.match({tkRpar}):
      raise
        newMissingTokenError("Expected ')' after condition", parser.previous().position)
    cleanUpNewlines()
    branches.add(newCondition(condition, parser.parseExpression()))

  # Parse else branch, else is always required
  cleanUpNewlines()
  if not parser.match({tkElse}):
    raise newMissingTokenError(
      "Expected 'else' after if-elif conditions", parser.previous().position
    )
  cleanUpNewlines()
  elseBranch = parser.parseExpression()
  result = newIfExpr(pos, branches, elseBranch)

proc parsePrimary(parser: var Parser): Expression =
  ## Parses primary expressions: numbers, groups, identifiers, and function definitions.
  let token = parser.peek()
  if parser.match({tkLpar}):
    return parser.parseGroupOrFuncInvoke()
  elif parser.match({tkLCurly}):
    result = parser.parseBlock()
  elif parser.match({tkIf}):
    result = parser.parseIf()
  elif parser.match({tkNumber}):
    return newNumberExpr(token.position, token.nValue)
  elif parser.match({tkTrue}):
    return newBoolExpr(token.position, true)
  elif parser.match({tkFalse}):
    return newBoolExpr(token.position, false)
  elif parser.match({tkIdent}):
    return parser.parseIdentifierOrFuncCall()
  elif parser.match({tkLine}):
    return parser.parseFunction()
  elif parser.match({tkLSquare}):
    return parser.parseVector()
  else:
    let token = parser.peek()
    raise newUnexpectedTokenError("Unexpected token " & $token, token.position)

proc parseUnary(parser: var Parser): Expression =
  ## Parses unary negations
  if parser.match({tkSub}):
    let pos = parser.previous().position
    let operand = parser.parseUnary()
    # Unary constant folding: if the operand is a number, return its negation directly
    case operand.kind
    of ekNumber:
      return newNumberExpr(pos, -operand.nValue)
    else:
      return newNegExpr(pos, operand)
  if parser.match({tkNot}):
    let pos = parser.previous().position
    let operand = parser.parseUnary()
    # Unary constant folding: if the operand is a boolean, return its negation directly
    case operand.kind
    of ekTrue:
      return newBoolExpr(pos, false)
    of ekFalse:
      return newBoolExpr(pos, true)
    else:
      return newNotExpr(pos, operand)
  else:
    return parser.parsePrimary()

proc parseChain(parser: var Parser): Expression =
  ## Parses chained expressions
  result = parser.parseUnary()
  while parser.match({tkChain}):
    # parse chain operator
    let prev = parser.previous()
    let right = parser.parsePrimary()
    if right.kind == ekFuncInvoke:
      result = newFuncInvokeExpr(prev.position, right.fun, @[result] & right.arguments)
    else:
      result = newFuncInvokeExpr(prev.position, right, @[result])

proc parsePower(parser: var Parser): Expression =
  ## Parses power operations
  result = parser.parseChain()
  while parser.match({tkPow}):
    let prev = parser.previous()
    let right = parser.parseChain()
    # power constant folding: if both operands are numbers, return the result directly
    result = newBinaryExpr(prev.position, ekPow, result, right)
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
      result = newBinaryExpr(prev.position, ekMul, result, right)
    of tkDiv:
      # division constant folding: if both operands are numbers, return the result directly
      result = newBinaryExpr(prev.position, ekDiv, result, right)
    of tkMod:
      # modulus constant folding: if both operands are numbers, return the result directly
      result = newBinaryExpr(prev.position, ekMod, result, right)
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
      result = newBinaryExpr(prev.position, ekSub, result, right)
    else:
      # addition constant folding: if both operands are numbers, return the result directly
      result = newBinaryExpr(prev.position, ekAdd, result, right)

proc parseComparison(parser: var Parser): Expression =
  ## Parses < <= > >= comparisons
  result = parser.parseTerm()
  while parser.match({tkLt, tkLe, tkGt, tkGe}):
    let prev = parser.previous()
    let right = parser.parseTerm()
    case prev.kind
    of tkLt:
      result = newBinaryExpr(prev.position, ekLt, result, right)
    of tkLe:
      result = newBinaryExpr(prev.position, ekLe, result, right)
    of tkGt:
      result = newBinaryExpr(prev.position, ekGt, result, right)
    of tkGe:
      result = newBinaryExpr(prev.position, ekGe, result, right)
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
      result = newBinaryExpr(prev.position, ekEq, result, right)
    of tkNe:
      result = newBinaryExpr(prev.position, ekNe, result, right)
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
      result = newBinaryExpr(prev.position, ekAnd, result, right)
    of tkLine:
      result = newBinaryExpr(prev.position, ekOr, result, right)
    else:
      discard # Should never happen, is unreachable

proc parseAssignment(parser: var Parser): Expression =
  ## Parses assignment expressions
  if parser.match({tkIdent, tkLocal}):
    let local = parser.previous().kind == tkLocal
    if local and not parser.match({tkIdent}):
      raise newMissingTokenError(
        "Expected identifier after 'local'", parser.previous().position
      )
    let name = parser.previous()
    if parser.match({tkAssign}):
      let value = parser.parseExpression()
      return newAssignExpr(name.position, name.name, value, local)
    elif not local:
      parser.back()
    else:
      raise newMissingTokenError(
        "Expected '=' after local '" & name.name & "'", parser.previous().position
      )
  return parser.parseBoolean()

proc parseExpression(parser: var Parser): Expression {.inline.} =
  result = parser.parseAssignment()

proc parse*(tokens: seq[Token]): Expression =
  var parser = newParser(tokens)
  result = parser.parseExpression()
  if not parser.isAtEnd:
    let token = parser.peek()
    raise newUnexpectedTokenError("Unexpected token " & $token, token.position)
