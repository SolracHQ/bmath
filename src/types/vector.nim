## vector.nim
##
## Provides a generic vector implementation that:
## - Allocates memory on the heap for efficient storage
## - Maintains fixed size once allocated
## - Provides convenient access operations and iteration

type
  VectorObj*[T] = object
    p: ptr UncheckedArray[T]
    len: int

  Vector*[T] = ref VectorObj[T]

proc `=destroy`*[T](v: VectorObj[T]) =
  ## Frees the memory allocated for the vector when it goes out of scope.
  ##
  ## Params:
  ##   v: VectorObj[T] - the vector object being destroyed.
  if v.p != nil:
    dealloc(v.p)

proc `=trace`*[T](v: var VectorObj[T], env: pointer) =
  ## Traces the vector's elements for garbage collection.
  ##
  ## Params:
  ##   v: var VectorObj[T] - the vector being traced.
  ##   env: pointer - environment pointer for the GC.
  if v.p != nil:
    for i in 0 ..< v.len:
      `=trace`(v.p[i], env)

proc `=wasMoved`*[T](v: var VectorObj[T]) {.error.}

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

proc toSeq*[T](v: Vector[T]): seq[T] =
  ## Converts the vector to a sequence.
  ##
  ## Params:
  ##   v: Vector[T] - the vector to convert.
  ## Returns: seq[T] - a sequence containing all elements of the vector.
  result = @[]
  for i in 0 ..< v.len:
    result.add(v.p[i])
