## trigonometry.nim

import ../types/[value, number, vector, errors, core]
import std/sugar

proc cos*(a: Value): Value {.inline, captureNumericError.} =
  ## Compute the cosine of a value
  ##
  ## Parameters:
  ## - a: value to compute cosine of (number or vector)
  ##
  ## Returns:
  ## - a new Value object with the result of the cosine
  ##
  ## Raises:
  ## - TypeError: if argument is not a number or vector
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber:
    return newValue(cos(a.number))
  elif a.kind == vkVector:
    result = Value(kind: vkVector, vector: a.vector.map((v: Value) => cos(v)))
  else:
    raise newTypeError("cos expects a number or vector as argument")

proc sin*(a: Value): Value {.inline, captureNumericError.} =
  ## Compute the sine of a value
  ##
  ## Parameters:
  ## - a: value to compute sine of (number or vector)
  ##
  ## Returns:
  ## - a new Value object with the result of the sine
  ##
  ## Raises:
  ## - TypeError: if argument is not a number or vector
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber:
    return newValue(sin(a.number))
  elif a.kind == vkVector:
    result = Value(kind: vkVector, vector: a.vector.map((v: Value) => sin(v)))
  else:
    raise newTypeError("sin expects a number or vector as argument")

proc tan*(a: Value): Value {.inline, captureNumericError.} =
  ## Compute the tangent of a value
  ##
  ## Parameters:
  ## - a: value to compute tangent of (number or vector)
  ##
  ## Returns:
  ## - a new Value object with the result of the tangent
  ##
  ## Raises:
  ## - TypeError: if argument is not a number or vector
  ## - ArithmeticError: for numeric calculation errors (including division by zero)
  if a.kind == vkNumber:
    return newValue(tan(a.number))
  elif a.kind == vkVector:
    result = Value(kind: vkVector, vector: a.vector.map((v: Value) => tan(v)))
  else:
    raise newTypeError("tan expects a number or vector as argument")

proc cot*(a: Value): Value {.inline, captureNumericError.} =
  ## Compute the cotangent of a value
  ##
  ## Parameters:
  ## - a: value to compute cotangent of (number or vector)
  ##
  ## Returns:
  ## - a new Value object with the result of the cotangent
  ##
  ## Raises:
  ## - TypeError: if argument is not a number or vector
  ## - ArithmeticError: for numeric calculation errors (including division by zero)
  if a.kind == vkNumber:
    return newValue(cot(a.number))
  elif a.kind == vkVector:
    result = Value(kind: vkVector, vector: a.vector.map((v: Value) => cot(v)))
  else:
    raise newTypeError("cot expects a number or vector as argument")

proc sec*(a: Value): Value {.inline, captureNumericError.} =
  ## Compute the secant of a value
  ##
  ## Parameters:
  ## - a: value to compute secant of (number or vector)
  ##
  ## Returns:
  ## - a new Value object with the result of the secant
  ##
  ## Raises:
  ## - TypeError: if argument is not a number or vector
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber:
    return newValue(sec(a.number))
  elif a.kind == vkVector:
    result = Value(kind: vkVector, vector: a.vector.map((v: Value) => sec(v)))
  else:
    raise newTypeError("sec expects a number or vector as argument")

proc csc*(a: Value): Value {.inline, captureNumericError.} =
  ## Compute the cosecant of a value
  ##
  ## Parameters:
  ## - a: value to compute cosecant of (number or vector)
  ##
  ## Returns:
  ## - a new Value object with the result of the cosecant
  ##
  ## Raises:
  ## - TypeError: if argument is not a number or vector
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber:
    return newValue(csc(a.number))
  elif a.kind == vkVector:
    result = Value(kind: vkVector, vector: a.vector.map((v: Value) => csc(v)))
  else:
    raise newTypeError("csc expects a number or vector as argument")

proc log*(a: Value, base: Value): Value {.inline, captureNumericError.} =
  ## Compute the logarithm of a value with given base
  ##
  ## Parameters:
  ## - a: value to compute logarithm of (number or vector)
  ## - base: base of the logarithm (number)
  ##
  ## Returns:
  ## - a new Value object with the result of the logarithm
  ##
  ## Raises:
  ## - TypeError: if arguments don't match expected types
  ## - ArithmeticError: for numeric calculation errors (including negative/zero arguments)
  if a.kind == vkNumber and base.kind == vkNumber:
    return newValue(log(a.number, base.number))
  elif a.kind == vkVector and base.kind == vkNumber:
    result = Value(kind: vkVector, vector: a.vector.map((v: Value) => log(v, base)))
  else:
    raise newTypeError("log expects a number/vector and a number as arguments")

proc exp*(a: Value): Value {.inline, captureNumericError.} =
  ## Compute the exponential of a value
  ##
  ## Parameters:
  ## - a: value to compute exponential of (number or vector)
  ##
  ## Returns:
  ## - a new Value object with the result of the exponential
  ##
  ## Raises:
  ## - TypeError: if argument is not a number or vector
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber:
    return newValue(exp(a.number))
  elif a.kind == vkVector:
    result = Value(kind: vkVector, vector: a.vector.map((v: Value) => exp(v)))
  else:
    raise newTypeError("exp expects a number or vector as argument")
