## comparison.nim

import utils, sequence
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

import std/options

proc min*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Find the minimum value in a collection based on several possible input forms
  ## 
  ## Parameters:
  ## - args: Can be one of several forms:
  ##   1. [vector]: Find minimum value in the vector of numbers
  ##   2. [sequence]: Find minimum value in the sequence of numbers
  ##   3. [val1, val2, ...]: Find minimum among multiple number values
  ##   4. [vector, compareFn]: Find minimum in vector using the comparison function
  ##   5. [sequence, compareFn]: Find minimum in sequence using the comparison function
  ##   6. [val1, val2, ..., compareFn]: Find minimum among values using the comparison function
  ## - invoker: The function used to invoke functions with arguments
  ##
  ## The comparison function (if provided) should return true if the first argument
  ## is "less than" (should come before) the second argument.
  ##
  ## Raises:
  ## - InvalidArgumentError: If no arguments provided or wrong format
  ## - TypeError: If values are not comparable or comparison function doesn't return boolean
  ##
  ## Returns:
  ## - The minimum value found

  if args.len == 0:
    raise newInvalidArgumentError("min requires at least one argument but got: 0")

  if args.len == 1 and (args[^1].kind == vkFunction or args[^1].kind == vkNativeFunc):
    raise newInvalidArgumentError("cannot return the minimum of a function")

  # Check if last argument is a comparison function
  let hasCustomCompare =
    args.len >= 2 and (args[^1].kind == vkFunction or args[^1].kind == vkNativeFunc)
  let comparisonFn =
    if hasCustomCompare:
      some(args[^1])
    else:
      none(Value)

  # Define our comparison function
  let isLess =
    if comparisonFn.isSome:
      proc(a, b: Value): bool =
        let isLess = invoker(comparisonFn.unsafeGet, [a, b])
        if isLess.kind != vkBool:
          raise newTypeError(
            "Comparison function must return a boolean value but got: " & $isLess.kind
          )
        isLess.boolean
    else:
      proc(a, b: Value): bool =
        # Default comparison (only for numbers)
        try:
          (a < b).boolean
        except TypeError:
          raise newTypeError(
            "Values must be numbers for default min comparison but got: " & $a.kind &
              ", " & $b.kind
          )

  # Case 1/4: Single vector argument [with optional compare function]
  if args.len == 1 + (if hasCustomCompare: 1 else: 0) and args[0].kind == vkVector:
    let vec = args[0].vector
    if vec.len == 0:
      raise newInvalidArgumentError("Cannot find minimum in empty vector")

    var minVal = vec[0]
    for i in 1 ..< vec.len:
      if isLess(vec[i], minVal):
        minVal = vec[i]

    return minVal

  # Case 2/5: Single sequence argument [with optional compare function]
  elif args.len == 1 + (if hasCustomCompare: 1 else: 0) and args[0].kind == vkSeq:
    var sequence = args[0]
    var minVal: Value
    var initialized = false

    for val in iter(sequence):
      if not initialized:
        minVal = val
        initialized = true
      elif isLess(val, minVal):
        minVal = val

    if not initialized:
      raise newInvalidArgumentError("Cannot find minimum in empty sequence")

    return minVal

  # Case 3/6: Multiple arguments [with optional compare function at the end]
  else:
    let argsEnd =
      if hasCustomCompare:
        args.len - 1
      else:
        args.len

    var minVal = args[0]
    for i in 1 ..< argsEnd:
      if isLess(args[i], minVal):
        minVal = args[i]

    return minVal

proc max*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Find the maximum value in a collection based on several possible input forms
  ## 
  ## Parameters:
  ## - args: Can be one of several forms:
  ##   1. [vector]: Find maximum value in the vector of numbers
  ##   2. [sequence]: Find maximum value in the sequence of numbers
  ##   3. [val1, val2, ...]: Find maximum among multiple number values
  ##   4. [vector, compareFn]: Find maximum in vector using the comparison function
  ##   5. [sequence, compareFn]: Find maximum in sequence using the comparison function
  ##   6. [val1, val2, ..., compareFn]: Find maximum among values using the comparison function
  ## - invoker: The function used to invoke functions with arguments
  ##
  ## The comparison function (if provided) should return true if the first argument
  ## is "greater than" (should come after) the second argument.
  ##
  ## Raises:
  ## - InvalidArgumentError: If no arguments provided or wrong format
  ## - TypeError: If values are not comparable or comparison function doesn't return boolean
  ##
  ## Returns:
  ## - The maximum value found

  if args.len == 0:
    raise newInvalidArgumentError("max requires at least one argument but got: 0")

  if args.len == 1 and (args[^1].kind == vkFunction or args[^1].kind == vkNativeFunc):
    raise newInvalidArgumentError("cannot return the maximum of a function")

  # Check if last argument is a comparison function
  let hasCustomCompare =
    args.len >= 2 and (args[^1].kind == vkFunction or args[^1].kind == vkNativeFunc)
  let comparisonFn =
    if hasCustomCompare:
      some(args[^1])
    else:
      none(Value)

  # Define our comparison function
  let isGreater =
    if comparisonFn.isSome:
      proc(a, b: Value): bool =
        let isGreater = invoker(comparisonFn.unsafeGet, [a, b])
        if isGreater.kind != vkBool:
          raise newTypeError(
            "Comparison function must return a boolean value but got: " & $isGreater.kind
          )
        isGreater.boolean
    else:
      proc(a, b: Value): bool =
        # Default comparison (only for numbers)
        try:
          (a > b).boolean
        except TypeError:
          raise newTypeError(
            "Values must be numbers for default max comparison but got: " & $a.kind &
              ", " & $b.kind
          )

  # Case 1/4: Single vector argument [with optional compare function]
  if args.len == 1 + (if hasCustomCompare: 1 else: 0) and args[0].kind == vkVector:
    let vec = args[0].vector
    if vec.len == 0:
      raise newInvalidArgumentError("Cannot find maximum in empty vector")

    var maxVal = vec[0]
    for i in 1 ..< vec.len:
      if isGreater(vec[i], maxVal):
        maxVal = vec[i]

    return maxVal

  # Case 2/5: Single sequence argument [with optional compare function]
  elif args.len == 1 + (if hasCustomCompare: 1 else: 0) and args[0].kind == vkSeq:
    var sequence = args[0]
    var maxVal: Value
    var initialized = false

    for val in iter(sequence):
      if not initialized:
        maxVal = val
        initialized = true
      elif isGreater(val, maxVal):
        maxVal = val

    if not initialized:
      raise newInvalidArgumentError("Cannot find maximum in empty sequence")

    return maxVal

  # Case 3/6: Multiple arguments [with optional compare function at the end]
  else:
    let argsEnd =
      if hasCustomCompare:
        args.len - 1
      else:
        args.len

    var maxVal = args[0]
    for i in 1 ..< argsEnd:
      if isGreater(args[i], maxVal):
        maxVal = args[i]

    return maxVal
