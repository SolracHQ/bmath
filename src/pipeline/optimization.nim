## optimization.nim - Compile-time optimizations for BMath expressions
##
## This module provides various compile-time optimizations that can be applied
## during parsing to improve performance by evaluating constant expressions,
## simplifying operations, and eliminating redundant computations.

import ../types/[expression, token, number, bm_types, value, position, core]

type
  OptimizationLevel* = enum
    olNone     ## No optimizations
    olBasic    ## Basic constant folding
    olFull     ## All optimizations enabled
  
  OptimizationFlags* = set[OptimizationKind]
  
  OptimizationKind* = enum
    okConstantFolding      ## Evaluate constant expressions at compile time
    okBooleanSimplification ## Simplify boolean operations
    okArithmeticSimplification ## Simplify arithmetic operations  
    okComparisonSimplification ## Simplify comparisons
    okTypeCheckSimplification ## Simplify type checks
    okConditionalSimplification ## Simplify if expressions with constant conditions
    okRemoveGrouping ## Remove parentheses/grouping during parse-time optimization

  Optimizer* = object
    level*: OptimizationLevel
    flags*: OptimizationFlags
    enabled*: bool

proc newOptimizer*(level: OptimizationLevel = olFull): Optimizer =
  ## Create a new optimizer with the specified optimization level
  let flags = case level:
    of olNone: {}
    of olBasic: {okConstantFolding}
    of olFull: {okConstantFolding, okBooleanSimplification, okArithmeticSimplification,
               okComparisonSimplification, okTypeCheckSimplification, okConditionalSimplification,
               okRemoveGrouping}
  
  Optimizer(level: level, flags: flags, enabled: level != olNone)

proc setOptimizationFlag*(optimizer: var Optimizer, flag: OptimizationKind, enabled: bool) =
  ## Enable or disable a specific optimization
  if enabled:
    optimizer.flags.incl(flag)
  else:
    optimizer.flags.excl(flag)

proc isEnabled*(optimizer: Optimizer, flag: OptimizationKind): bool =
  ## Check if a specific optimization is enabled
  optimizer.enabled and flag in optimizer.flags

# =============================================================================
# CONSTANT FOLDING OPTIMIZATIONS
# =============================================================================

proc optimizeArithmetic*(optimizer: Optimizer, op: TokenKind, left, right: Expression, pos: Position): Expression =
  ## Optimize arithmetic binary operations with constant operands
  if not optimizer.isEnabled(okConstantFolding):
    return nil
    
  if left.kind == ekValue and right.kind == ekValue and 
     left.value.kind == vkNumber and right.value.kind == vkNumber:
    
    case op:
    of tkAdd:
      return newValueExpr(pos, newValue(left.value.number + right.value.number))
    of tkSub:
      return newValueExpr(pos, newValue(left.value.number - right.value.number))
    of tkMul:
      return newValueExpr(pos, newValue(left.value.number * right.value.number))
    of tkDiv:
      if not right.value.number.isZero():
        return newValueExpr(pos, newValue(left.value.number / right.value.number))
    of tkMod:
      if not right.value.number.isZero() and left.value.number.kind != nkComplex:
        return newValueExpr(pos, newValue(left.value.number % right.value.number))
    of tkPow:
      return newValueExpr(pos, newValue(left.value.number ^ right.value.number))
    else: discard
  
  return nil

proc optimizeBoolean*(optimizer: Optimizer, op: TokenKind, left, right: Expression, pos: Position): Expression =
  ## Optimize boolean binary operations with constant operands
  if not optimizer.isEnabled(okBooleanSimplification):
    return nil
    
  if left.kind == ekValue and right.kind == ekValue and 
     left.value.kind == vkBool and right.value.kind == vkBool:
    case op:
    of tkAnd:
      return newValueExpr(pos, newValue(left.value.boolean and right.value.boolean))
    of tkLine: # OR operator
      return newValueExpr(pos, newValue(left.value.boolean or right.value.boolean))
    else: discard
  
  return nil

proc optimizeComparison*(optimizer: Optimizer, op: TokenKind, left, right: Expression, pos: Position): Expression =
  ## Optimize comparison operations with constant numeric operands
  if not optimizer.isEnabled(okComparisonSimplification):
    return nil
    
  if left.kind == ekValue and right.kind == ekValue and 
     left.value.kind == vkNumber and right.value.kind == vkNumber and
     left.value.number.kind != nkComplex and right.value.number.kind != nkComplex:
    case op:
    of tkEq:
      return newValueExpr(pos, newValue(left.value.number == right.value.number))
    of tkNe:
      return newValueExpr(pos, newValue(left.value.number != right.value.number))
    of tkLt:
      return newValueExpr(pos, newValue(left.value.number < right.value.number))
    of tkLe:
      return newValueExpr(pos, newValue(left.value.number <= right.value.number))
    of tkGt:
      return newValueExpr(pos, newValue(left.value.number > right.value.number))
    of tkGe:
      return newValueExpr(pos, newValue(left.value.number >= right.value.number))
    else: discard
  
  return nil

# =============================================================================
# UNARY OPERATION OPTIMIZATIONS
# =============================================================================

proc optimizeUnaryMinus*(optimizer: Optimizer, operand: Expression, pos: Position): Expression =
  ## Optimize unary minus with constant numeric operands
  if not optimizer.isEnabled(okConstantFolding):
    return nil
    
  if operand.kind == ekValue and operand.value.kind == vkNumber:
    return newValueExpr(pos, newValue(-operand.value.number))
  
  return nil

proc optimizeUnaryNot*(optimizer: Optimizer, operand: Expression, pos: Position): Expression =
  ## Optimize unary not with constant boolean operands
  if not optimizer.isEnabled(okBooleanSimplification):
    return nil
    
  if operand.kind == ekValue and operand.value.kind == vkBool:
    return newValueExpr(pos, newValue(not operand.value.boolean))
  
  return nil

# =============================================================================
# CONDITIONAL OPTIMIZATIONS
# =============================================================================

proc optimizeConditional*(optimizer: Optimizer, branches: seq[Branch], elseBranch: Expression): Expression =
  ## Optimize if expressions with constant boolean conditions
  if not optimizer.isEnabled(okConditionalSimplification):
    return nil
    
  for branch in branches:
    if branch.condition.kind == ekValue and branch.condition.value.kind == vkBool:
      if branch.condition.value.boolean:
        return branch.then
    else:
      # Non-constant condition found, can't optimize
      return nil
  
  # All conditions were false constants, return else branch
  return elseBranch

# =============================================================================
# TYPE CHECK OPTIMIZATIONS
# =============================================================================

proc optimizeTypeCheck*(optimizer: Optimizer, right: Expression, pos: Position): Expression =
  ## Optimize type checks against AnyType (always true)
  if not optimizer.isEnabled(okTypeCheckSimplification):
    return nil
    
  if right.kind == ekValue and right.value.kind == vkType and right.value.typ === AnyType:
    return newValueExpr(pos, newValue(true))
  
  return nil

# =============================================================================
# BINARY OPERATION OPTIMIZATION DISPATCHER
# =============================================================================

proc optimizeBinaryOp*(optimizer: Optimizer, op: TokenKind, left, right: Expression, pos: Position): Expression =
  ## Main dispatcher for binary operation optimizations
  if not optimizer.enabled:
    return nil
  
  # Try arithmetic optimizations
  case op:
  of tkAdd, tkSub, tkMul, tkDiv, tkMod, tkPow:
    let optimized = optimizer.optimizeArithmetic(op, left, right, pos)
    if optimized != nil: return optimized
  of tkAnd, tkLine:
    let optimized = optimizer.optimizeBoolean(op, left, right, pos)
    if optimized != nil: return optimized
  of tkEq, tkNe, tkLt, tkLe, tkGt, tkGe:
    let optimized = optimizer.optimizeComparison(op, left, right, pos)
    if optimized != nil: return optimized
  else: discard
  
  return nil

proc optimizeUnaryOp*(optimizer: Optimizer, op: TokenKind, operand: Expression, pos: Position): Expression =
  ## Main dispatcher for unary operation optimizations
  if not optimizer.enabled:
    return nil
  
  case op:
  of tkSub: # Unary minus
    return optimizer.optimizeUnaryMinus(operand, pos)
  of tkNot:
    return optimizer.optimizeUnaryNot(operand, pos)
  else: discard
  
  return nil

# =============================================================================
# GROUPING (PARENTHESIS) OPTIMIZATION
# =============================================================================
proc optimizeGrouping*(optimizer: Optimizer, expr: Expression, pos: Position): Expression =
  ## Decides whether to keep parentheses as explicit group nodes or remove
  ## them, based on the optimizer configuration.
  ##
  ## Returns:
  ## - the inner expression (unwrapped) when grouping removal is enabled,
  ## - an explicit group Expression when grouping removal is disabled.
  if optimizer.isEnabled(okRemoveGrouping):
    return expr
  else:
    return newGroupExpr(pos, expr)