## interpreter.nim - Abstract Syntax Tree Evaluator
##
## Implements recursive tree-walking interpretation of parsed
## mathematical expressions. Handles:
## - Numeric value propagation
## - Arithmetic operation execution
## - Type promotion (int/float) during operations

import std/[sequtils]
import ../../types/[value, expression, position]
import ../../types/errors
import ./errors
import corelib, environment
import stdlib/[arithmetic, comparison]

type Interpreter* = ref object ## Abstract Syntax Tree evaluator
  env: Environment

proc newInterpreter*(): Interpreter =
  ## Initializes a new interpreter with an empty environment
  result = Interpreter()
  result.env = newEnv()

proc evalValue(
  interpreter: Interpreter, node: Expression, environment: Environment
): Value

proc evalAssign(interpreter: Interpreter, node: Expression, env: Environment): Value =
  ## Evaluates an assignment node and returns its computed value.
  let val = interpreter.evalValue(node.expr, env)
  env[node.ident, node.isLocal] = val
  return val

template emptyLabeled(val: Value): LabeledValue =
  LabeledValue(value: val)

proc applyFunction(
    interpreter: Interpreter,
    funValue: Value,
    args: seq[Expression],
    env: Environment,
    pos: Position,
): Value =
  ## Dispatches a function value (native or user-defined) with the given arguments.
  if funValue.kind == vkNativeFunc:
    let native = funValue.nativeFunc
    if args.len != native.argc:
      raise newInvalidArgumentError(
        "Function expects " & $(native.argc) & " arguments, got " & $(args.len), pos
      )
    let evaluator = proc(node: Expression): Value =
      interpreter.evalValue(node, env)
    return native.fun(args, evaluator)
  elif funValue.kind == vkFunction:
    if args.len != funValue.params.len:
      raise newInvalidArgumentError(
        "Function expects " & $(funValue.params.len) & " arguments, got " & $(args.len),
        pos,
      )
    let funcEnv = newEnv(parent = funValue.env)
    for i, param in funValue.params.pairs:
      funcEnv[param, true] = interpreter.evalValue(args[i], env)
    return interpreter.evalValue(funValue.body, funcEnv)
  else:
    raise newTypeError("Provided value is not callable", pos)

proc evalFunInvoke(
    interpreter: Interpreter, node: Expression, env: Environment
): Value =
  ## Evaluates a function invocation when the callee has already been computed.
  let callee = interpreter.evalValue(node.fun, env)
  if callee.kind != vkFunction and callee.kind != vkNativeFunc:
    raise newTypeError("Value is not a function", node.position)
  return applyFunction(interpreter, callee, node.arguments, env, node.position)

proc evalBlock(interpreter: Interpreter, node: Expression, env: Environment): Value =
  ## Evaluates a block of expressions and returns the last computed value.
  var blockEnv = newEnv(parent = env)
  var lastVal: Value
  for expr in node.expressions:
    lastVal = interpreter.evalValue(expr, blockEnv)
  return lastVal

proc evalFunc(interpreter: Interpreter, node: Expression, env: Environment): Value =
  ## Evaluates a function definition.
  return Value(kind: vkFunction, body: node.body, env: env, params: node.params)

proc evalValue(
    interpreter: Interpreter, node: Expression, environment: Environment
): Value =
  ## Recursively evaluates an AST node and returns a plain Value.
  let env = if environment == nil: interpreter.env else: environment
  template binOp(node, op: untyped): Value =
    op(interpreter.evalValue(node.left, env), interpreter.evalValue(node.right, env))

  try:
    case node.kind
    of ekNumber:
      return newValue(node.nValue)
    of ekTrue:
      return Value(kind: vkBool, bValue: true)
    of ekFalse:
      return Value(kind: vkBool, bValue: false)
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
    of ekAnd:
      return binOp(node, `and`)
    of ekOr:
      return binOp(node, `or`)
    of ekVector:
      return
        Value(kind: vkVector, values: node.values.mapIt(interpreter.evalValue(it, env)))
    of ekNeg:
      return -interpreter.evalValue(node.operand, env)
    of ekNot:
      return not interpreter.evalValue(node.operand, env)
    of ekAssign:
      return evalAssign(interpreter, node, env)
    of ekIdent:
      return env[node.name]
    of ekBlock:
      return evalBlock(interpreter, node, env)
    of ekFunc:
      return evalFunc(interpreter, node, env)
    of ekFuncInvoke:
      return evalFunInvoke(interpreter, node, env)
    of ekIf:
      for branch in node.branches:
        let condition = interpreter.evalValue(branch.condition, env)
        if condition.kind != vkBool:
          raise newTypeError(
            "Expected boolean condition, got " & $condition.kind,
            branch.condition.position,
          )
        if condition.bValue:
          return interpreter.evalValue(branch.then, env)
      return interpreter.evalValue(node.elseBranch, env)
  except BMathError as e:
    e.position = node.position
    raise e

proc eval*(
    interpreter: Interpreter, node: Expression, environment: Environment = nil
): LabeledValue =
  ## Top-level evaluation returns a LabeledValue.
  ## If the node is an assignment, the label is preserved.
  let env = if environment == nil: interpreter.env else: environment
  if node.kind == ekAssign:
    return LabeledValue(label: node.ident, value: interpreter.evalValue(node, env))
  else:
    return emptyLabeled(interpreter.evalValue(node, env))
