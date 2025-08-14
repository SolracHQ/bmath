## value.nim
## 
## This module contains all type definitions for the interpreter to avoid cyclic dependencies.
## It includes fundamental types for values, tokens, AST nodes, and errors, along with their
## string representation implementations.

import std/[strutils, tables, sequtils, complex]

import position, expression, number, vector, bm_types

import ../types

template newValue*(n: typed): Value =
  ## Create a new Value object from a number
  when n is SomeInteger:
    Value(kind: vkNumber, number: newNumber(n))
  elif n is SomeFloat:
    Value(kind: vkNumber, number: newNumber(n))
  elif n is Complex[float]:
    Value(kind: vkNumber, number: newNumber(n))
  elif n is Number:
    Value(kind: vkNumber, number: n)
  elif n is bool:
    Value(kind: vkBool, boolean: n.bool)
  elif n is seq[Value]:
    Value(kind: vkVector, vector: n)
  elif n is Type:
    Value(kind: vkType, typ: n)
  elif n is string:
    Value(kind: vkString, content: n)
  else:
    const message = "Unsupported type '" & $T & "' for Value"
    {.error: message.}

proc newValue*(
    body: Expression, env: Environment, params: seq[Parameter]
): Value {.inline.} =
  ## Creates a new Value object wrapping a user-defined function.
  var functionObj = Function(body: body, env: env, params: params)
  result = Value(kind: vkFunction, function: functionObj)

template rawAccess*(value: Value, kind: static[ValueKind]) =
  when kind == vkNumber:
    ## Returns the numeric value of the Value object
    value.number
  elif kind == vkBool:
    ## Returns the boolean value of the Value object
    value.boolean
  elif kind == vkVector:
    ## Returns the vector values of the Value object
    value.vector
  else:
    {.error: "Unsupported type for rawAccess".}

proc `$`*(kind: ValueKind): string =
  ## Returns string representation of value kind
  case kind
  of vkNumber: "number"
  of vkBool: "bool"
  of vkNativeFunc: "native func"
  of vkFunction: "function"
  of vkVector: "vector"
  of vkSeq: "seq"
  of vkType: "type"
  of vkString: "string"

proc `$`*(value: Value): string =
  ## Returns string representation of numeric value
  case value.kind
  of vkNumber:
    $value.number
  of vkBool:
    $value.boolean
  of vkNativeFunc:
    "<native func>"
  of vkFunction:
    "|" & value.function.params.join(", ") & "| " & value.function.body.asSource
  of vkVector:
    "[" & value.vector.toSeq.mapIt($it).join(", ") & "]"
  of vkSeq:
    "<seq>"
  of vkType:
    $value.typ
  of vkString:
    "\"" & value.content & "\""

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

when defined(showSize):
  static:
    echo "Value type size analysis:"
    echo "└─ Size of Value: ", sizeof(Value), " bytes"
    echo "   ├─ Base size (kind discriminator): ", sizeof(ValueKind), " bytes"
    echo "   ├─ vkNumber variant"
    echo "   │  └─ Number component: ", sizeof(Number), " bytes"
    echo "   ├─ vkBool variant"
    echo "   │  └─ Bool component: ", sizeof(bool), " bytes"
    echo "   ├─ vkNativeFunc variant"
    echo "   │  └─ NativeFunc component: ", sizeof(NativeFn), " bytes"
    echo "   ├─ vkFunction variant"
    echo "   │  └─ Function pointer size: ", sizeof(ref Function), " bytes"
    echo "   ├─ vkVector variant"
    echo "   │  └─ Vector component: ", sizeof(Vector[Value]), " bytes"
    echo "   └─ vkSeq variant"
    echo "      └─ Sequence pointer size: ", sizeof(ref Sequence), " bytes"
