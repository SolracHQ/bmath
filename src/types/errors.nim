import position

type
  BMathError* = object of CatchableError
    ## Error type with contextual information for parser/runtime errors.
    position*: Position ## Source location where error occurred

  IncompleteInputError* = object of BMathError ## Raised when input is incomplete

template newBMathError*(message: string, pos: Position): ref BMathError =
  ## Creates a new BMathError with given position and message
  (ref BMathError)(position: pos, msg: message)