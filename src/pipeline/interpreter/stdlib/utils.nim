import macros

import ../../../types/number
import ../errors

macro captureNumericError*(procDef: untyped): untyped =
  ## This macro is used as a pragma on arithmetic functions.
  ## It wraps the function body in a try-except block to capture
  ## specific numeric errors and convert them to the corresponding RuntimeError.

  # Extract the body from the procedure definition
  var body = procDef.body

  # Create a new body with try-except
  let newBody = quote:
    try:
      `body`
    except DivisionByZeroError:
      raise newZeroDivisionError()
    except ComplexModulusError:
      raise newInvalidOperationError("modulus", "complex", "complex")
    except ComplexComparisonError:
      raise newInvalidOperationError("comparison", "complex", "complex")
    except ComplexCeilFloorRoundError as e:
      raise newUnsupportedTypeError(e.msg)
    except NumericError as e:
      # For other numeric errors, wrap in ArithmeticError
      raise newArithmeticError(e.msg)

  # Replace the body in the procedure definition
  procDef.body = newBody

  result = procDef
