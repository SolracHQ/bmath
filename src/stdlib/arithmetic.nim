## arithmetic.nim

import ../types/[value, number, errors]

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

# ----- Real and imaginary part procedures -----
proc re*(a: Value): Value {.inline, captureNumericError.} =
  ## Real part of a value
  ##
  ## Parameters:
  ## - a: value to get the real part of
  ##
  ## Returns:
  ## - a new Value object with the real part
  ##
  ## Raises:
  ## - UnsupportedTypeError: if operand is not a number
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber:
    return newValue(re(a.number))
  else:
    raise newUnsupportedTypeError("Cannot get real part of value of type: " & $a.kind)

proc im*(a: Value): Value {.inline, captureNumericError.} =
  ## Imaginary part of a value
  ##
  ## Parameters:
  ## - a: value to get the imaginary part of
  ##
  ## Returns:
  ## - a new Value object with the imaginary part
  ##
  ## Raises:
  ## - UnsupportedTypeError: if operand is not a number
  ## - ArithmeticError: for numeric calculation errors
  if a.kind == vkNumber:
    return newValue(im(a.number))
  else:
    raise
      newUnsupportedTypeError("Cannot get imaginary part of value of type: " & $a.kind)
