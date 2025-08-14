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
import ../../types
import ../../types
import ../../errors
import environment
import ../../stdlib/[arithmetic, comparison, logical, types]

type Interpreter* = ref object ## Abstract Syntax Tree evaluator
  env: Environment ## The global environment for storing variables

proc newInterpreter*(): Interpreter =
  ## Initializes a new interpreter with an empty global environment.
  ##
  ## Returns: 
  ##   Interpreter - A new interpreter instance with initialized environment.
  result = Interpreter()
  result.env = newEnv()

proc evalExpression(
  interpreter: Interpreter, expression: Expression, environment: Environment
): Value

proc evalAssign(
    interpreter: Interpreter, expression: Expression, env: Environment
): Value =
  ## Evaluates an assignment expression, storing the result in the environment.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   expression: Expression - The assignment expression node.
  ##   env: Environment - The current execution environment.
  ##
  ## Returns:
  ##   Value - The computed value of the assigned expression.
  ##
  ## Remarks:
  ##   The computed value is stored in the environment under the identifier
  ##   specified in the assignment node, respecting scope (local/global).
  let val = interpreter.evalExpression(expression.assign.expr, env)
  env[expression.assign.ident, expression.assign.isLocal] = val
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
      funcEnv[param.name, true] = args[i]
    return interpreter.evalExpression(fun.body, funcEnv)
  else:
    raise newTypeError("Provided value is not callable")

proc evalFunInvoke(
    interpreter: Interpreter, expression: Expression, env: Environment
): Value {.inline.} =
  ## Evaluates a function invocation when the callee has already been computed.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   expression: Expression - The function invocation expression node.
  ##   env: Environment - The current execution environment.
  ##
  ## Returns:
  ##   Value - The result of the function invocation.
  ##
  ## Raises:
  ##   TypeError - If the callee is not a function.
  try:
    let callee = interpreter.evalExpression(expression.functionCall.function, env)
    if callee.kind == vkType:
      if expression.functionCall.params.len != 1:
        raise newInvalidArgumentError("Type constructor expects one argument")
      return casting(
        callee.typ, interpreter.evalExpression(expression.functionCall.params[0], env)
      )
    if callee.kind != vkFunction and callee.kind != vkNativeFunc:
      raise newTypeError("Value is not a function")
    return evalFunctionCall(
      interpreter,
      callee,
      expression.functionCall.params.mapIt(interpreter.evalExpression(it, env)),
      env,
    )
  except BMathError as e:
    e.stack.add(expression.position)
    raise e

proc evalBlock(
    interpreter: Interpreter, expression: Expression, env: Environment
): Value {.inline.} =
  ## Evaluates a block of expressions and returns the last computed value.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   expression: Expression - The block expression node.
  ##   env: Environment - The current execution environment.
  ##
  ## Returns:
  ##   Value - The last computed value in the block.
  try:
    var blockEnv = newEnv(parent = env)
    var lastVal: Value
    for expr in expression.blockExpr.expressions:
      lastVal = interpreter.evalExpression(expr, blockEnv)
    return lastVal
  except BMathError as e:
    raise e

proc evalFunc(
    interpreter: Interpreter, expression: Expression, env: Environment
): Value {.inline.} =
  ## Evaluates a function definition.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   expression: Expression - The function definition expression node.
  ##   env: Environment - The current execution environment.
  ##
  ## Returns:
  ##   Value - The function value.
  return newValue(expression.functionDef.body, env, expression.functionDef.params)

proc evalExpression(
    interpreter: Interpreter, expression: Expression, environment: Environment
): Value =
  ## Recursively evaluates an AST node and returns a plain Value.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   expression: Expression - The expression node to evaluate.
  ##   environment: Environment - The current execution environment.
  ##
  ## Returns:
  ##   Value - The evaluated value of the expression.
  ##
  ## Raises:
  ##   TypeError - If a type mismatch occurs during evaluation.
  ##   BMathError - If a mathematical error occurs during evaluation.
  let env = if environment == nil: interpreter.env else: environment
  template binOp(expression, op: untyped): Value =
    op(
      interpreter.evalExpression(expression.binaryOp.left, env),
      interpreter.evalExpression(expression.binaryOp.right, env),
    )

  try:
    case expression.kind
    of ekValue:
      return expression.value
    of ekAdd:
      return binOp(expression, `+`)
    of ekSub:
      return binOp(expression, `-`)
    of ekMul:
      return binOp(expression, `*`)
    of ekDiv:
      return binOp(expression, `/`)
    of ekPow:
      return binOp(expression, `^`)
    of ekMod:
      return binOp(expression, `%`)
    of ekEq:
      return binOp(expression, `==`)
    of ekNe:
      return binOp(expression, `!=`)
    of ekGt:
      return binOp(expression, `>`)
    of ekLt:
      return binOp(expression, `<`)
    of ekGe:
      return binOp(expression, `>=`)
    of ekLe:
      return binOp(expression, `<=`)
    of ekAnd:
      return binOp(expression, `and`)
    of ekOr:
      return binOp(expression, `or`)
    of ekVector:
      var vector = expression.vector.map(
        proc(e: Expression): Value =
          interpreter.evalExpression(e, env)
      )
      return Value(kind: vkVector, vector: vector)
    of ekNeg:
      return -interpreter.evalExpression(expression.unaryOp.operand, env)
    of ekNot:
      return not interpreter.evalExpression(expression.unaryOp.operand, env)
    of ekAssign:
      return evalAssign(interpreter, expression, env)
    of ekIdent:
      return env[expression.identifier.ident]
    of ekBlock:
      return evalBlock(interpreter, expression, env)
    of ekFuncDef:
      return evalFunc(interpreter, expression, env)
    of ekFuncCall:
      return evalFunInvoke(interpreter, expression, env)
    of ekIf:
      for branch in expression.ifExpr.branches:
        let condition = interpreter.evalExpression(branch.condition, env)
        if condition.kind != vkBool:
          raise (ref TypeError)(
            msg: "Expected boolean condition, got " & $condition.kind,
            stack: @[branch.condition.position],
          )
        if condition.boolean:
          return interpreter.evalExpression(branch.then, env)
      return interpreter.evalExpression(expression.ifExpr.elseBranch, env)
    of ekType:
      return newValue(expression.typ)
  except BMathError as e:
    if e.stack.len == 0:
      e.stack.add(expression.position)
    raise e

proc eval*(
    interpreter: Interpreter, expression: Expression, environment: Environment = nil
): LabeledValue {.inline.} =
  ## Top-level evaluation returns a LabeledValue.
  ## If the node is an assignment, the label is preserved.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   expression: Expression - The expression node to evaluate.
  ##   environment: Environment - The current execution environment (optional).
  ##
  ## Returns:
  ##   LabeledValue - The evaluated value with an optional label.
  let env = if environment == nil: interpreter.env else: environment
  if expression.kind == ekAssign:
    return LabeledValue(
      label: expression.assign.ident, value: interpreter.evalExpression(expression, env)
    )
  else:
    return emptyLabeled(interpreter.evalExpression(expression, env))
