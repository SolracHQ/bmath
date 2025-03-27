## control.nim
## Standard library functions for program flow control

import ../../../types/[value, number]
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
    if args[0].kind != vkNumber or args[0].number.kind != nkInt:
      raise newTypeError(
        "exit expects an integer value for the exit code, but got " & (
          if args[0].kind == vkNumber: "a " & $args[0].number.kind & " number"
          else: "a " & $args[0].kind
        )
      )

    exitCode = args[0].number.iValue

  # Exit the program with the specified exit code
  quit(exitCode)
