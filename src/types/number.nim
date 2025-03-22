import std/math
import std/complex

import errors

type
  NumberKind* = enum
    nkInt ## Integer number
    nkFloat ## Floating-point number
    nkComplex ## Complex number

  Number* = object
    case kind*: NumberKind
    of nkInt:
      iValue*: int ## Integer value
    of nkFloat:
      fValue*: float ## Floating-point value
    of nkComplex:
      cValue*: Complex[float] ## Complex number value

  NumericError* = object of BMathError
  
  DivisionByZeroError* = object of NumericError
    ## Raised when attempting to divide by zero
  
  ComplexModulusError* = object of NumericError
    ## Raised when modulus operation is attempted with complex numbers
  
  ComplexComparisonError* = object of NumericError
    ## Raised when comparison is attempted with complex numbers
  
  ComplexCeilFloorRoundError* = object of NumericError
    ## Raised when ceil/floor/round is attempted with complex numbers

proc newNumber*[T](value: T): Number {.inline.} =
  ## Creates a new Number object based on the type of value
  when value is SomeInteger:
    Number(kind: nkInt, iValue: value.int)
  elif value is SomeFloat:
    Number(kind: nkFloat, fValue: value.float)
  elif value is Complex[float]:
    if value.im == 0.0:
      Number(kind: nkFloat, fValue: value.re)
    else:
      Number(kind: nkComplex, cValue: value)
  else:
    {.error: "Unsupported type for Number".}

template newNumber*(re: SomeFloat, im: SomeFloat): Number =
  ## Creates a new Number object from real and imaginary parts
  Number(kind: nkComplex, cValue: complex(re.float, im.float))

const ZERO* = newNumber(0)

proc isZero*(n: Number): bool {.inline.} =
  ## Checks if a Number object is zero
  case n.kind
  of nkInt:
    return n.iValue == 0
  of nkFloat:
    return n.fValue == 0.0
  of nkComplex:
    return n.cValue.re == 0.0 and n.cValue.im == 0.0

template toComplex(n: Number): Complex[float] =
  case n.kind
  of nkInt:
    complex(n.iValue.float, 0.0)
  of nkFloat:
    complex(n.fValue, 0.0)
  of nkComplex:
    n.cValue

template toFloat(n: Number): float =
  case n.kind
  of nkInt:
    n.iValue.float
  of nkFloat:
    n.fValue
  of nkComplex:
    raise (ref NumericError)(msg:"Cannot convert complex number to float")

proc `+`*(a, b: Number): Number {.inline.} =
  ## Adds two Number objects together
  ## Promotion rules:
  ## int -> float -> complex
  ## any operation with complex will return complex,
  ## if there is no complex, any operation with float will return float,
  ## only operations between int values will return int.
  if a.kind == nkComplex or b.kind == nkComplex:
    return newNumber(toComplex(a) + toComplex(b))
  elif a.kind == nkFloat or b.kind == nkFloat:
    return newNumber(toFloat(a) + toFloat(b))
  else:
    return newNumber(a.iValue + b.iValue)

proc `-`*(a, b: Number): Number {.inline.} =
  ## Subtracts two Number objects
  ## Promotion rules:
  ## int -> float -> complex
  ## any operation with complex will return complex,
  ## if there is no complex, any operation with float will return float,
  ## only operations between int values will return int.
  if a.kind == nkComplex or b.kind == nkComplex:
    return newNumber(toComplex(a) - toComplex(b))
  elif a.kind == nkFloat or b.kind == nkFloat:
    return newNumber(toFloat(a) - toFloat(b))
  else:
    return newNumber(a.iValue - b.iValue)

proc `-`*(a: Number): Number {.inline.} =
  ## Negates a Number object
  case a.kind
  of nkInt:
    return newNumber(-a.iValue)
  of nkFloat:
    return newNumber(-a.fValue)
  of nkComplex:
    return newNumber(-a.cValue)

proc `*`*(a, b: Number): Number {.inline.} =
  ## Multiplies two Number objects
  ## Promotion rules:
  ## int -> float -> complex
  ## any operation with complex will return complex,
  ## if there is no complex, any operation with float will return float,
  ## only operations between int values will return int.
  if a.kind == nkComplex or b.kind == nkComplex:
    return newNumber(toComplex(a) * toComplex(b))
  elif a.kind == nkFloat or b.kind == nkFloat:
    return newNumber(toFloat(a) * toFloat(b))
  else:
    return newNumber(a.iValue * b.iValue)

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
  elif a.kind == nkFloat or b.kind == nkFloat:
    return newNumber(toFloat(a) / toFloat(b))
  else:
    return newNumber(a.iValue / b.iValue)

proc `%`*(a, b: Number): Number {.inline.} =
  ## Modulus operation for two Number objects
  ## Promotion rules:
  ## Modulus is only defined for int and float types.
  ## any operation with complex will raise an exception,
  ## any operation with float will return float,
  ## only operations between int values will return int.
  if a.kind == nkComplex or b.kind == nkComplex:
    raise (ref ComplexModulusError)(msg: "Modulus operation not supported for complex numbers")
  elif a.kind == nkFloat or b.kind == nkFloat:
    return newNumber(toFloat(a) mod toFloat(b))
  else:
    return newNumber(a.iValue mod b.iValue)

proc `^`*(a, b: Number): Number {.inline.} =
  ## Raises a Number object to the power of another
  ## Promotion rules:
  ## int -> float -> complex
  ## any operation with complex will return complex,
  ## if there is no complex, any operation with float will return float,
  ## only operations between int values will return int except negative powers
  ## which will return float.
  if a.kind == nkComplex or b.kind == nkComplex:
    return newNumber(toComplex(a).pow toComplex(b))
  elif a.kind == nkFloat or b.kind == nkFloat:
    return newNumber(toFloat(a) ^ toFloat(b))
  else:
    if b.iValue < 0:
      return newNumber(a.iValue.float ^ b.iValue.float)
    else:
      return newNumber(a.iValue ^ b.iValue)

proc sqrt*(n: Number): Number {.inline.} =
  ## Returns the square root of a Number object
  case n.kind
  of nkInt:
    if n.iValue < 0:
      return newNumber(sqrt(n.toComplex()))
    return newNumber(sqrt(n.iValue.float))
  of nkFloat:
    if n.fValue < 0:
      return newNumber(sqrt(n.toComplex()))
    return newNumber(sqrt(n.fValue))
  of nkComplex:
    return newNumber(sqrt(n.cValue))

proc `==`*(a, b: Number): bool {.inline.} =
  ## Compares two Number objects for equality
  a.toComplex == b.toComplex

proc sin*(n: Number): Number {.inline.} =
  ## Returns the sine of a Number object
  case n.kind
  of nkInt:
    return newNumber(sin(n.iValue.float))
  of nkFloat:
    return newNumber(sin(n.fValue))
  of nkComplex:
    return newNumber(sin(n.cValue))

proc cos*(n: Number): Number {.inline.} =
  ## Returns the cosine of a Number object
  case n.kind
  of nkInt:
    return newNumber(cos(n.iValue.float))
  of nkFloat:
    return newNumber(cos(n.fValue))
  of nkComplex:
    return newNumber(cos(n.cValue))

proc tan*(n: Number): Number {.inline.} =
  ## Returns the tangent of a Number object
  case n.kind
  of nkInt:
    return newNumber(tan(n.iValue.float))
  of nkFloat:
    return newNumber(tan(n.fValue))
  of nkComplex:
    return newNumber(tan(n.cValue))

proc log*(n: Number, base: Number): Number {.inline.} =
  ## Returns the natural logarithm of a Number object
  if n.kind == nkComplex or base.kind == nkComplex:
    return newNumber(ln(toComplex(n)) / ln(toComplex(base)))
  else:
    return newNumber(log(toFloat(n), toFloat(base)))

proc ceil*(n: Number): Number {.inline.} =
  ## Returns the ceiling of a Number object
  case n.kind
  of nkInt:
    return n
  of nkFloat:
    return newNumber(ceil(n.fValue).int)
  of nkComplex:
    raise (ref ComplexCeilFloorRoundError)(msg: "Ceiling operation not supported for complex numbers")

proc floor*(n: Number): Number {.inline.} =
  ## Returns the floor of a Number object
  case n.kind
  of nkInt:
    return n
  of nkFloat:
    return newNumber(floor(n.fValue).int)
  of nkComplex:
    raise (ref ComplexCeilFloorRoundError)(msg: "Floor operation not supported for complex numbers")

proc round*(n: Number): Number {.inline.} =
  ## Returns the rounded value of a Number object
  case n.kind
  of nkInt:
    return n
  of nkFloat:
    return newNumber(round(n.fValue).int)
  of nkComplex:
    raise (ref ComplexCeilFloorRoundError)(msg: "Round operation not supported for complex numbers")

proc exp*(n: Number): Number {.inline.} =
  ## Returns the exponential e^n of a Number object
  case n.kind
  of nkInt:
    return newNumber(exp(n.iValue.float))
  of nkFloat:
    return newNumber(exp(n.fValue))
  of nkComplex:
    return newNumber(exp(n.cValue))

proc `<`*(a, b: Number): bool {.inline.} =
  ## Compares two Number objects for less than
  if a.kind == nkComplex or b.kind == nkComplex:
    raise (ref ComplexComparisonError)(msg: "Comparison not supported for complex numbers")
  else:
    a.toFloat < b.toFloat

proc `<=`*(a, b: Number): bool {.inline.} =
  ## Compares two Number objects for less than or equal to
  if a.kind == nkComplex or b.kind == nkComplex:
    raise (ref ComplexComparisonError)(msg: "Comparison not supported for complex numbers")
  else:
    a.toFloat <= b.toFloat

proc `>`*(a, b: Number): bool {.inline.} =
  ## Compares two Number objects for greater than
  if a.kind == nkComplex or b.kind == nkComplex:
    raise (ref ComplexComparisonError)(msg: "Comparison not supported for complex numbers")
  else:
    a.toFloat > b.toFloat

proc `>=`*(a, b: Number): bool {.inline.} =
  ## Compares two Number objects for greater than or equal to
  if a.kind == nkComplex or b.kind == nkComplex:
    raise (ref ComplexComparisonError)(msg: "Comparison not supported for complex numbers")
  else:
    a.toFloat >= b.toFloat

proc `$`*(n: Number): string {.inline.} =
  ## Returns string representation of a Number object
  case n.kind
  of nkInt:
    return $n.iValue
  of nkFloat:
    return $n.fValue
  of nkComplex:
    if n.cValue.re == 0.0 and n.cValue.im == 0.0:
      return "0"
    elif n.cValue.re == 0.0:
      return $n.cValue.im & "i"
    elif n.cValue.im == 0.0:
      return $n.cValue.re
    else:
      if n.cValue.im < 0.0:
        return $n.cValue.re & " - " & $(abs(n.cValue.im)) & "i"
      else:
        return $n.cValue.re & " + " & $n.cValue.im & "i"
