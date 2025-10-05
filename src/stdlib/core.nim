## core.nim
## Core language functions and utilities

import ../types/[value, number, bm_types, errors, core, vector]

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
      "try_or expects exactly 2 arguments (function, default value), but got " &
        $args.len & " arguments"
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
      "try_catch expects exactly 2 arguments (function, handler), but got " & $args.len &
        " arguments"
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
    # Create an error Value with the exception kind and message
    let errorValue = Value(kind: vkError, errKind: $e.name, error: e.msg)

    # Pass the error Value to the handler function
    return invoker(args[1], [errorValue])

proc concat*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Concatenates any number of values into a single string
  ##
  ## Parameters:
  ## - args: An array of values to concatenate
  ##
  ## Returns:
  ## - A new Value object containing the concatenated string
  if args.len == 0:
    return newValue("")

  var sb = ""
  for v in args:
    if v.kind == vkString:
      sb &= v.content
    else:
      sb &= $v
  return newValue(sb)

proc print*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Prints any number of values separated by a single space.
  # Require at least one argument
  if args.len == 0:
    raise newInvalidArgumentError("print expects at least 1 argument, but got 0")

  # Build a single string of all arguments separated by a space
  var sb = ""
  for i in 0 ..< args.len:
    if i > 0:
      sb &= " "
    if args[i].kind == vkString:
      sb &= args[i].content
    else:
      sb &= $args[i]
  echo sb

  # Return the argument(s): single value if one argument, vector if many
  if args.len == 1:
    result = args[0]
  else:
    result = Value(kind: vkVector)
    result.vector = newVector(args.len)
    for i in 0 ..< args.len:
      result.vector[i] = args[i]

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

proc vec*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Create a vector of specified length where each element is calculated by applying 
  ## a function to its index position
  ##
  ## Parameters:
  ## - args: An array containing exactly 2 values:
  ##   1. The length of the vector (must evaluate to an integer)
  ##   2. A function to apply to each index or a value to repeat
  ## - invoker: The function used to invoke functions with arguments
  ##
  ## Raises:
  ## - InvalidArgumentError: If not exactly 2 values are provided
  ## - TypeError: If the length is not an integer
  ##
  ## Returns:
  ## - A new Value object containing the generated vector

  # Check if we have exactly 2 arguments (length and function/value)
  if args.len != 2:
    raise newInvalidArgumentError(
      "vec expects exactly 2 arguments (length and function/value), but got " & $args.len &
        " arguments"
    )

  # Evaluate the first argument to get the vector length
  let size = args[0]
  if size.kind != vkNumber or (size.kind == vkNumber and size.number.kind != nkInteger):
    raise newTypeError(
      "vec expects an integer value for the vector length, but got " & (
        if size.kind == vkNumber: "a " & $size.number.kind & " number"
        else: "a " & $size.kind
      )
    )

  # Initialize the result as a vector
  result = Value(kind: vkVector)
  result.vector = newVector(size.number.integer)

  if args[1].kind == vkFunction or args[1].kind == vkNativeFunc:
    # If the second argument is a function, apply it to each index
    for i in 0 ..< size.number.integer:
      result.vector[i] = invoker(args[1], [newValue(i)])
  else:
    # If the second argument is a value, repeat it for each index
    for i in 0 ..< size.number.integer:
      result.vector[i] = args[1]

proc seq*(values: openArray[Value], invoker: FnInvoker): Value =
  ## Create a sequence 
  ## 
  ## Parameters:
  ## - values: Can be in one of four forms:
  ##   1. [value]: Creates an infinite sequence that always returns the given value
  ##   2. [function]: Creates an infinite sequence that calls the function with integers 0, 1, 2...
  ##   3. [number, function]: Creates a finite sequence calling the function with integers from 0 to number-1
  ##   4. [vector]: Creates a finite sequence containing the vector's elements
  ## - invoker: Function used to invoke functions with arguments
  ##
  ## Raises:
  ## - TypeError: If the arguments have incorrect types (e.g., when expecting an integer or function)
  ## - InvalidArgumentError: If the number of arguments is incorrect or when trying to access beyond sequence bounds
  ##
  ## Returns:
  ## - A new Value object containing the generated sequence

  var resultSeq = Sequence(transformers: @[])

  case values.len
  of 1:
    # Case 1: Single value (infinite sequence of that value)
    if values[0].kind == vkVector:
      # Case 4: Vector (finite sequence of vector elements)
      let vec = values[0].vector
      var index = 0

      resultSeq.generator = Generator(
        atEnd: proc(): bool =
          index >= vec.size,
        next: proc(peek: bool = false): Value =
          if index >= vec.size:
            raise newSequenceExhaustedError(
              "Sequence exhausted: attempted to access beyond the end of sequence derived from vector of length " &
                $vec.size
            )
          result = vec[index]
          if not peek:
            inc index
        ,
      )
    elif values[0].kind == vkFunction or values[0].kind == vkNativeFunc:
      # Case 2: Single function (infinite sequence of function calls with increasing integers)
      var counter = 0 # Start from 0 instead of 1
      let value = values[0]

      resultSeq.generator = Generator(
        atEnd: proc(): bool =
          false, # Never ends
        next: proc(peek: bool = false): Value =
          result = invoker(value, [newValue(counter)])
          if not peek:
            inc counter
        ,
      )
    else:
      # Case 1: Single value (infinite sequence of that value)
      let value = values[0]
      resultSeq.generator = Generator(
        atEnd: proc(): bool =
          false, # Never ends
        next: proc(peek: bool = false): Value =
          value,
      )
  of 2:
    # Case 3: Number and function (finite sequence up to the given number)
    if values[0].kind != vkNumber or values[0].number.kind != nkInteger:
      raise newTypeError(
        "sequence expects an integer value for the sequence length, but got " & (
          if values[0].kind == vkNumber: "a " & $values[0].number.kind & " number"
          else: "a " & $values[0].kind
        )
      )

    if values[1].kind != vkFunction and values[1].kind != vkNativeFunc:
      raise newTypeError(
        "sequence expects a function as the second argument, but got a " &
          $values[1].kind
      )

    let limit = values[0].number.integer
    if limit <= 0:
      raise newInvalidArgumentError(
        "sequence expects a positive integer for the sequence length, but got " & $limit
      )

    var counter = 0
    let function = values[1]

    resultSeq.generator = Generator(
      atEnd: proc(): bool =
        counter >= limit,
      next: proc(peek: bool = false): Value =
        if counter >= limit:
          raise newSequenceExhaustedError(
            "Sequence exhausted: attempted to access beyond the end of finite sequence of length " &
              $limit
          )
        result = invoker(function, [newValue(counter)])
        if not peek:
          inc counter
      ,
    )
  else:
    raise newInvalidArgumentError(
      "sequence expects 1 or 2 arguments (value/function or length+function), but got " &
        $values.len & " arguments"
    )

  result = Value(kind: vkSeq, sequence: resultSeq)

proc help*(args: openArray[Value], invoker: FnInvoker): Value =
  ## Display help information for a function or value
  ##
  ## Parameters:
  ## - args: An array containing exactly 1 value:
  ##   - The function or identifier to get help for
  ##
  ## Returns:
  ## - A string containing the help information
  ##
  ## Raises:
  ## - InvalidArgumentError: If not exactly 1 argument is provided
  
  if args.len != 1:
    raise newInvalidArgumentError(
      "help expects exactly 1 argument, but got " & $args.len & " arguments"
    )
  
  let value = args[0]
  var helpText = ""
  
  case value.kind
  of vkNativeFunc:
    # Display help for native functions
    if value.nativeFn.metadata.description != "":
      helpText &= value.nativeFn.metadata.description & "\n\n"
    
    if value.nativeFn.signatures.len > 0:
      helpText &= "Signatures:\n"
      for sig in value.nativeFn.signatures:
        helpText &= "  |"
        for i, param in sig.params:
          if i > 0:
            helpText &= ", "
          if param.isVariadic:
            helpText &= "..."
          helpText &= param.name & ": " & $param.bmath_type
          if param.isOptional:
            helpText &= " (optional)"
          if param.description != "":
            helpText &= " - " & param.description
        helpText &= "| => " & $sig.returnType & "\n"
    
    if value.nativeFn.metadata.examples.len > 0:
      helpText &= "\nExamples:\n"
      for example in value.nativeFn.metadata.examples:
        helpText &= "  " & example & "\n"
  
  of vkFunction:
    # Display help for user-defined functions
    if value.function.metadata.description != "":
      helpText &= value.function.metadata.description & "\n\n"
    
    helpText &= "User-defined function\n"
    helpText &= "Signature: |"
    for i, param in value.function.signature.params:
      if i > 0:
        helpText &= ", "
      helpText &= param.name & ": " & $param.bmath_type
      if param.isOptional:
        helpText &= " (optional)"
      if param.description != "":
        helpText &= " - " & param.description
    helpText &= "| => " & $value.function.signature.returnType
  
  of vkNumber:
    helpText = "Number: " & $value
  
  of vkBool:
    helpText = "Boolean: " & $value
  
  of vkString:
    helpText = "String: " & $value
  
  of vkVector:
    helpText = "Vector of length " & $value.vector.size
  
  of vkSeq:
    helpText = "Sequence"
  
  of vkType:
    helpText = "Type: " & $value.bmath_type
  
  of vkError:
    helpText = "Error: " & value.error
  
  of vkModule:
    helpText = "Module"
  
  if helpText == "":
    helpText = "No help available for this value"
  
  return newValue(helpText)
