## arithmetic.nim

import ../../../types/[value, number]
import ../errors
import utils

# ----- Addition procedures -----

proc `+`*(a, b: Value): Value {.inline.}

proc `+`*(a, b: openArray[Value]): Value {.inline, captureNumericError.} =
  ## Add two vectors together
  ## 
  ## Parameters:
  ## - a: first vector
  ## - b: second vector
  ##
  ## Raises:
  ## - BMathError: if the vectors are not of the same length
  ## 
  ## Returns:
  ## - a new Value object with the result of the addition
  if a.len != b.len:
    raise newVectorLengthMismatchError(a.len, b.len)
  result = Value(kind: vkVector)
  result.values = newSeqOfCap[Value](a.len)
  for i in 0 ..< a.len:
    result.values.add(a[i] + b[i])

proc `+`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Add two values together
  ##
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with the result of the addition
  if a.kind == vkNumber and b.kind == vkNumber:
    return newValue(a.nValue + b.nValue)
  elif a.kind == vkVector and b.kind == vkVector:
    return a.values + b.values
  else:
    raise newInvalidOperationError("addition", $a.kind, $b.kind)

# ----- Subtraction procedures -----
proc `-`*(a, b: Value): Value {.inline.}

proc `-`*(a, b: openArray[Value]): Value {.inline, captureNumericError.} =
  ## Subtract two vectors
  ##
  ## Parameters:
  ## - a: first vector
  ## - b: second vector
  ##
  ## Raises:
  ## - BMathError: if the vectors are not of the same length
  ##
  ## Returns:
  ## - a new Value object with the result of the subtraction
  if a.len != b.len:
    raise newVectorLengthMismatchError(a.len, b.len)
  result = Value(kind: vkVector)
  result.values = newSeqOfCap[Value](a.len)
  for i in 0 ..< a.len:
    result.values.add(a[i] - b[i])

proc `-`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Subtract two values
  ##
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with the result of the subtraction
  if a.kind == vkNumber and b.kind == vkNumber:
    return newValue(a.nValue - b.nValue)
  elif a.kind == vkVector and b.kind == vkVector:
    return a.values - b.values
  else:
    raise newInvalidOperationError("subtraction", $a.kind, $b.kind)

# ----- Multiplication procedures -----

proc `*`*(a, b: Value): Value {.inline.}

proc `*`*(a, b: openArray[Value]): Value {.inline, captureNumericError.} =
  ## Make dot product of two vectors
  ##
  ## Parameters:
  ## - a: first vector
  ## - b: second vector
  ##
  ## Raises:
  ## - BMathError: if the vectors are not of the same length
  ##
  ## Returns:
  ## - a new Value object with the result of the multiplication
  if a.len != b.len:
    raise newVectorLengthMismatchError(a.len, b.len)
  result = newValue(0)
  for i in 0 ..< a.len:
    result = result + a[i] * b[i]

proc `*`*(a: Value, b: openArray[Value]): Value {.inline, captureNumericError.} =
  ## Multiply a number with a vector
  ##
  ## Parameters:
  ## - a: first number
  ## - b: second vector
  ##
  ## Returns:
  ## - a new Value object with the result of the multiplication
  result = Value(kind: vkVector)
  result.values = newSeqOfCap[Value](b.len)
  for i in 0 ..< b.len:
    result = result + a * b[i]

proc `*`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Multiply two values
  ##
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with the result of the multiplication
  if a.kind == vkNumber and b.kind == vkNumber:
    return newValue(a.nValue * b.nValue)
  elif a.kind == vkVector and b.kind == vkVector:
    return a.values * b.values
  elif a.kind == vkNumber and b.kind == vkVector:
    return a * b.values
  elif a.kind == vkVector and b.kind == vkNumber:
    return b * a.values
  else:
    raise newInvalidOperationError("multiplication", $a.kind, $b.kind)

# ----- Division procedures -----

proc `/`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Divide two values
  ##
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with the result of the division
  if a.kind == vkNumber and b.kind == vkNumber:
    if b.nValue.isZero:
      raise newZeroDivisionError()
    return newValue(a.nValue / b.nValue)
  else:
    raise newInvalidOperationError("division", $a.kind, $b.kind)

# ----- Modulus procedures -----

proc `%`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Modulus of two values
  ##
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with the result of the modulus
  if a.kind == vkNumber and b.kind == vkNumber:
    if b.nValue.isZero:
      raise newZeroDivisionError()
    return newValue(a.nValue % b.nValue)
  else:
    raise newInvalidOperationError("modulus", $a.kind, $b.kind)

# ----- Exponentiation procedures -----

proc `^`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Exponentiation of two values
  ##
  ## Parameters:
  ## - a: base value
  ## - b: exponent value
  ##
  ## Returns:
  ## - a new Value object with the result of the exponentiation
  if a.kind == vkNumber and b.kind == vkNumber:
    return newValue(a.nValue ^ b.nValue)
  else:
    raise newInvalidOperationError("exponentiation", $a.kind, $b.kind)

# ----- Unary procedures -----
proc `-`*(a: Value): Value {.inline.}

proc `-`*(a: openArray[Value]): Value {.inline, captureNumericError.} =
  ## Negate a vector
  ##
  ## Parameters:
  ## - a: vector to negate
  ##
  ## Returns:
  ## - a new Value object with the negated vector
  result = Value(kind: vkVector)
  result.values = newSeqOfCap[Value](a.len)
  for i in 0 ..< a.len:
    result.values[i] = -a[i]

proc `-`*(a: Value): Value {.inline, captureNumericError.} =
  ## Negate a value
  ##
  ## Parameters:
  ## - a: value to negate
  ##
  ## Returns:
  ## - a new Value object with the negated value
  if a.kind == vkNumber:
    return newValue(-a.nValue)
  elif a.kind == vkVector:
    return -a.values
  else:
    raise newUnsupportedTypeError("Cannot negate value of type: " & $a.kind)
