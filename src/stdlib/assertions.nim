## assertions.nim
## Standard library functions for testing and validation

import ../types/[value, number, bm_types]
import ../types
import ../errors
from types import getType
from comparison import `==`, `<`, `>`

type AssertionError* = object of RuntimeError ## Raised when an assertion fails

template newAssertionError*(message: string): ref AssertionError =
  ## Creates a new AssertionError with given message
  (ref AssertionError)(msg: message)

proc assert*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Assert that a condition is true, with optional custom messages
  ##
  ## Parameters:
  ## - args: An array containing 1-3 values:
  ##   - condition: A boolean value to check
  ##   - failureMessage (optional): A string message to display on failure
  ##   - successMessage (optional): A string message to return on success
  ##
  ## Returns:
  ## - true if assertion passes and no success message provided
  ## - successMessage if assertion passes and success message provided
  ##
  ## Raises:
  ## - InvalidArgumentError: If wrong number of arguments provided
  ## - TypeError: If condition is not a boolean or messages are not strings
  ## - AssertionError: If the condition is false

  if args.len < 1 or args.len > 3:
    raise newInvalidArgumentError(
      "assert expects 1-3 arguments (condition, optional failureMessage, optional successMessage), but got " &
        $args.len & " arguments"
    )

  # Check that first argument is a boolean
  if args[0].kind != vkBool:
    raise newTypeError("assert expects a boolean condition, but got " & $args[0].kind)

  # If condition is false, raise AssertionError
  if not args[0].boolean:
    var message = "Assertion failed"

    # If custom failure message provided, validate and use it
    if args.len >= 2:
      if args[1].kind != vkString:
        raise newTypeError(
          "assert failure message must be a string, but got " & $args[1].kind
        )
      message = args[1].content

    raise newAssertionError(message)

  # If assertion passes, return success message if provided, otherwise true
  if args.len == 3:
    if args[2].kind != vkString:
      raise newTypeError(
        "assert success message must be a string, but got " & $args[2].kind
      )
    return args[2] # Return the success message

  return newValue(true)

proc assert_eq*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Assert that two values are equal
  ##
  ## Parameters:
  ## - args: An array containing 2-4 values:
  ##   - expected: The expected value
  ##   - actual: The actual value to compare
  ##   - failureMessage (optional): A string message to display on failure
  ##   - successMessage (optional): A string message to return on success
  ##
  ## Returns:
  ## - true if assertion passes and no success message provided
  ## - successMessage if assertion passes and success message provided
  ##
  ## Raises:
  ## - InvalidArgumentError: If wrong number of arguments provided
  ## - TypeError: If messages are provided but not strings
  ## - AssertionError: If the values are not equal

  if args.len < 2 or args.len > 4:
    raise newInvalidArgumentError(
      "assert_eq expects 2-4 arguments (expected, actual, optional failureMessage, optional successMessage), but got " &
        $args.len & " arguments"
    )

  let expected = args[0]
  let actual = args[1]

  # Use the existing == operator from comparison module
  let isEqual = (expected == actual).boolean

  if not isEqual:
    var message = "Assertion failed: expected " & $expected & ", but got " & $actual

    # If custom failure message provided, validate and use it
    if args.len >= 3:
      if args[2].kind != vkString:
        raise newTypeError(
          "assert_eq failure message must be a string, but got " & $args[2].kind
        )
      message = args[2].content & " (expected " & $expected & ", got " & $actual & ")"

    raise newAssertionError(message)

  # If assertion passes, return success message if provided, otherwise true
  if args.len == 4:
    if args[3].kind != vkString:
      raise newTypeError(
        "assert_eq success message must be a string, but got " & $args[3].kind
      )
    return args[3] # Return the success message

  return newValue(true)

proc assert_neq*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Assert that two values are not equal
  ##
  ## Parameters:
  ## - args: An array containing 2-4 values:
  ##   - first: The first value
  ##   - second: The second value to compare
  ##   - failureMessage (optional): A string message to display on failure
  ##   - successMessage (optional): A string message to return on success
  ##
  ## Returns:
  ## - true if assertion passes and no success message provided
  ## - successMessage if assertion passes and success message provided
  ##
  ## Raises:
  ## - InvalidArgumentError: If wrong number of arguments provided
  ## - TypeError: If messages are provided but not strings
  ## - AssertionError: If the values are equal

  if args.len < 2 or args.len > 4:
    raise newInvalidArgumentError(
      "assert_neq expects 2-4 arguments (first, second, optional failureMessage, optional successMessage), but got " &
        $args.len & " arguments"
    )

  let first = args[0]
  let second = args[1]

  # Use the existing == operator from comparison module
  let isEqual = (first == second).boolean

  if isEqual:
    var message = "Assertion failed: values should not be equal, but both are " & $first

    # If custom failure message provided, validate and use it
    if args.len >= 3:
      if args[2].kind != vkString:
        raise newTypeError(
          "assert_neq failure message must be a string, but got " & $args[2].kind
        )
      message = args[2].content & " (both values are " & $first & ")"

    raise newAssertionError(message)

  # If assertion passes, return success message if provided, otherwise true
  if args.len == 4:
    if args[3].kind != vkString:
      raise newTypeError(
        "assert_neq success message must be a string, but got " & $args[3].kind
      )
    return args[3] # Return the success message

  return newValue(true)

proc assert_lt*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Assert that first value is less than second value
  ##
  ## Parameters:
  ## - args: An array containing 2-4 values:
  ##   - first: The first value (should be smaller)
  ##   - second: The second value (should be larger)
  ##   - failureMessage (optional): A string message to display on failure
  ##   - successMessage (optional): A string message to return on success
  ##
  ## Returns:
  ## - true if assertion passes and no success message provided
  ## - successMessage if assertion passes and success message provided
  ##
  ## Raises:
  ## - InvalidArgumentError: If wrong number of arguments provided
  ## - TypeError: If values are not numbers or messages are not strings
  ## - AssertionError: If first value is not less than second

  if args.len < 2 or args.len > 4:
    raise newInvalidArgumentError(
      "assert_lt expects 2-4 arguments (first, second, optional failureMessage, optional successMessage), but got " &
        $args.len & " arguments"
    )

  let first = args[0]
  let second = args[1]

  # Use the existing < operator from comparison module (it validates types)
  let isLess = (first < second).boolean

  if not isLess:
    var message = "Assertion failed: " & $first & " is not less than " & $second

    # If custom failure message provided, validate and use it
    if args.len >= 3:
      if args[2].kind != vkString:
        raise newTypeError(
          "assert_lt failure message must be a string, but got " & $args[2].kind
        )
      message = args[2].content & " (" & $first & " is not less than " & $second & ")"

    raise newAssertionError(message)

  # If assertion passes, return success message if provided, otherwise true
  if args.len == 4:
    if args[3].kind != vkString:
      raise newTypeError(
        "assert_lt success message must be a string, but got " & $args[3].kind
      )
    return args[3] # Return the success message

  return newValue(true)

proc assert_gt*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Assert that first value is greater than second value
  ##
  ## Parameters:
  ## - args: An array containing 2-4 values:
  ##   - first: The first value (should be larger)
  ##   - second: The second value (should be smaller)
  ##   - failureMessage (optional): A string message to display on failure
  ##   - successMessage (optional): A string message to return on success
  ##
  ## Returns:
  ## - true if assertion passes and no success message provided
  ## - successMessage if assertion passes and success message provided
  ##
  ## Raises:
  ## - InvalidArgumentError: If wrong number of arguments provided
  ## - TypeError: If values are not numbers or messages are not strings
  ## - AssertionError: If first value is not greater than second

  if args.len < 2 or args.len > 4:
    raise newInvalidArgumentError(
      "assert_gt expects 2-4 arguments (first, second, optional failureMessage, optional successMessage), but got " &
        $args.len & " arguments"
    )

  let first = args[0]
  let second = args[1]

  # Use the existing > operator from comparison module (it validates types)
  let isGreater = (first > second).boolean

  if not isGreater:
    var message = "Assertion failed: " & $first & " is not greater than " & $second

    # If custom failure message provided, validate and use it
    if args.len >= 3:
      if args[2].kind != vkString:
        raise newTypeError(
          "assert_gt failure message must be a string, but got " & $args[2].kind
        )
      message =
        args[2].content & " (" & $first & " is not greater than " & $second & ")"

    raise newAssertionError(message)

  # If assertion passes, return success message if provided, otherwise true
  if args.len == 4:
    if args[3].kind != vkString:
      raise newTypeError(
        "assert_gt success message must be a string, but got " & $args[3].kind
      )
    return args[3] # Return the success message

  return newValue(true)

proc assert_type*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Assert that a value has the expected type
  ##
  ## Parameters:
  ## - args: An array containing 2-4 values:
  ##   - value: The value to check
  ##   - expectedType: The expected type (as a Type value)
  ##   - failureMessage (optional): A string message to display on failure
  ##   - successMessage (optional): A string message to return on success
  ##
  ## Returns:
  ## - true if assertion passes and no success message provided
  ## - successMessage if assertion passes and success message provided
  ##
  ## Raises:
  ## - InvalidArgumentError: If wrong number of arguments provided
  ## - TypeError: If expectedType is not a Type or messages are not strings
  ## - AssertionError: If value doesn't have the expected type

  if args.len < 2 or args.len > 4:
    raise newInvalidArgumentError(
      "assert_type expects 2-4 arguments (value, expectedType, optional failureMessage, optional successMessage), but got " &
        $args.len & " arguments"
    )

  let value = args[0]
  let expectedType = args[1]

  # Check that second argument is a Type
  if expectedType.kind != vkType:
    raise newTypeError(
      "assert_type expects a Type as second argument, but got " & $expectedType.kind
    )

  let valueType = getType(value)

  if not (valueType === expectedType.typ):
    var message =
      "Assertion failed: expected type " & $expectedType.typ & ", but got " & $valueType

    # If custom failure message provided, validate and use it
    if args.len >= 3:
      if args[2].kind != vkString:
        raise newTypeError(
          "assert_type failure message must be a string, but got " & $args[2].kind
        )
      message =
        args[2].content & " (expected type " & $expectedType.typ & ", got " & $valueType &
        ")"

    raise newAssertionError(message)

  # If assertion passes, return success message if provided, otherwise true
  if args.len == 4:
    if args[3].kind != vkString:
      raise newTypeError(
        "assert_type success message must be a string, but got " & $args[3].kind
      )
    return args[3] # Return the success message

  return newValue(true)

proc assert_error*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Assert that a function call raises an error
  ##
  ## Parameters:
  ## - args: An array containing 1-3 values:
  ##   - funcCall: The function call to execute
  ##   - failureMessage (optional): A string message to display on failure
  ##   - successMessage (optional): A string message to return on success
  ##
  ## Returns:
  ## - true if assertion passes (i.e. error was raised) and no success message provided
  ## - successMessage if assertion passes and success message provided
  ##
  ## Raises:
  ## - InvalidArgumentError: If wrong number of arguments provided
  ## - TypeError: If messages are provided but not strings
  ## - AssertionError: If no error was raised

  if args.len < 1 or args.len > 3:
    raise newInvalidArgumentError(
      "assert_error expects 1-3 arguments (funcCall, optional failureMessage, optional successMessage), but got " &
        $args.len & " arguments"
    )

  let funcCall = args[0]

  # Check that first argument is a callable function
  if funcCall.kind != vkNativeFunc and funcCall.kind != vkFunction:
    raise newTypeError(
      "assert_error expects a callable function, but got " & $funcCall.kind
    )

  try:
    # Try to invoke the function call
    discard invoker(funcCall, @[])
    # If no error was raised, assertion fails
    var message = "Assertion failed: expected an error to be raised"

    # If custom failure message provided, validate and use it
    if args.len >= 2:
      if args[1].kind != vkString:
        raise newTypeError(
          "assert_error failure message must be a string, but got " & $args[1].kind
        )
      message = args[1].content & " (expected an error to be raised)"
    raise newAssertionError(message)
  except RuntimeError:
    # If an error was raised, assertion passes
    # Return success message if provided, otherwise true
    if args.len == 3:
      if args[2].kind != vkString:
        raise newTypeError(
          "assert_error success message must be a string, but got " & $args[2].kind
        )
      return args[2] # Return the success message

    return newValue(true)
