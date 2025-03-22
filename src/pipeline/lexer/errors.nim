## Module for lexer-specific error types

import ../../types/[errors, position]

type
  LexerError* = object of BMathError ## Base error for lexical analysis issues
  
  IncompleteInputError* = object of LexerError 
    ## Raised when input is incomplete

  UnexpectedCharacterError* = object of LexerError
    ## Raised when an unexpected character is encountered

  InvalidNumberFormatError* = object of LexerError
    ## Raised when a number is malformed

# Create a new IncompleteInputError with given position and message
template newIncompleteInputError*(
    message: string, pos: Position = Position()
): ref IncompleteInputError =
  (ref IncompleteInputError)(position: pos, msg: message)

# Create a new UnexpectedCharacterError with given position and message
template newUnexpectedCharacterError*(
    message: string, pos: Position = Position()
): ref UnexpectedCharacterError =
  (ref UnexpectedCharacterError)(position: pos, msg: message)

# Create a new InvalidNumberFormatError with given position and message
template newInvalidNumberFormatError*(
    message: string, pos: Position = Position()
): ref InvalidNumberFormatError =
  (ref InvalidNumberFormatError)(position: pos, msg: message)
