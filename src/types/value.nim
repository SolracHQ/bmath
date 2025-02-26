## types.nim
## 
## This module contains all type definitions for the interpreter to avoid cyclic dependencies.
## It includes fundamental types for values, tokens, AST nodes, and errors, along with their
## string representation implementations.

import std/[strutils, tables, sequtils]

import position, expression
export Position

type
  ValueKind* = enum
    ## Discriminator for runtime value types stored in `Value` objects.
    vkInt ## Integer value stored in `iValue` field
    vkFloat ## Floating-point value stored in `fValue` field
    vkNativeFunc ## Native function stored in `nativeFunc` field
    vkFunction ## User-defined function
    vkVector ## Vector value
    vkBool ## Boolean value

  Value* = object
    ## Variant type representing runtime numeric values with type tracking.
    case kind*: ValueKind ## Type discriminator determining active field
    of vkInt:
      iValue*: int ## Integer storage when kind is `vkInt`
    of vkFloat:
      fValue*: float ## Float storage when kind is `vkFloat`
    of vkNativeFunc:
      nativeFunc*: NativeFunc
    of vkFunction:
      body*: Expression
      env*: Environment
      params*: seq[string]
    of vkVector:
      values*: seq[Value]
    of vkBool:
      bValue*: bool

  LabeledValue* = object
    label*: string
    value*: Value

  Evaluator* = proc(node: Expression): Value
    ## Function type for evaluating AST nodes in the interpreter.

  HostFunction* = proc(args: openArray[Expression], evaluator: Evaluator): Value
    ## Function in the host language callable from the interpreter.

  NativeFunc* = object
    ## Native function interface callable from the interpreter.
    ## Native functions get access to the interpreter capabilities using the evaluator.
    ## 
    ## Fields:
    ##   argc: Number of expected arguments
    ##   fun:  Procedure implementing the function logic
    argc*: int
    fun*: HostFunction

  Environment* = ref object
    ## Environment for storing variable bindings and parent scopes.
    values*: Table[string, Value]
    parent*: Environment

proc newValue*[T](n: T): Value =
  ## Create a new Value object from a number
  when T is SomeInteger:
    result = Value(kind: vkInt, iValue: n.int)
  elif T is SomeFloat:
    result = Value(kind: vkFloat, fValue: n.float)
  elif T is bool:
    result = Value(kind: vkBool, bValue: n.bool)
  elif T is seq[Value]:
    result = Value(kind: vkVector, values: n)
  else:
    {.error: "Unsupported type for Value".}

proc newValue*(fn: NativeFunc): Value =
  ## Creates a new Value object wrapping a native function.
  result = Value(kind: vkNativeFunc, nativeFunc: fn)

proc newValue*(body: Expression, env: Environment, params: seq[string]): Value =
  ## Creates a new Value object wrapping a user-defined function.
  result = Value(kind: vkFunction, body: body, env: env, params: params)

proc `$`*(value: Value): string =
  ## Returns string representation of numeric value
  case value.kind
  of vkInt:
    $value.iValue
  of vkFloat:
    $value.fValue
  of vkNativeFunc:
    "<native func>"
  of vkFunction:
    "|" & value.params.join(", ") & "| " & value.body.asSource
  of vkVector:
    "[" & value.values.mapIt($it).join(", ") & "]"
  of vkBool:
    $value.bValue

proc `$`*(val: LabeledValue): string =
  if val.label != "":
    result = val.label & " = "
  result &= $val.value

proc `$`*(env: Environment): string =
  ## Returns string representation of environment values
  if env.parent != nil:
    result = "Environment(parent: " & $env.parent & ", values: " & $env.values & ")"
  else:
    result = "Environment(values: " & $env.values & ")"
