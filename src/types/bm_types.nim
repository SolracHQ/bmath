## BMathTypes.nim

import std/sets
from core import BMathType, BMathSimpleType, BMathTypeKind
export BMathType, BMathSimpleType, BMathTypeKind

const
  AnyType* = BMathType(
    kind: tkSum,
    types: toHashSet(
      [
        stInteger, stReal, stComplex, stBoolean, stVector, stSequence, stFunction,
        stType, stString, stError,
      ]
    ),
  )
  NumberType* = BMathType(kind: tkSum, types: toHashSet([stInteger, stReal, stComplex]))

proc newType*(`type`: BMathSimpleType): BMathType =
  ## Create a new BMathType object from a BMathSimpleType
  BMathType(kind: tkSimple, simpleType: `type`)

proc `===`*(a, b: BMathType): bool =
  ## Compares two BMathTypes for identity
  if a.kind != b.kind:
    return false
  else:
    # Same kinds
    case a.kind
    of tkSimple:
      return a.simpleType == b.simpleType
    of tkSum:
      return a.types == b.types
    of tkError:
      return a.error == b.error

proc `==`*(a, b: BMathType): bool =
  ## Compares two BMathTypes for equality
  ## Numeric subtype relation helper
  proc isSubtypeSimple(fromS, toS: BMathSimpleType): bool =
    ## Returns true when `fromS` can be considered a subtype of `toS`.
    ## Numeric hierarchy: Integer <= Real <= Complex. Other types only equal themselves.
    case fromS
    of stInteger:
      return toS in {stInteger, stReal, stComplex}
    of stReal:
      return toS in {stReal, stComplex}
    else:
      return fromS == toS

  if a.kind != b.kind:
    # Handle different kinds - special handling for sum and simple using subtype checks
    if a.kind == tkSum and b.kind == tkSimple:
      for t in a.types:
        if isSubtypeSimple(t, b.simpleType):
          return true
      return false
    elif a.kind == tkSimple and b.kind == tkSum:
      for t in b.types:
        if isSubtypeSimple(a.simpleType, t):
          return true
      return false
    else:
      return false
  else:
    # Same kinds
    case a.kind
    of tkSimple:
      return isSubtypeSimple(a.simpleType, b.simpleType)
    of tkSum:
      return a.types == b.types
    of tkError:
      return a.error == b.error

proc `$`*(t: BMathType): string =
  ## Returns a human-readable representation of the BMathType
  case t.kind
  of tkSimple:
    case t.simpleType
    of stInteger:
      return "Int"
    of stString:
      return "String"
    of stReal:
      return "Real"
    of stComplex:
      return "Complex"
    of stBoolean:
      return "Bool"
    of stVector:
      return "Vec"
    of stSequence:
      return "Seq"
    of stFunction:
      return "Function"
    of stType:
      return "Type"
    of stError:
      return "Error"
  of tkSum:
    if t.types == AnyType.types:
      return "Any"
    if t.types == NumberType.types:
      return "Number"
    else:
      result = "Sum(" & $t.types & ")"
  of tkError:
    result = "Error(" & $t.error & ")"
