## BMathTypes.nim

import std/sets
from core import BMathType, BMathSimpleType, BMathTypeKind
from core import Value, ValueKind, NumberKind
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

proc newType*(bmath_simple_type: varargs[BMathSimpleType]): BMathType =
  ## Create a new BMathType object from a BMathSimpleType
  if bmath_simple_type.len == 1:
    BMathType(kind: tkSimple, simpleType: bmath_simple_type[0])
  else:
    BMathType(kind: tkSum, types: toHashSet(bmath_simple_type))

proc getType*(v: Value): BMathType =
  ## Returns the BMathType corresponding to the given Value
  case v.kind
  of vkNumber:
    case v.number.kind
    of nkInteger:
      newType(stInteger)
    of nkReal:
      newType(stReal)
    of nkComplex:
      newType(stComplex)
  of vkBool:
    newType(stBoolean)
  of vkVector:
    newType(stVector)
  of vkSeq:
    newType(stSequence)
  of vkFunction, vkNativeFunc:
    newType(stFunction)
  of vkType:
    newType(stType)
  of vkString:
    newType(stString)
  of vkError:
    newType(stError)
  of vkModule:
    newType(stModule)

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
    of stModule:
      return "Module"
  of tkSum:
    if t.types == AnyType.types:
      return "Any"
    if t.types == NumberType.types:
      return "Number"
    else:
      result = "Sum(" & $t.types & ")"
