## Module for lexer-specific error types

import ../../types/[errors, position]

type
  LexerError* = object of BMathError ## Base error for lexical analysis issues

  IncompleteInputError* = object of LexerError ## Raised when input is incomplete

  UnexpectedCharacterError* = object of LexerError
    ## Raised when an unexpected character is encountered

  InvalidNumberFormatError* = object of LexerError ## Raised when a number is malformed

# Create a new IncompleteInputError with given message and position in stack
template newIncompleteInputError*(message: string, pos: Position): ref IncompleteInputError =
  (ref IncompleteInputError)(msg: message, stack: @[pos])

# Create a new UnexpectedCharacterError with given message and position in stack
template newUnexpectedCharacterError*(message: string, pos: Position): ref UnexpectedCharacterError =
  (ref UnexpectedCharacterError)(msg: message, stack: @[pos])

# Create a new InvalidNumberFormatError with given message and position in stack
template newInvalidNumberFormatError*(message: string, pos: Position): ref InvalidNumberFormatError =
  (ref InvalidNumberFormatError)(msg: message, stack: @[pos])
