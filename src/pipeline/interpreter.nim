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

import std/[sequtils, tables, os, strutils]
import ../types/[value, expression, vector, errors, environment, core]
import ../stdlib/stdlib
import ../stdlib/types as typesStdlib
import lexer
import parser

type Interpreter* = ref object ## Abstract Syntax Tree evaluator
  env: Environment ## The global environment for storing variables
  importStack: seq[string] ## Stack to track imports for circular dependency detection
  currentDir: string ## Current directory for relative path resolution
  disableGlobals: bool ## Whether global functions are disabled

var loadedModules*: Table[string, Value] = {
  # Unified standard library module
  "std": stdlib.createStdModule()
}.toTable()

proc newInterpreter*(
    scriptPath: string = "", disableGlobals: bool = false
): Interpreter =
  ## Initializes a new interpreter with an empty global environment.
  ##
  ## Parameters:
  ##   scriptPath: string - Optional path to the initial script for relative path resolution
  ##   disableGlobals: bool - Whether to disable global functions
  ##
  ## Returns: 
  ##   Interpreter - A new interpreter instance with initialized environment.
  result = Interpreter()
  result.env = newEnv(disableGlobals = disableGlobals)
  result.importStack = @[]
  result.disableGlobals = disableGlobals

  # Set current directory based on script path or current working directory
  if scriptPath != "":
    result.currentDir = scriptPath.parentDir.absolutePath
  else:
    result.currentDir = getCurrentDir()

proc evalExpression(
  interpreter: Interpreter, expression: Expression, environment: Environment
): Value

proc loadModule*(
    path: string, interpreter: Interpreter = nil, env: Environment = nil
): Value =
  ## Loads and evaluates a module from the given file path or local environment.
  ## Also handles module::member syntax for extracting specific members.
  ##
  ## Parameters:
  ## 
  ## path: string - The file path of the module to load, module name, or local variable name
  ## interpreter: Interpreter - The interpreter instance for context (optional)
  ## env: Environment - The current environment to check for local modules (optional)
  ## 
  ## Returns:
  ##   Value - The evaluated module value or specific member if :: syntax is used.
  ## 
  ## Raises:
  ##   IOError - If the file cannot be read.
  ##   ParseError - If the module content cannot be parsed.
  ##   CircularDependencyError - If a circular import is detected.

  # Handle module::member syntax (including deeply nested access)
  if "::" in path:
    let parts = path.split("::")
    if parts.len < 2:
      raise newRuntimeError("Invalid module path: " & path)

    # Load the base module first
    var currentValue = loadModule(parts[0], interpreter, env)

    # Navigate through each member access
    for i in 1 ..< parts.len:
      if currentValue.kind != vkModule:
        raise
          newTypeError("Cannot access member '" & parts[i] & "' on non-module value")

      try:
        currentValue = currentValue.environment[parts[i]]
      except UndefinedVariableError:
        raise newRuntimeError("Member '" & parts[i] & "' not found in module")

    return currentValue

  # First, check if it's a local module in the current environment
  if env != nil:
    try:
      let localValue = env[path]
      if localValue.kind == vkModule:
        return localValue
    except UndefinedVariableError:
      # Not a local variable, continue with other resolution methods
      discard

  # Check if it's a stdlib module
  if path in loadedModules:
    return loadedModules[path]

  # Handle file-based modules
  let currentDir =
    if interpreter != nil:
      interpreter.currentDir
    else:
      getCurrentDir()
  var absPath: string

  # Resolve relative paths
  if path.isAbsolute:
    absPath = path
  else:
    absPath = currentDir / path

  # Add .bm extension if not present and no extension given
  if fileExists(absPath & ".bm"):
    absPath = absPath & ".bm"
  elif not fileExists(absPath):
    raise newRuntimeError("Module file not found: " & absPath)

  # Check for circular dependency
  if interpreter != nil:
    if absPath in interpreter.importStack:
      let cycleStart = interpreter.importStack.find(absPath)
      let cycle = interpreter.importStack[cycleStart ..^ 1] & @[absPath]
      raise newRuntimeError("Circular import detected: " & cycle.join(" -> "))

    # Add to import stack
    interpreter.importStack.add(absPath)

  try:
    # Check cache first
    if absPath in loadedModules:
      return loadedModules[absPath]

    # Read file content
    let content = readFile(absPath)

    # Create module environment; prefer the provided env as parent when present
    let parentEnv = env
    var moduleEnv = newEnv(parent = parentEnv)

    # Tokenize / parse / evaluate sequentially (the lexer/parser are designed
    # to produce one expression per tokenizeExpression call, like the REPL loop)
    var lx = newLexer(content)
    while not lx.atEnd:
      let tokens = lx.tokenizeExpression()
      if tokens.len == 0:
        continue
      let ast = parser.parse(tokens)
      discard interpreter.evalExpression(ast, moduleEnv)

    let moduleValue = Value(kind: vkModule, environment: moduleEnv)

    # Cache the result
    loadedModules[absPath] = moduleValue
    return moduleValue
  except IOError as e:
    raise newRuntimeError("Could not read module file: " & absPath & " (" & e.msg & ")")
  finally:
    discard interpreter.importStack.pop()

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
    return native.callable(args, invoker)
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
      return typesStdlib.casting(
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
    of ekGroup:
      return interpreter.evalExpression(expression.groupExpr, env)
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
    of ekModule:
      var modEnv = newEnv(parent = env)
      for expr in expression.moduleDef.content:
        discard interpreter.evalExpression(expr, modEnv)
      return Value(kind: vkModule, environment: modEnv)
    of ekModAccess:
      let base = interpreter.evalExpression(expression.moduleAccess.target, env)
      if base.kind != vkModule:
        raise newTypeError("Base of module access is not a module")
      let memberName = expression.moduleAccess.member
      return base.environment[memberName]
    of ekUse:
      # Simple module loading - just load the module specified by path
      return loadModule(expression.useModule.path, interpreter, env)
  except BMathError as e:
    if e.stack.len == 0:
      e.stack.add(expression.position)
    raise e

proc eval*(
    interpreter: Interpreter, expression: Expression, environment: Environment = nil
): Value {.inline.} =
  ## Top-level evaluation returns a Value directly.
  ##
  ## Parameters:
  ##   interpreter: Interpreter - The current interpreter instance.
  ##   expression: Expression - The expression node to evaluate.
  ##   environment: Environment - The current execution environment (optional).
  ##
  ## Returns:
  ##   Value - The evaluated value of the expression.
  let env = if environment == nil: interpreter.env else: environment
  return interpreter.evalExpression(expression, env)
