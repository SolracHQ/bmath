## control.nim
## Standard library functions for program flow control

import ../../../types/[value, number, types]
import ../errors

proc exit*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Exits the program with an optional exit code
  ##
  ## Parameters:
  ## - args: An array containing at most 1 value:
  ##   - (Optional) The exit code (must be an integer)
  ##
  ## Raises:
  ## - InvalidArgumentError: If more than one argument is provided
  ## - TypeError: If the exit code is not an integer
  ##
  ## Returns:
  ## - This function never returns as it terminates the program

  # Check if we have at most 1 argument (exit code is optional)
  if args.len > 1:
    raise newInvalidArgumentError(
      "exit expects at most 1 argument (exit code), but got " & $args.len & " arguments"
    )

  var exitCode = 0 # Default exit code is 0

  # If an argument is provided, check that it's an integer
  if args.len == 1:
    if args[0].kind != vkNumber or args[0].number.kind != nkInteger:
      raise newTypeError(
        "exit expects an integer value for the exit code, but got " & (
          if args[0].kind == vkNumber: "a " & $args[0].number.kind & " number"
          else: "a " & $args[0].kind
        )
      )

    exitCode = args[0].number.integer

  # Exit the program with the specified exit code
  quit(exitCode)

proc try_or*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Executes a function and returns its result, or a default value if an exception occurs
  ##
  ## Parameters:
  ## - args: An array containing exactly 2 values:
  ##   - The function to try executing
  ##   - The default value to return if an exception occurs
  ##
  ## Returns:
  ## - The result of the function if successful, otherwise the default value
  ##
  ## Raises:
  ## - InvalidArgumentError: If not exactly 2 arguments are provided
  ## - TypeError: If the first argument is not callable

  if args.len != 2:
    raise newInvalidArgumentError(
      "try_or expects exactly 2 arguments (function, default value), but got " & $args.len & " arguments"
    )

  # Verify the first argument is a function
  if args[0].kind != vkFunction and args[0].kind != vkNativeFunc:
    raise newTypeError(
      "try_or expects a function as first argument, but got a " & $args[0].kind
    )

  try:
    # Try to invoke the function with no arguments
    return invoker(args[0], [])
  except:
    # If any exception occurs, return the default value
    return args[1]

proc try_catch*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Executes a function and returns its result, or passes the exception to a handler function
  ##
  ## Parameters:
  ## - args: An array containing exactly 2 values:
  ##   - The function to try executing
  ##   - The handler function to call if an exception occurs (receives error type)
  ##
  ## Returns:
  ## - The result of the function if successful, otherwise the result of the handler
  ##
  ## Raises:
  ## - InvalidArgumentError: If not exactly 2 arguments are provided
  ## - TypeError: If either argument is not callable

  if args.len != 2:
    raise newInvalidArgumentError(
      "try_catch expects exactly 2 arguments (function, handler), but got " & $args.len & " arguments"
    )

  # Verify both arguments are functions
  if args[0].kind != vkFunction and args[0].kind != vkNativeFunc:
    raise newTypeError(
      "try_catch expects a function as first argument, but got a " & $args[0].kind
    )

  if args[1].kind != vkFunction and args[1].kind != vkNativeFunc:
    raise newTypeError(
      "try_catch expects a function as second argument, but got a " & $args[1].kind
    )

  try:
    # Try to invoke the function with no arguments
    return invoker(args[0], [])
  except BMathError as e:
    # Create an error type with the exception message
    let errorType = Type(kind: tkError, error: e.name)
    let errorValue = Value(kind: vkType, typ: errorType)
    
    # Pass the error to the handler function
    return invoker(args[1], [errorValue])

proc print*(value:Value): Value =
  ## Prints a value to the standard output
  ##
  ## Parameters:
  ## - value: The value to print
  ##
  ## Returns:
  ## - The printed value (for chaining)
  
  # Convert the value to a string and print it
  echo $value
  return value