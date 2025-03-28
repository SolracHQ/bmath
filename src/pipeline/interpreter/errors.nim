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

  SequenceExhaustedError* = object of InvalidArgumentError
    ## Raised when attempting to access an exhausted sequence

template newRuntimeError*(message: string): ref RuntimeError =
  ## Creates a new RuntimeError with given message
  (ref RuntimeError)(msg: message)

template newArithmeticError*(message: string): ref ArithmeticError =
  ## Creates a new ArithmeticError with given message
  (ref ArithmeticError)(msg: message)

template newDivideByZeroError*(
    message: string = "Division by zero"
): ref DivideByZeroError =
  ## Creates a new DivideByZeroError with given message
  ## Default message: "Division by zero"
  (ref DivideByZeroError)(msg: message)

template newTypeError*(message: string): ref TypeError =
  ## Creates a new TypeError with given message
  (ref TypeError)(msg: message)

template newUnsupportedTypeError*(message: string): ref UnsupportedTypeError =
  ## Creates a new UnsupportedTypeError with given message
  (ref UnsupportedTypeError)(msg: message)

template newInvalidArgumentError*(message: string): ref InvalidArgumentError =
  ## Creates a new InvalidArgumentError with given message
  (ref InvalidArgumentError)(msg: message)

template newUnknownIdentifierError*(message: string): ref UnknownIdentifierError =
  ## Creates a new UnknownIdentifierError with given message
  (ref UnknownIdentifierError)(msg: message)

template newEnvironmentError*(message: string): ref EnvironmentError =
  ## Creates a new EnvironmentError with given message
  (ref EnvironmentError)(msg: message)

template newUndefinedVariableError*(name: string): ref UndefinedVariableError =
  ## Creates a new UndefinedVariableError for an undefined variable
  (ref UndefinedVariableError)(msg: "Variable '" & name & "' is not defined")

template newReservedNameError*(name: string): ref ReservedNameError =
  ## Creates a new ReservedNameError for attempts to modify reserved names
  (ref ReservedNameError)(
    msg:
      "Cannot overwrite the reserved name '" & name &
      "', for local shadowing use local keyword"
  )

template newSequenceExhaustedError*(
    message: string = "Sequence has been exhausted"
): ref SequenceExhaustedError =
  ## Creates a new SequenceExhaustedError with given message
  (ref SequenceExhaustedError)(msg: message)

# Templates with specific error names for common cases
template newZeroDivisionError*(): ref DivideByZeroError =
  ## Shorthand for division by zero error with default message
  newDivideByZeroError("Division by zero is not allowed")

template newVectorLengthMismatchError*(
    expected, actual: int
): ref InvalidArgumentError =
  ## Creates an error for vector length mismatches
  newInvalidArgumentError(
    "Vector length mismatch: expected " & $expected & ", got " & $actual
  )

template newInvalidOperationError*(op: string, lhs, rhs: string): ref TypeError =
  ## Creates an error for invalid operations between types
  newTypeError(
    "Invalid types for " & op & " operation: '" & lhs & "' and '" & rhs & "'"
  )
