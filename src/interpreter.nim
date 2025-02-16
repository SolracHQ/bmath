## interpreter.nim - Abstract Syntax Tree Evaluator
##
## Implements recursive tree-walking interpretation of parsed
## mathematical expressions. Handles:
## - Numeric value propagation
## - Arithmetic operation execution
## - Type promotion (int/float) during operations

import std/[tables, sequtils, macros]
import types, value, logging, environment

type Interpreter* = object
  ## Abstract Syntax Tree evaluator
  env: Environment

macro native*(call: untyped): NativeFunc =
  ## Creates a NativeFunc from function call syntax.
  ## 
  ## Usage:
  ##   native(pow(a, b))  # Creates NativeFunc with argc=2
  ##   native(values.`+`(x, y))  # Qualified operator
  ##   native(negate(x))  # Single argument function
  
  # Validate input structure
  let funcSym = call[0]
  let callArgs = call.len - 1

  let param = ident("args")

  # Generate argument unpacking
  var funcCall = newCall(funcSym)
  for i in 0..<callArgs:
    funcCall.add nnkBracketExpr.newTree(param, newLit(i))

  # Construct NativeFunc using quote for clarity
  result = quote do:
    NativeFunc(
      fun: proc(`param`: seq[Value]): Value = `funcCall`,
      argc: `callArgs`
    )

proc newInterpreter*(): Interpreter =
  ## Initializes a new interpreter with an empty environment
  result = Interpreter()
  result.env = newEnv()

proc eval*(interpreter: var Interpreter, node: AstNode, env: Environment = nil): LabeledValue =
  ## Recursively evaluates an abstract syntax tree node
  ## 
  ## Parameters:
  ##   node: AstNode - Abstract syntax tree node to evaluate
  ## 
  ## Returns:
  ##   Value - Result of node evaluation with type promotion
  ## 
  ## Raises:
  ##   (Propagates from Value operations)
  ##   BMathError for arithmetic errors (e.g., division by zero)
  ## 
  ## Notes:
  ##   - Handles type promotion between int/float automatically
  ##   - Returns 0 with warning for nil nodes (shouldn't occur)
  assert node != nil, "Node is nil"

  let env = if env == nil: interpreter.env else: env

  let value = try: 
    case node.kind:
    of nkNumber: node.value 
    of nkAdd: interpreter.eval(node.left).value + interpreter.eval(node.right).value
    of nkSub: interpreter.eval(node.left).value - interpreter.eval(node.right).value
    of nkMul: interpreter.eval(node.left).value * interpreter.eval(node.right).value
    of nkDiv: interpreter.eval(node.left).value / interpreter.eval(node.right).value
    of nkPow: interpreter.eval(node.left).value ^ interpreter.eval(node.right).value
    of nkMod: interpreter.eval(node.left).value % interpreter.eval(node.right).value
    of nkGroup: interpreter.eval(node.child).value
    of nkNeg: -interpreter.eval(node.operand).value
    of nkAssign:
      let value = interpreter.eval(node.expr).value
      env[node.ident] = value
      return LabeledValue(label: node.ident, value: value)
    of nkIdent:
      interpreter.env[node.name]
    of nkFuncCall:
      if not env.hasKey(node.fun):
        raise newBMathError("Undefined function: " & node.fun, node.position)
      let funValue = env[node.fun]
      if funValue.kind != vkNativeFunc:
        raise newBMathError("Function " & node.fun & " is not callable", node.position)
      let fun = funValue.nativeFunc
      let args = node.args.mapIt(interpreter.eval(it).value)
      if args.len != fun.argc:
          raise newBMathError("Function " & node.fun & " expects " & $fun.argc & " arguments, got " & $args.len, node.position)
      fun.fun(args)
  except BMathError as e:
    e.position = node.position
    raise e
  LabeledValue(value: value)
  #else: raise newException(ValueError, "TODO: Implement evaluation for node kind: " & $node.kind)