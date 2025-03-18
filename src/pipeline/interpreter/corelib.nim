## corelib.nim
## module to define the operations for the Value type

import std/[math, sequtils]
import fusion/matching
import ../../types/[value, errors, expression, number]

proc `+`*(a, b: Value): Value =
  ## Add two values together
  ## Promotion rules:
  ## - If both values are integers, the result is an integer
  ## - If one of the values is a float, the result is a float
  ## Raise a `BMathError` if the values are not numbers
  case (a.kind, b.kind)
  of (vkNumber, vkNumber):
    return newValue(a.nValue + b.nValue)
  of (vkVector, vkVector):
    if a.values.len != b.values.len:
      raise
        newException(BMathError, "Vector addition requires vectors of the same length")
    var values: seq[Value] = newSeqOfCap[Value](a.values.len)
    for i in 0 ..< a.values.len:
      values.add(a.values[i] + b.values[i])
    return newValue(values)
  of (@a, @b):
    raise newException(
      BMathError, "'+' operands are not numbers they are: " & $a & " and " & $b
    )

proc `+=`*(a: var Value, b: Value) =
  ## Add a value to another value in place
  a = a + b

proc `-`*(a, b: Value): Value =
  ## Subtract two values using newValue
  case (a.kind, b.kind)
  of (vkNumber, vkNumber):
    result = newValue(a.nValue - b.nValue)
  of (vkVector, vkVector):
    if a.values.len != b.values.len:
      raise newException(
        BMathError, "Vector subtraction requires vectors of the same length"
      )
    var values: seq[Value] = newSeqOfCap[Value](a.values.len)
    for i in 0 ..< a.values.len:
      values.add(a.values[i] - b.values[i])
    result = newValue(values)
  of (_, _):
    raise newException(BMathError, "'-' operands are not numbers")

proc `-`*(a: Value): Value =
  ## Negate a value
  case a.kind
  of vkNumber:
    return newValue(-a.nValue)
  of vkVector:
    raise newException(BMathError, "Cannot negate a vector using '-' consider use map")
  of vkNativeFunc, vkFunction:
    raise newException(BMathError, "Cannot negate a function")
  of vkBool:
    raise newException(
      BMathError, "Cannot negate a boolean using '-' for not operation use '!'"
    )
  of vkSeq:
    raise
      newException(BMathError, "Cannot negate a sequence using '-' consider use map")

proc dotProduct*(a, b: Value): Value

proc `*`*(a, b: Value): Value =
  ## Multiply two values
  ## Promotion rules:
  ## - If both values are integers, the result is an integer
  ## - If one of the values is a float, the result is a float
  ## - If one of the values is a vector and the other is a number, the result is the scalar product
  ## Raise a `BMathError` if the values are not numbers
  case (a.kind, b.kind)
  of (vkNumber, vkNumber):
    result = newValue(a.nValue * b.nValue)
  of (vkVector, vkVector):
    result = dotProduct(a, b)
  of (vkVector, vkNumber):
    var values: seq[Value] = newSeqOfCap[Value](a.values.len)
    for i in 0 ..< a.values.len:
      values.add(a.values[i] * b)
    result = newValue(values)
  of (vkNumber, vkVector):
    var values: seq[Value] = newSeqOfCap[Value](b.values.len)
    for i in 0 ..< b.values.len:
      values.add(a * b.values[i])
    result = newValue(values)
  of (@a, @b):
    raise newException(
      BMathError, "'*' operands are not numbers they are: " & $a & " and " & $b
    )

proc `*=`*(a: var Value, b: Value) =
  ## Multiply a value by another value in place
  a = a * b

proc dotProduct*(a, b: Value): Value =
  ## Compute the dot product of two vectors
  if a.kind != vkVector or b.kind != vkVector:
    raise newException(BMathError, "Dot product requires two vectors")
  if a.values.len != b.values.len:
    raise newException(BMathError, "Vectors must have the same length")
  result = newValue(0)
  for i in 0 ..< a.values.len:
    result += a.values[i] * b.values[i]

proc `/`*(a, b: Value): Value =
  ## Divide two values
  ## The division is always a float
  if a.kind != vkNumber or b.kind != vkNumber:
    raise newException(BMathError, "'/' operands are not numbers")
  const ZERO = newNumber(0)
  if b.nValue == ZERO:
    raise newException(BMathError, "Division by zero")
  newValue(a.nValue / b.nValue)

template `!=`*(a, b: Value): Value =
  ## Compare two values for inequality
  not (a == b)

proc `not`*(a: Value): Value =
  ## Negate a boolean value
  if a.kind != vkBool:
    raise newException(
      BMathError,
      "Cannot negate a non-boolean value, expected: bool but got: " & $a.kind,
    )
  result = newValue(not a.bValue)

proc `==`*(a, b: Value): Value =
  ## Compare two values for equality
  case (a.kind, b.kind)
  of (vkNumber, vkNumber):
    result = newValue(a.nValue == b.nValue)
  of (vkVector, vkVector):
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

proc `<`*(a, b: Value): Value =
  ## Compare two values for less than
  case (a.kind, b.kind)
  of (vkNumber, vkNumber):
    result = newValue(a.nValue < b.nValue)
  else:
    raise newException(BMathError, "'<' operands are not numbers")

proc `<=`*(a, b: Value): Value =
  ## Compare two values for less than or equal
  case (a.kind, b.kind)
  of (vkNumber, vkNumber):
    result = newValue(a.nValue <= b.nValue)
  else:
    raise newException(BMathError, "'<=' operands are not numbers")

proc `>`*(a, b: Value): Value =
  ## Compare two values for greater than
  case (a.kind, b.kind)
  of (vkNumber, vkNumber):
    result = newValue(a.nValue > b.nValue)
  else:
    raise newException(BMathError, "'>' operands are not numbers")

proc `>=`*(a, b: Value): Value =
  ## Compare two values for greater than or equal
  case (a.kind, b.kind)
  of (vkNumber, vkNumber):
    result = newValue(a.nValue >= b.nValue)
  else:
    raise newException(BMathError, "'>=' operands are not numbers")

template `and`*(a, b: Value): Value =
  ## Compute the logical AND of two boolean values
  let left = a
  if left.kind != vkBool:
    raise newException(BMathError, "Cannot perform logical AND on non-boolean values")
  if not left.bValue:
    newValue(false)
  else:
    let right = b
    if right.kind != vkBool:
      raise newException(BMathError, "Cannot perform logical AND on non-boolean values")
    newValue(right.bValue)

template `or`*(a, b: Value): Value =
  ## Compute the logical OR of two boolean values
  let left = a
  if left.kind != vkBool:
    raise newException(BMathError, "Cannot perform logical OR on non-boolean values")
  if left.bValue:
    newValue(true)
  else:
    let right = b
    if right.kind != vkBool:
      raise newException(BMathError, "Cannot perform logical OR on non-boolean values")
    newValue(right.bValue)

proc `^`*(a, b: Value): Value =
  ## Raise a value to the power of another value
  ## If both values are integers, the result is an integer
  ## Otherwise, the result is a float
  if a.kind != vkNumber or b.kind != vkNumber:
    raise newException(BMathError, "'^' operands are not numbers")
  return newValue(a.nValue ^ b.nValue)

proc sqrt*(a: Value): Value =
  ## Compute the square root of a value
  if a.kind != vkNumber:
    raise newException(BMathError, "sqrt expects a number as argument")
  result = newValue(sqrt(a.nValue))

proc ceil*(a: Value): Value =
  ## Compute the ceiling of a value
  if a.kind != vkNumber:
    raise newException(BMathError, "ceil expects a number as argument")
  newValue(ceil(a.nValue))

proc floor*(a: Value): Value =
  ## Compute the floor of a value
  if a.kind != vkNumber:
    raise newException(BMathError, "floor expects a number as argument")
  newValue(floor(a.nValue))

proc round*(a: Value): Value =
  ## Round a value to the nearest integer
  if a.kind != vkNumber:
    raise newException(BMathError, "round expects a number as argument")

proc `%`*(a, b: Value): Value =
  ## Compute the remainder of the division of two values
  ## If values ar3e floats will be rounded to integers
  ## If the divisor is zero, a `BMathError` is raised
  ## The remainder is always an integer
  if a.kind != vkNumber or b.kind != vkNumber:
    raise newException(BMathError, "'%' operands are not numbers")
  const ZERO = newNumber(0)
  if b.nValue == ZERO:
    raise newException(BMathError, "Division by zero")
  newValue(a.nValue % b.nValue)

proc createVector*(values: openArray[Expression], evaluator: Evaluator): Value =
  # values should contain exactly 2 values (length and function or value to be repeated)
  if values.len != 2:
    raise newException(BMathError, "Vector should have exactly 2 values")
  let size = evaluator(values[0])
  if size.kind != vkNumber and size.nValue.kind != nkInt:
    raise newException(BMathError, "Vector length should be an integer")
  var elements = newSeqOfCap[Value](size.nValue.iValue)
  for i in 0 ..< size.nValue.iValue:
    let funcInvoke = Expression(
      kind: ekFuncInvoke,
      fun: values[1],
      arguments: @[newNumberExpr(values[1].position, newNumber(i))],
    )
    elements.add(evaluator(funcInvoke))
  result = newValue(elements)

proc createSeq*(values: openArray[Expression], evaluator: Evaluator): Value =
  # values should contain exactly 2 values (length and function to be called)
  if values.len != 2:
    raise newException(BMathError, "Seq should have exactly 2 values")
  let size = evaluator(values[0])
  if size.kind != vkNumber and size.nValue.kind != nkInt:
    raise newException(BMathError, "Seq length should be an integer")
  var i = 0
  let fun = values[1]
  result = Value(
    kind: vkSeq,
    generator: Generator(
      next: proc(peek: bool): Value =
        if i < size.nValue.iValue:
          let value = evaluator(
            Expression(
              kind: ekFuncInvoke,
              fun: fun,
              arguments: @[Expression(kind: ekNumber, nValue: newNumber(i))],
            )
          )
          if not peek:
            i.inc
          return value
        else:
          raise newException(BMathError, "End of seq"),
      atEnd: proc(): bool =
        i >= size.nValue.iValue,
    ),
  )

iterator iter(sequence: Value): Value =
  # Iterate over a sequence
  while not sequence.generator.atEnd():
    var next = sequence.generator.next()
    block transformations:
      for transformer in sequence.transformers:
        if transformer.kind == tkMap:
          next = transformer.fun(next)
        elif transformer.kind == tkFilter:
          let condition = transformer.fun(next)
          if condition.kind != vkBool:
            raise newException(BMathError, "Filter function must return a boolean")
          if not condition.bValue:
            break transformations
      yield next

proc valueToExpression*(value: Value): Expression =
  # Convert a value to an expression
  case value.kind
  of vkNumber:
    result = Expression(kind: ekNumber, nValue: value.nValue)
  of vkBool:
    if value.bValue:
      result = Expression(kind: ekTrue)
    else:
      result = Expression(kind: ekFalse)
  of vkVector:
    result =
      Expression(kind: ekVector, values: value.values.mapIt(valueToExpression(it)))
  else:
    raise newException(BMathError, "Cannot convert value to expression")

proc vecToGenerator*(vector: Value): Generator =
  # Convert a vector to a generator
  var i = 0
  result = Generator()
  result.next = proc(peek: bool): Value =
    if i < vector.values.len:
      let value = vector.values[i]
      if not peek:
        i.inc
      return value
    else:
      raise newException(BMathError, "End of seq")
  result.atEnd = proc(): bool =
    i >= vector.values.len

proc map*(values: openArray[Expression], evaluator: Evaluator): Value =
  # Map a function over a vector or seq
  # always returns a seq
  let vec = evaluator(values[0])
  result =
    case vec.kind
    of vkVector:
      Value(kind: vkSeq, generator: vecToGenerator(vec))
    of vkSeq:
      vec
    else:
      raise
        newException(BMathError, "map requires a vector or seq as the first argument")
  let fun = values[1]
  result.transformers.add(
    Transformer(
      kind: tkMap,
      fun: proc(x: Value): Value =
        evaluator(
          Expression(kind: ekFuncInvoke, fun: fun, arguments: @[x.valueToExpression()])
        ),
    )
  )

proc filter*(values: openArray[Expression], evaluator: Evaluator): Value =
  # Filter a vector or seq using a predicate
  # always returns a seq
  let vec = evaluator(values[0])
  result =
    case vec.kind
    of vkVector:
      Value(kind: vkSeq, generator: vecToGenerator(vec))
    of vkSeq:
      vec
    else:
      raise newException(
        BMathError, "filter requires a vector or seq as the first argument"
      )
  let fun = values[1]
  result.transformers.add(
    Transformer(
      kind: tkFilter,
      fun: proc(x: Value): Value =
        evaluator(
          Expression(kind: ekFuncInvoke, fun: fun, arguments: @[x.valueToExpression()])
        ),
    )
  )

proc reduce*(values: openArray[Expression], evaluator: Evaluator): Value =
  ## Reduce a vector using a binary function, accumulates on the initial value
  ## In case the vector is empty the initial value is returned
  let value = evaluator(values[0])
  let sequence =
    case value.kind
    of vkVector:
      Value(kind: vkSeq, generator: vecToGenerator(value))
    of vkSeq:
      value
    else:
      raise newException(
        BMathError, "reduce requires a vector or seq as the first argument"
      )
  var acc = evaluator(values[1])
  for item in iter(sequence):
    acc += item
  result = acc

proc sum*(value: Value): Value =
  # Compute the sum of a vector or seq
  # If the vector is empty, the result is 0
  let sequence =
    case value.kind
    of vkVector:
      Value(kind: vkSeq, generator: vecToGenerator(value))
    of vkSeq:
      value
    else:
      raise newException(BMathError, "sum requires a vector or seq as the argument")
  result = newValue(0)
  for item in iter(sequence):
    result += item

proc any*(vector: Value): Value =
  # Check if any element in the vector or seq is true
  let sequence =
    case vector.kind
    of vkVector:
      Value(kind: vkSeq, generator: vecToGenerator(vector))
    of vkSeq:
      vector
    else:
      raise newException(BMathError, "any requires a vector or seq as the argument")
  result = newValue(false)
  for item in iter(sequence):
    if item.kind != vkBool:
      raise newException(BMathError, "any requires a vector of booleans")
    if item.bValue:
      return newValue(true)

proc all*(vector: Value): Value =
  # Check if all elements in the vector are true
  if vector.kind != vkVector:
    raise newException(BMathError, "all requires a vector as the argument")
  result = newValue(true)
  for val in vector.values:
    if val.kind != vkBool:
      raise newException(BMathError, "all requires a vector of booleans")
    if not val.bValue:
      return newValue(false)

proc nth*(vector: Value, index: Value): Value =
  # Get the nth element of a vector
  if vector.kind != vkVector:
    raise newException(BMathError, "nth requires a vector as the first argument")
  if index.kind != vkNumber and index.nValue.kind != nkInt:
    raise newException(BMathError, "nth requires an integer as the second argument")
  if index.nValue.iValue < 0 or index.nValue.iValue >= vector.values.len:
    raise newException(BMathError, "Index out of bounds")
  result = vector.values[index.nValue.iValue]

proc first*(vector: Value): Value =
  # Get the first element of a vector
  if vector.kind != vkVector:
    raise newException(BMathError, "first requires a vector as the argument")
  if vector.values.len == 0:
    raise newException(BMathError, "Vector is empty")
  result = vector.values[0]

proc last*(vector: Value): Value =
  # Get the last element of a vector
  if vector.kind != vkVector:
    raise newException(BMathError, "last requires a vector as the argument")
  if vector.values.len == 0:
    raise newException(BMathError, "Vector is empty")
  result = vector.values[^1]

proc skip*(sequence: Value, n: Value): Value =
  # Skip the first n elements of a sequence and return the next element
  if sequence.kind != vkSeq:
    raise newException(BMathError, "skip requires a seq as the argument")
  if n.kind != vkNumber and n.nValue.kind != nkInt:
    raise newException(BMathError, "skip requires an integer as the second argument")
  if n.nValue.iValue < 0:
    raise newException(
      BMathError, "skip requires a non-negative integer as the second argument"
    )
  for _ in 0 ..< n.nValue.iValue:
    discard sequence.generator.next()
  sequence.generator.next()

proc hasNext*(sequence: Value): Value =
  # Check if a sequence has a next element
  if sequence.kind != vkSeq:
    raise newException(BMathError, "hasNext requires a seq as the argument")
  newValue(not sequence.generator.atEnd())

proc next*(sequence: Value): Value =
  # Get the next element of a sequence
  if sequence.kind != vkSeq:
    raise newException(BMathError, "next requires a seq as the argument")
  sequence.generator.next()

proc len*(vector: Value): Value =
  # Get the length of a vector
  if vector.kind != vkVector:
    raise newException(BMathError, "len requires a vector as the argument")
  result = newValue(vector.values.len)

proc cos*(a: Value): Value =
  # Compute the cosine of a value
  if a.kind != vkNumber:
    raise newException(BMathError, "cos expects a number as argument")
  newValue(cos(a.nValue))

proc sin*(a: Value): Value =
  # Compute the sine of a value
  if a.kind != vkNumber:
    raise newException(BMathError, "sin expects a number as argument")
  newValue(sin(a.nValue))

proc tan*(a: Value): Value =
  # Compute the tangent of a value
  if a.kind != vkNumber:
    raise newException(BMathError, "tan expects a number as argument")
  newValue(tan(a.nValue))

proc log*(a: Value, base: Value): Value =
  # Compute the logarithm of a value
  if a.kind != vkNumber or base.kind != vkNumber:
    raise newException(BMathError, "log expects two numbers as arguments")
  newValue(log(a.nValue, base.nValue))

proc exp*(a: Value): Value =
  # Compute the exponential of a value
  if a.kind != vkNumber:
    raise newException(BMathError, "exp expects a number as argument")
  newValue(exp(a.nValue))

proc collect*(sequence: Value): Value =
  # Collect a sequence into a vector
  if sequence.kind != vkSeq:
    raise newException(BMathError, "collect expects a seq as argument")
  result = newValue(newSeq[Value]())
  for item in iter(sequence):
    result.values.add(item)
