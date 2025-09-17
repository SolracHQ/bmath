## vector.nim
##
## Provides a generic vector implementation that:
## - Allocates memory on the heap for efficient storage
## - Maintains fixed size once allocated
## - Provides convenient access operations and iteration
##
## This module only exist because Nim seq has copy-on-write semantics

from core import Vector, Value
import errors
export Vector

proc newVector*(len: int): Vector =
  ## Creates a new vector with the specified length.
  ##
  ## Params:
  ##   len: int - the length of the vector to create.
  ## Returns: Vector - a newly allocated vector of the specified length.
  result = new(Vector)
  result.len = len
  if len <= 0:
    result.p = nil
  else:
    result.p = cast[ptr UncheckedArray[Value]](create(Value, len))

proc size*(v: Vector): int {.inline.} =
  ## Returns the size/length of the vector.
  ##
  ## Params:
  ##   v: Vector - the vector to query.
  ## Returns: int - the number of elements in the vector.
  result = v.len

proc `[]`*(v: Vector, i: int): Value {.inline.} =
  ## Retrieves the element at the specified index.
  ##
  ## Params:
  ##   v: Vector - the vector to access.
  ##   i: int - the index of the element to retrieve.
  ## Returns: T - the element at the specified index.
  ## Raises:
  ##   IndexDefect - in debug mode, if index is out of bounds.
  var i = i
  if i >= v.len:
    raise newInvalidArgumentError("Index out of bounds")
  if i < 0 and i + v.len < 0 and i + v.len >= v.len:
    raise newInvalidArgumentError("Index out of bounds ")
  if i < 0:
    i = v.len + i
  result = v.p[i]

proc `[]=`*(v: Vector, i: int, value: Value) {.inline.} =
  ## Sets the element at the specified index.
  ##
  ## Params:
  ##   v: Vector - the vector to modify.
  ##   i: int - the index at which to set the value.
  ##   value: T - the value to set.
  ## Raises:
  ##   IndexDefect - if index is out of bounds.
  var i = i
  if i >= v.len:
    raise newInvalidArgumentError("Index out of bounds")
  if i < 0 and i + v.len < 0 and i + v.len >= v.len:
    raise newInvalidArgumentError("Index out of bounds ")
  if i < 0:
    i = v.len + i
  v.p[i] = value

iterator items*(v: Vector): Value {.inline.} =
  ## Provides an iterator over the elements of the vector.
  ##
  ## Params:
  ##   v: Vector - the vector to iterate over.
  ## Yields: T - each element in the vector.
  for i in 0 ..< v.len:
    yield v.p[i]

iterator pairs*(v: Vector): (int, Value) {.inline.} =
  ## Provides an iterator over the index-element pairs of the vector.
  ##
  ## Params:
  ##   v: Vector - the vector to iterate over.
  ## Yields: (int, T) - each index and its corresponding element in the vector.
  for i in 0 ..< v.len:
    yield (i, v.p[i])

proc map*(v: Vector, f: proc(x: Value): Value): Vector {.inline.} =
  ## Applies a function to each element of the vector and returns a new vector with the results.
  ##
  ## Params:
  ##   v: Vector - the input vector.
  ##   f: proc(x: Value): Value - the function to apply to each element.
  ## Returns: Vector - a new vector containing the results of applying the function.
  result = newVector(v.len)
  for i in 0 ..< v.len:
    result.p[i] = f(v.p[i])

proc toSeq*(v: Vector): seq[Value] =
  ## Converts the vector to a sequence.
  ##
  ## Params:
  ##   v: Vector - the vector to convert.
  ## Returns: seq - a sequence containing all elements of the vector.
  result = @[]
  for i in 0 ..< v.len:
    result.add(v.p[i])

proc fromSeq*(s: seq): Vector =
  ## Creates a vector from a sequence.
  ##
  ## Params:
  ##   s: seq - the sequence to convert.
  ## Returns: Vector - a new vector containing all elements of the sequence.
  result = newVector(s.len)
  for i in 0 ..< s.len:
    result.p[i] = s[i]
