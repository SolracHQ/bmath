## Module for interpreter-specific error types

import ../../types/[errors, position]

type
  RuntimeError* = object of BMathError ## Raised when runtime errors occur

  ArithmeticError* = object of RuntimeError ## Raised for arithmetic errors

  DivideByZeroError* = object of ArithmeticError ## Raised for division by zero

  TypeError* = object of RuntimeError ## Raised for type errors 

  UnsupportedTypeError* = object of TypeError ## Raised for unsupported types

  InvalidArgumentError* = object of TypeError ## Raised for invalid arguments

  UnknownIdentifierError* = object of RuntimeError ## Raised for unknown identifiers

  EnvironmentError* = object of RuntimeError ## Raised for environment-related errors

  UndefinedVariableError* = object of EnvironmentError
    ## Raised when a variable is not defined

  ReservedNameError* = object of EnvironmentError
    ## Raised when attempting to modify a reserved name

template newRuntimeError*(
    message: string, pos: Position = Position()
): ref RuntimeError =
  ## Creates a new RuntimeError with given position and message
  (ref RuntimeError)(position: pos, msg: message)

template newArithmeticError*(
    message: string, pos: Position = Position()
): ref ArithmeticError =
  ## Creates a new ArithmeticError with given position and message
  (ref ArithmeticError)(position: pos, msg: message)

template newDivideByZeroError*(
    message: string = "Division by zero", pos: Position = Position()
): ref DivideByZeroError =
  ## Creates a new DivideByZeroError with given position and message
  ## Default message: "Division by zero"
  (ref DivideByZeroError)(position: pos, msg: message)

template newTypeError*(message: string, pos: Position = Position()): ref TypeError =
  ## Creates a new TypeError with given position and message
  (ref TypeError)(position: pos, msg: message)

template newUnsupportedTypeError*(
    message: string, pos: Position = Position()
): ref UnsupportedTypeError =
  ## Creates a new UnsupportedTypeError with given position and message
  (ref UnsupportedTypeError)(position: pos, msg: message)

template newInvalidArgumentError*(
    message: string, pos: Position = Position()
): ref InvalidArgumentError =
  ## Creates a new InvalidArgumentError with given position and message
  (ref InvalidArgumentError)(position: pos, msg: message)

template newUnknownIdentifierError*(
    message: string, pos: Position = Position()
): ref UnknownIdentifierError =
  ## Creates a new UnknownIdentifierError with given position and message
  (ref UnknownIdentifierError)(position: pos, msg: message)

template newEnvironmentError*(
    message: string, pos: Position = Position()
): ref EnvironmentError =
  ## Creates a new EnvironmentError with given position and message
  (ref EnvironmentError)(position: pos, msg: message)

template newUndefinedVariableError*(
    name: string, pos: Position = Position()
): ref UndefinedVariableError =
  ## Creates a new UndefinedVariableError for an undefined variable
  (ref UndefinedVariableError)(
    position: pos, msg: "Variable '" & name & "' is not defined"
  )

template newReservedNameError*(
    name: string, pos: Position = Position()
): ref ReservedNameError =
  ## Creates a new ReservedNameError for attempts to modify reserved names
  (ref ReservedNameError)(
    position: pos, msg: "Cannot overwrite the reserved name '" & name & "'"
  )

# Templates with specific error names for common cases
template newZeroDivisionError*(pos: Position = Position()): ref DivideByZeroError =
  ## Shorthand for division by zero error with default message
  newDivideByZeroError("Division by zero is not allowed", pos)

template newVectorLengthMismatchError*(
    expected, actual: int, pos: Position = Position()
): ref InvalidArgumentError =
  ## Creates an error for vector length mismatches
  newInvalidArgumentError(
    "Vector length mismatch: expected " & $expected & ", got " & $actual, pos
  )

template newInvalidOperationError*(
    op: string, lhs, rhs: string, pos: Position = Position()
): ref TypeError =
  ## Creates an error for invalid operations between types
  newTypeError("Invalid types for " & op & " operation: " & lhs & " and " & rhs, pos)
