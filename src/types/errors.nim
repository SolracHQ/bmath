import position

type
  BMathError* = object of CatchableError
    ## Error type with contextual information for parser/runtime errors.
    position*: Position ## Source location where error occurred

# Generic template with optional position
template newBMathError*(message: string, pos: Position = Position()): ref BMathError =
  ## Creates a new BMathError with given position and message
  (ref BMathError)(position: pos, msg: message)
