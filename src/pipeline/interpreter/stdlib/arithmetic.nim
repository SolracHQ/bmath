## arithmetic.nim

import ../../../types/[value, number, vector]
import ../errors
import utils

# ----- Addition procedures -----

proc `+`*(a, b: Value): Value {.inline.}

proc `+=`*(a: var Value, b: Value) {.inline.} =
  a = a + b

proc `+`*(a, b: Vector[Value]): Value {.inline, captureNumericError.} =
  ## Add two vectors together
  ## 
  ## Parameters:
  ## - a: first vector
  ## - b: second vector
  ##
  ## Raises:
  ## - VectorLengthMismatchError: if the vectors are not of the same length
  ## - ArithmeticError: for arithmetic errors during calculations
  ## 
  ## Returns:
  ## - a new Value object with the result of the addition
  if a.size != b.size:
    raise newVectorLengthMismatchError(a.size, b.size)
  result = Value(kind: vkVector)
  result.vector = newVector[Value](a.size)
  for i in 0 ..< a.size:
    result.vector[i] = a[i] + b[i]

proc `+`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Add two values together
  ##
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with the result of the addition
  ##
  ## Raises:
  ## - InvalidOperationError: if operands are of incompatible types
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber and b.kind == vkNumber:
    return newValue(a.number + b.number)
  elif a.kind == vkVector and b.kind == vkVector:
    return a.vector + b.vector
  else:
    raise newInvalidOperationError("addition", $a.kind, $b.kind)

# ----- Subtraction procedures -----
proc `-`*(a, b: Value): Value {.inline.}

proc `-`*(a, b: Vector[Value]): Value {.inline, captureNumericError.} =
  ## Subtract two vectors
  ##
  ## Parameters:
  ## - a: first vector
  ## - b: second vector
  ##
  ## Raises:
  ## - VectorLengthMismatchError: if the vectors are not of the same length
  ## - ArithmeticError: for arithmetic errors during calculations
  ##
  ## Returns:
  ## - a new Value object with the result of the subtraction
  if a.size != b.size:
    raise newVectorLengthMismatchError(a.size, b.size)
  result = Value(kind: vkVector)
  result.vector = newVector[Value](a.size)
  for i in 0 ..< a.size:
    result.vector[i] = a[i] - b[i]

proc `-`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Subtract two values
  ##
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with the result of the subtraction
  ##
  ## Raises:
  ## - InvalidOperationError: if operands are of incompatible types
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber and b.kind == vkNumber:
    return newValue(a.number - b.number)
  elif a.kind == vkVector and b.kind == vkVector:
    return a.vector - b.vector
  else:
    raise newInvalidOperationError("subtraction", $a.kind, $b.kind)

# ----- Multiplication procedures -----

proc `*`*(a, b: Value): Value {.inline.}

proc `*`*(a, b: Vector[Value]): Value {.inline, captureNumericError.} =
  ## Make dot product of two vectors
  ##
  ## Parameters:
  ## - a: first vector
  ## - b: second vector
  ##
  ## Raises:
  ## - VectorLengthMismatchError: if the vectors are not of the same length
  ## - ArithmeticError: for numeric calculation errors
  ##
  ## Returns:
  ## - a new Value object with the result of the multiplication
  if a.size != b.size:
    raise newVectorLengthMismatchError(a.size, b.size)
  result = newValue(0)
  for i in 0 ..< a.size:
    result = result + a[i] * b[i]

proc `*`*(a: Value, b: Vector[Value]): Value {.inline, captureNumericError.} =
  ## Multiply a number with a vector
  ##
  ## Parameters:
  ## - a: first number
  ## - b: second vector
  ##
  ## Returns:
  ## - a new Value object with the result of the multiplication
  ##
  ## Raises:
  ## - ArithmeticError: for numeric calculation errors
  result = Value(kind: vkVector)
  result.vector = newVector[Value](b.size)
  for i in 0 ..< b.size:
    result.vector[i] = a * b[i]

proc `*`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Multiply two values
  ##
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with the result of the multiplication
  ##
  ## Raises:
  ## - InvalidOperationError: if operands are of incompatible types
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber and b.kind == vkNumber:
    return newValue(a.number * b.number)
  elif a.kind == vkVector and b.kind == vkVector:
    return a.vector * b.vector
  elif a.kind == vkNumber and b.kind == vkVector:
    return a * b.vector
  elif a.kind == vkVector and b.kind == vkNumber:
    return b * a.vector
  else:
    raise newInvalidOperationError("multiplication", $a.kind, $b.kind)

# ----- Division procedures -----

proc `/`*(a, b: Value): Value {.inline.}

proc `/`*(a: Vector[Value], b: Value): Value {.inline, captureNumericError.} =
  ## Divide a vector by a number
  ##
  ## Parameters:
  ## - a: vector to divide
  ## - b: number to divide by
  ##
  ## Returns:
  ## - a new Value object with the result of the division
  ##
  ## Raises:
  ## - ArithmeticError: for numeric calculation errors
  result = Value(kind: vkVector)
  result.vector = newVector[Value](a.size)
  for i in 0 ..< a.size:
    result.vector[i] = a[i] / b

proc `/`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Divide two values
  ##
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with the result of the division
  ##
  ## Raises:
  ## - InvalidOperationError: if operands are of incompatible types
  ## - ZeroDivisionError: if divisor is zero
  ## - ArithmeticError: for other numeric calculation errors
  if a.kind == vkNumber and b.kind == vkNumber:
    if b.number.isZero:
      raise newZeroDivisionError()
    return newValue(a.number / b.number)
  elif a.kind == vkVector and b.kind == vkNumber:
    if b.number.isZero:
      raise newZeroDivisionError()
    return a.vector / b
  else:
    raise newInvalidOperationError("division", $a.kind, $b.kind)

# ----- Modulus procedures -----

proc `%`*(a, b: Value): Value {.inline.}

proc `%`*(a: Vector[Value], b: Value): Value {.inline, captureNumericError.} =
  ## Modulus of a vector by a number
  ##
  ## Parameters:
  ## - a: vector to take modulus of
  ## - b: number to take modulus by
  ##
  ## Returns:
  ## - a new Value object with the result of the modulus
  ##
  ## Raises:
  ## - ArithmeticError: for numeric calculation errors
  result = Value(kind: vkVector)
  result.vector = newVector[Value](a.size)
  for i in 0 ..< a.size:
    result.vector[i] = a[i] % b

proc `%`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Modulus of two values
  ##
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with the result of the modulus
  ##
  ## Raises:
  ## - InvalidOperationError: if operands are of incompatible types or if complex numbers are used
  ## - ZeroDivisionError: if divisor is zero
  ## - ArithmeticError: for other numeric calculation errors
  if a.kind == vkNumber and b.kind == vkNumber:
    if b.number.isZero:
      raise newZeroDivisionError()
    return newValue(a.number % b.number)
  elif a.kind == vkVector and b.kind == vkNumber:
    if b.number.isZero:
      raise newZeroDivisionError()
    return a.vector % b
  else:
    raise newInvalidOperationError("modulus", $a.kind, $b.kind)

# ----- Exponentiation procedures -----

proc `^`*(a, b: Value): Value {.inline.}

proc `^`*(a: Vector[Value], b: Value): Value {.inline, captureNumericError.} =
  ## Exponentiation of a vector by a number
  ##
  ## Parameters:
  ## - a: vector to exponentiate
  ## - b: exponent value
  ##
  ## Returns:
  ## - a new Value object with the result of the exponentiation
  ##
  ## Raises:
  ## - ArithmeticError: for numeric calculation errors
  result = Value(kind: vkVector)
  result.vector = newVector[Value](a.size)
  for i in 0 ..< a.size:
    result.vector[i] = a[i] ^ b

proc `^`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Exponentiation of two values
  ##
  ## Parameters:
  ## - a: base value
  ## - b: exponent value
  ##
  ## Returns:
  ## - a new Value object with the result of the exponentiation
  ##
  ## Raises:
  ## - InvalidOperationError: if operands are of incompatible types
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber and b.kind == vkNumber:
    return newValue(a.number ^ b.number)
  elif a.kind == vkVector and b.kind == vkNumber:
    return a.vector ^ b
  else:
    raise newInvalidOperationError("exponentiation", $a.kind, $b.kind)

# ----- Unary procedures -----
proc `-`*(a: Value): Value {.inline.}

proc `-`*(a: Vector[Value]): Value {.inline, captureNumericError.} =
  ## Negate a vector
  ##
  ## Parameters:
  ## - a: vector to negate
  ##
  ## Returns:
  ## - a new Value object with the negated vector
  ##
  ## Raises:
  ## - ArithmeticError: for numeric calculation errors
  result = Value(kind: vkVector)
  result.vector = newVector[Value](a.size)
  for i in 0 ..< a.size:
    result.vector[i] = -a[i]

proc `-`*(a: Value): Value {.inline, captureNumericError.} =
  ## Negate a value
  ##
  ## Parameters:
  ## - a: value to negate
  ##
  ## Returns:
  ## - a new Value object with the negated value
  ##
  ## Raises:
  ## - UnsupportedTypeError: if operand is not a number or vector
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber:
    return newValue(-a.number)
  elif a.kind == vkVector:
    return -a.vector
  else:
    raise newUnsupportedTypeError("Cannot negate value of type: " & $a.kind)

# ----- Square root procedure -----
proc sqrt*(a: Value): Value {.inline, captureNumericError.} =
  ## Square root of a value
  ##
  ## Parameters:
  ## - a: value to take the square root of
  ##
  ## Returns:
  ## - a new Value object with the result of the square root
  ##
  ## Raises:
  ## - UnsupportedTypeError: if operand is not a number
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber:
    return newValue(sqrt(a.number))
  else:
    raise
      newUnsupportedTypeError("Cannot take square root of value of type: " & $a.kind)

# ----- Absolute value procedure -----
proc abs*(a: Value): Value {.inline, captureNumericError.} =
  ## Absolute value of a value
  ##
  ## Parameters:
  ## - a: value to take the absolute value of
  ##
  ## Returns:
  ## - a new Value object with the result of the absolute value
  ##
  ## Raises:
  ## - UnsupportedTypeError: if operand is not a number
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber:
    return newValue(abs(a.number))
  else:
    raise
      newUnsupportedTypeError("Cannot take absolute value of value of type: " & $a.kind)

# ----- Floor procedure -----
proc floor*(a: Value): Value {.inline, captureNumericError.} =
  ## Floor of a value
  ##
  ## Parameters:
  ## - a: value to take the floor of
  ##
  ## Returns:
  ## - a new Value object with the result of the floor
  ##
  ## Raises:
  ## - UnsupportedTypeError: if operand is not a number
  ## - ComplexCeilFloorRoundError: if operand is a complex number
  if a.kind == vkNumber:
    return newValue(floor(a.number))
  else:
    raise newUnsupportedTypeError("Cannot take floor of value of type: " & $a.kind)

# ----- Ceiling procedure -----
proc ceil*(a: Value): Value {.inline, captureNumericError.} =
  ## Ceiling of a value
  ##
  ## Parameters:
  ## - a: value to take the ceiling of
  ##
  ## Returns:
  ## - a new Value object with the result of the ceiling
  ##
  ## Raises:
  ## - UnsupportedTypeError: if operand is not a number
  ## - ComplexCeilFloorRoundError: if operand is a complex number
  if a.kind == vkNumber:
    return newValue(ceil(a.number))
  else:
    raise newUnsupportedTypeError("Cannot take ceiling of value of type: " & $a.kind)

# ----- Round procedure -----
proc round*(a: Value): Value {.inline, captureNumericError.} =
  ## Round a value
  ##
  ## Parameters:
  ## - a: value to round
  ##
  ## Returns:
  ## - a new Value object with the result of the rounding
  ##
  ## Raises:
  ## - UnsupportedTypeError: if operand is not a number
  ## - ComplexCeilFloorRoundError: if operand is a complex number
  if a.kind == vkNumber:
    return newValue(round(a.number))
  else:
    raise newUnsupportedTypeError("Cannot round value of type: " & $a.kind)
