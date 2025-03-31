## types.nim
## 
## This module contains all type definitions for the interpreter to avoid cyclic dependencies.
## It includes fundamental types for values, tokens, AST nodes, and errors, along with their
## string representation implementations.

import std/[strutils, tables, sequtils, complex]

import position, expression, number, vector, types
export Position

type
  ValueKind* = enum
    ## Discriminator for runtime value types stored in `Value` objects.
    vkNumber ## Numeric value stored in `nValue` field
    vkBool ## Boolean value stored in `bValue` field
    vkNativeFunc ## Native function stored in `nativeFunc` field
    vkFunction ## User-defined function stored as reference
    vkVector ## Vector value
    vkSeq ## Sequence value, lazily evaluated and stored as reference

  Function* = ref object ## User-defined function data
    body*: Expression ## Function body
    env*: Environment ## Environment for variable bindings
    params*: seq[Parameter] ## Parameter names for the function

  Sequence* = ref object ## Lazily evaluated sequence
    generator*: Generator ## Function to generate sequence values
    transformers*: seq[Transformer] ## Functions to transform sequence values

  Value* = object
    ## Variant type representing runtime numeric values with type tracking.
    case kind*: ValueKind ## Type discriminator determining active field
    of vkNumber:
      number*: Number ## Numeric storage when kind is `vkNumber`
    of vkBool:
      boolean*: bool ## Boolean storage when kind is `vkBool`
    of vkNativeFunc:
      nativeFn*: NativeFn ## Native function storage when kind is `vkNativeFunc`
    of vkFunction:
      function*: Function ## User-defined function storage when kind is `vkFunction`
    of vkVector:
      vector*: Vector[Value] ## Vector storage when kind is `vkVector`
    of vkSeq:
      sequence*: Sequence ## Sequence storage when kind is `vkSeq`

  TransformerKind* = enum
    ## Discriminator for runtime transformer types stored in `Transformer` objects.
    tkMap ## Map transformer
    tkFilter ## Filter transformer

  Transformer* = object
    kind*: TransformerKind ## Type of transformer
    fun*: proc(x: Value): Value ## Function to transform each item in a sequence.

  Generator* {.exportc.} = object
    atEnd*: proc(): bool ## Function to check if the sequence is exhausted.
    next*: proc(peek: bool = false): Value ## Function to generate sequence values.

  LabeledValue* = object
    label*: string
    value*: Value

  FnInvoker* = proc(function: Value, args: openArray[Value]): Value
    ## Function type for invoking functions in the runtime.

  NativeFn* = proc(args: openArray[Value], invoker: FnInvoker): Value
    ## Function in the host language callable from the interpreter.

  Environment* = ref object
    ## Environment for storing variable bindings and parent scopes.
    values*: Table[string, Value]
    parent*: Environment

template newValue*[T](n: T): Value =
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
