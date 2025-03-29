## sequence.nim

import ../../../types/[value, number, vector]
import ../errors

proc sequence*(values: openArray[Value], invoker: FnInvoker): Value =
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

proc skip*(sequence: Value, n: Value): Value =
  ## Skip the first n elements of a sequence and return the result
  ## 
  ## Parameters:
  ## - sequence: The sequence to operate on
  ## - n: Number of elements to skip (must be a non-negative integer)
  ##
  ## Raises:
  ## - TypeError: If the sequence is not a sequence or n is not an integer
  ## - InvalidArgumentError: If n is negative
  ## - SequenceExhaustedError: If the sequence doesn't have enough elements
  ##
  ## Returns:
  ## - The sequence after skipping n elements
  if sequence.kind != vkSeq:
    raise newTypeError(
      "skip requires a sequence as the first argument, but got a " & $sequence.kind
    )
  if n.kind != vkNumber or n.number.kind != nkInteger:
    raise newTypeError(
      "skip requires an integer as the second argument, but got " &
        (if n.kind == vkNumber: "a " & $n.number.kind & " number"
        else: "a " & $n.kind)
    )
  if n.number.integer < 0:
    raise newInvalidArgumentError(
      "skip requires a non-negative integer as the second argument, but got " &
        $n.number.integer
    )

  for _ in 0 ..< n.number.integer:
    discard sequence.sequence.generator.next()
  result = sequence

proc take*(sequence: Value, n: Value): Value =
  ## Take only the first n elements of a sequence and return the result
  ## 
  ## Parameters:
  ## - sequence: The sequence to operate on
  ## - n: Number of elements to take (must be a non-negative integer)
  ##
  ## Raises:
  ## - TypeError: If the sequence is not a sequence or n is not an integer
  ## - InvalidArgumentError: If n is negative
  ##
  ## Returns:
  ## - A new sequence limited to at most n elements
  if sequence.kind != vkSeq:
    raise newTypeError(
      "take requires a sequence as the first argument, but got a " & $sequence.kind
    )
  if n.kind != vkNumber or n.number.kind != nkInteger:
    raise newTypeError(
      "take requires an integer as the second argument, but got " &
        (if n.kind == vkNumber: "a " & $n.number.kind & " number"
        else: "a " & $n.kind)
    )
  if n.number.integer < 0:
    raise newInvalidArgumentError(
      "take requires a non-negative integer as the second argument, but got " &
        $n.number.integer
    )

  result = sequence
  var taken = 0
  var limit = n.number.integer
  let originalAtEnd = result.sequence.generator.atEnd
  result.sequence.generator.atEnd = proc(): bool =
    taken >= limit or originalAtEnd()
  result.sequence.transformers.add(
    Transformer(
      kind: tkFilter,
      fun: proc(value: Value): Value =
        if taken < limit:
          taken += 1
          newValue(true)
        else:
          newValue(false),
    )
  )

proc hasNext*(sequence: Value): Value =
  ## Check if a sequence has a next element
  ##
  ## Parameters:
  ## - sequence: The sequence to check
  ##
  ## Raises:
  ## - TypeError: If the input is not a sequence
  ##
  ## Returns:
  ## - A boolean value indicating whether the sequence has a next element
  if sequence.kind != vkSeq:
    raise newTypeError(
      "hasNext requires a sequence as the argument, but got a " & $sequence.kind
    )
  newValue(not sequence.sequence.generator.atEnd())

proc next*(sequence: Value): Value =
  ## Get the next element of a sequence
  ##
  ## Parameters:
  ## - sequence: The sequence to get the next element from
  ##
  ## Raises:
  ## - TypeError: If the input is not a sequence
  ## - SequenceExhaustedError: If the sequence has been exhausted
  ##
  ## Returns:
  ## - The next value in the sequence
  if sequence.kind != vkSeq:
    raise newTypeError(
      "next requires a sequence as the argument, but got a " & $sequence.kind
    )

  if sequence.sequence.generator.atEnd():
    raise
      newSequenceExhaustedError("Cannot get next element: sequence has been exhausted")

  sequence.sequence.generator.next()

iterator items*(sequence: Sequence): Value =
  ## Iterate over a sequence, applying any transformers
  ##
  ## Parameters:
  ## - sequence: The sequence to iterate over
  ##
  ## Yields:
  ## - Each transformed value from the sequence
  while not sequence.generator.atEnd():
    var next = sequence.generator.next()
    block transformations:
      for transformer in sequence.transformers:
        if transformer.kind == tkMap:
          next = transformer.fun(next)
        elif transformer.kind == tkFilter:
          let condition = transformer.fun(next)
          if condition.kind != vkBool:
            raise newTypeError(
              "Filter function must return a boolean, but got a " & $condition.kind
            )
          if not condition.boolean:
            break transformations
      yield next

proc collect*(s: Value): Value =
  ## Collect a sequence into a vector
  ##
  ## Parameters:
  ## - sequence: The sequence to collect into a vector
  ##
  ## Raises:
  ## - TypeError: If the input is not a sequence
  ##
  ## Returns:
  ## - A vector containing all elements of the sequence
  if s.kind != vkSeq:
    raise newTypeError("collect expects a sequence as argument, but got a " & $s.kind)

  # First, collect all elements to determine the size
  var elements: seq[Value] = @[]
  for item in s.sequence:
    elements.add(item)

  # Create a vector of the right size and populate it
  result = Value(kind: vkVector)
  result.vector = newVector[Value](elements.len)

  # Fill the vector with collected elements
  for i in 0 ..< elements.len:
    result.vector[i] = elements[i]

proc zip*(seq1: Value, seq2: Value): Value =
  ## Create a sequence by pairing elements from two sequences
  ## 
  ## Parameters:
  ## - seq1: First sequence
  ## - seq2: Second sequence
  ##
  ## Raises:
  ## - TypeError: If either input is not a sequence
  ## - SequenceExhaustedError: When trying to access beyond the end of either sequence
  ##
  ## Returns:
  ## - A new sequence containing vectors of paired elements from input sequences,
  ##   with length equal to the length of the shorter input sequence

  # Type checking
  if seq1.kind != vkSeq:
    raise newTypeError(
      "zip requires a sequence as the first argument, but got a " & $seq1.kind
    )
  if seq2.kind != vkSeq:
    raise newTypeError(
      "zip requires a sequence as the second argument, but got a " & $seq2.kind
    )

  # Create the result sequence
  var resultSeq = Sequence(transformers: @[])
  let gen1 = seq1.sequence.generator
  let gen2 = seq2.sequence.generator

  resultSeq.generator = Generator(
    atEnd: proc(): bool =
      gen1.atEnd() or gen2.atEnd(),
    next: proc(peek: bool = false): Value =
      if gen1.atEnd() or gen2.atEnd():
        raise newSequenceExhaustedError(
          "Sequence exhausted: one of the input sequences has been exhausted"
        )

      # Get next elements from both sequences
      let val1 = gen1.next(peek)
      let val2 = gen2.next(peek)

      # Pair them in a vector
      result = Value(kind: vkVector)
      result.vector = newVector[Value](2)
      result.vector[0] = val1
      result.vector[1] = val2,
  )

  result = Value(kind: vkSeq, sequence: resultSeq)
