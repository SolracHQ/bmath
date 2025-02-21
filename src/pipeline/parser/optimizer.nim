import std/[tables, sets, sequtils, math]
import fusion/matching
import ../../types/[expression, position]
from ../interpreter/environment import CORE_NAMES

type
  AbortOptimization = object of ValueError

  VirtualValueKind = enum
    ## Represents the kind of a virtual value
    vvkInt
    vvkFloat
    vvkBool
    vvkVector
    vvkFunc
    vvkUnoptimized
    vvkOptimized # especial case when an assignment has it value optimized and its local
    vvkError

  VirtualValue = object ## Represents a virtual value for constant folding
    position: Position
    case kind: VirtualValueKind
    of vvkInt:
      iValue: int
    of vvkFloat:
      fValue: float
    of vvkBool:
      bValue: bool
    of vvkVector:
      values: seq[VirtualValue]
    of vvkFunc:
      virtualEnv: VirtualEnvironment
      params: seq[string]
      body: Expression
    of vvkUnoptimized:
      expr: Expression
    of vvkOptimized:
      ident: string
      optExpr: ref VirtualValue
    of vvkError:
      message: string

  VirtualEnvironment = ref object
    ## Represents a virtual environment for constant folding
    parent: VirtualEnvironment ## Parent environment for nested scopes
    values: Table[string, VirtualValue]
      ## Table of variable names to their constant values
    captured: bool ## Flag indicating if the environment has captured variables

proc newVirtualValue[T](position: Position, value: T): VirtualValue =
  ## Initializes a new virtual value
  when T is int:
    result = VirtualValue(position: position, kind: vvkInt, iValue: value)
  elif T is float:
    result = VirtualValue(position: position, kind: vvkFloat, fValue: value)
  elif T is bool:
    result = VirtualValue(position: position, kind: vvkBool, bValue: value)
  elif T is seq[VirtualValue]:
    result = VirtualValue(position: position, kind: vvkVector, values: value)
  else:
    raise newException(ValueError, "Invalid type for virtual value")

proc newVirtualEnv*(
    parent: VirtualEnvironment = nil, captured: bool = false
): VirtualEnvironment =
  ## Initializes a new virtual environment
  result = VirtualEnvironment(
    parent: parent, values: initTable[string, VirtualValue](), captured: captured
  )

proc getValue*(env: VirtualEnvironment, name: string): (VirtualValue, bool) =
  ## Retrieves a value from the environment
  var current = env
  var captured = false
  while true:
    if name in current.values:
      return (current.values[name], captured or current.captured)
    elif current.parent != nil:
      captured = captured or current.captured
      current = current.parent
    elif name in CORE_NAMES:
      raise (ref AbortOptimization)()
    else:
      raise newException(ValueError, "Variable not found: " & name)

proc setValue*(
    env: VirtualEnvironment, name: string, local: bool, value: VirtualValue
): (int, bool) =
  ## Sets a value in the environment
  ## returns the distance to the variable and if it was captured
  if name in CORE_NAMES:
    raise newException(
      AbortOptimization, "Cannot overwrite the reserved name '" & name & "'"
    )

  if local:
    env.values[name] = value
    return (0, false)

  var current = env
  var dist = 0
  var captured = false

  while current != nil:
    captured = captured or current.captured
    if name in current.values:
      current.values[name] = VirtualValue(
        position: current.values[name].position,
        kind: vvkUnoptimized,
        expr: newIdentExpr(current.values[name].position, name),
      )
      return (dist, captured)
    dist.inc()
    current = current.parent

  env.values[name] = value
  return (0, false)

type Optimizer* = object ## Represents the optimizer for constant folding
  env*: VirtualEnvironment ## Current virtual environment

proc newOptimizer*(): Optimizer =
  ## Initializes a new optimizer
  result = Optimizer(env: newVirtualEnv())

proc optimize*(optimizer: var Optimizer, node: Expression): Expression

proc toExpression*(node: VirtualValue): Expression =
  ## Converts a virtual value to an expression
  case node.kind
  of vvkInt:
    result = newIntExpr(node.position, node.iValue)
  of vvkFloat:
    result = newFloatExpr(node.position, node.fValue)
  of vvkBool:
    result = newBoolExpr(node.position, node.bValue)
  of vvkVector:
    result = newVectorExpr(node.position, node.values.mapIt(toExpression(it)))
  of vvkFunc:
    result = newFuncExpr(node.position, node.params, node.body)
  of vvkUnoptimized:
    result = node.expr
  of vvkOptimized:
    result =
      newAssignExpr(node.position, node.ident, toExpression(node.optExpr[]), true)
  of vvkError:
    result = newErrorExpr(node.position, node.message)

proc optimize(
  optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): VirtualValue

template optimizeBiNumOpNoDiv(
    optimizer: var Optimizer,
    node: Expression,
    env: VirtualEnvironment,
    op: untyped,
    kd: static[ExpressionKind],
) =
  let left = optimize(optimizer, node.left, env)
  if left.kind == vvkError:
    return left
  let right = optimize(optimizer, node.right, env)
  if right.kind == vvkError:
    return right
  if left.kind == vvkUnoptimized:
    return VirtualValue(
      position: node.position,
      kind: vvkUnoptimized,
      expr: newBinaryExpr(node.position, kd, node.left, right.toExpression()),
    )
  if right.kind == vvkUnoptimized:
    return VirtualValue(
      position: node.position,
      kind: vvkUnoptimized,
      expr: newBinaryExpr(node.position, kd, left.toExpression(), node.right),
    )
  if left.kind == vvkFunc or right.kind == vvkFunc:
    return VirtualValue(
      position: node.position, kind: vvkError, message: "Cannot add a function"
    )
  case (left.kind, right.kind)
  of (vvkInt, vvkInt):
    return newVirtualValue(node.position, op(left.iValue, right.iValue))
  of (vvkFloat, vvkFloat):
    return newVirtualValue(node.position, op(left.fValue, right.fValue))
  of (vvkInt, vvkFloat):
    return newVirtualValue(node.position, op(left.iValue.float, right.fValue))
  of (vvkFloat, vvkInt):
    return newVirtualValue(node.position, op(left.fValue, right.iValue.float))
  else:
    return VirtualValue(
      position: node.position,
      kind: vvkUnoptimized,
      expr: newBinaryExpr(node.position, kd, left.toExpression(), right.toExpression()),
    )

proc optimizeAssign(
    optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): VirtualValue =
  let value = optimize(optimizer, node.expr, env)
  if value.kind == vvkError:
    return value
  let (distance, isCaptured) = setValue(env, node.ident, node.isLocal, value)
  let isLocal = distance == 0
  if value.kind == vvkUnoptimized or isCaptured:
    result = VirtualValue(position: node.position, kind: vvkUnoptimized)
    result.expr = node
  else:
    result =
      VirtualValue(position: node.position, kind: vvkOptimized, ident: node.ident)
    new(result.optExpr)
    result.optExpr[] = value

proc optimizeIdent(
    optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): VirtualValue =
  let (value, captured) =
    try:
      getValue(env, node.name)
    except AbortOptimization:
      # return not optimized
      return VirtualValue(position: node.position, kind: vvkUnoptimized, expr: node)
  if not captured:
    return value
  else:
    var res = VirtualValue(position: node.position, kind: vvkUnoptimized)
    res.expr = node
    return res

proc optimizeFunc(
    optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): VirtualValue =
  let funcEnv = newVirtualEnv(env, true)
  var res = VirtualValue(position: node.position, kind: vvkFunc)
  var tempEnv = newVirtualEnv(funcEnv)
  for param in node.params:
    tempEnv.values[param] = VirtualValue(position: node.position, kind: vvkUnoptimized)
  res.virtualEnv = funcEnv
  res.params = node.params
  res.body = node.body
  return res

proc optimizeBlock(
    optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): VirtualValue =
  let blockEnv = newVirtualEnv(env)
  result = VirtualValue(
    position: node.position,
    kind: vvkUnoptimized,
    expr: newBlockExpr(node.position, newSeqOfCap[Expression](node.expressions.len)),
  )
  var allOptimized = true
  for i, expr in node.expressions.pairs():
    let value = optimize(optimizer, expr, blockEnv)
    if value.kind == vvkError:
      return value
    allOptimized =
      allOptimized and (value.kind != vvkUnoptimized) and (value.kind != vvkFunc)
    if allOptimized and i == node.expressions.len - 1:
      return value
    result.expr.expressions.add(value.toExpression())

proc optimizeFuncInvoke(
    optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): VirtualValue =
  var funVal = optimize(optimizer, node.fun, env)

  while true:
    case funVal.kind
    of vvkError:
      return funVal
    of vvkInt, vvkFloat, vvkBool, vvkVector:
      return VirtualValue(
        position: node.position, kind: vvkError, message: "Cannot call a non-function"
      )
    of vvkUnoptimized:
      return VirtualValue(position: node.position, kind: vvkUnoptimized, expr: node)
    of vvkOptimized:
      if funVal.optExpr[].kind == vvkFunc:
        funVal = funVal.optExpr[]
      else:
        return VirtualValue(
          position: node.position, kind: vvkError, message: "Cannot call a non-function"
        )
    of vvkFunc:
      let funcEnv = newVirtualEnv(funVal.virtualEnv)
      if funVal.params.len != node.arguments.len:
        return VirtualValue(
          position: node.position,
          kind: vvkError,
          message: "Function call with wrong number of arguments",
        )
      for i, param in funVal.params.pairs():
        let argValue = optimize(optimizer, node.arguments[i], env)
        if argValue.kind == vvkError:
          return argValue
        discard setValue(funcEnv, param, true, argValue)
      let value = optimize(optimizer, funVal.body, funcEnv)
      if value.kind == vvkUnoptimized:
        return VirtualValue(position: node.position, kind: vvkUnoptimized, expr: node)
      return value

proc optimizeIf(
    optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): VirtualValue =
  for branch in node.branches:
    let cond = optimize(optimizer, branch.condition, env)
    if cond.kind == vvkError:
      return cond
    if cond.kind == vvkUnoptimized:
      return VirtualValue(position: node.position, kind: vvkUnoptimized, expr: node)
    if cond.kind == vvkBool and not cond.bValue:
      continue
    let value = optimize(optimizer, branch.then, env)
    if value.kind == vvkError:
      return value
    if value.kind == vvkUnoptimized:
      return
        VirtualValue(position: node.position, kind: vvkUnoptimized, expr: branch.then)
    return value
  let value = optimize(optimizer, node.elseBranch, env)
  if value.kind == vvkUnoptimized:
    return
      VirtualValue(position: node.position, kind: vvkUnoptimized, expr: node.elseBranch)
  return value

proc optimize(
    optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): VirtualValue =
  case node.kind
  of ekInt:
    return VirtualValue(position: node.position, kind: vvkInt, iValue: node.iValue)
  of ekFloat:
    return VirtualValue(position: node.position, kind: vvkFloat, fValue: node.fValue)
  of ekTrue:
    return VirtualValue(position: node.position, kind: vvkBool, bValue: true)
  of ekFalse:
    return VirtualValue(position: node.position, kind: vvkBool, bValue: false)
  of ekAdd:
    optimizeBiNumOpNoDiv(optimizer, node, env, `+`, ekAdd)
  of ekSub:
    optimizeBiNumOpNoDiv(optimizer, node, env, `-`, ekSub)
  of ekMul:
    optimizeBiNumOpNoDiv(optimizer, node, env, `*`, ekMul)
  of ekPow:
    optimizeBiNumOpNoDiv(optimizer, node, env, `^`, ekPow)
  of ekGt:
    optimizeBiNumOpNoDiv(optimizer, node, env, `>`, ekGt)
  of ekLt:
    optimizeBiNumOpNoDiv(optimizer, node, env, `<`, ekLt)
  of ekGe:
    optimizeBiNumOpNoDiv(optimizer, node, env, `>=`, ekGe)
  of ekLe:
    optimizeBiNumOpNoDiv(optimizer, node, env, `<=`, ekLe)
  of ekAssign:
    return optimizeAssign(optimizer, node, env)
  of ekIdent:
    return optimizeIdent(optimizer, node, env)
  of ekFunc:
    return optimizeFunc(optimizer, node, env)
  of ekBlock:
    return optimizeBlock(optimizer, node, env)
  of ekFuncInvoke:
    return optimizeFuncInvoke(optimizer, node, env)
  of ekIf:
    return optimizeIf(optimizer, node, env)
  else:
    return VirtualValue(position: node.position, kind: vvkUnoptimized, expr: node)

proc optimize*(optimizer: var Optimizer, node: Expression): Expression =
  return node
  let optimized = optimize(optimizer, node, optimizer.env)
  optimized.toExpression()
