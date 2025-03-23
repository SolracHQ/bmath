## itertools.nim

import ../../../types/[value]
import ../errors
import sequence, arithmetic

proc map*(values: openArray[Value], invoker: FnInvoker): Value =
  ## Map a function over a vector or sequence
  ##
  ## Parameters:
  ## - values: An array containing exactly 2 values:
  ##   1. A vector or sequence to map over
  ##   2. A function to apply to each element
  ##
  ## Raises:
  ## - InvalidArgumentError: If not exactly 2 values are provided
  ## - TypeError: If the first argument is not a vector or sequence
  ##
  ## Returns:
  ## - A new Value object containing the mapped sequence

  # Check if we have exactly 2 arguments (vector/sequence and function)
  if values.len != 2:
    raise newInvalidArgumentError(
      "map expects exactly 2 arguments (vector/sequence and function), but got " &
        $values.len
    )
  # Evaluate the first argument to get the vector/sequence
  let value = values[0]

  case value.kind
  of vkVector:
    # Apply the function to each element of the vector
    result = Value(kind: vkVector)
    result.vector = newSeqOfCap[Value](value.vector.len)
    for i in 0 ..< value.vector.len:
      result.vector.add(invoker(values[1], [value.vector[i]]))
  of vkSeq:
    # Apply the function to each element of the sequence
    result = value
    let fun = values[1]
    result.sequence.transformers.add(
      Transformer(
        kind: tkMap,
        fun: proc(x: Value): Value =
          invoker(fun, [x]),
      )
    )
  else:
    raise newTypeError(
      "map requires a vector or sequence as the first argument, but got a " & $value.kind
    )

proc filter*(values: openArray[Value], invoker: FnInvoker): Value =
  ## Filter a vector or sequence using a predicate function
  ##
  ## Parameters:
  ## - values: An array containing exactly 2 values:
  ##   1. A vector or sequence to filter
  ##   2. A predicate function that returns true for elements to keep
  ##
  ## Raises:
  ## - InvalidArgumentError: If not exactly 2 values are provided
  ## - TypeError: If the first argument is not a vector or sequence
  ##
  ## Returns:
  ## - A new Value object containing the filtered elements

  # Check if we have exactly 2 arguments (vector/sequence and predicate function)
  if values.len != 2:
    raise newInvalidArgumentError(
      "filter expects exactly 2 arguments (vector/sequence and predicate function), but got " &
        $values.len
    )

  # Evaluate the first argument to get the vector/sequence
  let value = values[0]

  case value.kind
  of vkVector:
    # Apply the predicate to each element and keep those that return true
    result = Value(kind: vkVector)
    result.vector = newSeq[Value]()
    for i in 0 ..< value.vector.len:
      let predResult = invoker(values[1], [value.vector[i]])
      if predResult.kind == vkBool and predResult.boolean:
        result.vector.add(value.vector[i])
  of vkSeq:
    # Add a filter transformer to the sequence
    result = value
    let fun = values[1]
    result.sequence.transformers.add(
      Transformer(
        kind: tkFilter,
        fun: proc(x: Value): Value =
          invoker(fun, [x]),
      )
    )
  else:
    raise newTypeError(
      "filter requires a vector or sequence as the first argument, but got a " &
        $value.kind
    )

proc reduce*(values: openArray[Value], invoker: FnInvoker): Value =
  ## Reduces a vector or sequence by applying a binary function
  ##
  ## Parameters:
  ## - values: An array containing exactly 3 values:
  ##   1. A vector or sequence to reduce
  ##   2. An initial accumulator value
  ##   3. A binary function that takes accumulator and element
  ##
  ## Raises:
  ## - InvalidArgumentError: If not exactly 3 values are provided
  ## - TypeError: If the first argument is not a vector or sequence
  ##
  ## Returns:
  ## - A single Value representing the reduced result

  # Check if we have exactly 3 arguments (vector/sequence, initial value, and function)
  if values.len != 3:
    raise newInvalidArgumentError(
      "reduce expects exactly 3 arguments (vector/sequence, initial value, and function), but got " &
        $values.len
    )

  # Evaluate the first argument to get the vector/sequence
  let value = values[0]
  result = values[1] # Initial value

  case value.kind
  of vkVector:
    # Apply the reduction function to each element
    for i in 0 ..< value.vector.len:
      result = invoker(values[2], [result, value.vector[i]])
  of vkSeq:
    # Materialize the sequence and then reduce
    for v in value.iter():
      result = invoker(values[2], [result, v])
  else:
    raise newTypeError(
      "reduce requires a vector or sequence as the first argument, but got a " &
        $value.kind
    )

proc sum*(a: Value): Value {.inline.} =
  ## Computes the total sum of all elements in a vector or sequence
  ##
  ## Parameters:
  ## - a: vector or sequence of numeric values
  ##
  ## Returns:
  ## - A numeric Value representing the sum of all elements
  ##
  ## Raises:
  ## - TypeError: if argument is not a vector or sequence
  ## - TypeError: if any element is not a number

  case a.kind
  of vkVector:
    result = newValue(0)
    for val in a.vector:
      if val.kind != vkNumber:
        raise newTypeError("sum requires numeric values, but found " & $val.kind)
      result += val
  of vkSeq:
    result = newValue(0)
    for v in a.iter():
      if v.kind != vkNumber:
        raise newTypeError("sum requires numeric values, but found " & $v.kind)
      result += v
  else:
    raise newTypeError(
      "sum requires a vector or sequence as argument, but got a " & $a.kind
    )

proc any*(a: Value): Value {.inline.} =
  ## Returns true if at least one element in a vector or sequence of boolean values is true
  ##
  ## Parameters:
  ## - a: vector or sequence of boolean values
  ##
  ## Returns:
  ## - A boolean Value (true if any element is true, false otherwise)
  ##
  ## Raises:
  ## - TypeError: if argument is not a vector or sequence
  ## - TypeError: if any element is not a boolean

  case a.kind
  of vkVector:
    result = Value(kind: vkBool, boolean: false)
    for val in a.vector:
      if val.kind != vkBool:
        raise newTypeError("any requires boolean values, but found " & $val.kind)
      if val.boolean:
        result.boolean = true
        break
  of vkSeq:
    result = Value(kind: vkBool, boolean: false)
    for v in a.iter():
      if v.kind != vkBool:
        raise newTypeError("any requires boolean values, but found " & $v.kind)
      if v.boolean:
        result.boolean = true
        break
  else:
    raise newTypeError(
      "any requires a vector or sequence as argument, but got a " & $a.kind
    )

proc all*(a: Value): Value {.inline.} =
  ## Returns true only if every element in a vector or sequence of boolean values is true
  ##
  ## Parameters:
  ## - a: vector or sequence of boolean values
  ##
  ## Returns:
  ## - A boolean Value (true if all elements are true, false otherwise)
  ##
  ## Raises:
  ## - TypeError: if argument is not a vector or sequence
  ## - TypeError: if any element is not a boolean

  case a.kind
  of vkVector:
    result = Value(kind: vkBool, boolean: true)
    for val in a.vector:
      if val.kind != vkBool:
        raise newTypeError("all requires boolean values, but found " & $val.kind)
      if not val.boolean:
        result.boolean = false
        break
  of vkSeq:
    result = Value(kind: vkBool, boolean: true)
    for v in a.iter():
      if v.kind != vkBool:
        raise newTypeError("all requires boolean values, but found " & $v.kind)
      if not v.boolean:
        result.boolean = false
        break
  else:
    raise newTypeError(
      "all requires a vector or sequence as argument, but got a " & $a.kind
    )
