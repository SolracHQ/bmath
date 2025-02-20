import std/[tables, sets]
import fusion/matching
import ../../types/[expression]
from ../interpreter/environment import CORE_NAMES

type AbortOptimization = object of ValueError

type VirtualEnvironment = ref object
  ## Represents a virtual environment for constant folding
  parent: VirtualEnvironment ## Parent environment for nested scopes
  values: Table[string, Expression] ## Table of variable names to their constant values
  captured: bool ## Flag indicating if the environment has captured variables

proc newVirtualEnv*(
    parent: VirtualEnvironment = nil, captured: bool = false
): VirtualEnvironment =
  ## Initializes a new virtual environment
  result = VirtualEnvironment(
    parent: parent, values: initTable[string, Expression](), captured: captured
  )

proc getValue*(
    env: VirtualEnvironment, name: string, distance: int = 0, captured: bool = false
): (Expression, int, bool) =
  ## Retrieves a value from the environment
  if name in env.values:
    return (env.values[name], distance, captured or env.captured)
  elif env.parent != nil:
    return getValue(env.parent, name, distance + 1)
  elif name in CORE_NAMES:
    raise (ref AbortOptimization)()
  else:
    raise newException(ValueError, "Variable not found: " & name)

proc setValue*(
    env: VirtualEnvironment,
    name: string,
    local: bool,
    value: Expression,
    depth: int = 0,
): int =
  ## Sets a value in the environment
  ## returns the distance to the variable
  if name in CORE_NAMES:
    raise newException(
      AbortOptimization, "Cannot overwrite the reserved name '" & name & "'"
    )

  if local:
    env.values[name] = value
    return depth

  if name in env.values:
    env.values[name] = value
    return depth
  elif env.parent != nil:
    result = setValue(env.parent, name, local, value, depth + 1)
  else:
    result = -1
  ## If the variable is not found, add it to the current environment
  if result == -1:
    env.values[name] = value
    result = depth

type Optimizer* = object ## Represents the optimizer for constant folding
  env*: VirtualEnvironment ## Current virtual environment

proc newOptimizer*(): Optimizer =
  ## Initializes a new optimizer
  result = Optimizer(env: newVirtualEnv())

proc optimize*(
  optimizer: var Optimizer, node: Expression, environment: VirtualEnvironment = nil
): Expression

proc optimizeBlock*(
    optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): Expression =
  ## Optimizes a block of code
  result = Expression(kind: ekBlock)
  let blockScope = newVirtualEnv(env)
  result.expressions = newSeqOfCap[Expression](node.expressions.len)
  for expr in node.expressions:
    result.expressions.add(optimize(optimizer, expr, blockScope))
  return result

proc optimizeAdd*(
    optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): Expression =
  ## Optimizes an addition operation
  let left = optimize(optimizer, node.left, env)
  let right = optimize(optimizer, node.right, env)
  case (left.kind, right.kind)
  of (ekInt, ekInt):
    result = newIntExpr(node.position, left.iValue + right.iValue)
  of (ekFloat, ekFloat):
    result = newFloatExpr(node.position, left.fValue + right.fValue)
  of (ekInt, ekFloat):
    result = newFloatExpr(node.position, left.iValue.float + right.fValue)
  of (ekFloat, ekInt):
    result = newFloatExpr(node.position, left.fValue + right.iValue.float)
  else:
    result = newBinaryExpr(node.position, ekAdd, left, right)

proc optimizeSub*(
    optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): Expression =
  ## Optimizes a subtraction operation
  let left = optimize(optimizer, node.left, env)
  let right = optimize(optimizer, node.right, env)
  case (left.kind, right.kind)
  of (ekInt, ekInt):
    result = newIntExpr(node.position, left.iValue - right.iValue)
  of (ekFloat, ekFloat):
    result = newFloatExpr(node.position, left.fValue - right.fValue)
  of (ekInt, ekFloat):
    result = newFloatExpr(node.position, left.iValue.float - right.fValue)
  of (ekFloat, ekInt):
    result = newFloatExpr(node.position, left.fValue - right.iValue.float)
  else:
    result = newBinaryExpr(node.position, ekSub, left, right)

proc optimizeMul*(
    optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): Expression =
  ## Optimizes a multiplication operation
  let left = optimize(optimizer, node.left, env)
  let right = optimize(optimizer, node.right, env)
  case (left.kind, right.kind)
  of (ekInt, ekInt):
    result = newIntExpr(node.position, left.iValue * right.iValue)
  of (ekFloat, ekFloat):
    result = newFloatExpr(node.position, left.fValue * right.fValue)
  of (ekInt, ekFloat):
    result = newFloatExpr(node.position, left.iValue.float * right.fValue)
  of (ekFloat, ekInt):
    result = newFloatExpr(node.position, left.fValue * right.iValue.float)
  else:
    result = newBinaryExpr(node.position, ekMul, left, right)

proc optimizeDiv*(
    optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): Expression =
  ## Optimizes a division operation
  let left = optimize(optimizer, node.left, env)
  let right = optimize(optimizer, node.right, env)
  case (left.kind, right.kind)
  of (ekInt, ekInt):
    result = newFloatExpr(node.position, left.iValue.float / right.iValue.float)
  of (ekFloat, ekFloat):
    result = newFloatExpr(node.position, left.fValue / right.fValue)
  of (ekInt, ekFloat):
    result = newFloatExpr(node.position, left.iValue.float / right.fValue)
  of (ekFloat, ekInt):
    result = newFloatExpr(node.position, left.fValue / right.iValue.float)
  else:
    result = newBinaryExpr(node.position, ekDiv, left, right)

proc optimizeNeg*(
    optimizer: var Optimizer, node: Expression, env: VirtualEnvironment
): Expression =
  ## Optimizes a negation operation
  let operand = optimize(optimizer, node.operand, env)
  case operand.kind
  of ekInt:
    result = newIntExpr(node.position, -operand.iValue)
  of ekFloat:
    result = newFloatExpr(node.position, -operand.fValue)
  else:
    result = newNegExpr(node.position, operand)

template optCompactionGeneric*(
    n: Expression, left, rigth: Expression, op: untyped, kd: ExpressionKind
): Expression =
  if left.kind == ekInt and rigth.kind == ekInt:
    newBoolExpr(n.position, op(left.iValue, rigth.iValue))
  elif left.kind == ekFloat and rigth.kind == ekFloat:
    newBoolExpr(n.position, op(left.fValue, rigth.fValue))
  elif left.kind == ekInt and rigth.kind == ekFloat:
    newBoolExpr(n.position, op(left.iValue.float, rigth.fValue))
  elif left.kind == ekFloat and rigth.kind == ekInt:
    newBoolExpr(n.position, op(left.fValue, rigth.iValue.float))
  else:
    newBinaryExpr(n.position, kd, left, rigth)

proc optimizeCompaction*(
    optimizer: var Optimizer,
    node: Expression,
    env: VirtualEnvironment,
    kind: static[ExpressionKind],
): Expression =
  let left = optimize(optimizer, node.left, env)
  let right = optimize(optimizer, node.right, env)
  case kind
  of ekEq:
    optCompactionGeneric(node, left, right, `==`, ekEq)
  of ekNe:
    optCompactionGeneric(node, left, right, `!=`, ekNe)
  of ekLt:
    optCompactionGeneric(node, left, right, `<`, ekLt)
  of ekLe:
    optCompactionGeneric(node, left, right, `<=`, ekLe)
  of ekGt:
    optCompactionGeneric(node, left, right, `>`, ekGt)
  of ekGe:
    optCompactionGeneric(node, left, right, `>=`, ekGe)
  else:
    newBinaryExpr(node.position, kind, left, right)

proc optimize*(
    optimizer: var Optimizer, node: Expression, environment: VirtualEnvironment = nil
): Expression =
  result = node
  let env = if environment == nil: optimizer.env else: environment
  return
    case node.kind
    of ekInt, ekFloat, ekTrue, ekFalse:
      node
    of ekAdd:
      optimizer.optimizeAdd(node, env)
    of ekSub:
      optimizer.optimizeSub(node, env)
    of ekMul:
      optimizer.optimizeMul(node, env)
    of ekDiv:
      optimizer.optimizeDiv(node, env)
    of ekNeg:
      optimizer.optimizeNeg(node, env)
    of ekBlock:
      optimizer.optimizeBlock(node, env)
    of ekEq:
      optimizer.optimizeCompaction(node, env, ekEq)
    of ekNe:
      optimizer.optimizeCompaction(node, env, ekNe)
    of ekLt:
      optimizer.optimizeCompaction(node, env, ekLt)
    of ekLe:
      optimizer.optimizeCompaction(node, env, ekLe)
    of ekGt:
      optimizer.optimizeCompaction(node, env, ekGt)
    of ekGe:
      optimizer.optimizeCompaction(node, env, ekGe)
    else:
      node
