## Module for parser-specific error types

import ../../types/[errors, position]

type
  ParserError* = object of BMathError ## Base error for parsing issues

  UnexpectedTokenError* = object of ParserError
    ## Raised when an unexpected token is encountered

  MissingTokenError* = object of ParserError ## Raised when an expected token is missing

  InvalidExpressionError* = object of ParserError ## Raised when an expression is invalid

# Create a new UnexpectedTokenError with given message and position in stack
template newUnexpectedTokenError*(message: string, pos: Position): ref UnexpectedTokenError =
  (ref UnexpectedTokenError)(msg: message, stack: @[pos])

# Create a new MissingTokenError with given message and position in stack
template newMissingTokenError*(message: string, pos: Position): ref MissingTokenError =
  (ref MissingTokenError)(msg: message, stack: @[pos])

# Create a new InvalidExpressionError with given message and position in stack
template newInvalidExpressionError*(message: string, pos: Position): ref InvalidExpressionError =
  (ref InvalidExpressionError)(msg: message, stack: @[pos])
