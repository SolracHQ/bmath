## Module for parser-specific error types

import ../../types/[errors, position]

type
  ParserError* = object of BMathError ## Base error for parsing issues
  
  UnexpectedTokenError* = object of ParserError
    ## Raised when an unexpected token is encountered
  
  MissingTokenError* = object of ParserError
    ## Raised when an expected token is missing
  
  InvalidExpressionError* = object of ParserError
    ## Raised when an expression is invalid

# Create a new UnexpectedTokenError with given position and message
template newUnexpectedTokenError*(
    message: string, pos: Position = Position()
): ref UnexpectedTokenError =
  (ref UnexpectedTokenError)(position: pos, msg: message)

# Create a new MissingTokenError with given position and message
template newMissingTokenError*(
    message: string, pos: Position = Position()
): ref MissingTokenError =
  (ref MissingTokenError)(position: pos, msg: message)

# Create a new InvalidExpressionError with given position and message
template newInvalidExpressionError*(
    message: string, pos: Position = Position()
): ref InvalidExpressionError =
  (ref InvalidExpressionError)(position: pos, msg: message)
