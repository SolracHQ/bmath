import std/[tables, sets, sequtils, math]
import fusion/matching
import ../../types/[expression]
from ../interpreter/environment import CORE_NAMES

type
  AbortOptimization = object of ValueError

  VirtualValueKind = enum
    ## Represents the kind of a virtual value
    vvkInt
    vvkFloat
    vvkBool
    vvkFunction
    vvkUnoptimized

  VirtualValue = object ## Represents a virtual value for constant folding
    case kind: VirtualValueKind
    of vvkInt:
      iValue: int
    of vvkFloat:
      fValue: float
    of vvkBool:
      bValue: bool
    of vvkFunction:
      body: Expression
      params: seq[string]
      env: VirtualEnvironment
    of vvkUnoptimized: discard

  VirtualEnvironment = ref object
    ## Represents a virtual environment for constant folding
    parent: VirtualEnvironment ## Parent environment for nested scopes
    values: Table[string, VirtualValue]
      ## Table of variable names to their constant values
    captured: bool ## Flag indicating if the environment has captured variables

proc newVirtualValue[T](value: T): VirtualValue =
  ## Initializes a new virtual value
  when T is int:
    result = VirtualValue(kind: vvkInt, iValue: value)
  elif T is float:
    result = VirtualValue(kind: vvkFloat, fValue: value)
  elif T is bool:
    result = VirtualValue(kind: vvkBool, bValue: value)
  else:
    raise newException(ValueError, "Invalid type for virtual value")

proc unoptimized(): VirtualValue =
  ## Marks a value as unoptimized
  result = VirtualValue(kind: vvkUnoptimized)

proc newVirtualEnv*(
    parent: VirtualEnvironment = nil, captured: bool = false
): VirtualEnvironment =
  ## Initializes a new virtual environment
  result = VirtualEnvironment(
    parent: parent, values: initTable[string, VirtualValue](), captured: captured
  )

proc getValue*(env: VirtualEnvironment, name: string): VirtualValue =
  ## Retrieves a value from the environment
  if name in CORE_NAMES:
    return unoptimized()

  var current = env
  var captured = false
  while true:
    if captured:
      return unoptimized()
    elif name in current.values:
      return current.values[name]
    elif current.parent != nil:
      captured = captured or current.captured
      current = current.parent
    else:
      raise newException(AbortOptimization, "Variable '" & name & "' is not defined")

proc setValue*(
    env: VirtualEnvironment, name: string, local: bool, value: VirtualValue
): bool =
  ## Sets a value in the environment
  ## returns if the assignment was local
  if name in CORE_NAMES:
    raise newException(
      AbortOptimization, "Cannot overwrite the reserved name '" & name & "'"
    )

  if local or name in env.values:
    env.values[name] = value
    return true

  var current = env.parent
  var captured = false

  while current != nil:
    captured = captured or current.captured
    if name in current.values:
      if captured:
        current.values[name] = unoptimized()
      else:
        current.values[name] = value
      return false
    current = current.parent

  env.values[name] = value
  return true

type Optimizer* = object ## Represents the optimizer for constant folding
  env*: VirtualEnvironment ## Current virtual environment

proc newOptimizer*(): Optimizer {.inline.} =
  ## Initializes a new optimizer
  result = Optimizer(env: newVirtualEnv())

proc optimize*(optimizer: var Optimizer, node: Expression): Expression

proc isOptimized(node: Expression): bool {.inline.} =
  ## Checks if an expression is optimized
  result = node.kind in {ekInt, ekFloat, ekTrue, ekFalse, ekVector}
  result = result or (node.kind == ekAssign and node.isLocal and isOptimized(node.expr))

proc exprToVirtualValue(
    node: Expression, optimizer: var Optimizer
): VirtualValue {.inline.} =
  ## Converts an expression to a virtual value
  case node.kind
  of ekInt:
    return newVirtualValue(node.iValue)
  of ekFloat:
    return newVirtualValue(node.fValue)
  of ekTrue:
    return newVirtualValue(true)
  of ekFalse:
    return newVirtualValue(false)
  of ekFunc:
    return VirtualValue(
      kind: vvkFunction,
      body: node.body,
      params: node.params,
      env: newVirtualEnv(optimizer.env, true),
    )
  else:
    return unoptimized()

proc VirtualValueToExpr(
    value: VirtualValue, default: Expression
): Expression {.inline.} =
  ## Converts a virtual value to an expression
  case value.kind
  of vvkInt:
    return newLiteralExpr(default.position, value.iValue)
  of vvkFloat:
    return newLiteralExpr(default.position, value.fValue)
  of vvkBool:
    return newBoolExpr(default.position, value.bValue)
  of vvkFunction:
    return newFuncExpr(default.position, value.params, value.body)
  else:
    return default

proc optimizeAssign(optimizer: var Optimizer, node: Expression): Expression {.inline.} =
  ## Optimize assignment expressions
  let name = node.ident
  let value = optimize(optimizer, node.expr)
  let vValue = exprToVirtualValue(value, optimizer)
  let local =
    try:
      setValue(optimizer.env, name, node.isLocal, vValue)
    except AbortOptimization as e:
      return newErrorExpr(node.position, e.msg)
  return newAssignExpr(node.position, name, value, local)

proc optimizeIdent(optimizer: var Optimizer, node: Expression): Expression {.inline.} =
  ## Optimize identifier expressions using the virtual environment
  let value = getValue(optimizer.env, node.name)
  return VirtualValueToExpr(value, node)

proc optimizeBlock(optimizer: var Optimizer, node: Expression): Expression {.inline.} =
  ## Optimize a block by introducing a new virtual environment
  let oldEnv = optimizer.env
  optimizer.env = newVirtualEnv(oldEnv)
  var allOptimized = true
  var optimizedExprs = newSeqOfCap[Expression](node.expressions.len)
  for expr in node.expressions:
    let optimized = optimize(optimizer, expr)
    case optimized.kind
    of ekError:
      optimizer.env = oldEnv
      return optimized
    of ekInt, ekFloat, ekTrue, ekFalse:
      discard
    of ekAssign:
      if not optimized.isLocal:
        allOptimized = false
    else:
      allOptimized = false
    optimizedExprs.add(optimized)
  optimizer.env = oldEnv
  if allOptimized:
    return optimizedExprs[^1]
  else:
    return newBlockExpr(node.position, optimizedExprs)

proc optimizeVector(optimizer: var Optimizer, node: Expression): Expression {.inline.} =
  ## Optimize vector expressions by mapping optimize over each element
  return newVectorExpr(node.position, node.values.mapIt(optimize(optimizer, it)))

template optimizeBinary(
    opt: var Optimizer, nd: Expression, op: untyped, kd: static[ExpressionKind]
): Expression =
  ## Optimize binary operations that are not division
  proc innerProc(optimizer: var Optimizer, node: Expression): Expression {.inline.} =
    let left = optimize(optimizer, node.left)
    if left.kind == ekError:
      return left
    let right = optimize(optimizer, node.right)
    if right.kind == ekError:
      return right

    when kd in {ekAdd, ekSub, ekMul, ekPow, ekGt, ekLt, ekGe, ekLe}:
      if not (left.kind in {ekInt, ekFloat}):
        return newBinaryExpr(node.position, kd, left, right)
      if not (right.kind in {ekInt, ekFloat}):
        return newBinaryExpr(node.position, kd, left, right)

    when kd in {ekDiv, ekMod}:
      # check right is not zero
      if right.kind == ekInt and right.iValue == 0:
        return newErrorExpr(node.position, "Division by zero")
      if right.kind == ekFloat and right.fValue == 0:
        return newErrorExpr(node.position, "Division by zero")

    case (left.kind, right.kind)
    of (ekInt, ekInt):
      return newLiteralExpr(node.position, `op`(left.iValue, right.iValue))
    of (ekFloat, ekFloat):
      return newLiteralExpr(node.position, `op`(left.fValue, right.fValue))
    of (ekInt, ekFloat):
      return newLiteralExpr(node.position, `op`(left.iValue.float, right.fValue))
    of (ekFloat, ekInt):
      return newLiteralExpr(node.position, `op`(left.fValue, right.iValue.float))
    else:
      return newBinaryExpr(node.position, kd, left, right)

  innerProc(opt, nd)

proc optimizeBooleanBinary(
    optimizer: var Optimizer, node: Expression, kd: static[ExpressionKind]
): Expression =
  ## Optimize boolean binary operations
  let left = optimize(optimizer, node.left)
  if left.kind == ekError:
    return left

  if left.kind == ekFalse and kd == ekAnd:
    return left
  if left.kind == ekTrue and kd == ekOr:
    return left

  let right = optimize(optimizer, node.right)
  if right.kind == ekError:
    return right

  if right.kind == ekFalse and kd == ekAnd:
    return right
  if right.kind == ekTrue and kd == ekOr:
    return right
  return newBinaryExpr(node.position, kd, left, right)

proc optimizeFunction(
    optimizer: var Optimizer, node: Expression
): Expression {.inline.} =
  ## Optimize function calls by optimizing each argument
  let oldEnv = optimizer.env
  optimizer.env = newVirtualEnv(optimizer.env, true)
  try:
    for param in node.params:
      discard optimizer.env.setValue(param, true, unoptimized())
    let body = optimize(optimizer, node.body)
    if body.kind == ekError:
      return body
    return newFuncExpr(node.position, node.params, body)
  finally:
    optimizer.env = oldEnv

proc optimizeFuncInvoke(
    optimizer: var Optimizer, node: Expression
): Expression {.inline.} =
  ## Optimize function invocation arguments
  result = newFuncInvokeExpr(
    node.position, node.fun, newSeqOfCap[Expression](node.arguments.len)
  )
  var allOptimized = true
  for i in 0 ..< node.arguments.len:
    let arg = optimize(optimizer, node.arguments[i])
    if arg.kind == ekError:
      return arg
    if not isOptimized(arg):
      allOptimized = false
    result.arguments.add(arg)
  if allOptimized:
    let olEnv = optimizer.env
    try:
      var funValue: VirtualValue =
        case node.fun.kind
        of ekIdent:
          getValue(optimizer.env, node.fun.name)
        of ekFunc:
          exprToVirtualValue(node.fun, optimizer)
        else:
          return newErrorExpr(node.position, "Value is not a function")
      if funValue.kind == vvkFunction:
        optimizer.env = newVirtualEnv(funValue.env)
        for i, arg in node.arguments:
          discard optimizer.env.setValue(
            funValue.params[i], true, exprToVirtualValue(arg, optimizer)
          )
        let body = optimize(optimizer, funValue.body)
        if body.kind == ekError:
          return body
        if isOptimized(body):
          return body
        return
    finally:
      optimizer.env = olEnv

proc optimizeNegate(optimizer: var Optimizer, node: Expression): Expression {.inline.} =
  ## Optimize negation operations
  let value = optimize(optimizer, node.operand)
  if value.kind == ekError:
    return value
  case value.kind
  of ekInt:
    return newLiteralExpr(node.position, -value.iValue)
  of ekFloat:
    return newLiteralExpr(node.position, -value.fValue)
  else:
    return newNegExpr(node.position, value)

proc optimizeNot(optimizer: var Optimizer, node: Expression): Expression {.inline.} =
  ## Optimize negation operations
  let value = optimize(optimizer, node.expr)
  if value.kind == ekError:
    return value
  case value.kind
  of ekTrue:
    return newLiteralExpr(node.position, false)
  of ekFalse:
    return newLiteralExpr(node.position, true)
  else:
    return newNotExpr(node.position, value)

proc optimizeIf(optimizer: var Optimizer, node: Expression): Expression {.inline.} =
  ## Optimize if expressions
  result =
    newIfExpr(node.position, newSeqOfCap[Condition](node.branches.len), node.elseBranch)
  var allOptimized = true
  for branch in node.branches:
    let condition = optimize(optimizer, branch.condition)
    if condition.kind == ekError:
      return condition
    if condition.kind == ekTrue and allOptimized:
      return optimize(optimizer, branch.then)
    if condition.kind == ekFalse:
      continue
    allOptimized = false
    result.branches.add(newCondition(condition, optimize(optimizer, branch.then)))
  if result.branches.len == 0:
    return optimize(optimizer, node.elseBranch)
  result.elseBranch = optimize(optimizer, node.elseBranch)

proc optimizeExpression(optimizer: var Optimizer, node: Expression): Expression =
  when defined(disableBMathOpt):
    return node
  ## Dispatch optimization based on the expression kind
  case node.kind
  of ekInt, ekFloat, ekTrue, ekFalse:
    return node
  of ekAssign:
    return optimizeAssign(optimizer, node)
  of ekIdent:
    return optimizeIdent(optimizer, node)
  of ekBlock:
    return optimizeBlock(optimizer, node)
  of ekVector:
    return optimizeVector(optimizer, node)
  of ekAdd:
    return optimizeBinary(optimizer, node, `+`, ekAdd)
  of ekSub:
    return optimizeBinary(optimizer, node, `-`, ekSub)
  of ekMul:
    return optimizeBinary(optimizer, node, `*`, ekMul)
  of ekDiv:
    return optimizeBinary(optimizer, node, `/`, ekDiv)
  of ekMod:
    return optimizeBinary(optimizer, node, `mod`, ekMod)
  of ekPow:
    return optimizeBinary(optimizer, node, `^`, ekPow)
  of ekGt:
    return optimizeBinary(optimizer, node, `>`, ekGt)
  of ekLt:
    return optimizeBinary(optimizer, node, `<`, ekLt)
  of ekGe:
    return optimizeBinary(optimizer, node, `>=`, ekGe)
  of ekLe:
    return optimizeBinary(optimizer, node, `<=`, ekLe)
  of ekEq:
    return optimizeBinary(optimizer, node, `==`, ekEq)
  of ekNe:
    return optimizeBinary(optimizer, node, `!=`, ekNe)
  of ekAnd:
    return optimizeBooleanBinary(optimizer, node, ekAnd)
  of ekOr:
    return optimizeBooleanBinary(optimizer, node, ekOr)
  of ekFunc:
    return optimizeFunction(optimizer, node)
  of ekFuncInvoke:
    return optimizeFuncInvoke(optimizer, node)
  of ekNeg:
    return optimizeNegate(optimizer, node)
  of ekNot:
    return optimizeNot(optimizer, node)
  of ekIf:
    return optimizeIf(optimizer, node)
  else:
    return node

proc optimize*(optimizer: var Optimizer, node: Expression): Expression =
  try:
    optimizeExpression(optimizer, node)
  except AbortOptimization as e:
    newErrorExpr(node.position, e.msg)
