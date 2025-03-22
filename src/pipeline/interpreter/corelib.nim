## corelib.nim
## This module to define the operations for the Value type
## Basic operations like: + - * / % ^ and logical operations
## Trigonometrical functions: sin, cos, tan
## Exponential functions: exp, log
## Vector operations: dot product, length, map, filter, reduce
## Sequence operations: collect, skip, hasNext, next

import std/[math, sequtils]
import ../../types/[value, expression, number]
import ../../types/errors
import ./errors
import stdlib/arithmetic

proc dotProduct*(a, b: Value): Value =
  ## Compute the dot product of two vectors
  ## 
  ## Parameters:
  ## - a: first vector - must be a vector
  ## - b: second vector - must be a vector
  ##
  ## Raises:
  ## - BMathError: if the vectors are not of the same length
  ## - BMathError: if the values are not vectors
  if a.kind != vkVector or b.kind != vkVector:
    raise newTypeError("Dot product requires two vectors")
  return a.values * b.values

template `and`*(a, b: Value): Value =
  ## Compute the logical AND of two boolean values
  let left = a
  if left.kind != vkBool:
    raise newTypeError("Cannot perform logical AND on non-boolean values")
  if not left.bValue:
    newValue(false)
  else:
    let right = b
    if right.kind != vkBool:
      raise newTypeError("Cannot perform logical AND on non-boolean values")
    newValue(right.bValue)

template `or`*(a, b: Value): Value =
  ## Compute the logical OR of two boolean values
  let left = a
  if left.kind != vkBool:
    raise newTypeError("Cannot perform logical OR on non-boolean values")
  if left.bValue:
    newValue(true)
  else:
    let right = b
    if right.kind != vkBool:
      raise newTypeError("Cannot perform logical OR on non-boolean values")
    newValue(right.bValue)

proc sqrt*(a: Value): Value =
  ## Compute the square root of a value
  if a.kind != vkNumber:
    raise newTypeError("sqrt expects a number as argument")
  result = newValue(sqrt(a.nValue))

proc ceil*(a: Value): Value =
  ## Compute the ceiling of a value
  if a.kind != vkNumber:
    raise newTypeError("ceil expects a number as argument")
  newValue(ceil(a.nValue))

proc floor*(a: Value): Value =
  ## Compute the floor of a value
  if a.kind != vkNumber:
    raise newTypeError("floor expects a number as argument")
  newValue(floor(a.nValue))

proc round*(a: Value): Value =
  ## Round a value to the nearest integer
  if a.kind != vkNumber:
    raise newException(BMathError, "round expects a number as argument")

proc createVector*(values: openArray[Expression], evaluator: Evaluator): Value =
  # values should contain exactly 2 values (length and function or value to be repeated)
  if values.len != 2:
    raise newInvalidArgumentError("Vector should have exactly 2 values")
  let size = evaluator(values[0])
  if size.kind != vkNumber and size.nValue.kind != nkInt:
    raise newTypeError("Vector length should be an integer")
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
    raise newInvalidArgumentError("Seq should have exactly 2 values")
  let size = evaluator(values[0])
  if size.kind != vkNumber and size.nValue.kind != nkInt:
    raise newTypeError("Seq length should be an integer")
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
          raise newRuntimeError("End of seq"),
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
    raise newUnsupportedTypeError("Cannot convert value to expression")

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
      raise newRuntimeError("End of seq")
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
      raise newTypeError("map requires a vector or seq as the first argument")
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
      raise newTypeError("filter requires a vector or seq as the first argument")
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
      raise newTypeError("reduce requires a vector or seq as the first argument")
  result = evaluator(values[1])
  for item in iter(sequence):
    result = result + item

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
      raise newTypeError("sum requires a vector or seq as the argument")
  result = newValue(0)
  for item in iter(sequence):
    result = result + item

proc any*(vector: Value): Value =
  # Check if any element in the vector or seq is true
  let sequence =
    case vector.kind
    of vkVector:
      Value(kind: vkSeq, generator: vecToGenerator(vector))
    of vkSeq:
      vector
    else:
      raise newTypeError("any requires a vector or seq as the argument")
  result = newValue(false)
  for item in iter(sequence):
    if item.kind != vkBool:
      raise newTypeError("any requires a vector of booleans")
    if item.bValue:
      return newValue(true)

proc all*(vector: Value): Value =
  # Check if all elements in the vector are true
  if vector.kind != vkVector:
    raise newTypeError("all requires a vector as the argument")
  result = newValue(true)
  for val in vector.values:
    if val.kind != vkBool:
      raise newTypeError("all requires a vector of booleans")
    if not val.bValue:
      return newValue(false)

proc nth*(vector: Value, index: Value): Value =
  # Get the nth element of a vector
  if vector.kind != vkVector:
    raise newTypeError("nth requires a vector as the first argument")
  if index.kind != vkNumber and index.nValue.kind != nkInt:
    raise newTypeError("nth requires an integer as the second argument")
  if index.nValue.iValue < 0 or index.nValue.iValue >= vector.values.len:
    raise newInvalidArgumentError("Index out of bounds")
  result = vector.values[index.nValue.iValue]

proc first*(vector: Value): Value =
  # Get the first element of a vector
  if vector.kind != vkVector:
    raise newTypeError("first requires a vector as the argument")
  if vector.values.len == 0:
    raise newException(InvalidArgumentError, "Vector is empty")
  result = vector.values[0]

proc last*(vector: Value): Value =
  # Get the last element of a vector
  if vector.kind != vkVector:
    raise newTypeError("last requires a vector as the argument")
  if vector.values.len == 0:
    raise newException(InvalidArgumentError, "Vector is empty")
  result = vector.values[^1]

proc skip*(sequence: Value, n: Value): Value =
  # Skip the first n elements of a sequence and return the next element
  if sequence.kind != vkSeq:
    raise newTypeError("skip requires a seq as the argument")
  if n.kind != vkNumber and n.nValue.kind != nkInt:
    raise newTypeError("skip requires an integer as the second argument")
  if n.nValue.iValue < 0:
    raise newInvalidArgumentError("skip requires a non-negative integer as the second argument")
  for _ in 0 ..< n.nValue.iValue:
    discard sequence.generator.next()
  sequence.generator.next()

proc hasNext*(sequence: Value): Value =
  # Check if a sequence has a next element
  if sequence.kind != vkSeq:
    raise newTypeError("hasNext requires a seq as the argument")
  newValue(not sequence.generator.atEnd())

proc next*(sequence: Value): Value =
  # Get the next element of a sequence
  if sequence.kind != vkSeq:
    raise newTypeError("next requires a seq as the argument")
  sequence.generator.next()

proc len*(vector: Value): Value =
  # Get the length of a vector
  if vector.kind != vkVector:
    raise newTypeError("len requires a vector as the argument")
  result = newValue(vector.values.len)

proc cos*(a: Value): Value =
  # Compute the cosine of a value
  if a.kind != vkNumber:
    raise newTypeError("cos expects a number as argument")
  newValue(cos(a.nValue))

proc sin*(a: Value): Value =
  # Compute the sine of a value
  if a.kind != vkNumber:
    raise newTypeError("sin expects a number as argument")
  newValue(sin(a.nValue))

proc tan*(a: Value): Value =
  # Compute the tangent of a value
  if a.kind != vkNumber:
    raise newTypeError("tan expects a number as argument")
  newValue(tan(a.nValue))

proc log*(a: Value, base: Value): Value =
  # Compute the logarithm of a value
  if a.kind != vkNumber or base.kind != vkNumber:
    raise newTypeError("log expects two numbers as arguments")
  newValue(log(a.nValue, base.nValue))

proc exp*(a: Value): Value =
  # Compute the exponential of a value
  if a.kind != vkNumber:
    raise newTypeError("exp expects a number as argument")
  newValue(exp(a.nValue))

proc collect*(sequence: Value): Value =
  # Collect a sequence into a vector
  if sequence.kind != vkSeq:
    raise newTypeError("collect expects a seq as argument")
  result = newValue(newSeq[Value]())
  for item in iter(sequence):
    result.values.add(item)
