## Centralized error types and creation templates for BMath

import ./types

# --- Base Error Types ---
type
  BMathError* = object of CatchableError
    stack*: seq[Position]

# --- Number Errors ---
type
  NumericError* = object of BMathError

  DivisionByZeroError* = object of NumericError
    ## Raised when attempting to divide by zero

  ComplexModulusError* = object of NumericError
    ## Raised when modulus operation is attempted with complex numbers

  ComplexComparisonError* = object of NumericError
    ## Raised when comparison is attempted with complex numbers

  ComplexCeilFloorRoundError* = object of NumericError
    ## Raised when ceil/floor/round is attempted with complex numbers

# --- Interpreter Errors ---
type
  RuntimeError* = object of BMathError
  ArithmeticError* = object of RuntimeError
  DivideByZeroError* = object of ArithmeticError
  TypeError* = object of RuntimeError
  UnsupportedTypeError* = object of TypeError
  InvalidArgumentError* = object of TypeError
  UnknownIdentifierError* = object of RuntimeError
  EnvironmentError* = object of RuntimeError
  UndefinedVariableError* = object of EnvironmentError
  ReservedNameError* = object of EnvironmentError
  SequenceExhaustedError* = object of InvalidArgumentError

# --- Lexer Errors ---
type
  LexerError* = object of BMathError
  IncompleteInputError* = object of LexerError
  UnexpectedCharacterError* = object of LexerError
  InvalidNumberFormatError* = object of LexerError
  InvalidEscapeSequenceError* = object of LexerError

# --- Parser Errors ---
type
  ParserError* = object of BMathError
  UnexpectedTokenError* = object of ParserError
  MissingTokenError* = object of ParserError
  InvalidExpressionError* = object of ParserError

# --- Error Creation Templates ---

# Generic template without position parameter
template newBMathError*(message: string): ref BMathError =
  (ref BMathError)(msg: message)

# Interpreter error templates
template newRuntimeError*(message: string): ref RuntimeError =
  (ref RuntimeError)(msg: message)

template newArithmeticError*(message: string): ref ArithmeticError =
  (ref ArithmeticError)(msg: message)

template newDivideByZeroError*(message: string = "Division by zero"): ref DivideByZeroError =
  (ref DivideByZeroError)(msg: message)

template newTypeError*(message: string): ref TypeError =
  (ref TypeError)(msg: message)

template newUnsupportedTypeError*(message: string): ref UnsupportedTypeError =
  (ref UnsupportedTypeError)(msg: message)

template newInvalidArgumentError*(message: string): ref InvalidArgumentError =
  (ref InvalidArgumentError)(msg: message)

template newUnknownIdentifierError*(message: string): ref UnknownIdentifierError =
  (ref UnknownIdentifierError)(msg: message)

template newEnvironmentError*(message: string): ref EnvironmentError =
  (ref EnvironmentError)(msg: message)

template newUndefinedVariableError*(name: string): ref UndefinedVariableError =
  (ref UndefinedVariableError)(msg: "Variable '" & name & "' is not defined")

template newReservedNameError*(name: string): ref ReservedNameError =
  (ref ReservedNameError)(msg: "Cannot overwrite the reserved name '" & name & "', for local shadowing use local keyword")

template newSequenceExhaustedError*(message: string = "Sequence has been exhausted"): ref SequenceExhaustedError =
  (ref SequenceExhaustedError)(msg: message)

template newZeroDivisionError*(): ref DivideByZeroError =
  newDivideByZeroError("Division by zero is not allowed")

template newVectorLengthMismatchError*(expected, actual: int): ref InvalidArgumentError =
  newInvalidArgumentError("Vector length mismatch: expected " & $expected & ", got " & $actual)

template newInvalidOperationError*(op: string, lhs, rhs: string): ref TypeError =
  newTypeError("Invalid types for " & op & " operation: '" & lhs & "' and '" & rhs & "'")

# Lexer error templates
template newIncompleteInputError*(message: string, pos: Position): ref IncompleteInputError =
  (ref IncompleteInputError)(msg: message, stack: @[pos])

template newUnexpectedCharacterError*(message: string, pos: Position): ref UnexpectedCharacterError =
  (ref UnexpectedCharacterError)(msg: message, stack: @[pos])

template newInvalidNumberFormatError*(message: string, pos: Position): ref InvalidNumberFormatError =
  (ref InvalidNumberFormatError)(msg: message, stack: @[pos])

template newInvalidEscapeSequenceError*(message: string, pos: Position): ref InvalidEscapeSequenceError =
  (ref InvalidEscapeSequenceError)(msg: message, stack: @[pos])

# Parser error templates
template newUnexpectedTokenError*(message: string, pos: Position): ref UnexpectedTokenError =
  (ref UnexpectedTokenError)(msg: message, stack: @[pos])

template newMissingTokenError*(message: string, pos: Position): ref MissingTokenError =
  (ref MissingTokenError)(msg: message, stack: @[pos])

template newInvalidExpressionError*(message: string, pos: Position): ref InvalidExpressionError =
  (ref InvalidExpressionError)(msg: message, stack: @[pos])
