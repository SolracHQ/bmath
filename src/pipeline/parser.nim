## parser.nim - Syntax Analysis Module
##
## Transforms token streams into abstract syntax trees (AST) using
## a recursive descent approach with the following capabilities:
##
## - Expression parsing with proper operator precedence
## - Support for parenthesized expression grouping
## - Function definition and invocation handling
## - Control structures (if-elif-else blocks)
## - Variable assignment and reference
## - Vector literal parsing
## - Block expressions for statement sequencing
## - Robust error detection with position tracking

import ../types/[expression, token, number, bm_types, value, errors]

type Parser = object
  tokens: seq[Token] ## Sequence of tokens to parse
  current: int ## Current position in token stream

template isAtEnd(parser: Parser): bool =
  ## Checks if parser has reached end of token stream
  ##
  ## Params:
  ##   parser: Parser - the parser to check
  ##
  ## Returns: bool - true if at end of token stream, false otherwise
  parser.current >= parser.tokens.len

template previous(parser: Parser): Token =
  ## Returns token at previous position
  ##
  ## Params:
  ##   parser: Parser - the parser to get token from
  ##
  ## Returns: Token - the previous token, or an EOE token if at the beginning
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
  ##
  ## Params:
  ##   parser: var Parser - the parser to advance
  if not parser.isAtEnd:
    parser.current += 1

template back(parser: var Parser) =
  ## Moves to previous token in stream
  ##
  ## Params:
  ##   parser: var Parser - the parser to move back
  if parser.current > 0:
    parser.current -= 1

template check(parser: Parser, kd: static[set[TokenKind]]): bool =
  ## Checks if current token matches any of the given kinds
  ##
  ## Params:
  ##   parser: Parser - the parser to check
  ##   kd: set[TokenKind] - set of token kinds to match against
  ##
  ## Returns: bool - true if the current token matches any kind in the set
  not parser.isAtEnd and parser.peek.kind in kd

template `match`(parser: var Parser, kind: set[TokenKind]): bool =
  ## Consumes current token if it matches any of the given kinds
  ##
  ## Params:
  ##   parser: var Parser - the parser to match tokens from
  ##   kind: set[TokenKind] - set of token kinds to match against
  ##
  ## Returns: bool - true if a token was matched and consumed, false otherwise
  if parser.check(kind):
    parser.advance()
    true
  else:
    false

template cleanUpNewlines(parser: var Parser) =
  ## Consumes newlines in token stream
  ##
  ## Params:
  ##   parser: var Parser - the parser to clean newlines from
  while parser.match({tkNewline}):
    discard

proc newParser*(tokens: seq[Token]): Parser {.inline.} =
  ## Creates new parser from token sequence
  ##
  ## Params:
  ##   tokens: seq[Token] - sequence of tokens to parse
  ##
  ## Returns: Parser - a new parser instance initialized with tokens
  Parser(tokens: tokens, current: 0)

# Forward declaration for recursive descent parser
proc parseExpression(parser: var Parser): Expression {.inline.}

proc parseGroup(parser: var Parser): Expression {.inline.} =
  ## Parses grouped expressions: (expression) and, if immediately followed by '(',
  ## parses function invocations on the grouped expression.
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract group from
  ##
  ## Returns: Expression - the parsed expression inside the group
  ##
  ## Raises:
  ##   MissingTokenError - if closing parenthesis is not found
  let pos = parser.previous().position
  parser.cleanUpNewlines()
  result = parser.parseExpression()
  parser.cleanUpNewlines()
  if not parser.match({tkRpar}):
    raise newMissingTokenError("Expected ')'", pos)

proc parseIdentifier(parser: var Parser): Expression {.inline.} =
  ## Parses identifiers and distinguishes between variable references and function calls.
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract identifier from
  ##
  ## Returns: Expression - the parsed identifier expression
  let token = parser.previous()
  return newIdentExpr(token.position, token.name)

proc parseFunction(parser: var Parser): Expression =
  ## Parses function definitions with parameters and body.
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract function from
  ##
  ## Returns: Expression - the parsed function expression
  ##
  ## Raises:
  ##   UnexpectedTokenError - if an identifier is expected but not found
  ##   MissingTokenError - if a comma is expected but not found
  var params: seq[Parameter] = @[]
  # parse parameter list until closing '|'
  while not parser.match({tkLine}):
    parser.cleanUpNewlines()
    if parser.match({tkIdent}):
      # simple param without explicit type
      let name = parser.previous().name
      var typ = AnyType
      if parser.match({tkColon}):
        if not parser.match({tkType}):
          raise newMissingTokenError("Expected type after ':'", parser.previous().position)
        typ = parser.previous().value.typ
      params.add(Parameter(name: name, typ: typ))
    elif parser.match({tkLine}):
      break
    else:
      if not parser.match({tkComma}):
        raise newMissingTokenError("Expected ','", parser.previous().position)

  # optional return type: '=>' TYPE
  var returnType: BMathType = AnyType
  if parser.match({tkFatArrow}):
    if not parser.match({tkType}):
      raise newMissingTokenError("Expected type after '=>'", parser.previous().position)
    returnType = parser.previous().value.typ

  return newFuncExpr(parser.previous().position, params, parser.parseExpression(), returnType)

proc parseVector*(parser: var Parser): Expression =
  ## Parses vector literals
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract vector from
  ##
  ## Returns: Expression - the parsed vector expression
  ##
  ## Raises:
  ##   MissingTokenError - if a comma is expected but not found
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

proc parseBlock*(parser: var Parser): Expression =
  ## Returns: Expression - the parsed block expression
  ##
  ## Raises:
  ##   MissingTokenError - if a newline or closing curly brace is expected but not found
  ##   InvalidExpressionError - if the block contains no expressions

  let pos = parser.previous().position
  parser.cleanUpNewlines()
  var expressions: seq[Expression] = @[]
  while true:
    expressions.add(parser.parseExpression())
    if parser.match({tkRCurly}):
      break
    if not parser.match({tkNewline}):
      raise newMissingTokenError(
        "Expected newline or '}' after expression", parser.peek().position
      )
    while parser.match({tkNewline}):
      discard
    if parser.match({tkRCurly}):
      break
  if expressions.len == 0:
    raise newInvalidExpressionError("Blocks must contain at least one expression", pos)
  return newBlockExpr(pos, expressions)

proc parseIf*(parser: var Parser): Expression =
  ## Parses if-elif-else expressions
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract if-elif-else from
  ##
  ## Returns: Expression - the parsed if expression
  ##
  ## Raises:
  ##   MissingTokenError - if expected tokens are not found
  let pos = parser.previous().position
  parser.cleanUpNewlines()
  var branches: seq[Branch] = @[]
  var elseBranch: Expression

  # ----- PARSING IF CONDITION -----
  if not parser.match({tkLpar}):
    raise newMissingTokenError("Expected '(' after 'if'", parser.previous().position)
  parser.cleanUpNewlines()

  let branch = parser.parseExpression()

  parser.cleanUpNewlines()
  if not parser.match({tkRpar}):
    raise
      newMissingTokenError("Expected ')' after condition", parser.previous().position)

  parser.cleanUpNewlines()
  branches.add(newBranch(branch, parser.parseExpression()))
  parser.cleanUpNewlines()

  # ----- PARSING ELIF CONDITIONS -----
  while parser.match({tkElif}):
    if not parser.match({tkLpar}):
      raise
        newMissingTokenError("Expected '(' after 'elif'", parser.previous().position)

    parser.cleanUpNewlines()
    let branch = parser.parseExpression()

    parser.cleanUpNewlines()
    if not parser.match({tkRpar}):
      raise
        newMissingTokenError("Expected ')' after condition", parser.previous().position)

    parser.cleanUpNewlines()
    branches.add(newBranch(branch, parser.parseExpression()))
    parser.cleanUpNewlines()

  # ----- PARSING ELSE BRANCH -----
  parser.cleanUpNewlines()
  if not parser.match({tkElse}):
    raise newMissingTokenError(
      "Expected 'else' after if-elif conditions but got " & $parser.peek(),
      parser.previous().position,
    )

  parser.cleanUpNewlines()
  elseBranch = parser.parseExpression()

  result = newIfExpr(pos, branches, elseBranch)

  # ----- OPTIMIZATION -----
  # If conditions are trivially boolean, return the first expression that is true
  var allBool = true
  for branch in branches:
    if branch.condition.kind == ekValue and branch.condition.value.kind == vkBool:
      if branch.condition.value.boolean:
        return branch.then
    else:
      allBool = false

  if allBool:
    return result.ifExpr.elseBranch

proc parsePrimary*(parser: var Parser): Expression =
  ## Parses primary expressions: numbers, groups, identifiers, and function definitions.
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract primary expression from
  ##
  ## Returns: Expression - the parsed primary expression
  ##
  ## Raises:
  ##   UnexpectedTokenError - if an unexpected token is encountered
  let token = parser.peek()
  if parser.match({tkLpar}):
    result = parser.parseGroup()
  elif parser.match({tkLCurly}):
    result = parser.parseBlock()
  elif parser.match({tkIf}):
    result = parser.parseIf()
  elif parser.match({tkNumber}):
    result = newValueExpr(token.position, token.value)
  elif parser.match({tkTrue}):
    result = newValueExpr(token.position, newValue(true))
  elif parser.match({tkFalse}):
    result = newValueExpr(token.position, newValue(false))
  elif parser.match({tkIdent}):
    result = parser.parseIdentifier()
  elif parser.match({tkString}):
    result = newValueExpr(token.position, token.value)
  elif parser.match({tkLine}):
    result = parser.parseFunction()
  elif parser.match({tkLSquare}):
    result = parser.parseVector()
  elif parser.match({tkType}):
    result = newValueExpr(token.position, token.value)
  else:
    let token = parser.peek()
    raise newUnexpectedTokenError("Unexpected token " & $token, token.position)

proc parseFunctionCall*(parser: var Parser): Expression =
  ## Parses function calls
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract function call from
  ##
  ## Returns: Expression - the parsed function call expression
  ##
  ## Raises:
  ##   MissingTokenError - if expected tokens are not found
  result = parser.parsePrimary()
  if parser.match({tkLpar}):
    let prev = parser.previous()
    var args: seq[Expression] = @[]
    while not parser.match({tkRpar}):
      parser.cleanUpNewlines()
      args.add(parser.parseExpression())
      parser.cleanUpNewlines()
      if parser.match({tkRpar}):
        break
      if not parser.match({tkComma}):
        raise newMissingTokenError("Expected ','", parser.previous().position)
    result = newFuncCallExpr(prev.position, result, args)

proc parseUnary*(parser: var Parser): Expression =
  ## Parses unary negations
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract unary expression from
  ##
  ## Returns: Expression - the parsed unary expression
  if parser.match({tkSub}):
    let pos = parser.previous().position
    let operand = parser.parseUnary()

    if operand.kind == ekValue and operand.value.kind == vkNumber:
      # Optimize for numeric negation
      return newValueExpr(pos, newValue(-operand.value.number))
    else:
      return newNegExpr(pos, operand)
  elif parser.match({tkNot}):
    let pos = parser.previous().position
    let operand = parser.parseUnary()

    if operand.kind == ekValue and operand.value.kind == vkBool:
      return newValueExpr(pos, newValue(not operand.value.boolean))
    else:
      return newNotExpr(pos, operand)
  else:
    return parser.parseFunctionCall()

proc parseChain*(parser: var Parser): Expression =
  ## Parses chained expressions
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract chain expression from
  ##
  ## Returns: Expression - the parsed chain expression
  result = parser.parseUnary()
  while parser.match({tkChain}):
    let prev = parser.previous()
    let right = parser.parseFunctionCall()
    if right.kind == ekFuncCall:
      result = newFuncCallExpr(
        prev.position,
        right.functionCall.function,
        @[result] & right.functionCall.params,
      )
    else:
      result = newFuncCallExpr(prev.position, right, @[result])

proc parsePower*(parser: var Parser): Expression =
  ## Parses power operations
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract power expression from
  ##
  ## Returns: Expression - the parsed power expression
  result = parser.parseChain()
  while parser.match({tkPow}):
    let prev = parser.previous()
    let right = parser.parseChain()

    if result.kind == ekValue and right.kind == ekValue and result.value.kind == vkNumber and
        right.value.kind == vkNumber:
      # Optimize by computing power at parse time when both operands are numbers
      result =
        newValueExpr(prev.position, newValue(result.value.number ^ right.value.number))
    else:
      result = newBinaryExpr(prev.position, ekPow, result, right)

  return result

proc parseFactor*(parser: var Parser): Expression =
  ## Parses multiplication/division operations
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract factor expression from
  ##
  ## Returns: Expression - the parsed factor expression
  result = parser.parsePower()
  while parser.match({tkMul, tkDiv, tkMod}):
    let prev = parser.previous()
    let right = parser.parsePower()

    if prev.kind == tkMul:
      if result.kind == ekValue and right.kind == ekValue and
          result.value.kind == vkNumber and right.value.kind == vkNumber:
        result = newValueExpr(
          prev.position, newValue(result.value.number * right.value.number)
        )
      else:
        result = newBinaryExpr(prev.position, ekMul, result, right)
    elif prev.kind == tkDiv:
      if result.kind == ekValue and right.kind == ekValue and
          result.value.kind == vkNumber and right.value.kind == vkNumber and
          not right.value.number.isZero():
        result = newValueExpr(
          prev.position, newValue(result.value.number / right.value.number)
        )
      else:
        result = newBinaryExpr(prev.position, ekDiv, result, right)
    elif prev.kind == tkMod:
      if result.kind == ekValue and right.kind == ekValue and
          result.value.kind == vkNumber and right.value.kind == vkNumber and
          result.value.number.kind != nkComplex and not right.value.number.isZero():
        result = newValueExpr(
          prev.position, newValue(result.value.number % right.value.number)
        )
      else:
        result = newBinaryExpr(prev.position, ekMod, result, right)

proc parseTerm*(parser: var Parser): Expression =
  ## Parses addition/subtraction
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract term expression from
  ##
  ## Returns: Expression - the parsed term expression
  result = parser.parseFactor()
  while parser.match({tkSub, tkAdd}):
    let prev = parser.previous()
    let right = parser.parseFactor()
    if prev.kind == tkSub:
      if result.kind == ekValue and right.kind == ekValue and
          result.value.kind == vkNumber and right.value.kind == vkNumber:
        result = newValueExpr(
          prev.position, newValue(result.value.number - right.value.number)
        )
      else:
        result = newBinaryExpr(prev.position, ekSub, result, right)
    elif prev.kind == tkAdd:
      if result.kind == ekValue and right.kind == ekValue and
          result.value.kind == vkNumber and right.value.kind == vkNumber:
        result = newValueExpr(
          prev.position, newValue(result.value.number + right.value.number)
        )
      else:
        result = newBinaryExpr(prev.position, ekAdd, result, right)

proc parseComparison*(parser: var Parser): Expression =
  ## Parses < <= > >= comparisons
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract comparison expression from
  ##
  ## Returns: Expression - the parsed comparison expression
  result = parser.parseTerm()
  while parser.match({tkLt, tkLe, tkGt, tkGe}):
    let prev = parser.previous()
    let right = parser.parseTerm()

    if result.kind == ekValue and right.kind == ekValue and result.value.kind == vkNumber and
        right.value.kind == vkNumber and result.value.number.kind != nkComplex and
        right.value.number.kind != nkComplex:
      if prev.kind == tkLt:
        result = newValueExpr(
          prev.position, newValue(result.value.number < right.value.number)
        )
      elif prev.kind == tkLe:
        result = newValueExpr(
          prev.position, newValue(result.value.number <= right.value.number)
        )
      elif prev.kind == tkGt:
        result = newValueExpr(
          prev.position, newValue(result.value.number > right.value.number)
        )
      elif prev.kind == tkGe:
        result = newValueExpr(
          prev.position, newValue(result.value.number >= right.value.number)
        )
    else:
      if prev.kind == tkLt:
        result = newBinaryExpr(prev.position, ekLt, result, right)
      elif prev.kind == tkLe:
        result = newBinaryExpr(prev.position, ekLe, result, right)
      elif prev.kind == tkGt:
        result = newBinaryExpr(prev.position, ekGt, result, right)
      elif prev.kind == tkGe:
        result = newBinaryExpr(prev.position, ekGe, result, right)

proc parseEquality*(parser: var Parser): Expression =
  ## Parses ==, != and is operators
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract equality expression from
  ##
  ## Returns: Expression - the parsed equality expression
  result = parser.parseComparison()
  while parser.match({tkEq, tkNe, tkIs}):
    let prev = parser.previous()
    let right = parser.parseComparison()

    # if tkIs and right.typ is AnyType, we can just return true
    if prev.kind == tkIs and right.kind == ekValue and right.value.kind == vkType and
        right.value.typ === AnyType:
      return newValueExpr(prev.position, newValue(true))

    if prev.kind == tkIs:
      # we need rap left in a get_type call and compare equal to right
      let getTypeCall = newFuncCallExpr(
        prev.position, newIdentExpr(prev.position, "get_type"), @[result]
      )
      result = newBinaryExpr(prev.position, ekEq, getTypeCall, right)
      continue
        

    # Optimize for numbers and booleans
    if (
      result.kind == ekValue and right.kind == ekValue and result.value.kind == vkNumber and
      right.value.kind == vkNumber
    ):
      let areEqual = result.value.number == right.value.number
      if prev.kind == tkEq:
        result = newValueExpr(prev.position, newValue(areEqual))
      else: # tkNe
        result = newValueExpr(prev.position, newValue(not areEqual))
    elif (
      result.kind == ekValue and right.kind == ekValue and result.value.kind == vkBool and
      right.value.kind == vkBool
    ):
      let areEqual = result.value.boolean == right.value.boolean
      if prev.kind == tkEq:
        result = newValueExpr(prev.position, newValue(areEqual))
      else: # tkNe
        result = newValueExpr(prev.position, newValue(not areEqual))
    elif (
      result.kind == ekValue and right.kind == ekValue and (
        (result.value.kind == vkNumber and right.value.kind == vkBool) or
        (result.value.kind == vkBool and right.value.kind == vkNumber)
      )
    ):
      result = newValueExpr(prev.position, newValue(false))
    else:
      if prev.kind == tkEq or prev.kind == tkIs:
        result = newBinaryExpr(prev.position, ekEq, result, right)
      else: # tkNe
        result = newBinaryExpr(prev.position, ekNe, result, right)

proc parseLogical*(parser: var Parser): Expression =
  ## Parses & and | operators
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract boolean expression from
  ##
  ## Returns: Expression - the parsed boolean expression
  result = parser.parseEquality()
  while parser.match({tkAnd, tkLine}):
    let prev = parser.previous()
    let right = parser.parseEquality()

    if result.kind == ekValue and right.kind == ekValue and result.value.kind == vkBool and
        right.value.kind == vkBool:
      if prev.kind == tkAnd:
        result = newValueExpr(
          prev.position, newValue(result.value.boolean and right.value.boolean)
        )
      elif prev.kind == tkLine:
        result = newValueExpr(
          prev.position, newValue(result.value.boolean or right.value.boolean)
        )
    elif result.kind == ekValue and result.value.kind == vkBool and prev.kind == tkAnd and
        not result.value.boolean:
      result = newValueExpr(prev.position, newValue(false))
    elif result.kind == ekValue and result.value.kind == vkBool and prev.kind == tkLine and
        result.value.boolean:
      result = newValueExpr(prev.position, newValue(true))
    else:
      if prev.kind == tkAnd:
        result = newBinaryExpr(prev.position, ekAnd, result, right)
      elif prev.kind == tkLine:
        result = newBinaryExpr(prev.position, ekOr, result, right)

proc parseAssignment*(parser: var Parser): Expression =
  ## Parses assignment expressions with both local and non-local variables
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract assignment from
  ##
  ## Returns: Expression - either an assignment expression or the result of parseBoolean
  ##
  ## Raises:
  ##   MissingTokenError - if expected tokens are not found
  if parser.match({tkIdent, tkLocal}):
    let local = parser.previous().kind == tkLocal
    if local and not parser.match({tkIdent}):
      raise newMissingTokenError(
        "Expected identifier after 'local'", parser.previous().position
      )
    let name = parser.previous()
    var typ: BMathType = AnyType
    if parser.match({tkColon}):
      if parser.match({tkType}):
        typ = parser.previous().value.typ
      else:
        raise
          newMissingTokenError("Expected type after ':'", parser.previous().position)
    if parser.match({tkAssign}):
      let value = parser.parseExpression()
      return newAssignExpr(name.position, name.name, value, local, typ)
    elif not local:
      parser.back()
    else:
      raise newMissingTokenError(
        "Expected '=' after local '" & name.name & "'", parser.previous().position
      )
  return parser.parseLogical()

proc parseExpression(parser: var Parser): Expression {.inline.} =
  ## Entry point for expression parsing, delegates to parseAssignment
  ##
  ## Params:
  ##   parser: var Parser - the parser to extract expression from
  ##
  ## Returns: Expression - the parsed expression
  result = parser.parseAssignment()

proc parse*(tokens: seq[Token]): Expression =
  ## Main parsing function that processes a sequence of tokens into an expression
  ##
  ## Params:
  ##   tokens: seq[Token] - sequence of tokens to parse
  ##
  ## Returns: Expression - the complete parsed expression
  ##
  ## Raises:
  ##   UnexpectedTokenError - if there are unexpected tokens after a complete expression
  var parser = newParser(tokens)
  result = parser.parseExpression()
  if not parser.isAtEnd:
    let token = parser.peek()
    raise newUnexpectedTokenError("Unexpected token " & $token, token.position)
