## types.nim
## 
## 
import std/[sets]

type
  TypeKind* = enum
    tkSimple
    tkSum
    tkError

  SimpleType* {.pure.} = enum
    Integer
    Real
    Complex
    Boolean
    Vector
    Sequence
    Function
    Type

  Type* = object
    case kind*: TypeKind
    of tkSimple:
      simpleType*: SimpleType
    of tkSum:
      types*: HashSet[SimpleType]
    of tkError:
      error*: cstring

const 
  AnyType* = Type(
    kind: tkSum, types: toHashSet([Integer, Real, Complex, Boolean, Vector, Sequence, Function, Type])
  )
  NumberType* = Type(
    kind: tkSum, types: toHashSet([Integer, Real, Complex])
  )

proc newType*(`type`: SimpleType): Type =
  ## Create a new Type object from a SimpleType
  Type(kind: tkSimple, simpleType: `type`)

proc `===`*(a, b: Type): bool =
  ## Compares two types for identity
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

proc `==`*(a, b: Type): bool =
  ## Compares two types for equality
  if a.kind != b.kind:
    # Handle different kinds - special handling for sum and simple
    if a.kind == tkSum and b.kind == tkSimple:
      return b.simpleType in a.types
    elif a.kind == tkSimple and b.kind == tkSum:
      return a.simpleType in b.types
    else:
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

proc `$`*(t: Type): string =
  ## Returns a human-readable representation of the type
  case t.kind
  of tkSimple:
    case t.simpleType
    of Integer:
      return "integer"
    of Real:
      return "real"
    of Complex:
      return "complex"
    of Boolean:
      return "boolean"
    of Vector:
      return "vector"
    of Sequence:
      return "sequence"
    of Function:
      return "function"
    of Type:
      return "type"
  of tkSum:
    if t.types == AnyType.types:
      return "any"
    if t.types == NumberType.types:
      return "number"
    else:
      result = "sum(" & $t.types & ")"
  of tkError:
    result = "error(" & $t.error & ")"