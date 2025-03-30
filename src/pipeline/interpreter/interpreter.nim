## interpreter.nim - Abstract Syntax Tree Evaluator
##
## Implements tree-walking interpretation of parsed mathematical expressions.
## This module is responsible for:
## - Expression evaluation and value propagation
## - Environment management (variable scoping)
## - Function calling and application
## - Arithmetic, logical, and comparison operations
## - Type checking and error handling during execution
## - Control flow (conditionals, blocks)
##
## The interpreter processes expressions recursively, maintaining an execution
## environment that tracks variable bindings and their values.

import std/[sequtils]
import ../../types/[value, expression, vector]
import ../../types/errors
import ./errors
import environment
import stdlib/[arithmetic, comparison, logical]

type Interpreter* = ref object ## Abstract Syntax Tree evaluator
  env: Environment ## The global environment for storing variables

proc newInterpreter*(): Interpreter =
  ## Initializes a new interpreter with an empty global environment.
  ##
  ## Returns: 
  ##   Interpreter - A new interpreter instance with initialized environment.
  result = Interpreter()
  result.env = newEnv()

proc evalValue(
  interpreter: Interpreter, node: Expression, environment: Environment
): Value

proc evalAssign(interpreter: Interpreter, node: Expression, env: Environment): Value =
  ## Evaluates an assignment expression, storing the result in the environment.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   node: Expression - The assignment expression node.
  ##   env: Environment - The current execution environment.
  ##
  ## Returns:
  ##   Value - The computed value of the assigned expression.
  ##
  ## Remarks:
  ##   The computed value is stored in the environment under the identifier
  ##   specified in the assignment node, respecting scope (local/global).
  let val = interpreter.evalValue(node.expr, env)
  env[node.ident, node.isLocal] = val
  return val

template emptyLabeled(val: Value): LabeledValue =
  LabeledValue(value: val)

proc evalFunctionCall(
    interpreter: Interpreter, funValue: Value, args: openArray[Value], env: Environment
): Value {.inline.} =
  ## Dispatches a function value (native or user-defined) with the given arguments.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   funValue: Value - The function value to be applied.
  ##   args: openArray[Value] - The arguments to pass to the function.
  ##   env: Environment - The current execution environment.
  ##
  ## Returns:
  ##   Value - The result of the function application.
  ##
  ## Raises:
  ##   InvalidArgumentError - If the number of arguments does not match the function's parameters.
  ##   TypeError - If the provided value is not callable.
  if funValue.kind == vkNativeFunc:
    let native = funValue.nativeFn
    let invoker = proc(function: Value, args: openArray[Value]): Value =
      interpreter.evalFunctionCall(function, args, env)
    return native(args, invoker)
  elif funValue.kind == vkFunction:
    let fun = funValue.function
    if args.len != fun.params.len:
      raise newInvalidArgumentError(
        "Function expects " & $(fun.params.len) & " arguments, got " & $(args.len)
      )
    let funcEnv = newEnv(parent = fun.env)
    for i, param in fun.params.pairs:
      funcEnv[param, true] = args[i]
    return interpreter.evalValue(fun.body, funcEnv)
  else:
    raise newTypeError("Provided value is not callable")

proc evalFunInvoke(
    interpreter: Interpreter, node: Expression, env: Environment
): Value {.inline.} =
  ## Evaluates a function invocation when the callee has already been computed.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   node: Expression - The function invocation expression node.
  ##   env: Environment - The current execution environment.
  ##
  ## Returns:
  ##   Value - The result of the function invocation.
  ##
  ## Raises:
  ##   TypeError - If the callee is not a function.
  try:
    let callee = interpreter.evalValue(node.fun, env)
    if callee.kind != vkFunction and callee.kind != vkNativeFunc:
      raise newTypeError("Value is not a function")
    return evalFunctionCall(
      interpreter, callee, node.arguments.mapIt(interpreter.evalValue(it, env)), env
    )
  except BMathError as e:
    e.stack.add(node.position)
    raise e

proc evalBlock(
    interpreter: Interpreter, node: Expression, env: Environment
): Value {.inline.} =
  ## Evaluates a block of expressions and returns the last computed value.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   node: Expression - The block expression node.
  ##   env: Environment - The current execution environment.
  ##
  ## Returns:
  ##   Value - The last computed value in the block.
  try:
    var blockEnv = newEnv(parent = env)
    var lastVal: Value
    for expr in node.expressions:
      lastVal = interpreter.evalValue(expr, blockEnv)
    return lastVal
  except BMathError as e:
    raise e

proc evalFunc(
    interpreter: Interpreter, node: Expression, env: Environment
): Value {.inline.} =
  ## Evaluates a function definition.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   node: Expression - The function definition expression node.
  ##   env: Environment - The current execution environment.
  ##
  ## Returns:
  ##   Value - The function value.
  return newValue(node.body, env, node.params)

proc evalValue(
    interpreter: Interpreter, node: Expression, environment: Environment
): Value =
  ## Recursively evaluates an AST node and returns a plain Value.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   node: Expression - The expression node to evaluate.
  ##   environment: Environment - The current execution environment.
  ##
  ## Returns:
  ##   Value - The evaluated value of the expression.
  ##
  ## Raises:
  ##   TypeError - If a type mismatch occurs during evaluation.
  ##   BMathError - If a mathematical error occurs during evaluation.
  let env = if environment == nil: interpreter.env else: environment
  template binOp(node, op: untyped): Value =
    op(interpreter.evalValue(node.left, env), interpreter.evalValue(node.right, env))

  try:
    case node.kind
    of ekNumber:
      return newValue(node.nValue)
    of ekBool:
      return newValue(node.bValue)
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
      var vector = newVector[Value](node.values.len)
      for i in 0 ..< node.values.len:
        vector[i] = interpreter.evalValue(node.values[i], env)
      return Value(kind: vkVector, vector: vector)
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
          raise (ref TypeError)(
            msg: "Expected boolean condition, got " & $condition.kind,
            stack: @[branch.condition.position],
          )
        if condition.boolean:
          return interpreter.evalValue(branch.then, env)
      return interpreter.evalValue(node.elseBranch, env)
  except BMathError as e:
    if e.stack.len == 0:
      e.stack.add(node.position)
    raise e

proc eval*(
    interpreter: Interpreter, node: Expression, environment: Environment = nil
): LabeledValue {.inline.} =
  ## Top-level evaluation returns a LabeledValue.
  ## If the node is an assignment, the label is preserved.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   node: Expression - The expression node to evaluate.
  ##   environment: Environment - The current execution environment (optional).
  ##
  ## Returns:
  ##   LabeledValue - The evaluated value with an optional label.
  let env = if environment == nil: interpreter.env else: environment
  if node.kind == ekAssign:
    return LabeledValue(label: node.ident, value: interpreter.evalValue(node, env))
  else:
    return emptyLabeled(interpreter.evalValue(node, env))
