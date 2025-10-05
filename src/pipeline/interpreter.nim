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

type Interpreter* = ref object
  env: Environment
  importStack: seq[string]
  currentDir: string
  disableGlobals: bool
  loadedModules: Table[string, Value]

type EvalContext* = object
  interpreter*: Interpreter
  env*: Environment

proc newEvalContext(interpreter: Interpreter, env: Environment = nil): EvalContext =
  EvalContext(interpreter: interpreter, env: if env != nil: env else: interpreter.env)

# Forward declaration
proc evaluate(ctx: EvalContext, expr: Expression): Value
proc callFunction(
  interpreter: Interpreter, funValue: Value, args: openArray[Value], env: Environment
): Value

# --- Literal Values ---
proc evalValue(ctx: EvalContext, expr: Expression): Value {.inline.} =
  expr.value

proc evalGroup(ctx: EvalContext, expr: Expression): Value {.inline.} =
  ctx.evaluate(expr.groupExpr)

proc evalVector(ctx: EvalContext, expr: Expression): Value {.inline.} =
  let elements = expr.vector.mapIt(ctx.evaluate(it))
  Value(kind: vkVector, vector: elements.fromSeq())

proc evalIdent(ctx: EvalContext, expr: Expression): Value {.inline.} =
  ctx.env[expr.identifier.ident]

proc evalThis(ctx: EvalContext, expr: Expression): Value {.inline.} =
  ## Returns the current module as a Value
  # Find the current module environment by traversing up the chain
  var current = ctx.env
  while current != nil:
    if current.kind == ekModule:
      return Value(
        kind: vkModule, metadata: ValueMetadata(isMutable: false), environment: current
      )
    current = current.parent

  # If no module found, we're at the top level - return the global environment as a module
  Value(kind: vkModule, metadata: ValueMetadata(isMutable: false), environment: ctx.env)

# --- Unary Operations ---
proc evalNeg(ctx: EvalContext, expr: Expression): Value {.inline.} =
  -ctx.evaluate(expr.unaryOp.operand)

proc evalNot(ctx: EvalContext, expr: Expression): Value {.inline.} =
  not ctx.evaluate(expr.unaryOp.operand)

# --- Binary Operations ---
template defineBinaryOp(name: untyped, op: untyped): untyped =
  proc `eval name`(ctx: EvalContext, expr: Expression): Value {.inline.} =
    let left = ctx.evaluate(expr.binaryOp.left)
    let right = ctx.evaluate(expr.binaryOp.right)
    op(left, right)

defineBinaryOp(Add, `+`)
defineBinaryOp(Sub, `-`)
defineBinaryOp(Mul, `*`)
defineBinaryOp(Div, `/`)
defineBinaryOp(Pow, `^`)
defineBinaryOp(Mod, `%`)
defineBinaryOp(Eq, `==`)
defineBinaryOp(Ne, `!=`)
defineBinaryOp(Gt, `>`)
defineBinaryOp(Lt, `<`)
defineBinaryOp(Ge, `>=`)
defineBinaryOp(Le, `<=`)
defineBinaryOp(And, `and`)
defineBinaryOp(Or, `or`)

# --- Assignment ---
proc evalAssign(ctx: EvalContext, expr: Expression): Value {.inline.} =
  let val = ctx.evaluate(expr.assign.expr)
  case expr.assign.lvalue.kind
  of ekIdent:
    # Assignment can only modify existing mutable variables
    ctx.env.assignVariable(expr.assign.lvalue.identifier.ident, val)
  of ekVecIndex:
    let vectorValue = ctx.evaluate(expr.assign.lvalue.vectorIndex.vector)
    if vectorValue.kind != vkVector:
      raise newTypeError("Left-hand side of assignment is not a vector")
    if not vectorValue.metadata.isMutable:
      raise newTypeError("Cannot modify immutable vector")
    let indexValue = ctx.evaluate(expr.assign.lvalue.vectorIndex.index)
    if indexValue.kind != vkNumber and indexValue.number.kind != nkInteger:
      raise newTypeError("Vector index must be an integer")
    let index = indexValue.number.integer
    vectorValue.vector[index] = val
  of ekModAccess:
    let base = ctx.evaluate(expr.assign.lvalue.moduleAccess.target)
    if base.kind != vkModule:
      raise newTypeError("Left-hand side of assignment is not a module")
    base.environment.assignVariable(expr.assign.lvalue.moduleAccess.member, val)
  else:
    raise newTypeError("Invalid left-hand side in assignment")
  val

# --- Declarations ---
proc evalImmutableDecl(ctx: EvalContext, expr: Expression): Value {.inline.} =
  let val = ctx.evaluate(expr.immutableDecl.expr)
  let immutableVal = val.withMutability(false) # Ensure value is marked as immutable
  case expr.immutableDecl.lvalue.kind
  of ekIdent:
    # Immutable declarations always create new bindings in the current scope
    ctx.env.declareVariable(expr.immutableDecl.lvalue.identifier.ident, immutableVal)
  else:
    raise newTypeError("Invalid left-hand side in immutable declaration")
  immutableVal

proc evalMutableDecl(ctx: EvalContext, expr: Expression): Value {.inline.} =
  let val = ctx.evaluate(expr.mutableDecl.expr)
  let mutableVal = val.withMutability(true) # Ensure value is marked as mutable
  case expr.mutableDecl.lvalue.kind
  of ekIdent:
    # Mutable declarations allow redeclaration if the existing variable is mutable
    ctx.env.declareMutableVariable(expr.mutableDecl.lvalue.identifier.ident, mutableVal)
  else:
    raise newTypeError("Invalid left-hand side in mutable declaration")
  mutableVal

# --- Control Flow ---
proc evalIf(ctx: EvalContext, expr: Expression): Value {.inline.} =
  for branch in expr.ifExpr.branches:
    let condition = ctx.evaluate(branch.condition)
    if condition.kind != vkBool:
      raise (ref TypeError)(
        msg: "Expected boolean condition, got " & $condition.kind,
        stack: @[branch.condition.position],
      )
    if condition.boolean:
      return ctx.evaluate(branch.then)
  ctx.evaluate(expr.ifExpr.elseBranch)

# --- Block Expressions ---
proc evalBlock(ctx: EvalContext, expr: Expression): Value {.inline.} =
  let blockEnv = newEnv(ekBlock, parent = ctx.env)
  let blockCtx = newEvalContext(ctx.interpreter, blockEnv)
  var lastVal: Value
  for e in expr.blockExpr.expressions:
    lastVal = blockCtx.evaluate(e)
  lastVal

proc evalFunctionDef(ctx: EvalContext, expr: Expression): Value {.inline.} =
  # Find the capture environment following the scoping rules:
  # - Skip ekBlock environments (they're transparent for capture)
  # - Functions can only capture from immediate ekModule or ekFunction parent
  var currentEnv = ctx.env
  var captureEnv: Environment = nil

  # Find the actual scope boundary (function or module)
  while currentEnv != nil:
    if currentEnv.kind in {ekFunction, ekModule}:
      captureEnv = currentEnv
      break
    currentEnv = currentEnv.parent

  if captureEnv == nil:
    # Fallback - use current environment
    captureEnv = ctx.env

  # Instead of creating a new environment, we'll use the capture environment directly
  # but collect variables from intermediate blocks
  if ctx.env != captureEnv:
    # There are block environments between us and the capture environment
    # We need to create a new environment that includes block variables
    let functionCaptureEnv = newEnv(captureEnv.kind, parent = captureEnv.parent)

    # Copy all variables from the capture environment
    for name, value in captureEnv.values.pairs:
      functionCaptureEnv.values[name] = value

    # Walk back through blocks and collect their variables
    currentEnv = ctx.env
    while currentEnv != nil and currentEnv != captureEnv:
      if currentEnv.kind == ekBlock:
        for name, value in currentEnv.values.pairs:
          functionCaptureEnv.values[name] = value
      currentEnv = currentEnv.parent

    newValue(expr.functionDef.body, functionCaptureEnv, expr.functionDef.signature)
  else:
    # We're directly in the capture environment, use it as-is
    newValue(expr.functionDef.body, captureEnv, expr.functionDef.signature)

proc callNativeFunction(
    ctx: EvalContext, nativeFn: NativeFn, args: openArray[Value]
): Value =
  let invoker = proc(function: Value, args: openArray[Value]): Value =
    ctx.interpreter.callFunction(function, args, ctx.env)
  nativeFn.callable(args, invoker)

proc callUserFunction(ctx: EvalContext, fun: Function, args: openArray[Value]): Value =
  if args.len != fun.signature.params.len:
    raise newInvalidArgumentError(
      "Function expects " & $(fun.signature.params.len) & " arguments, got " & $(args.len)
    )

  let funcEnv = newEnv(ekFunction, parent = fun.env)
  for i, param in fun.signature.params.pairs:
    funcEnv.declareVariable(param.name, args[i])

  let funcCtx = newEvalContext(ctx.interpreter, funcEnv)
  funcCtx.evaluate(fun.body)

proc callFunction(
    interpreter: Interpreter, funValue: Value, args: openArray[Value], env: Environment
): Value =
  let ctx = newEvalContext(interpreter, env)
  case funValue.kind
  of vkNativeFunc:
    ctx.callNativeFunction(funValue.nativeFn, args)
  of vkFunction:
    ctx.callUserFunction(funValue.function, args)
  else:
    raise newTypeError("Provided value is not callable")

proc evalFunctionCall(ctx: EvalContext, expr: Expression): Value {.inline.} =
  let callee = ctx.evaluate(expr.functionCall.function)

  # Handle type constructors
  if callee.kind == vkType:
    if expr.functionCall.params.len != 1:
      raise newInvalidArgumentError("Type constructor expects one argument")
    return typesStdlib.casting(callee.bmath_type, ctx.evaluate(expr.functionCall.params[0]))

  # Handle function calls
  if callee.kind notin {vkFunction, vkNativeFunc}:
    raise newTypeError("Value is not a function")

  let args = expr.functionCall.params.mapIt(ctx.evaluate(it))
  ctx.interpreter.callFunction(callee, args, ctx.env)

proc loadModule*(
    interpreter: Interpreter, path: string, env: Environment = nil
): Value =
  # Handle module::member syntax
  if "::" in path:
    let parts = path.split("::")
    if parts.len < 2:
      raise newRuntimeError("Invalid module path: " & path)

    var currentValue = interpreter.loadModule(parts[0], env)
    for i in 1 ..< parts.len:
      if currentValue.kind != vkModule:
        raise
          newTypeError("Cannot access member '" & parts[i] & "' on non-module value")

      try:
        currentValue = currentValue.environment[parts[i]]
      except UndefinedVariableError:
        raise newRuntimeError("Member '" & parts[i] & "' not found in module")

    return currentValue

  # Check local modules
  if env != nil:
    try:
      let localValue = env[path]
      if localValue.kind == vkModule:
        return localValue
    except UndefinedVariableError:
      discard

  # Check stdlib modules
  if path in interpreter.loadedModules:
    return interpreter.loadedModules[path]

  # Handle file-based modules
  let currentDir = interpreter.currentDir
  var absPath: string

  if path.isAbsolute:
    absPath = path
  else:
    absPath = currentDir / path

  if fileExists(absPath & ".bm"):
    absPath = absPath & ".bm"
  elif not fileExists(absPath):
    raise newRuntimeError("Module file not found: " & absPath)

  # Check for circular dependency
  if absPath in interpreter.importStack:
    let cycleStart = interpreter.importStack.find(absPath)
    let cycle = interpreter.importStack[cycleStart ..^ 1] & @[absPath]
    raise newRuntimeError("Circular import detected: " & cycle.join(" -> "))

  interpreter.importStack.add(absPath)

  try:
    if absPath in interpreter.loadedModules:
      return interpreter.loadedModules[absPath]

    let content = readFile(absPath)
    let parentEnv = env
    let moduleEnv = newEnv(parent = parentEnv)
    let ctx = newEvalContext(interpreter, moduleEnv)

    var lx = newLexer(content)
    var parser = newParser()
    while not lx.atEnd:
      let tokens = lx.tokenizeExpression()
      if tokens.len == 0:
        continue
      let ast = parser.parse(tokens)
      discard ctx.evaluate(ast)

    let moduleValue = Value(kind: vkModule, environment: moduleEnv)
    interpreter.loadedModules[absPath] = moduleValue
    return moduleValue
  except IOError as e:
    raise newRuntimeError("Could not read module file: " & absPath & " (" & e.msg & ")")
  finally:
    discard interpreter.importStack.pop()

proc evalModule(ctx: EvalContext, expr: Expression): Value {.inline.} =
  let modEnv = newEnv(ekModule, parent = ctx.env)
  let modCtx = newEvalContext(ctx.interpreter, modEnv)

  for e in expr.moduleDef.content:
    discard modCtx.evaluate(e)

  Value(kind: vkModule, metadata: ValueMetadata(isMutable: false), environment: modEnv)

proc evalModuleAccess(ctx: EvalContext, expr: Expression): Value {.inline.} =
  let base = ctx.evaluate(expr.moduleAccess.target)
  if base.kind != vkModule:
    raise newTypeError("Base of module access is not a module")

  base.environment[expr.moduleAccess.member]

proc evalVectorIndex(ctx: EvalContext, expr: Expression): Value {.inline.} =
  let vectorValue = ctx.evaluate(expr.vectorIndex.vector)
  if vectorValue.kind != vkVector:
    raise newTypeError("Value is not a vector")
  let indexValue = ctx.evaluate(expr.vectorIndex.index)
  if indexValue.kind != vkNumber and indexValue.number.kind != nkInteger:
    raise newTypeError("Vector index must be an integer")
  let index = indexValue.number.integer
  if index >= vectorValue.vector.size:
    raise newInvalidArgumentError("Vector index out of bounds")
  vectorValue.vector[index]

proc evalUse(ctx: EvalContext, expr: Expression): Value {.inline.} =
  ctx.interpreter.loadModule(expr.useModule.path, ctx.env)

type ExpressionEvaluator = proc(ctx: EvalContext, expr: Expression): Value {.inline.}

const EVALUATORS: array[ExpressionKind, ExpressionEvaluator] = [
  # Primaries
  ekValue: evalValue,
  ekGroup: evalGroup,
  ekVector: evalVector,
  ekIdent: evalIdent,
  ekThis: evalThis,
  ekFuncDef: evalFunctionDef,
  ekModule: evalModule,
  ekUse: evalUse,
  ekBlock: evalBlock,

  # Postfix / call-like
  ekFuncCall: evalFunctionCall,
  ekModAccess: evalModuleAccess,
  ekVecIndex: evalVectorIndex, # Added evaluator for vector indexing

  # Unary
  ekNeg: evalNeg,
  ekNot: evalNot,

  # Power
  ekPow: evalPow,

  # Multiplicative
  ekMul: evalMul,
  ekDiv: evalDiv,
  ekMod: evalMod,

  # Additive
  ekAdd: evalAdd,
  ekSub: evalSub,

  # Relational
  ekLt: evalLt,
  ekLe: evalLe,
  ekGt: evalGt,
  ekGe: evalGe,

  # Equality
  ekEq: evalEq,
  ekNe: evalNe,

  # Logical
  ekAnd: evalAnd,
  ekOr: evalOr,

  # Assignment / Control
  ekAssign: evalAssign,
  ekImmutableDecl: evalImmutableDecl,
  ekMutableDecl: evalMutableDecl,
  ekIf: evalIf,
]

proc evaluate(ctx: EvalContext, expr: Expression): Value =
  try:
    EVALUATORS[expr.kind](ctx, expr)
  except BMathError as e:
    if e.stack.len == 0:
      e.stack.add(expr.position)
    raise e

# ============================================================================
# PUBLIC API
# ============================================================================

proc newInterpreter*(
    scriptPath: string = "", disableGlobals: bool = false
): Interpreter =
  result = Interpreter()
  result.env = newEnv(ekModule)
  result.importStack = @[]
  result.disableGlobals = disableGlobals
  result.loadedModules = {"std": stdlib.createStdModule()}.toTable()

  # Inject core globals unless disabled
  if not disableGlobals:
    stdlib.injectCoreGlobals(result.env)

  if scriptPath != "":
    result.currentDir = scriptPath.parentDir.absolutePath
  else:
    result.currentDir = getCurrentDir()

proc eval*(
    interpreter: Interpreter, expression: Expression, environment: Environment = nil
): Value =
  let ctx = newEvalContext(interpreter, environment)
  ctx.evaluate(expression)
