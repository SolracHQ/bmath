import position

type BMathError* = object of CatchableError
  ## Error type with contextual information for parser/runtime errors.
  stack*: seq[Position] ## Stack of positions for nested errors

# Generic template without position parameter
template newBMathError*(message: string): ref BMathError =
  ## Creates a new BMathError with given message
  (ref BMathError)(msg: message)
