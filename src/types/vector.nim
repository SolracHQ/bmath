## vector.nim
##
## Provides a generic vector implementation that:
## - Allocates memory on the heap for efficient storage
## - Maintains fixed size once allocated
## - Provides convenient access operations and iteration

import ../types

proc newVector*[T](len: int): Vector[T] =
  ## Creates a new vector with the specified length.
  ##
  ## Params:
  ##   len: int - the length of the vector to create.
  ## Returns: Vector[T] - a newly allocated vector of the specified length.
  result = new(Vector[T])
  result.len = len
  if len <= 0:
    result.p = nil
  else:
    result.p = cast[ptr UncheckedArray[T]](create(T, len))

proc size*[T](v: Vector[T]): int {.inline.} =
  ## Returns the size/length of the vector.
  ##
  ## Params:
  ##   v: Vector[T] - the vector to query.
  ## Returns: int - the number of elements in the vector.
  result = v.len

proc `[]`*[T](v: Vector[T], i: int): T {.inline.} =
  ## Retrieves the element at the specified index.
  ##
  ## Params:
  ##   v: Vector[T] - the vector to access.
  ##   i: int - the index of the element to retrieve.
  ## Returns: T - the element at the specified index.
  ## Raises:
  ##   IndexDefect - in debug mode, if index is out of bounds.
  when defined(debug):
    # this is incredibly dangerous, but since index is checked at runtime by the bmath interpreter
    # we can leave it unchecked unless we are in debug mode
    if i < 0 or i >= v.len:
      raise newException(IndexDefect, "Index out of bounds")
  result = v.p[i]

proc `[]=`*[T](v: Vector[T], i: int, value: T) {.inline.} =
  ## Sets the element at the specified index.
  ##
  ## Params:
  ##   v: Vector[T] - the vector to modify.
  ##   i: int - the index at which to set the value.
  ##   value: T - the value to set.
  ## Raises:
  ##   IndexDefect - if index is out of bounds.
  when defined(debug):
    # this is incredibly dangerous, but since index is checked at runtime by the bmath interpreter
    # we can leave it unchecked unless we are in debug mode
    if i < 0 or i >= v.len:
      raise newException(IndexDefect, "Index out of bounds")
  v.p[i] = value

iterator items*[T](v: Vector[T]): T {.inline.} =
  ## Provides an iterator over the elements of the vector.
  ##
  ## Params:
  ##   v: Vector[T] - the vector to iterate over.
  ## Yields: T - each element in the vector.
  for i in 0 ..< v.len:
    yield v.p[i]

iterator pairs*[T](v: Vector[T]): (int, T) {.inline.} =
  ## Provides an iterator over the index-element pairs of the vector.
  ##
  ## Params:
  ##   v: Vector[T] - the vector to iterate over.
  ## Yields: (int, T) - each index and its corresponding element in the vector.
  for i in 0 ..< v.len:
    yield (i, v.p[i])

proc map*[T, U](v: Vector[T], f: proc(t: T): U): Vector[U] {.inline.} =
  ## Applies a function to each element of the vector and returns a new vector.
  ##
  ## Params:
  ##   v: Vector[T] - the vector to map.
  ##   f: proc (T): U - the function to apply to each element.
  ## Returns: Vector[U] - a new vector containing the results of applying f to each element.
  result = newVector[U](v.len)
  for i in 0 ..< v.len:
    result.p[i] = f(v.p[i])

proc toSeq*[T](v: Vector[T]): seq[T] =
  ## Converts the vector to a sequence.
  ##
  ## Params:
  ##   v: Vector[T] - the vector to convert.
  ## Returns: seq[T] - a sequence containing all elements of the vector.
  result = @[]
  for i in 0 ..< v.len:
    result.add(v.p[i])

proc fromSeq*[T](s: seq[T]): Vector[T] =
  ## Creates a vector from a sequence.
  ##
  ## Params:
  ##   s: seq[T] - the sequence to convert.
  ## Returns: Vector[T] - a new vector containing all elements of the sequence.
  result = newVector[T](s.len)
  for i in 0 ..< s.len:
    result.p[i] = s[i]
