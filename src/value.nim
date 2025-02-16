## value.nim
## module to define the operations for the Value type

import std/[math, sequtils]
import fusion/matching
import types, logging

proc newValue[T: SomeNumber](n: T): Value =
  ## Create a new Value object from a number
  when T is SomeInteger:
    result = Value(kind: vkInt, iValue: n.int)
  else:
    result = Value(kind: vkFloat, fValue: n.float)

proc isZero(a: Value): bool =
  ## Check if a value is zero
  case a.kind
  of vkInt:
    result = a.iValue == 0
  of vkFloat:
    result = a.fValue == 0.0
  else:
    discard

proc `+`*(a, b: Value): Value =
  ## Add two values together
  ## Promotion rules:
  ## - If both values are integers, the result is an integer
  ## - If one of the values is a float, the result is a float
  ## Raise a `BMathError` if the values are not numbers
  case (a.kind, b.kind)
  of (vkInt, vkInt):
    result = Value(kind: vkInt, iValue: a.iValue + b.iValue)
  of (vkInt, vkFloat):
    result = Value(kind: vkFloat, fValue: float(a.iValue) + b.fValue)
  of (vkFloat, vkInt):
    result = Value(kind: vkFloat, fValue: a.fValue + float(b.iValue))
  of (vkFloat, vkFloat):
    result = Value(kind: vkFloat, fValue: a.fValue + b.fValue)
  of (vkVector, vkVector):
    if a.values.len != b.values.len:
      raise
        newException(BMathError, "Vector addition requires vectors of the same length")
    var values: seq[Value] = newSeqOfCap[Value](a.values.len)
    for i in 0 ..< a.values.len:
      values.add(a.values[i] + b.values[i])
    result = Value(kind: vkVector, values: values)
  of (_, _):
    raise newException(BMathError, "'+' operands are not numbers")

proc `+=`*(a: var Value, b: Value) =
  ## Add a value to another value in place
  a = a + b

proc `-`*(a, b: Value): Value =
  ## Subtract two values
  ## Promotion rules:
  ## - If both values are integers, the result is an integer
  ## - If one of the values is a float, the result is a float
  ## Raise a `BMathError` if the values are not numbers
  case (a.kind, b.kind)
  of (vkInt, vkInt):
    result = Value(kind: vkInt, iValue: a.iValue - b.iValue)
  of (vkInt, vkFloat):
    result = Value(kind: vkFloat, fValue: float(a.iValue) - b.fValue)
  of (vkFloat, vkInt):
    result = Value(kind: vkFloat, fValue: a.fValue - float(b.iValue))
  of (vkFloat, vkFloat):
    result = Value(kind: vkFloat, fValue: a.fValue - b.fValue)
  of (vkVector, vkVector):
    if a.values.len != b.values.len:
      raise newException(
        BMathError, "Vector subtraction requires vectors of the same length"
      )
    var values: seq[Value] = newSeqOfCap[Value](a.values.len)
    for i in 0 ..< a.values.len:
      values.add(a.values[i] - b.values[i])
    result = Value(kind: vkVector, values: values)
  of (_, _):
    raise newException(BMathError, "'-' operands are not numbers")

proc `-`*(a: Value): Value =
  ## Negate a value
  case a.kind
  of vkInt:
    result = Value(kind: vkInt, iValue: -a.iValue)
  of vkFloat:
    result = Value(kind: vkFloat, fValue: -a.fValue)
  of vkVector:
    result = Value(kind: vkVector, values: a.values.mapIt(-it))
  of vkNativeFunc, vkFunction:
    raise newException(BMathError, "Cannot negate a function")

proc `*`*(a, b: Value): Value =
  ## Multiply two values
  ## Promotion rules:
  ## - If both values are integers, the result is an integer
  ## - If one of the values is a float, the result is a float
  ## Raise a `BMathError` if the values are not numbers
  case (a.kind, b.kind)
  of (vkInt, vkInt):
    result = Value(kind: vkInt, iValue: a.iValue * b.iValue)
  of (vkInt, vkFloat):
    result = Value(kind: vkFloat, fValue: float(a.iValue) * b.fValue)
  of (vkFloat, vkInt):
    result = Value(kind: vkFloat, fValue: a.fValue * float(b.iValue))
  of (vkFloat, vkFloat):
    result = Value(kind: vkFloat, fValue: a.fValue * b.fValue)
  of (vkFloat, vkVector), (vkInt, vkVector):
    result = Value(kind: vkVector, values: b.values.mapIt(a * it))
  of (vkVector, vkFloat), (vkVector, vkInt):
    result = Value(kind: vkVector, values: a.values.mapIt(it * b))
  of (_, _):
    raise newException(BMathError, "'*' operands are not numbers")

proc `*=`*(a: var Value, b: Value) =
  ## Multiply a value by another value in place
  a = a * b

proc dotProduct*(a, b: Value): Value =
  ## Compute the dot product of two vectors
  if a.kind != vkVector or b.kind != vkVector:
    raise newException(BMathError, "Dot product requires two vectors")
  if a.values.len != b.values.len:
    raise newException(BMathError, "Vectors must have the same length")
  result = Value(kind: vkInt, iValue: 0)
  for i in 0 ..< a.values.len:
    result += a.values[i] * b.values[i]

proc `/`*(a, b: Value): Value =
  ## Divide two values
  ## The division is always a float
  ## If the divisor is zero, a `BMAthError` is raised
  if b.isZero:
    raise newException(BMathError, "Division by zero")

  let a =
    case a.kind
    of vkInt:
      a.iValue.float
    of vkFloat:
      a.fValue
    else:
      raise newException(BMathError, "'/' left operand is not a number")

  let b =
    case b.kind
    of vkInt:
      b.iValue.float
    of vkFloat:
      b.fValue
    else:
      raise newException(BMathError, "'/' right operand is not a number")

  result = Value(kind: vkFloat, fValue: a / b)

proc `==`*(a, b: Value): bool =
  ## Compare two values for equality
  case a.kind
  of vkInt:
    case b.kind
    of vkInt:
      result = a.iValue == b.iValue
    of vkFloat:
      result = float(a.iValue) == b.fValue
    else:
      discard
  of vkFloat:
    case b.kind
    of vkInt:
      result = a.fValue == float(b.iValue)
    of vkFloat:
      result = a.fValue == b.fValue
    else:
      discard
  else:
    discard

proc `%`*(a, b: Value): Value =
  ## Compute the remainder of the division of two values
  ## The remainder is always an integer
  if b.isZero:
    raise newException(BMathError, "Modulus by zero")
  case a.kind
  of vkInt:
    case b.kind
    of vkInt:
      result = Value(kind: vkInt, iValue: a.iValue mod b.iValue)
    of vkFloat:
      result = Value(kind: vkInt, iValue: a.iValue mod round(b.fValue).int)
    else:
      discard
  of vkFloat:
    case b.kind
    of vkInt:
      result = Value(kind: vkInt, iValue: round(a.fValue).int mod b.iValue)
    of vkFloat:
      result = Value(kind: vkInt, iValue: round(a.fValue).int mod round(b.fValue).int)
    else:
      discard
  else:
    discard

proc `^`*(a, b: Value): Value =
  ## Raise a value to the power of another value
  ## If both values are integers, the result is an integer
  ## Otherwise, the result is a float
  case a.kind
  of vkInt:
    case b.kind
    of vkInt:
      result = Value(kind: vkInt, iValue: a.iValue ^ b.iValue)
    of vkFloat:
      result = Value(kind: vkFloat, fValue: a.iValue.toFloat ^ b.fValue)
    else:
      discard
  of vkFloat:
    case b.kind
    of vkInt:
      result = Value(kind: vkFloat, fValue: a.fValue ^ b.iValue)
    of vkFloat:
      result = Value(kind: vkFloat, fValue: pow(a.fValue, b.fValue))
    else:
      discard
  else:
    discard

proc sqrt*(a: Value): Value =
  ## Compute the square root of a value
  case a.kind
  of vkInt:
    result = Value(kind: vkFloat, fValue: sqrt(float(a.iValue)))
  of vkFloat:
    result = Value(kind: vkFloat, fValue: sqrt(a.fValue))
  else:
    discard

proc ceil*(a: Value): Value =
  ## Compute the ceiling of a value
  case a.kind
  of vkInt:
    result = a
  of vkFloat:
    result = Value(kind: vkInt, iValue: ceil(a.fValue).toInt)
  else:
    discard

proc floor*(a: Value): Value =
  ## Compute the floor of a value
  case a.kind
  of vkInt:
    result = a
  of vkFloat:
    result = Value(kind: vkInt, iValue: floor(a.fValue).toInt)
  else:
    discard

proc round*(a: Value): Value =
  ## Round a value to the nearest integer
  case a.kind
  of vkInt:
    result = a
  of vkFloat:
    result = Value(kind: vkInt, iValue: round(a.fValue).toInt)
  else:
    discard

proc createVector*(values: openArray[AstNode], evaluator: proc(node: AstNode): Value): Value =
  # values should contains exactly 2 values (length and function or value to be repeated)
  debug "Create vector has been called with values: ", values
  if values.len != 2:
    raise newException(BMathError, "Vector should have exactly 2 values")
  let size = evaluator(values[0])
  debug "Size of the vector: ", size.ivalue
  # Check if the first value is an integer
  if size.kind != vkInt:
    raise newException(BMathError, "Vector length should be an integer")
  let value = evaluator(values[1])
  debug "Value of the vector: ", value
  # check if is a function that recieves 1 argument
  case value.kind
  of vkFunction:
    if value.params.len != 1:
      raise newException(BMathError, "Vector value should be a function that receives 1 argument")
  of vkNativeFunc:
    if value.nativeFunc.argc != 1:
      raise newException(BMathError, "Vector value should be a function that receives 1 argument")
  else:
    if value.kind != vkInt and value.kind != vkFloat and value.kind != vkVector:
      raise newException(BMathError, "Vector value should be a number a vector or a function")
  var values = newSeqOfCap[Value](size.iValue)
  for i in 0 ..< size.iValue:
    if value.kind == vkFunction or value.kind == vkNativeFunc:
      let funcInvoke = AstNode(kind: nkFuncInvoke, callee: value, arguments: @[AstNode(kind: nkValue, value: Value(kind: vkInt, iValue: i))])
      debug "Evaluating function with argument: ", i
      values.add(evaluator(funcInvoke))
    else:
      values.add(value)
  result = Value(kind: vkVector, values: values)

proc nth*(vector: Value, index: Value): Value =
  # Get the nth element of a vector
  if vector.kind != vkVector:
    raise newException(BMathError, "nth requires a vector as the first argument")
  if index.kind != vkInt:
    raise newException(BMathError, "nth requires an integer as the second argument")
  if index.iValue < 0 or index.iValue >= vector.values.len:
    raise newException(BMathError, "Index out of bounds")
  result = vector.values[index.iValue]

proc first*(vector: Value): Value =
  # Get the first element of a vector
  if vector.kind != vkVector:
    raise newException(BMathError, "first requires a vector as the argument")
  if vector.values.len == 0:
    raise newException(BMathError, "Vector is empty")
  result = vector.values[0]

proc last*(vector: Value): Value =
  # Get the last element of a vector
  if vector.kind != vkVector:
    raise newException(BMathError, "last requires a vector as the argument")
  if vector.values.len == 0:
    raise newException(BMathError, "Vector is empty")
  result = vector.values[^1]