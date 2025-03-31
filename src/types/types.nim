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

proc `$`*(t: Type): string =
  ## Returns a human-readable representation of the type
  case t.kind
  of tkSimple:
    case t.simpleType
    of Integer:
      return "Integer"
    of Real:
      return "Real"
    of Complex:
      return "Complex"
    of Boolean:
      return "Boolean"
    of Vector:
      return "Vector"
    of Sequence:
      return "Sequence"
    of Function:
      return "Function"
    of Type:
      return "Type"
  of tkSum:
    if t.types == AnyType.types:
      return "Any"
    if t.types == NumberType.types:
      return "Number"
    else:
      result = "Sum(" & $t.types & ")"
  of tkError:
    result = "Error(" & $t.error & ")"