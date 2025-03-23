## vector.nim

import ../../../types/[value, number]
import arithmetic
import ../errors

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
    raise newInvalidArgumentError("vec expects exactly 2 arguments (length and function/value), but got " & $args.len & " arguments")
    
  # Evaluate the first argument to get the vector length
  let size = args[0]
  if size.kind != vkNumber or (size.kind == vkNumber and size.number.kind != nkInt):
    raise newTypeError("vec expects an integer value for the vector length, but got " & 
      (if size.kind == vkNumber: "a " & $size.number.kind & " number" else: "a " & $size.kind))
    
  # Initialize the result as a vector
  result = Value(kind: vkVector)
  result.vector = newSeqOfCap[Value](size.number.iValue)
  
  if args[1].kind == vkFunction or args[1].kind == vkNativeFunc:
    # If the second argument is a function, apply it to each index
    for i in 0 ..< size.number.iValue:
      result.vector.add(invoker(args[1], [newValue(i)]))
  else:
    # If the second argument is a value, repeat it for each index
    for i in 0 ..< size.number.iValue:
      result.vector.add(args[1])

proc dotProduct*(a, b: Value): Value =
  ## Compute the dot product of two vectors
  ## 
  ## Parameters:
  ## - a: first vector - must be a vector
  ## - b: second vector - must be a vector
  ##
  ## Raises:
  ## - TypeError: if either input is not a vector
  ## - VectorLengthMismatchError: if the vectors are not of the same length
  ## - ArithmeticError: for numeric calculation errors during the dot product
  if a.kind != vkVector or b.kind != vkVector:
    raise newTypeError("dot expects two vector arguments, but got " & 
      (if a.kind != vkVector: "a " & $a.kind & " as first argument" else: "a vector as first argument") & " and " &
      (if b.kind != vkVector: "a " & $b.kind & " as second argument" else: "a vector as second argument"))
  return a.vector * b.vector

proc nth*(vector: Value, index: Value): Value =
  ## Get the nth element of a vector
  ##
  ## Parameters:
  ## - vector: A vector value to extract an element from
  ## - index: An integer index to access the vector element
  ##
  ## Raises:
  ## - TypeError: If vector is not a vector or index is not an integer
  ## - InvalidArgumentError: If the index is out of bounds
  ##
  ## Returns:
  ## - The value at the specified index in the vector
  if vector.kind != vkVector:
    raise newTypeError("nth expects a vector as the first argument, but got a " & $vector.kind)
  if index.kind != vkNumber or (index.kind == vkNumber and index.number.kind != nkInt):
    raise newTypeError("nth expects an integer as the second argument, but got " & 
      (if index.kind == vkNumber: "a " & $index.number.kind & " number" else: "a " & $index.kind))
  if index.number.iValue < 0 or index.number.iValue >= vector.vector.len:
    raise newInvalidArgumentError("Index out of bounds for nth: index " & $index.number.iValue & 
      " is outside valid range [0, " & $(vector.vector.len-1) & "] for vector of length " & $vector.vector.len)
  result = vector.vector[index.number.iValue]

proc first*(vector: Value): Value =
  ## Get the first element of a vector
  ##
  ## Parameters:
  ## - vector: A vector value to extract the first element from
  ##
  ## Raises:
  ## - TypeError: If the input is not a vector
  ## - InvalidArgumentError: If the vector is empty
  ##
  ## Returns:
  ## - The first element of the vector
  if vector.kind != vkVector:
    raise newTypeError("first expects a vector argument, but got a " & $vector.kind)
  if vector.vector.len == 0:
    raise newInvalidArgumentError("Cannot get first element: vector is empty")
  result = vector.vector[0]

proc last*(vector: Value): Value =
  ## Get the last element of a vector
  ##
  ## Parameters:
  ## - vector: A vector value to extract the last element from
  ##
  ## Raises:
  ## - TypeError: If the input is not a vector
  ## - InvalidArgumentError: If the vector is empty
  ##
  ## Returns:
  ## - The last element of the vector
  if vector.kind != vkVector:
    raise newTypeError("last expects a vector argument, but got a " & $vector.kind)
  if vector.vector.len == 0:
    raise newInvalidArgumentError("Cannot get last element: vector is empty")
  result = vector.vector[^1]

proc len*(vector: Value): Value =
  ## Get the length of a vector
  ##
  ## Parameters:
  ## - vector: A vector value to get the length of
  ##
  ## Raises:
  ## - TypeError: If the input is not a vector
  ##
  ## Returns:
  ## - The number of elements in the vector as a numeric value
  if vector.kind != vkVector:
    raise newTypeError("len expects a vector argument, but got a " & $vector.kind)
  result = newValue(vector.vector.len)