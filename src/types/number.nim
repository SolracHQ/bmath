import std/math
import std/complex

import errors

type
  NumberKind* = enum
    nkInteger ## Integer number
    nkReal ## Floating-point number
    nkComplex ## Complex number

  Number* = object
    case kind*: NumberKind
    of nkInteger:
      integer*: int ## Integer value
    of nkReal:
      real*: float ## Floating-point value
    of nkComplex:
      complex*: Complex[float] ## Complex number value

  NumericError* = object of BMathError

  DivisionByZeroError* = object of NumericError
    ## Raised when attempting to divide by zero

  ComplexModulusError* = object of NumericError
    ## Raised when modulus operation is attempted with complex numbers

  ComplexComparisonError* = object of NumericError
    ## Raised when comparison is attempted with complex numbers

  ComplexCeilFloorRoundError* = object of NumericError
    ## Raised when ceil/floor/round is attempted with complex numbers

template newNumber*(value: typed): Number =
  ## Creates a new Number object based on the type of value
  when value is SomeInteger:
    Number(kind: nkInteger, integer: value.int)
  elif value is SomeFloat:
    Number(kind: nkReal, real: value.float)
  elif value is Complex[float]:
    if value.im == 0.0:
      Number(kind: nkReal, real: value.re)
    else:
      Number(kind: nkComplex, complex: value)
  else:
    {.error: "Unsupported type for Number".}

template newNumber*(re: SomeFloat, im: SomeFloat): Number =
  ## Creates a new Number object from real and imaginary parts
  Number(kind: nkComplex, complex: complex(re.float, im.float))

const ZERO* = newNumber(0)

proc isZero*(n: Number): bool {.inline.} =
  ## Checks if a Number object is zero
  case n.kind
  of nkInteger:
    return n.integer == 0
  of nkReal:
    return n.real == 0.0
  of nkComplex:
    return n.complex.re == 0.0 and n.complex.im == 0.0

template toComplex(n: Number): Complex[float] =
  case n.kind
  of nkInteger:
    complex(n.integer.float, 0.0)
  of nkReal:
    complex(n.real, 0.0)
  of nkComplex:
    n.complex

template toFloat(n: Number): float =
  case n.kind
  of nkInteger:
    n.integer.float
  of nkReal:
    n.real
  of nkComplex:
    raise (ref NumericError)(msg: "Cannot convert complex number to float")

proc `+`*(a, b: Number): Number {.inline.} =
  ## Adds two Number objects together
  ## Promotion rules:
  ## int -> float -> complex
  ## any operation with complex will return complex,
  ## if there is no complex, any operation with float will return float,
  ## only operations between int values will return int.
  if a.kind == nkComplex or b.kind == nkComplex:
    return newNumber(toComplex(a) + toComplex(b))
  elif a.kind == nkReal or b.kind == nkReal:
    return newNumber(toFloat(a) + toFloat(b))
  else:
    return newNumber(a.integer + b.integer)

proc `-`*(a, b: Number): Number {.inline.} =
  ## Subtracts two Number objects
  ## Promotion rules:
  ## int -> float -> complex
  ## any operation with complex will return complex,
  ## if there is no complex, any operation with float will return float,
  ## only operations between int values will return int.
  if a.kind == nkComplex or b.kind == nkComplex:
    return newNumber(toComplex(a) - toComplex(b))
  elif a.kind == nkReal or b.kind == nkReal:
    return newNumber(toFloat(a) - toFloat(b))
  else:
    return newNumber(a.integer - b.integer)

proc `-`*(a: Number): Number {.inline.} =
  ## Negates a Number object
  case a.kind
  of nkInteger:
    return newNumber(-a.integer)
  of nkReal:
    return newNumber(-a.real)
  of nkComplex:
    return newNumber(-a.complex)

proc `*`*(a, b: Number): Number {.inline.} =
  ## Multiplies two Number objects
  ## Promotion rules:
  ## int -> float -> complex
  ## any operation with complex will return complex,
  ## if there is no complex, any operation with float will return float,
  ## only operations between int values will return int.
  if a.kind == nkComplex or b.kind == nkComplex:
    return newNumber(toComplex(a) * toComplex(b))
  elif a.kind == nkReal or b.kind == nkReal:
    return newNumber(toFloat(a) * toFloat(b))
  else:
    return newNumber(a.integer * b.integer)

proc `/`*(a, b: Number): Number {.inline.} =
  ## Divides two Number objects
  ## Promotion rules:
  ## int -> float -> complex
  ## any operation with complex will return complex,
  ## if there is no complex, any operation with float will return float,
  ## there is not int division, only float division.
  if b.isZero:
    raise (ref DivisionByZeroError)(msg: "Division by zero is not allowed")

  if a.kind == nkComplex or b.kind == nkComplex:
    return newNumber(toComplex(a) / toComplex(b))
  elif a.kind == nkReal or b.kind == nkReal:
    return newNumber(toFloat(a) / toFloat(b))
  else:
    return newNumber(a.integer / b.integer)

proc `%`*(a, b: Number): Number {.inline.} =
  ## Modulus operation for two Number objects
  ## Promotion rules:
  ## Modulus is only defined for int and float types.
  ## any operation with complex will raise an exception,
  ## any operation with float will return float,
  ## only operations between int values will return int.
  ##
  ## Raises:
  ## - ComplexModulusError: when attempting modulus with complex numbers
  ## - DivisionByZeroError: when divisor is zero
  if a.kind == nkComplex or b.kind == nkComplex:
    raise (ref ComplexModulusError)(
      msg: "Modulus operation not supported for complex numbers"
    )
  elif a.kind == nkReal or b.kind == nkReal:
    return newNumber(toFloat(a) mod toFloat(b))
  else:
    return newNumber(a.integer mod b.integer)

proc `^`*(a, b: Number): Number {.inline.} =
  ## Raises a Number object to the power of another
  ## Promotion rules:
  ## int -> float -> complex
  ## any operation with complex will return complex,
  ## if there is no complex, any operation with float will return float,
  ## only operations between int values will return int except negative powers
  ## which will return float.
  ##
  ## Raises:
  ## - NumericError: for errors during power operation
  if a.kind == nkComplex or b.kind == nkComplex:
    return newNumber(toComplex(a).pow toComplex(b))
  elif a.kind == nkReal or b.kind == nkReal:
    return newNumber(toFloat(a) ^ toFloat(b))
  else:
    if b.integer < 0:
      return newNumber(a.integer.float ^ b.integer.float)
    else:
      return newNumber(a.integer ^ b.integer)

proc sqrt*(n: Number): Number {.inline.} =
  ## Returns the square root of a Number object
  ##
  ## Raises:
  ## - NumericError: for errors during square root calculation
  case n.kind
  of nkInteger:
    if n.integer < 0:
      return newNumber(sqrt(n.toComplex()))
    return newNumber(sqrt(n.integer.float))
  of nkReal:
    if n.real < 0:
      return newNumber(sqrt(n.toComplex()))
    return newNumber(sqrt(n.real))
  of nkComplex:
    return newNumber(sqrt(n.complex))

proc `==`*(a, b: Number): bool {.inline.} =
  ## Compares two Number objects for equality
  a.toComplex == b.toComplex

proc sin*(n: Number): Number {.inline.} =
  ## Returns the sine of a Number object
  ##
  ## Raises:
  ## - NumericError: for errors during sine calculation
  case n.kind
  of nkInteger:
    return newNumber(sin(n.integer.float))
  of nkReal:
    return newNumber(sin(n.real))
  of nkComplex:
    return newNumber(sin(n.complex))

proc cos*(n: Number): Number {.inline.} =
  ## Returns the cosine of a Number object
  ##
  ## Raises:
  ## - NumericError: for errors during cosine calculation
  case n.kind
  of nkInteger:
    return newNumber(cos(n.integer.float))
  of nkReal:
    return newNumber(cos(n.real))
  of nkComplex:
    return newNumber(cos(n.complex))

proc tan*(n: Number): Number {.inline.} =
  ## Returns the tangent of a Number object
  ##
  ## Raises:
  ## - NumericError: for errors during tangent calculation
  case n.kind
  of nkInteger:
    return newNumber(tan(n.integer.float))
  of nkReal:
    return newNumber(tan(n.real))
  of nkComplex:
    return newNumber(tan(n.complex))

proc cot*(n: Number): Number {.inline.} =
  ## Returns the cotangent of a Number object
  case n.kind
  of nkInteger:
    newNumber(cot(n.integer.float))
  of nkReal:
    newNumber(cot(n.real))
  of nkComplex:
    return newNumber(cot(n.complex))

proc sec*(n: Number): Number {.inline.} =
  ## Returns the secant of a Number object
  case n.kind
  of nkInteger:
    newNumber(sec(n.integer.float))
  of nkReal:
    newNumber(sec(n.real))
  of nkComplex:
    return newNumber(sec(n.complex))

proc csc*(n: Number): Number {.inline.} =
  ## Returns the cosecant of a Number object
  case n.kind
  of nkInteger:
    newNumber(csc(n.integer.float))
  of nkReal:
    newNumber(csc(n.real))
  of nkComplex:
    return newNumber(csc(n.complex))

proc log*(n: Number, base: Number): Number {.inline.} =
  ## Returns the natural logarithm of a Number object
  ##
  ## Raises:
  ## - NumericError: for errors during logarithm calculation
  if n.kind == nkComplex or base.kind == nkComplex:
    return newNumber(ln(toComplex(n)) / ln(toComplex(base)))
  else:
    return newNumber(log(toFloat(n), toFloat(base)))

proc ceil*(n: Number): Number {.inline.} =
  ## Returns the ceiling of a Number object
  ##
  ## Raises:
  ## - ComplexCeilFloorRoundError: when attempting with complex numbers
  case n.kind
  of nkInteger:
    return n
  of nkReal:
    return newNumber(ceil(n.real).int)
  of nkComplex:
    raise (ref ComplexCeilFloorRoundError)(
      msg: "Ceiling operation not supported for complex numbers"
    )

proc abs*(n: Number): Number {.inline.} =
  ## Returns the absolute value of a Number object
  case n.kind
  of nkInteger:
    return newNumber(abs(n.integer))
  of nkReal:
    return newNumber(abs(n.real))
  of nkComplex:
    return newNumber(abs(n.complex))

proc floor*(n: Number): Number {.inline.} =
  ## Returns the floor of a Number object
  ##
  ## Raises:
  ## - ComplexCeilFloorRoundError: when attempting with complex numbers
  case n.kind
  of nkInteger:
    return n
  of nkReal:
    return newNumber(floor(n.real).int)
  of nkComplex:
    raise (ref ComplexCeilFloorRoundError)(
      msg: "Floor operation not supported for complex numbers"
    )

proc round*(n: Number): Number {.inline.} =
  ## Returns the rounded value of a Number object
  ##
  ## Raises:
  ## - ComplexCeilFloorRoundError: when attempting with complex numbers
  case n.kind
  of nkInteger:
    return n
  of nkReal:
    return newNumber(round(n.real).int)
  of nkComplex:
    raise (ref ComplexCeilFloorRoundError)(
      msg: "Round operation not supported for complex numbers"
    )

proc exp*(n: Number): Number {.inline.} =
  ## Returns the exponential e^n of a Number object
  ##
  ## Raises:
  ## - NumericError: for errors during exponential calculation
  case n.kind
  of nkInteger:
    return newNumber(exp(n.integer.float))
  of nkReal:
    return newNumber(exp(n.real))
  of nkComplex:
    return newNumber(exp(n.complex))

proc `<`*(a, b: Number): bool {.inline.} =
  ## Compares two Number objects for less than
  ##
  ## Raises:
  ## - ComplexComparisonError: when comparing complex numbers
  if a.kind == nkComplex or b.kind == nkComplex:
    raise
      (ref ComplexComparisonError)(msg: "Comparison not supported for complex numbers")
  else:
    a.toFloat < b.toFloat

proc `<=`*(a, b: Number): bool {.inline.} =
  ## Compares two Number objects for less than or equal to
  ##
  ## Raises:
  ## - ComplexComparisonError: when comparing complex numbers
  if a.kind == nkComplex or b.kind == nkComplex:
    raise
      (ref ComplexComparisonError)(msg: "Comparison not supported for complex numbers")
  else:
    a.toFloat <= b.toFloat

proc `>`*(a, b: Number): bool {.inline.} =
  ## Compares two Number objects for greater than
  ##
  ## Raises:
  ## - ComplexComparisonError: when comparing complex numbers
  if a.kind == nkComplex or b.kind == nkComplex:
    raise
      (ref ComplexComparisonError)(msg: "Comparison not supported for complex numbers")
  else:
    a.toFloat > b.toFloat

proc `>=`*(a, b: Number): bool {.inline.} =
  ## Compares two Number objects for greater than or equal to
  ##
  ## Raises:
  ## - ComplexComparisonError: when comparing complex numbers
  if a.kind == nkComplex or b.kind == nkComplex:
    raise
      (ref ComplexComparisonError)(msg: "Comparison not supported for complex numbers")
  else:
    a.toFloat >= b.toFloat

proc `$`*(n: Number): string {.inline.} =
  ## Returns string representation of a Number object
  case n.kind
  of nkInteger:
    return $n.integer
  of nkReal:
    return $n.real
  of nkComplex:
    if n.complex.re == 0.0 and n.complex.im == 0.0:
      return "0"
    elif n.complex.re == 0.0:
      return $n.complex.im & "i"
    elif n.complex.im == 0.0:
      return $n.complex.re
    else:
      if n.complex.im < 0.0:
        return $n.complex.re & " - " & $(abs(n.complex.im)) & "i"
      else:
        return $n.complex.re & " + " & $n.complex.im & "i"

proc re*(n: Number): Number {.inline.} =
  ## Returns the real part of a Number object as a Number
  case n.kind
  of nkInteger, nkReal:
    return n
  of nkComplex:
    return newNumber(n.complex.re)

proc im*(n: Number): Number {.inline.} =
  ## Returns the imaginary part of a Number object as a Number
  case n.kind
  of nkInteger, nkReal:
    return newNumber(0.int)
  of nkComplex:
    return newNumber(n.complex.im)
