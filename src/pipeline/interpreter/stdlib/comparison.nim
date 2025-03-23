## comparison.nim

import utils
import ../../../types/[value, number]
import ../errors

proc `<`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Compare two values for less than
  ## 
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with bool kind
  ## - true if a is less than b
  ## - false if a is not less than b
  ##
  ## Raises:
  ## - TypeError: if the values are not numbers
  ## - InvalidOperationError: if any of the values is a complex
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.number < b.number)
  else:
    raise newTypeError("'<' operands are not numbers")

proc `<=`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Compare two values for less than or equal
  ## 
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with bool kind
  ## - true if a is less than or equal to b
  ## - false if a is not less than or equal to b
  ##
  ## Raises:
  ## - TypeError: if the values are not numbers
  ## - InvalidOperationError: if any of the values is a complex
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.number <= b.number)
  else:
    raise newTypeError("'<=' operands are not numbers")

proc `>`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Compare two values for greater than
  ## 
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with bool kind
  ## - true if a is greater than b
  ## - false if a is not greater than b
  ##
  ## Raises:
  ## - TypeError: if the values are not numbers
  ## - InvalidOperationError: if any of the values is a complex
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.number > b.number)
  else:
    raise newTypeError("'>' operands are not numbers")

proc `>=`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Compare two values for greater than or equal
  ## 
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with bool kind
  ## - true if a is greater than or equal to b
  ## - false if a is not greater than or equal to b
  ##
  ## Raises:
  ## - TypeError: if the values are not numbers
  ## - InvalidOperationError: if any of the values is a complex
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.number >= b.number)
  else:
    raise newTypeError("'>=' operands are not numbers")

template `!=`*(a, b: Value): Value =
  ## Compare two values for inequality
  ## 
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with bool kind
  ##
  ## Raises:
  ## - Same errors as the `==` operator
  not (a == b)

proc `not`*(a: Value): Value {.inline, captureNumericError.} =
  ## Negate a boolean value
  ## 
  ## Parameters:
  ## - a: value to be negated - must be a boolean
  ##
  ## Raises:
  ## - TypeError: if the value is not a boolean
  if a.kind != vkBool:
    raise newTypeError(
      "Cannot negate a non-boolean value, expected: bool but got: " & $a.kind
    )
  result = newValue(not a.boolean)

proc `==`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Compare two values for equality
  ## 
  ## Parameters:
  ## - a: first value
  ## - b: second value
  ##
  ## Returns:
  ## - a new Value object with bool kind
  ## - true if the values are equal
  ## - false if the values are not equal
  ##
  ## Raises:
  ## - ArithmeticError: when comparing values with arithmetic errors
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.number == b.number)
  elif a.kind == vkVector and b.kind == vkVector:
    if a.vector.len != b.vector.len:
      result = newValue(false)
    else:
      var eq = true
      for i in 0 ..< a.vector.len:
        if (a.vector[i] != b.vector[i]).boolean:
          eq = false
          break
      result = newValue(eq)
  else:
    result = newValue(false)
