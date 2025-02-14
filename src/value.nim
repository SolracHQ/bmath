## value.nim
## module to define the operations for the Value type

import std/math
import types

proc newValue[T: SomeNumber](n: T): Value =
  ## Create a new Value object from a number
  when T is SomeInteger:
    result = Value(kind: vkInt, iValue: n.int)
  else:
    result = Value(kind: vkFloat, fValue: n.float)

proc `+`*(a, b: Value): Value =
  ## Add two values together
  ## Promotion rules:
  ## - If both values are integers, the result is an integer
  ## - If one of the values is a float, the result is a float
  case a.kind
  of vkInt:
    case b.kind
    of vkInt: result = Value(kind: vkInt, iValue: a.iValue + b.iValue)
    of vkFloat: result = Value(kind: vkFloat, fValue: float(a.iValue) + b.fValue)
  of vkFloat:
    case b.kind
    of vkInt: result = Value(kind: vkFloat, fValue: a.fValue + float(b.iValue))
    of vkFloat: result = Value(kind: vkFloat, fValue: a.fValue + b.fValue)

proc `-`*(a, b: Value): Value =
  ## Subtract two values
  ## Promotion rules:
  ## - If both values are integers, the result is an integer
  ## - If one of the values is a float, the result is a float
  case a.kind
  of vkInt:
    case b.kind
    of vkInt: result = Value(kind: vkInt, iValue: a.iValue - b.iValue)
    of vkFloat: result = Value(kind: vkFloat, fValue: float(a.iValue) - b.fValue)
  of vkFloat:
    case b.kind
    of vkInt: result = Value(kind: vkFloat, fValue: a.fValue - float(b.iValue))
    of vkFloat: result = Value(kind: vkFloat, fValue: a.fValue - b.fValue)

proc `-`*(a: Value): Value =
  ## Negate a value
  case a.kind
  of vkInt: result = Value(kind: vkInt, iValue: -a.iValue)
  of vkFloat: result = Value(kind: vkFloat, fValue: -a.fValue)

proc `*`*(a, b: Value): Value =
  ## Multiply two values
  ## Promotion rules:
  ## - If both values are integers, the result is an integer
  ## - If one of the values is a float, the result is a float
  case a.kind
  of vkInt:
    case b.kind
    of vkInt: result = Value(kind: vkInt, iValue: a.iValue * b.iValue)
    of vkFloat: result = Value(kind: vkFloat, fValue: float(a.iValue) * b.fValue)
  of vkFloat:
    case b.kind
    of vkInt: result = Value(kind: vkFloat, fValue: a.fValue * float(b.iValue))
    of vkFloat: result = Value(kind: vkFloat, fValue: a.fValue * b.fValue)

proc `/`*(a, b: Value): Value =
  ## Divide two values
  ## The division is always a float
  ## If the divisor is zero, a `BMAthError` is raised with the position of the division
  ## Precondition: caller should ensure that the divisor is not zero
  case a.kind
  of vkInt:
    case b.kind
    of vkInt: result = Value(kind: vkFloat, fValue: float(a.iValue) / float(b.iValue))
    of vkFloat: result = Value(kind: vkFloat, fValue: float(a.iValue) / b.fValue)
  of vkFloat:
    case b.kind
    of vkInt: result = Value(kind: vkFloat, fValue: a.fValue / float(b.iValue))
    of vkFloat: result = Value(kind: vkFloat, fValue: a.fValue / b.fValue)

proc `==`*(a, b: Value): bool =
  ## Compare two values for equality
  case a.kind
  of vkInt:
    case b.kind
    of vkInt: result = a.iValue == b.iValue
    of vkFloat: result = float(a.iValue) == b.fValue
  of vkFloat:
    case b.kind
    of vkInt: result = a.fValue == float(b.iValue)
    of vkFloat: result = a.fValue == b.fValue

proc `%`*(a, b: Value): Value =
  ## Compute the remainder of the division of two values
  ## The remainder is always an integer
  ## Precondition: caller should ensure that the divisor is not zero
  case a.kind
  of vkInt:
    case b.kind
    of vkInt: result = Value(kind: vkInt, iValue: a.iValue mod b.iValue)
    of vkFloat: result = Value(kind: vkInt, iValue: a.iValue mod round(b.fValue).int)
  of vkFloat:
    case b.kind
    of vkInt: result = Value(kind: vkInt, iValue: round(a.fValue).int mod b.iValue)
    of vkFloat: result = Value(kind: vkInt, iValue: round(a.fValue).int mod round(b.fValue).int)

proc `^`*(a, b: Value): Value =
  ## Raise a value to the power of another value
  ## If both values are integers, the result is an integer
  ## Otherwise, the result is a float
  case a.kind
  of vkInt:
    case b.kind
    of vkInt: result = Value(kind: vkInt, iValue: a.iValue^b.iValue)
    of vkFloat: result = Value(kind: vkFloat, fValue: a.iValue.toFloat^b.fValue)
  of vkFloat:
    case b.kind
    of vkInt: result = Value(kind: vkFloat, fValue: a.fValue^b.iValue)
    of vkFloat: result = Value(kind: vkFloat, fValue: pow(a.fValue, b.fValue))

proc sqrt*(a: Value): Value =
  ## Compute the square root of a value
  case a.kind
  of vkInt: result = Value(kind: vkFloat, fValue: sqrt(float(a.iValue)))
  of vkFloat: result = Value(kind: vkFloat, fValue: sqrt(a.fValue))

proc ceil*(a: Value): Value =
  ## Compute the ceiling of a value
  case a.kind
  of vkInt: result = a
  of vkFloat: result = Value(kind: vkInt, iValue: ceil(a.fValue).toInt)

proc floor*(a: Value): Value =
  ## Compute the floor of a value
  case a.kind
  of vkInt: result = a
  of vkFloat: result = Value(kind: vkInt, iValue: floor(a.fValue).toInt)

proc round*(a: Value): Value =
  ## Round a value to the nearest integer
  case a.kind
  of vkInt: result = a
  of vkFloat: result = Value(kind: vkInt, iValue: round(a.fValue).toInt)

proc isZero*(a: Value): bool =
  ## Check if a value is zero
  case a.kind
  of vkInt: result = a.iValue == 0
  of vkFloat: result = a.fValue == 0.0