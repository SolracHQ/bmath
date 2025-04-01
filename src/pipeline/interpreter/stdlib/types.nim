## typed.nim

import ../../../types/[value, types, number, vector]
import ../errors
import sequence
import std/[complex]

proc getType*(value: Value): Type =
  ## Returns the type of a value.
  ##
  ## Parameters:
  ##   value: Value - The value to get the type of.
  ##
  ## Returns:
  ##   Type - The type of the value.

  case value.kind
  of vkNumber:
    case value.number.kind
    of nkInteger:
      return newType(SimpleType.Integer)
    of nkReal:
      return newType(SimpleType.Real)
    of nkComplex:
      return newType(SimpleType.Complex)
  of vkBool:
    return newType(SimpleType.Boolean)
  of vkFunction, vkNativeFunc:
    return newType(SimpleType.Function)
  of vkVector:
    return newType(SimpleType.Vector)
  of vkSeq:
    return newType(SimpleType.Sequence)
  of vkType:
    return newType(SimpleType.Type)

proc casting*(target: Type, source: Value): Value =
  ## Casts a value to a specified type.
  ## 
  ## Parameters:
  ##   target: Type - The target type to cast to.
  ##   source: Value - The source value to be casted.
  ##
  ## Returns:
  ##   Value - The casted value of the specified type.
  ##
  ## Raises:
  ##   InvalidArgumentError - If the source value cannot be casted to the target type.

  # Handle simple type conversions
  if target.kind == tkSimple:
    case target.simpleType:
    of SimpleType.Integer:
      if source.kind == vkNumber:
        case source.number.kind:
        of nkInteger:
          return source  # Already an integer
        of nkReal:
          return newValue(int(source.number.real))  # Convert float to int
        of nkComplex:
          return newValue(int(source.number.complex.re))  # Take real part and convert to int
      else:
        raise newInvalidArgumentError("Cannot convert " & $source.kind & " to Integer type")

    of SimpleType.Real:
      if source.kind == vkNumber:
        case source.number.kind:
        of nkInteger:
          return newValue(float(source.number.integer))  # Convert int to float
        of nkReal:
          return source  # Already a real number
        of nkComplex:
          return newValue(source.number.complex.re)  # Take real part
      else:
        raise newInvalidArgumentError("Cannot convert " & $source.kind & " to Real type")

    of SimpleType.Complex:
      if source.kind == vkNumber:
        case source.number.kind:
        of nkInteger:
          return newValue(complex(float(source.number.integer)))  # Convert int to complex
        of nkReal:
          return newValue(complex(source.number.real))  # Convert real to complex
        of nkComplex:
          return source  # Already a complex number
      else:
        raise newInvalidArgumentError("Cannot convert " & $source.kind & " to Complex type")

    of SimpleType.Boolean:
      if source.kind == vkBool:
        return source
      else:
        raise newInvalidArgumentError("Cannot convert " & $source.kind & " to Boolean type")

    of SimpleType.Vector:
      if source.kind == vkVector:
        return source
      elif source.kind == vkSeq:
        # Convert sequence to vector (similar to collect function)
        var elements: seq[Value] = @[]
        for item in source.sequence:
          elements.add(item)

        result = Value(kind: vkVector)
        result.vector = fromSeq(elements)
        
        return result
      else:
        raise newInvalidArgumentError("Cannot convert " & $source.kind & " to Vector type")

    of SimpleType.Sequence:
      if source.kind == vkSeq:
        return source
      elif source.kind == vkVector:
        # Convert vector to sequence
        var resultSeq = Sequence(transformers: @[])
        let vec = source.vector
        var index = 0

        resultSeq.generator = Generator(
          atEnd: proc(): bool =
            index >= vec.size,
          next: proc(peek: bool = false): Value =
            if index >= vec.size:
              raise newSequenceExhaustedError(
                "Sequence exhausted: attempted to access beyond the end of sequence derived from vector of length " &
                  $vec.size
              )
            result = vec[index]
            if not peek:
              inc index
          ,
        )
        
        return Value(kind: vkSeq, sequence: resultSeq)
      else:
        raise newInvalidArgumentError("Cannot convert " & $source.kind & " to Sequence type")

    of SimpleType.Function:
      if source.kind == vkFunction or source.kind == vkNativeFunc:
        return source
      else:
        raise newInvalidArgumentError("Cannot convert " & $source.kind & " to Function type")

    of SimpleType.Type:
      if source.kind == vkType:
        return source
      else:
        return source.getType().newValue()
  
  

  # Handle sum types
  elif target.kind == tkSum:
    # For sum types, get value type and check if it is in the sum type
    let valueType = getType(source)
    if target == valueType:
      return source
    
    # If no conversion worked
    raise newInvalidArgumentError("Cannot convert " & $valueType & " to " & $target)
  
  # Error types
  else:
    raise newInvalidArgumentError("Cannot convert to an error type")

