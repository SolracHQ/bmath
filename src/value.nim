## value.nim
## module to define the operations for the Value type

import std/math
import fusion/matching
import types

proc newValue[T: SomeNumber](n: T): Value =
  ## Create a new Value object from a number
  when T is SomeInteger:
    result = Value(kind: vkInt, iValue: n.int)
  else:
    result = Value(kind: vkFloat, fValue: n.float)

proc isZero(a: Value): bool =
  ## Check if a value is zero
  case a.kind
  of vkInt: result = a.iValue == 0
  of vkFloat: result = a.fValue == 0.0
  else: discard

proc `+`*(a, b: Value): Value =
  ## Add two values together
  ## Promotion rules:
  ## - If both values are integers, the result is an integer
  ## - If one of the values is a float, the result is a float
  ## Raise a `BMathError` if the values are not numbers
  case (a.kind, b.kind)
  of (vkInt, vkInt): result = Value(kind: vkInt, iValue: a.iValue + b.iValue)
  of (vkInt, vkFloat): result = Value(kind: vkFloat, fValue: float(a.iValue) + b.fValue)
  of (vkFloat, vkInt): result = Value(kind: vkFloat, fValue: a.fValue + float(b.iValue))
  of (vkFloat, vkFloat): result = Value(kind: vkFloat, fValue: a.fValue + b.fValue)
  of (_, _): raise newException(BMathError, "'+' operands are not numbers")

proc `-`*(a, b: Value): Value =
  ## Subtract two values
  ## Promotion rules:
  ## - If both values are integers, the result is an integer
  ## - If one of the values is a float, the result is a float
  ## Raise a `BMathError` if the values are not numbers
  case (a.kind, b.kind)
  of (vkInt, vkInt): result = Value(kind: vkInt, iValue: a.iValue - b.iValue)
  of (vkInt, vkFloat): result = Value(kind: vkFloat, fValue: float(a.iValue) - b.fValue)
  of (vkFloat, vkInt): result = Value(kind: vkFloat, fValue: a.fValue - float(b.iValue))
  of (vkFloat, vkFloat): result = Value(kind: vkFloat, fValue: a.fValue - b.fValue)
  of (_, _): raise newException(BMathError, "'-' operands are not numbers")

proc `-`*(a: Value): Value =
  ## Negate a value
  case a.kind
  of vkInt: result = Value(kind: vkInt, iValue: -a.iValue)
  of vkFloat: result = Value(kind: vkFloat, fValue: -a.fValue)
  of vkNativeFunc:
    raise newException(BMathError, "Cannot negate a function")

proc `*`*(a, b: Value): Value =
  ## Multiply two values
  ## Promotion rules:
  ## - If both values are integers, the result is an integer
  ## - If one of the values is a float, the result is a float
  ## Raise a `BMathError` if the values are not numbers
  case (a.kind, b.kind)
  of (vkInt, vkInt): result = Value(kind: vkInt, iValue: a.iValue * b.iValue)
  of (vkInt, vkFloat): result = Value(kind: vkFloat, fValue: float(a.iValue) * b.fValue)
  of (vkFloat, vkInt): result = Value(kind: vkFloat, fValue: a.fValue * float(b.iValue))
  of (vkFloat, vkFloat): result = Value(kind: vkFloat, fValue: a.fValue * b.fValue)
  of (_, _): raise newException(BMathError, "'*' operands are not numbers")

proc `/`*(a, b: Value): Value =
  ## Divide two values
  ## The division is always a float
  ## If the divisor is zero, a `BMAthError` is raised
  if b.isZero:
    raise newException(BMathError,"Division by zero")

  let a = case a.kind 
  of vkInt: a.iValue.float
  of vkFloat: a.fValue 
  else: raise newException(BMathError, "'/' left operand is not a number")

  let b = case b.kind
  of vkInt: b.iValue.float
  of vkFloat: b.fValue
  else: raise newException(BMathError, "'/' right operand is not a number")

  result = Value(kind: vkFloat, fValue: a / b)

proc `==`*(a, b: Value): bool =
  ## Compare two values for equality
  case a.kind
  of vkInt:
    case b.kind
    of vkInt: result = a.iValue == b.iValue
    of vkFloat: result = float(a.iValue) == b.fValue
    else: discard
  of vkFloat:
    case b.kind
    of vkInt: result = a.fValue == float(b.iValue)
    of vkFloat: result = a.fValue == b.fValue
    else: discard
  else: discard

proc `%`*(a, b: Value): Value =
  ## Compute the remainder of the division of two values
  ## The remainder is always an integer
  if b.isZero:
    raise newException(BMathError, "Modulus by zero")
  case a.kind
  of vkInt:
    case b.kind
    of vkInt: result = Value(kind: vkInt, iValue: a.iValue mod b.iValue)
    of vkFloat: result = Value(kind: vkInt, iValue: a.iValue mod round(b.fValue).int)
    else: discard
  of vkFloat:
    case b.kind
    of vkInt: result = Value(kind: vkInt, iValue: round(a.fValue).int mod b.iValue)
    of vkFloat: result = Value(kind: vkInt, iValue: round(a.fValue).int mod round(b.fValue).int)
    else: discard
  else: discard

proc `^`*(a, b: Value): Value =
  ## Raise a value to the power of another value
  ## If both values are integers, the result is an integer
  ## Otherwise, the result is a float
  case a.kind
  of vkInt:
    case b.kind
    of vkInt: result = Value(kind: vkInt, iValue: a.iValue^b.iValue)
    of vkFloat: result = Value(kind: vkFloat, fValue: a.iValue.toFloat^b.fValue)
    else: discard
  of vkFloat:
    case b.kind
    of vkInt: result = Value(kind: vkFloat, fValue: a.fValue^b.iValue)
    of vkFloat: result = Value(kind: vkFloat, fValue: pow(a.fValue, b.fValue))
    else: discard
  else: discard

proc sqrt*(a: Value): Value =
  ## Compute the square root of a value
  case a.kind
  of vkInt: result = Value(kind: vkFloat, fValue: sqrt(float(a.iValue)))
  of vkFloat: result = Value(kind: vkFloat, fValue: sqrt(a.fValue))
  else: discard

proc ceil*(a: Value): Value =
  ## Compute the ceiling of a value
  case a.kind
  of vkInt: result = a
  of vkFloat: result = Value(kind: vkInt, iValue: ceil(a.fValue).toInt)
  else: discard

proc floor*(a: Value): Value =
  ## Compute the floor of a value
  case a.kind
  of vkInt: result = a
  of vkFloat: result = Value(kind: vkInt, iValue: floor(a.fValue).toInt)
  else: discard

proc round*(a: Value): Value =
  ## Round a value to the nearest integer
  case a.kind
  of vkInt: result = a
  of vkFloat: result = Value(kind: vkInt, iValue: round(a.fValue).toInt)
  else: discard