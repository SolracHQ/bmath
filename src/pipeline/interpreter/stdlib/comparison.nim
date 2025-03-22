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
  ## - BMathError: if the values are not numbers
  ## - BMathError: if any of the values is a complex
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.nValue < b.nValue)
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
  ## - BMathError: if the values are not numbers
  ## - BMathError: if any of the values is a complex
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.nValue <= b.nValue)
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
  ## - BMathError: if the values are not numbers
  ## - BMathError: if any of the values is a complex
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.nValue > b.nValue)
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
  ## - BMathError: if the values are not numbers
  ## - BMathError: if any of the values is a complex
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.nValue >= b.nValue)
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
  not (a == b)

proc `not`*(a: Value): Value {.inline, captureNumericError.} =
  ## Negate a boolean value
  ## 
  ## Parameters:
  ## - a: value to be negated - must be a boolean
  ##
  ## Raises:
  ## - BMathError: if the value is not a boolean
  if a.kind != vkBool:
    raise newTypeError("Cannot negate a non-boolean value, expected: bool but got: " & $a.kind)
  result = newValue(not a.bValue)

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
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.nValue == b.nValue)
  elif a.kind == vkVector and b.kind == vkVector:
    if a.values.len != b.values.len:
      result = newValue(false)
    else:
      var eq = true
      for i in 0 ..< a.values.len:
        if (a.values[i] != b.values[i]).bValue:
          eq = false
          break
      result = newValue(eq)
  else:
    result = newValue(false)