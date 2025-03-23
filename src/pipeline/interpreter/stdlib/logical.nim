## logical.nim

import ../../../types/[value]
import ../errors

template `and`*(a, b: Value): Value =
  ## Compute the logical AND of two boolean values
  ##
  ## Parameters:
  ## - a: first boolean value
  ## - b: second boolean value
  ##
  ## Returns:
  ## - a new Value object with the result of the logical AND
  ##
  ## Raises:
  ## - TypeError: if any operand is not a boolean
  let left = a
  if left.kind != vkBool:
    raise newTypeError("Cannot perform logical AND on non-boolean values")
  if not left.boolean:
    newValue(false)
  else:
    let right = b
    if right.kind != vkBool:
      raise newTypeError("Cannot perform logical AND on non-boolean values")
    newValue(right.boolean)

template `or`*(a, b: Value): Value =
  ## Compute the logical OR of two boolean values
  ##
  ## Parameters:
  ## - a: first boolean value
  ## - b: second boolean value
  ##
  ## Returns:
  ## - a new Value object with the result of the logical OR
  ##
  ## Raises:
  ## - TypeError: if any operand is not a boolean
  let left = a
  if left.kind != vkBool:
    raise newTypeError("Cannot perform logical OR on non-boolean values")
  if left.boolean:
    newValue(true)
  else:
    let right = b
    if right.kind != vkBool:
      raise newTypeError("Cannot perform logical OR on non-boolean values")
    newValue(right.boolean)
