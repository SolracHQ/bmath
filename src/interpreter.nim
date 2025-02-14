## interpreter.nim - Abstract Syntax Tree Evaluator
##
## Implements recursive tree-walking interpretation of parsed
## mathematical expressions. Handles:
## - Numeric value propagation
## - Arithmetic operation execution
## - Type promotion (int/float) during operations

import std/[tables, sequtils, macros]
import types, value, logging

type Interpreter* = object
  ## Abstract Syntax Tree evaluator
  env: Table[string, Value] ## Variable environment
  nativeFuncs: Table[string, NativeFunc] ## Native function table

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
  result.nativeFuncs["exit"] = NativeFunc(fun: proc(args: seq[Value]): Value = quit(0))
  result.nativeFuncs["pow"] = native(a^b)
  result.nativeFuncs["sqrt"] = native(sqrt(a))
  result.nativeFuncs["floor"] = native(floor(a))
  result.nativeFuncs["ceil"] = native(ceil(a))
  result.nativeFuncs["round"] = native(round(a))

proc eval*(interpreter: var Interpreter, node: AstNode): LabeledValue =
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

  let value = case node.kind:
  of nkNumber: node.value 
  of nkAdd: interpreter.eval(node.left).value + interpreter.eval(node.right).value
  of nkSub: interpreter.eval(node.left).value - interpreter.eval(node.right).value
  of nkMul: interpreter.eval(node.left).value * interpreter.eval(node.right).value
  of nkDiv: 
    let left = interpreter.eval(node.left).value
    let right = interpreter.eval(node.right).value
    if right.isZero:
      raise newBMathError("Division by zero", node.position)
    left / right
  of nkPow: interpreter.eval(node.left).value ^ interpreter.eval(node.right).value
  of nkMod:
    let left = interpreter.eval(node.left).value
    let right = interpreter.eval(node.right).value
    if right.isZero:
      raise newBMathError("Modulo by zero", node.position)
    interpreter.eval(node.left).value % interpreter.eval(node.right).value
  of nkGroup: interpreter.eval(node.child).value
  of nkNeg: -interpreter.eval(node.operand).value
  of nkAssign:
    let value = interpreter.eval(node.expr).value
    interpreter.env[node.ident] = value
    return LabeledValue(label: node.ident, value: value)
  of nkIdent:
    if not interpreter.env.hasKey(node.name):
      raise newBMathError("Undefined variable: " & node.name, node.position)
    interpreter.env[node.name]
  of nkFuncCall:
    if not interpreter.nativeFuncs.hasKey(node.fun):
      raise newBMathError("Undefined function: " & node.fun, node.position)
    let fun = interpreter.nativeFuncs[node.fun]
    let args = node.args.mapIt(interpreter.eval(it).value)
    if args.len != fun.argc:
        raise newBMathError("Function " & node.fun & " expects " & $fun.argc & " arguments, got " & $args.len, node.position)
    fun.fun(args)
  LabeledValue(value: value)
  #else: raise newException(ValueError, "TODO: Implement evaluation for node kind: " & $node.kind)