## interpreter.nim - Abstract Syntax Tree Evaluator
##
## Implements recursive tree-walking interpretation of parsed
## mathematical expressions. Handles:
## - Numeric value propagation
## - Arithmetic operation execution
## - Type promotion (int/float) during operations

import std/[sequtils]
import types, value, logging, environment

type Interpreter* = object
  ## Abstract Syntax Tree evaluator
  env: Environment

proc newInterpreter*(): Interpreter =
  ## Initializes a new interpreter with an empty environment
  result = Interpreter()
  result.env = newEnv()

proc eval*(interpreter: var Interpreter, node: AstNode, environment: Environment = nil): LabeledValue

proc evalAssign*(interpreter: var Interpreter, node: AstNode, env: Environment): LabeledValue =
  ## Evaluates an assignment node.
  let val = interpreter.eval(node.expr, env).value
  env[node.ident] = val
  return LabeledValue(label: node.ident, value: val)

template emptyLabeled(val: Value): LabeledValue = LabeledValue(value: val)

proc evalFuncCall*(interpreter: var Interpreter, node: AstNode, env: Environment): LabeledValue =
  ## Evaluates a function call.
  if not env.hasKey(node.fun):
    raise newBMathError("Undefined function: " & node.fun, node.position)
  let funValue = env[node.fun]
  if funValue.kind == vkNativeFunc:
    let fun = funValue.nativeFunc
    let args = node.args.mapIt(interpreter.eval(it, env).value)
    if args.len != fun.argc:
      raise newBMathError("Function " & node.fun & " expects " & $(fun.argc) & " arguments, got " & $(args.len), node.position)
    return fun.fun(args).emptyLabeled
  elif funValue.kind == vkFunction:
    if node.args.len != funValue.params.len:
      raise newBMathError("Function " & node.fun & " expects " & $(funValue.params.len) & " arguments, got " & $(node.args.len), node.position)
    let funcEnv = newEnv(parent = funValue.env)
    for i, param in funValue.params.pairs:
      funcEnv[param] = interpreter.eval(node.args[i], env).value
    return interpreter.eval(funValue.body, funcEnv)
  else:
    raise newBMathError("Function " & node.fun & " is not callable", node.position)

proc evalBlock*(interpreter: var Interpreter, node: AstNode, env: Environment): LabeledValue =
  ## Evaluates a block of expressions.
  var blockEnv = newEnv(parent = env)
  var lastVal: LabeledValue
  for expr in node.expressions:
    lastVal = interpreter.eval(expr, blockEnv)
  return lastVal

proc evalFunc*(interpreter: var Interpreter, node: AstNode, env: Environment): Value =
  ## Evaluates a function definition.
  let funcEnv = newEnv(parent = env)
  return Value(kind: vkFunction, body: node.body, env: funcEnv, params: node.params)

proc eval*(interpreter: var Interpreter, node: AstNode, environment: Environment = nil): LabeledValue =
  ## Recursively evaluates an abstract syntax tree node.
  ## Uses helper procs for multi-line expressions.
  assert node != nil, "Node is nil"
  let env = if environment == nil: interpreter.env else: environment
  try:
    case node.kind:
    of nkNumber:
      return LabeledValue(value: node.value)
    of nkAdd:
      return LabeledValue(value: interpreter.eval(node.left, env).value + interpreter.eval(node.right, env).value)
    of nkSub:
      return LabeledValue(value: interpreter.eval(node.left, env).value - interpreter.eval(node.right, env).value)
    of nkMul:
      return LabeledValue(value: interpreter.eval(node.left, env).value * interpreter.eval(node.right, env).value)
    of nkDiv:
      return LabeledValue(value: interpreter.eval(node.left, env).value / interpreter.eval(node.right, env).value)
    of nkPow:
      return LabeledValue(value: interpreter.eval(node.left, env).value ^ interpreter.eval(node.right, env).value)
    of nkMod:
      return LabeledValue(value: interpreter.eval(node.left, env).value % interpreter.eval(node.right, env).value)
    of nkGroup:
      return LabeledValue(value: interpreter.eval(node.child, env).value)
    of nkNeg:
      return LabeledValue(value: -interpreter.eval(node.operand, env).value)
    of nkAssign:
      return evalAssign(interpreter, node, env)
    of nkIdent:
      return LabeledValue(value: env[node.name])
    of nkFuncCall:
      return evalFuncCall(interpreter, node, env)
    of nkBlock:
      return evalBlock(interpreter, node, env)
    of nkFunc:
      return LabeledValue(value: evalFunc(interpreter, node, env))
  except BMathError as e:
    e.position = node.position
    raise e