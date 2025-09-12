## parser_v2.nim - Pratt Parser Implementation
##
## A Pratt (top-down operator precedence) parser for the BMath expression-oriented language.
## This implementation provides cleaner, more maintainable operator precedence handling
## compared to the recursive descent approach.
##
## Features:
## - Compact operator precedence table (data, not code)
## - Easy extension for new operators  
## - Uniform handling of prefix, infix, and postfix operations
## - Natural support for function calls and chaining
## - Expression-oriented design (everything is an expression)

import std/[tables, strformat]
import ../types/[expression, token, number, bm_types, value, errors, core, position]
import optimization

type 
  Parser = object
    tokens: seq[Token]
    current: int
    optimizer: Optimizer

  # Pratt parser function signatures
  PrefixFunc = proc(parser: var Parser, token: Token): Expression
  InfixFunc = proc(parser: var Parser, left: Expression, token: Token): Expression

  # Operator info for Pratt table
  OpInfo = object
    precedence: int       # Left binding power
    prefix: PrefixFunc    # How to parse as prefix (nud)
    infix: InfixFunc      # How to parse as infix (led)

# Global operator table
var opTable: Table[TokenKind, OpInfo]

# Parser utilities (same as original)
template isAtEnd(parser: Parser): bool =
  parser.current >= parser.tokens.len or (parser.tokens[parser.current].kind == tkEoe)

template previous(parser: Parser): Token =
  if parser.current > 0:
    parser.tokens[parser.current - 1]
  else:
    Token(kind: tkEoe)

template peek(parser: Parser): Token =
  if not parser.isAtEnd:
    parser.tokens[parser.current]
  else:
    Token(kind: tkEoe, position: parser.previous().position)

template advance(parser: var Parser): Token =
  let tok = parser.peek()
  if not parser.isAtEnd:
    parser.current += 1
  tok

template check(parser: Parser, kinds: set[TokenKind]): bool =
  not parser.isAtEnd and parser.peek.kind in kinds

template match(parser: var Parser, kinds: set[TokenKind]): bool =
  if parser.check(kinds):
    discard parser.advance()
    true
  else:
    false

proc cleanUpNewlines(parser: var Parser) =
  ## Skips newline tokens without collecting them
  while parser.match({tkNewline}):
    discard

proc newParser*(tokens: seq[Token], optimizationLevel: OptimizationLevel = olFull): Parser {.inline.} =
  Parser(tokens: tokens, current: 0, optimizer: newOptimizer(optimizationLevel))

# Forward declarations
proc parsePrattExpr(parser: var Parser, minPrec: int = 0): Expression
proc parseLocalAssignment(parser: var Parser): Expression

proc parseExpression(parser: var Parser): Expression {.inline.} =
  ## Entry point for expression parsing, delegates to parseLocalAssignment
  return parser.parseLocalAssignment()

# =============================================================================
# PREFIX PARSERS (NUD - Null Denotation)
# =============================================================================

proc parseNumber(parser: var Parser, token: Token): Expression =
  newValueExpr(token.position, token.value)

proc parseBool(parser: var Parser, token: Token): Expression =
  let value = if token.kind == tkTrue: newValue(true) else: newValue(false)
  newValueExpr(token.position, value)

proc parseString(parser: var Parser, token: Token): Expression =
  newValueExpr(token.position, token.value)

proc parseType(parser: var Parser, token: Token): Expression =
  newValueExpr(token.position, token.value)

proc parseIdent(parser: var Parser, token: Token): Expression =
  newIdentExpr(token.position, token.name)

proc parseGroup(parser: var Parser, token: Token): Expression =
  ## Parses (expression)
  parser.cleanUpNewlines()
  
  let expr = parser.parsePrattExpr()
  
  parser.cleanUpNewlines()
  if not parser.match({tkRpar}):
    raise newMissingTokenError("Expected ')'", token.position)
  
  # Let the optimizer decide whether to remove grouping. If okRemoveGrouping is enabled
  # then parentheses are removed (for performance). Otherwise keep an explicit group node
  # which is useful for tooling (LSP, asSource, asSexp).
  let groupExpr = parser.optimizer.optimizeGrouping(expr, token.position)
  
  return groupExpr

proc parseVector(parser: var Parser, token: Token): Expression =
  ## Parses [expr, expr, ...]
  var values: seq[Expression] = @[]
  
  while not parser.match({tkRSquare}): # tkRSquare is ']'
    parser.cleanUpNewlines()
    let expr = parser.parsePrattExpr()
    
    values.add(expr)
    parser.cleanUpNewlines()
    if parser.match({tkRSquare}):
      break
    if not parser.match({tkComma}):
      raise newMissingTokenError("Expected ','", parser.previous().position)
  
  let vectorExpr = newVectorExpr(token.position, values)
  
  return vectorExpr

proc parseBlock(parser: var Parser, token: Token): Expression =
  ## Parses {expr; expr; ...}
  parser.cleanUpNewlines()
  var expressions: seq[Expression] = @[]
  
  # Handle empty blocks - they are not allowed
  if parser.match({tkRCurly}):
    raise newInvalidExpressionError("Empty blocks are not allowed", token.position)
  
  while true:
    parser.cleanUpNewlines()
    
    let expr = parser.parseExpression() # Use parseExpression like the original parser
    
    expressions.add(expr)
    
    if parser.match({tkRCurly}):
      break
    
    parser.cleanUpNewlines()
    if parser.match({tkRCurly}):
      break
      
  let blockExpr = newBlockExpr(token.position, expressions)
  
  return blockExpr

proc parseFunction(parser: var Parser, token: Token): Expression =
  ## Parses |param, param| body
  var params: seq[Parameter] = @[]
  
  # Parse parameters until closing '|'
  while not parser.match({tkLine}):
    parser.cleanUpNewlines()
    if parser.match({tkIdent}):
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

  # Optional return type: '=>' TYPE  
  var returnType: BMathType = AnyType
  if parser.match({tkFatArrow}):
    if not parser.match({tkType}):
      raise newMissingTokenError("Expected type after '=>'", parser.previous().position)
    returnType = parser.previous().value.typ

  let body = parser.parsePrattExpr()
  let funcExpr = newFuncExpr(token.position, params, body, returnType)
  
  return funcExpr

proc parseIf(parser: var Parser, token: Token): Expression =
  ## Parses if(cond) then elif(cond) then else elseExpr
  parser.cleanUpNewlines()
  var branches: seq[Branch] = @[]
  
  # Parse if condition
  if not parser.match({tkLpar}):
    raise newMissingTokenError("Expected '(' after 'if'", token.position)
  parser.cleanUpNewlines()
  let ifCond = parser.parsePrattExpr()
  parser.cleanUpNewlines()
  if not parser.match({tkRpar}):
    raise newMissingTokenError("Expected ')' after condition", parser.previous().position)
  parser.cleanUpNewlines()
  let ifThen = parser.parsePrattExpr()
  branches.add(newBranch(ifCond, ifThen))
  parser.cleanUpNewlines()

  # Parse elif branches
  while parser.match({tkElif}):
    if not parser.match({tkLpar}):
      raise newMissingTokenError("Expected '(' after 'elif'", parser.previous().position)
    parser.cleanUpNewlines()
    let elifCond = parser.parsePrattExpr()
    parser.cleanUpNewlines()
    if not parser.match({tkRpar}):
      raise newMissingTokenError("Expected ')' after condition", parser.previous().position)
    parser.cleanUpNewlines()
    let elifThen = parser.parsePrattExpr()
    branches.add(newBranch(elifCond, elifThen))
    parser.cleanUpNewlines()

  # Parse mandatory else
  if not parser.match({tkElse}):
    raise newMissingTokenError("Expected 'else' after if-elif conditions", parser.previous().position)
  parser.cleanUpNewlines()
  let elseBranch = parser.parsePrattExpr()

  let ifResult = newIfExpr(token.position, branches, elseBranch)
  
  # Try optimization first
  let optimized = parser.optimizer.optimizeConditional(branches, elseBranch)
  if optimized != nil:
    return optimized
  
  return ifResult

proc parseNeg(parser: var Parser, token: Token): Expression =
  ## Parses -expr
  let operand = parser.parsePrattExpr(70) # Higher precedence than most operators
  # Try optimization first
  let optimized = parser.optimizer.optimizeUnaryOp(tkSub, operand, token.position)
  if optimized != nil:
    return optimized
  return newNegExpr(token.position, operand)

proc parseNot(parser: var Parser, token: Token): Expression =
  ## Parses !expr
  let operand = parser.parsePrattExpr(70) # Higher precedence than most operators
  # Try optimization first
  let optimized = parser.optimizer.optimizeUnaryOp(tkNot, operand, token.position)
  if optimized != nil:
    return optimized
  return newNotExpr(token.position, operand)

# =============================================================================
# INFIX PARSERS (LED - Left Denotation) 
# =============================================================================

proc parseCall(parser: var Parser, left: Expression, token: Token): Expression =
  ## Parses left(arg, arg, ...)
  var args: seq[Expression] = @[]
  
  while not parser.match({tkRpar}):
    parser.cleanUpNewlines()
    let arg = parser.parsePrattExpr()
    
    args.add(arg)
    parser.cleanUpNewlines()
    if parser.match({tkRpar}):
      break
    if not parser.match({tkComma}):
      raise newMissingTokenError("Expected ','", parser.previous().position)
  
  let callExpr = newFuncCallExpr(token.position, left, args)
  
  return callExpr

proc parseChain(parser: var Parser, left: Expression, token: Token): Expression =
  ## Parses left->right, where right can be a function or function call
  parser.cleanUpNewlines()
  
  let right = parser.parsePrattExpr(opTable[tkChain].precedence)
  
  if right.kind == ekFuncCall:
    # right is func(args) -> convert to func(left, args)
    return newFuncCallExpr(token.position, right.functionCall.function, 
                          @[left] & right.functionCall.params)
  else:
    # right is just a function -> convert to right(left)
    return newFuncCallExpr(token.position, right, @[left])

proc parseBinaryOp(parser: var Parser, left: Expression, token: Token): Expression =
  ## Parses left OP right for binary operators
  let info = opTable[token.kind]
  # For left-associative: use precedence, for right-associative: precedence - 1
  let rightPrec = if token.kind == tkPow: info.precedence - 1 else: info.precedence
  
  parser.cleanUpNewlines()
  
  let right = parser.parsePrattExpr(rightPrec)
  
  # Try compile-time optimization first
  let optimized = parser.optimizer.optimizeBinaryOp(token.kind, left, right, token.position)
  if optimized != nil:
    return optimized

  # Create AST node
  case token.kind:
  of tkAdd: return newBinaryExpr(token.position, ekAdd, left, right)
  of tkSub: return newBinaryExpr(token.position, ekSub, left, right)
  of tkMul: return newBinaryExpr(token.position, ekMul, left, right)
  of tkDiv: return newBinaryExpr(token.position, ekDiv, left, right)
  of tkMod: return newBinaryExpr(token.position, ekMod, left, right)
  of tkPow: return newBinaryExpr(token.position, ekPow, left, right)
  of tkEq: return newBinaryExpr(token.position, ekEq, left, right)
  of tkNe: return newBinaryExpr(token.position, ekNe, left, right)
  of tkLt: return newBinaryExpr(token.position, ekLt, left, right)
  of tkLe: return newBinaryExpr(token.position, ekLe, left, right)
  of tkGt: return newBinaryExpr(token.position, ekGt, left, right)
  of tkGe: return newBinaryExpr(token.position, ekGe, left, right)
  of tkAnd: return newBinaryExpr(token.position, ekAnd, left, right)
  of tkLine: return newBinaryExpr(token.position, ekOr, left, right) # OR
  else:
    raise newUnexpectedTokenError(&"Unexpected binary operator: {token.kind}", token.position)

proc parseTypeCheck(parser: var Parser, left: Expression, token: Token): Expression =
  ## Parses left is Type
  let right = parser.parsePrattExpr(opTable[tkIs].precedence)
  
  # Try optimization first
  let optimized = parser.optimizer.optimizeTypeCheck(right, token.position)
  if optimized != nil:
    return optimized
  
  # Convert to type(left) == right
  let getTypeCall = newFuncCallExpr(token.position, newIdentExpr(token.position, "type"), @[left])
  return newBinaryExpr(token.position, ekEq, getTypeCall, right)

# =============================================================================
# PRATT PARSER CORE
# =============================================================================

proc parsePrattExpr(parser: var Parser, minPrec: int = 0): Expression =
  ## Core Pratt parsing algorithm
  # Get the current token and advance
  let token = parser.advance()
  
  # Look up prefix parser (nud)
  let prefixInfo = opTable.getOrDefault(token.kind)
  if prefixInfo.prefix == nil:
    raise newUnexpectedTokenError(&"Unexpected token: {token}", token.position)
  
  # Parse the left side using the prefix parser
  var left = prefixInfo.prefix(parser, token)
  
  # Parse infix operations while precedence allows
  while not parser.isAtEnd:
    let peekToken = parser.peek()
    let infixInfo = opTable.getOrDefault(peekToken.kind)
    
    # Stop if no infix parser or precedence too low
    if infixInfo.infix == nil or infixInfo.precedence <= minPrec:
      break
    
    # Consume the operator and parse the right side
    let opToken = parser.advance()
    left = infixInfo.infix(parser, left, opToken)
  
  # Don't collect trailing comments here in the core Pratt parser
  # Let the higher-level parsing functions handle comment collection
  return left

# =============================================================================
# ASSIGNMENT PARSING (still uses some RD logic due to complexity)
# =============================================================================

proc parseAssignment(parser: var Parser, left: Expression, token: Token): Expression =
  ## Handles assignment expressions as infix operations (right-associative)
  # Extract variable name from left side
  var name: string
  var typ: BMathType = AnyType
  
  case left.kind:
  of ekIdent:
    name = left.identifier.ident
  else:
    raise newInvalidExpressionError("Invalid assignment target", token.position)
  
  # Parse the right side with right-associativity (precedence - 1)
  let value = parser.parsePrattExpr(opTable[tkAssign].precedence - 1)
  let assignExpr = newAssignExpr(token.position, name, value, false, typ)
  
  return assignExpr

proc parseLocalAssignment(parser: var Parser): Expression =
  ## Handles local assignments and regular expressions
  if parser.match({tkLocal}):
    if not parser.match({tkIdent}):
      raise newMissingTokenError("Expected identifier after 'local'", parser.previous().position)
    let name = parser.previous()
    var typ: BMathType = AnyType
    if parser.match({tkColon}):
      if parser.match({tkType}):
        typ = parser.previous().value.typ
      else:
        raise newMissingTokenError("Expected type after ':'", parser.previous().position)
    if not parser.match({tkAssign}):
      raise newMissingTokenError(&"Expected '=' after local '{name.name}'", parser.previous().position)
    let value = parser.parsePrattExpr()
    let assignExpr = newAssignExpr(name.position, name.name, value, true, typ)
    
    return assignExpr
  
  let expr = parser.parsePrattExpr()
  
  return expr

# =============================================================================
# OPERATOR REGISTRATION
# =============================================================================

proc registerPrefix(kind: TokenKind, parser: PrefixFunc) =
  if kind in opTable:
    opTable[kind].prefix = parser
  else:
    opTable[kind] = OpInfo(precedence: 0, prefix: parser, infix: nil)

proc registerInfix(kind: TokenKind, precedence: int, parser: InfixFunc) =
  if kind in opTable:
    opTable[kind].precedence = precedence
    opTable[kind].infix = parser
  else:
    opTable[kind] = OpInfo(precedence: precedence, prefix: nil, infix: parser)

proc initOperatorTable*() =
  ## Initialize the Pratt parser operator table
  
  # Prefix operators (nud)
  registerPrefix(tkNumber, parseNumber)
  registerPrefix(tkTrue, parseBool)
  registerPrefix(tkFalse, parseBool)
  registerPrefix(tkString, parseString)
  registerPrefix(tkType, parseType)
  registerPrefix(tkIdent, parseIdent)
  registerPrefix(tkLpar, parseGroup)
  registerPrefix(tkLSquare, parseVector)  # '[' starts vector
  registerPrefix(tkLCurly, parseBlock)    # '{' starts block
  registerPrefix(tkLine, parseFunction)   # '|' starts function
  registerPrefix(tkIf, parseIf)
  registerPrefix(tkSub, parseNeg)         # Unary minus
  registerPrefix(tkNot, parseNot)         # Unary not
  
  # Infix operators (led) with precedence (higher = tighter binding)
  registerInfix(tkLpar, 80, parseCall)      # function(args) - highest precedence
  registerInfix(tkChain, 75, parseChain)    # left->right
  registerInfix(tkPow, 60, parseBinaryOp)   # ^ (right-associative)
  registerInfix(tkMul, 50, parseBinaryOp)   # *
  registerInfix(tkDiv, 50, parseBinaryOp)   # /
  registerInfix(tkMod, 50, parseBinaryOp)   # %
  registerInfix(tkAdd, 40, parseBinaryOp)   # +
  registerInfix(tkSub, 40, parseBinaryOp)   # -
  registerInfix(tkLt, 30, parseBinaryOp)    # <
  registerInfix(tkLe, 30, parseBinaryOp)    # <=
  registerInfix(tkGt, 30, parseBinaryOp)    # >
  registerInfix(tkGe, 30, parseBinaryOp)    # >=
  registerInfix(tkEq, 25, parseBinaryOp)    # ==
  registerInfix(tkNe, 25, parseBinaryOp)    # !=
  registerInfix(tkIs, 25, parseTypeCheck)   # is
  registerInfix(tkAnd, 20, parseBinaryOp)   # &
  registerInfix(tkLine, 15, parseBinaryOp)  # | (OR)
  registerInfix(tkAssign, 5, parseAssignment) # = (right-associative, lowest precedence)

# =============================================================================
# PUBLIC API
# =============================================================================

proc parse*(tokens: seq[Token], optimizationLevel: OptimizationLevel = olFull): Expression =
  ## Main parsing function that processes tokens into an expression AST
  # Initialize operator table if needed
  if opTable.len == 0:
    initOperatorTable()
  
  var parser = newParser(tokens, optimizationLevel)
  
  parser.cleanUpNewlines()
  
  # Check if we only have comments or are at end
  var parseResult: Expression
  if parser.isAtEnd:
    # No expression to parse, return nil or raise error
    raise newInvalidExpressionError("No expression to parse", pos(1, 1))
  else:
    parseResult = parser.parseLocalAssignment()
  
  # Check if there are any unexpected tokens left
  if not parser.isAtEnd:
    let token = parser.peek()
    raise newUnexpectedTokenError(&"Unexpected token: {token}", token.position)
  
  return parseResult