## value.nim
## module to define the operations for the Value type

import std/[math, sequtils]
import fusion/matching
import types/[value, errors, expression]

proc `+`*(a, b: Value): Value =
  ## Add two values together
  ## Promotion rules:
  ## - If both values are integers, the result is an integer
  ## - If one of the values is a float, the result is a float
  ## Raise a `BMathError` if the values are not numbers
  case (a.kind, b.kind)
  of (vkInt, vkInt):
    result = newValue(a.iValue + b.iValue)
  of (vkInt, vkFloat):
    result = newValue(float(a.iValue) + b.fValue)
  of (vkFloat, vkInt):
    result = newValue(a.fValue + float(b.iValue))
  of (vkFloat, vkFloat):
    result = newValue(a.fValue + b.fValue)
  of (vkVector, vkVector):
    if a.values.len != b.values.len:
      raise
        newException(BMathError, "Vector addition requires vectors of the same length")
    var values: seq[Value] = newSeqOfCap[Value](a.values.len)
    for i in 0 ..< a.values.len:
      values.add(a.values[i] + b.values[i])
    result = newValue(values)
  of (_, _):
    raise newException(BMathError, "'+' operands are not numbers")

proc `+=`*(a: var Value, b: Value) =
  ## Add a value to another value in place
  a = a + b

proc `-`*(a, b: Value): Value =
  ## Subtract two values using newValue
  case (a.kind, b.kind)
  of (vkInt, vkInt):
    result = newValue(a.iValue - b.iValue)
  of (vkInt, vkFloat):
    result = newValue(float(a.iValue) - b.fValue)
  of (vkFloat, vkInt):
    result = newValue(a.fValue - float(b.iValue))
  of (vkFloat, vkFloat):
    result = newValue(a.fValue - b.fValue)
  of (vkVector, vkVector):
    if a.values.len != b.values.len:
      raise newException(
        BMathError, "Vector subtraction requires vectors of the same length"
      )
    var values: seq[Value] = newSeqOfCap[Value](a.values.len)
    for i in 0 ..< a.values.len:
      values.add(a.values[i] - b.values[i])
    result = newValue(values)
  of (_, _):
    raise newException(BMathError, "'-' operands are not numbers")

proc `-`*(a: Value): Value =
  ## Negate a value
  case a.kind
  of vkInt:
    result = newValue(-a.iValue)
  of vkFloat:
    result = newValue(-a.fValue)
  of vkVector:
    result = newValue(a.values.mapIt(-it))
  of vkNativeFunc, vkFunction:
    raise newException(BMathError, "Cannot negate a function")
  of vkBool:
    raise newException(
      BMathError, "Cannot negate a boolean using '-' for not operation use '!'"
    )

proc `*`*(a, b: Value): Value =
  ## Multiply two values
  ## Promotion rules:
  ## - If both values are integers, the result is an integer
  ## - If one of the values is a float, the result is a float
  ## Raise a `BMathError` if the values are not numbers
  case (a.kind, b.kind)
  of (vkInt, vkInt):
    result = newValue(a.iValue * b.iValue)
  of (vkInt, vkFloat):
    result = newValue(float(a.iValue) * b.fValue)
  of (vkFloat, vkInt):
    result = newValue(a.fValue * float(b.iValue))
  of (vkFloat, vkFloat):
    result = newValue(a.fValue * b.fValue)
  of (vkFloat, vkVector), (vkInt, vkVector):
    result = newValue(b.values.mapIt(a * it))
  of (vkVector, vkFloat), (vkVector, vkInt):
    result = newValue(a.values.mapIt(it * b))
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
  result = newValue(0)
  for i in 0 ..< a.values.len:
    result += a.values[i] * b.values[i]

proc `/`*(a, b: Value): Value =
  ## Divide two values
  ## The division is always a float

  let aVal =
    case a.kind
    of vkInt:
      a.iValue.float
    of vkFloat:
      a.fValue
    else:
      raise newException(BMathError, "'/' left operand is not a number")

  let bVal =
    case b.kind
    of vkInt:
      b.iValue.float
    of vkFloat:
      b.fValue
    else:
      raise newException(BMathError, "'/' right operand is not a number")

  result = newValue(aVal / bVal)

template `!=`*(a, b: Value): Value =
  ## Compare two values for inequality
  not (a == b)

proc `not`*(a: Value): Value =
  ## Negate a boolean value
  if a.kind != vkBool:
    raise newException(BMathError, "Cannot negate a non-boolean value")
  result = newValue(not a.bValue)

proc `==`*(a, b: Value): Value =
  ## Compare two values for equality
  case (a.kind, b.kind)
  of (vkInt, vkInt):
    result = newValue(a.iValue == b.iValue)
  of (vkInt, vkFloat):
    result = newValue(float(a.iValue) == b.fValue)
  of (vkFloat, vkInt):
    result = newValue(a.fValue == float(b.iValue))
  of (vkFloat, vkFloat):
    result = newValue(a.fValue == b.fValue)
  of (vkVector, vkVector):
    if a.values.len != b.values.len:
      result = newValue(false)
    else:
      var eq = true
      for i in 0 ..< a.values.len:
        if (a.values[i] != b.values[i]).bvalue:
          eq = false
          break
      result = newValue(eq)
  else:
    result = newValue(false)

proc `<`*(a, b: Value): Value =
  ## Compare two values for less than
  case (a.kind, b.kind)
  of (vkInt, vkInt):
    result = newValue(a.iValue < b.iValue)
  of (vkInt, vkFloat):
    result = newValue(float(a.iValue) < b.fValue)
  of (vkFloat, vkInt):
    result = newValue(a.fValue < float(b.iValue))
  of (vkFloat, vkFloat):
    result = newValue(a.fValue < b.fValue)
  else:
    raise newException(BMathError, "'<' operands are not numbers")

proc `<=`*(a, b: Value): Value =
  ## Compare two values for less than or equal
  case (a.kind, b.kind)
  of (vkInt, vkInt):
    result = newValue(a.iValue <= b.iValue)
  of (vkInt, vkFloat):
    result = newValue(float(a.iValue) <= b.fValue)
  of (vkFloat, vkInt):
    result = newValue(a.fValue <= float(b.iValue))
  of (vkFloat, vkFloat):
    result = newValue(a.fValue <= b.fValue)
  else:
    raise newException(BMathError, "'<=' operands are not numbers")

proc `>`*(a, b: Value): Value =
  ## Compare two values for greater than
  case (a.kind, b.kind)
  of (vkInt, vkInt):
    result = newValue(a.iValue > b.iValue)
  of (vkInt, vkFloat):
    result = newValue(float(a.iValue) > b.fValue)
  of (vkFloat, vkInt):
    result = newValue(a.fValue > float(b.iValue))
  of (vkFloat, vkFloat):
    result = newValue(a.fValue > b.fValue)
  else:
    raise newException(BMathError, "'>' operands are not numbers")

proc `>=`*(a, b: Value): Value =
  ## Compare two values for greater than or equal
  case (a.kind, b.kind)
  of (vkInt, vkInt):
    result = newValue(a.iValue >= b.iValue)
  of (vkInt, vkFloat):
    result = newValue(float(a.iValue) >= b.fValue)
  of (vkFloat, vkInt):
    result = newValue(a.fValue >= float(b.iValue))
  of (vkFloat, vkFloat):
    result = newValue(a.fValue >= b.fValue)
  else:
    raise newException(BMathError, "'>=' operands are not numbers")

template `and`*(a, b: Value): Value =
  ## Compute the logical AND of two boolean values
  let left = a
  if left.kind != vkBool:
    raise newException(BMathError, "Cannot perform logical AND on non-boolean values")
  if not left.bValue:
    newValue(false)
  else:
    let right = b
    if right.kind != vkBool:
      raise newException(BMathError, "Cannot perform logical AND on non-boolean values")
    newValue(right.bValue)

template `or`*(a, b: Value): Value =
  ## Compute the logical OR of two boolean values
  let left = a
  if left.kind != vkBool:
    raise newException(BMathError, "Cannot perform logical OR on non-boolean values")
  if left.bValue:
    newValue(true)
  else:
    let right = b
    if right.kind != vkBool:
      raise newException(BMathError, "Cannot perform logical OR on non-boolean values")
    newValue(right.bValue)

proc `^`*(a, b: Value): Value =
  ## Raise a value to the power of another value
  ## If both values are integers, the result is an integer
  ## Otherwise, the result is a float
  case a.kind
  of vkInt:
    case b.kind
    of vkInt:
      result = newValue(a.iValue ^ b.iValue)
    of vkFloat:
      result = newValue(a.iValue.toFloat ^ b.fValue)
    else:
      discard
  of vkFloat:
    case b.kind
    of vkInt:
      result = newValue(a.fValue ^ b.iValue)
    of vkFloat:
      result = newValue(pow(a.fValue, b.fValue))
    else:
      discard
  else:
    discard

proc sqrt*(a: Value): Value =
  ## Compute the square root of a value
  case a.kind
  of vkInt:
    result = newValue(sqrt(float(a.iValue)))
  of vkFloat:
    result = newValue(sqrt(a.fValue))
  else:
    discard

proc ceil*(a: Value): Value =
  ## Compute the ceiling of a value
  case a.kind
  of vkInt:
    result = a
  of vkFloat:
    result = newValue(ceil(a.fValue).toInt)
  else:
    discard

proc floor*(a: Value): Value =
  ## Compute the floor of a value
  case a.kind
  of vkInt:
    result = a
  of vkFloat:
    result = newValue(floor(a.fValue).toInt)
  else:
    discard

proc round*(a: Value): Value =
  ## Round a value to the nearest integer
  case a.kind
  of vkInt:
    result = a
  of vkFloat:
    result = newValue(round(a.fValue).toInt)
  else:
    discard

proc `%`*(a, b: Value): Value =
  ## Compute the remainder of the division of two values
  ## If values ar3e floats will be rounded to integers
  ## If the divisor is zero, a `BMathError` is raised
  ## The remainder is always an integer
  try:
    case (a.kind, b.kind)
    of (vkInt, vkInt):
      result = newValue(a.iValue mod b.iValue)
    of (vkInt, vkFloat):
      result = newValue(a.iValue mod b.round.iValue)
    of (vkFloat, vkInt):
      result = newValue(a.round.iValue mod b.iValue)
    of (vkFloat, vkFloat):
      result = newValue(a.round.iValue mod b.round.iValue)
    else:
      raise newException(BMathError, "'%' operands are not numbers")
  except DivByZeroDefect:
    raise newException(BMathError, "Division by zero")

proc createVector*(
    values: openArray[Expression], evaluator: proc(node: Expression): Value
): Value =
  # values should contain exactly 2 values (length and function or value to be repeated)
  if values.len != 2:
    raise newException(BMathError, "Vector should have exactly 2 values")
  let size = evaluator(values[0])
  if size.kind != vkInt:
    raise newException(BMathError, "Vector length should be an integer")
  var elems = newSeqOfCap[Value](size.iValue)
  for i in 0 ..< size.iValue:
    let funcInvoke = Expression(
      kind: ekFuncInvoke,
      fun: values[1],
      arguments: @[Expression(kind: ekInt, iValue: i)],
    )
    elems.add(evaluator(funcInvoke))
  result = newValue(elems)

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
