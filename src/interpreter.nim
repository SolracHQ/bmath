## interpreter.nim - Abstract Syntax Tree Evaluator
##
## Implements recursive tree-walking interpretation of parsed
## mathematical expressions. Handles:
## - Numeric value propagation
## - Arithmetic operation execution
## - Type promotion (int/float) during operations

import std/[sequtils]
import types, value, logging, environment

type Interpreter* = ref object ## Abstract Syntax Tree evaluator
  env: Environment

proc newInterpreter*(): Interpreter =
  ## Initializes a new interpreter with an empty environment
  result = Interpreter()
  result.env = newEnv()

proc eval*(
  interpreter: Interpreter, node: Expression, environment: Environment = nil
): LabeledValue

proc evalAssign*(
    interpreter: Interpreter, node: Expression, env: Environment
): LabeledValue =
  ## Evaluates an assignment node.
  let val = interpreter.eval(node.expr, env).value
  env[node.ident, node.isLocal] = val
  return LabeledValue(label: node.ident, value: val)

template emptyLabeled(val: Value): LabeledValue =
  LabeledValue(value: val)

proc applyFunction*(interpreter: Interpreter, funValue: Value, 
                      args: seq[Expression], env: Environment, pos: Position): LabeledValue =
  ## Dispatches a function value (native or user-defined) with the given arguments
  if funValue.kind == vkNativeFunc:
    let native = funValue.nativeFunc
    if args.len != native.argc:
      raise newBMathError("Function expects " & $(native.argc) &
                             " arguments, got " & $(args.len), pos)
    let evaluator = proc(node: Expression): Value =
      interpreter.eval(node, env).value
    return native.fun(args, evaluator).emptyLabeled
  elif funValue.kind == vkFunction:
    if args.len != funValue.params.len:
      raise newBMathError("Function expects " & $(funValue.params.len) &
                             " arguments, got " & $(args.len), pos)
    let funcEnv = newEnv(parent = funValue.env)
    for i, param in funValue.params.pairs:
      funcEnv[param, true] = interpreter.eval(args[i], env).value
    return interpreter.eval(funValue.body, funcEnv)
  else:
    raise newBMathError("Provided value is not callable", pos)

proc evalFuncCall*(interpreter: Interpreter, node: Expression, env: Environment): LabeledValue =
  ## Evaluates a function call when the function is looked up via its identifier.
  if not env.hasKey(node.fun):
    raise newBMathError("Undefined function: " & node.fun, node.position)
  let funValue = env[node.fun]
  return applyFunction(interpreter, funValue, node.args, env, node.position)

proc evalFunInvoke*(interpreter: Interpreter, node: Expression, env: Environment): LabeledValue =
  ## Evaluates a function invocation when the callee is already computed.
  let callee = node.callee
  if callee.kind != vkFunction and callee.kind != vkNativeFunc:
    raise newBMathError("Value is not a function", node.position)
  return applyFunction(interpreter, callee, node.arguments, env, node.position)

proc evalBlock*(
    interpreter: Interpreter, node: Expression, env: Environment
): LabeledValue =
  ## Evaluates a block of expressions.
  var blockEnv = newEnv(parent = env)
  var lastVal: LabeledValue
  for expr in node.expressions:
    lastVal = interpreter.eval(expr, blockEnv)
  return lastVal

proc evalFunc*(interpreter: Interpreter, node: Expression, env: Environment): Value =
  ## Evaluates a function definition.
  let funcEnv = newEnv(parent = env)
  return Value(kind: vkFunction, body: node.body, env: funcEnv, params: node.params)

proc eval*(
    interpreter: Interpreter, node: Expression, environment: Environment = nil
): LabeledValue =
  ## Recursively evaluates an abstract syntax tree node.
  ## Uses helper procs for multi-line expressions.
  assert node != nil, "Node is nil"
  let env = if environment == nil: interpreter.env else: environment
  template binOp(node, op: untyped): LabeledValue = LabeledValue(value: op(interpreter.eval(node.left, env).value, interpreter.eval(node.right, env).value))
  try:
    case node.kind
    of ekValue:
      return LabeledValue(value: node.value)
    of ekAdd:
      return binOp(node, `+`)
    of ekSub:
      return binOp(node, `-`)
    of ekMul:
      return binOp(node, `*`)
    of ekDiv:
      return binOp(node, `/`)
    of ekPow:
      return binOp(node, `^`)
    of ekMod:
      return binOp(node, `%`)
    of ekEq:
      return binOp(node, `==`)
    of ekNe:
      return binOp(node, `!=`)
    of ekGt:
      return binOp(node, `>`)
    of ekLt:
      return binOp(node, `<`)
    of ekGe:
      return binOp(node, `>=`)
    of ekLe:
      return binOp(node, `<=`)
    of ekAnd: return binOp(node, `and`)
    of ekOr: return binOp(node, `or`)
    of ekVector:
      return
        Value(
          kind: vkVector, values: node.values.mapIt(interpreter.eval(it, env).value)
        ).emptyLabeled
    of ekGroup:
      return LabeledValue(value: interpreter.eval(node.child, env).value)
    of ekNeg:
      return LabeledValue(value: -interpreter.eval(node.operand, env).value)
    of ekAssign:
      return evalAssign(interpreter, node, env)
    of ekIdent:
      return LabeledValue(value: env[node.name])
    of ekFuncCall:
      return evalFuncCall(interpreter, node, env)
    of ekBlock:
      return evalBlock(interpreter, node, env)
    of ekFunc:
      return LabeledValue(value: evalFunc(interpreter, node, env))
    of ekFuncInvoke:
      return evalFunInvoke(interpreter, node, env)
    of ekIf:
      for branch in node.branches:
        let condition = interpreter.eval(branch.condition, env).value
        if condition.kind != vkBool:
          raise newBMathError("Expected boolean condition, got " & $condition.kind, branch.condition.position)
        if condition.bValue:
          return interpreter.eval(branch.thenBranch, env)
      return interpreter.eval(node.elseBranch, env)
  except BMathError as e:
    e.position = node.position
    raise e
