## value.nim
## 
## This module contains all type definitions for the interpreter to avoid cyclic dependencies.
## It includes fundamental types for values, tokens, AST nodes, and errors, along with their
## string representation implementations.

import std/[strutils, tables, sequtils, complex, sets]

import position, expression, number, vector, bm_types
import macros
import errors

from core import
  Value, ValueKind, NativeFn, Function, Environment, LabeledValue, Parameter, FnInvoker,
  Sequence, Generator, Transformer, TransformerKind, Signature
export
  Value, ValueKind, NativeFn, Function, Environment, LabeledValue, FnInvoker, Sequence,
  Generator, Transformer, TransformerKind

template newValue*(n: typed): Value =
  ## Create a new Value object from a number
  when n is SomeInteger:
    Value(kind: vkNumber, number: newNumber(n))
  elif n is SomeFloat:
    Value(kind: vkNumber, number: newNumber(n))
  elif n is Complex[float]:
    Value(kind: vkNumber, number: newNumber(n))
  elif n is Number:
    Value(kind: vkNumber, number: n)
  elif n is bool:
    Value(kind: vkBool, boolean: n.bool)
  elif n is seq[Value]:
    Value(kind: vkVector, vector: n)
  elif n is BMathType:
    Value(kind: vkType, typ: n)
  elif n is string:
    Value(kind: vkString, content: n)
  else:
    const message = "Unsupported type '" & $T & "' for Value"
    {.error: message.}

proc newValue*(
    body: Expression, env: Environment, params: seq[Parameter]
): Value {.inline.} =
  ## Creates a new Value object wrapping a user-defined function.
  var functionObj = Function(body: body, env: env, params: params)
  result = Value(kind: vkFunction, function: functionObj)

template rawAccess*(value: Value, kind: static[ValueKind]) =
  when kind == vkNumber:
    ## Returns the numeric value of the Value object
    value.number
  elif kind == vkBool:
    ## Returns the boolean value of the Value object
    value.boolean
  elif kind == vkVector:
    ## Returns the vector values of the Value object
    value.vector
  else:
    {.error: "Unsupported type for rawAccess".}

# --- String representations for debugging and logging ---

proc `$`*(kind: ValueKind): string =
  ## Returns string representation of value kind
  case kind
  of vkNumber: "number"
  of vkBool: "bool"
  of vkNativeFunc: "native func"
  of vkFunction: "function"
  of vkVector: "vector"
  of vkSeq: "seq"
  of vkType: "type"
  of vkString: "string"
  of vkError: "error"

proc `$`*(value: Value): string =
  ## Returns string representation of numeric value
  case value.kind
  of vkNumber:
    $value.number
  of vkBool:
    $value.boolean
  of vkNativeFunc:
    "<native func>"
  of vkFunction:
    "|" & value.function.params.join(", ") & "| " & value.function.body.asSource
  of vkVector:
    "[" & value.vector.toSeq.mapIt($it).join(", ") & "]"
  of vkSeq:
    "<seq>"
  of vkType:
    $value.typ
  of vkString:
    "\"" & value.content & "\""
  of vkError:
    "Error: " & value.error

proc `$`*(val: LabeledValue): string =
  if val.label != "":
    result = val.label & " = "
  result &= $val.value

proc `$`*(env: Environment): string =
  ## Returns string representation of environment values
  if env.parent != nil:
    result = "Environment(parent: " & $env.parent & ", values: " & $env.values & ")"
  else:
    result = "Environment(values: " & $env.values & ")"

# --- Value Operations ---

## Helper procs to apply Value->Value operators element-wise
template applyScalarOp(op: untyped, a: Value, b: Vector[Value]): Vector[Value] =
  ## Applies a scalar operation between a Value and each element of a vector
  var result = newVector[Value](b.size)
  for i in 0 ..< b.size:
    result[i] = op(a, b[i])
  result

template applyVectorOp(op: untyped, a: Vector[Value], b: Vector[Value]): Vector[Value]=
  ## Applies a vector operation element-wise between two vectors
  # if a.size != b.size: # this should be checked by the caller
  var result = newVector[Value](size[Value](a))
  for i in 0 ..< a.size:
    result[i] = op(a[i], b[i])
  result

template applyScalarOpRight(op: untyped, a: Vector[Value], b: Value): Vector[Value] =
  ## Applies an operation between each element of a vector and a scalar on the right
  var result = newVector[Value](a.size)
  for i in 0 ..< a.size:
    result[i] = op(a[i], b)
  result

# Capture numeric errors macro (moved from stdlib/utils.nim)
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

# ----- Binary Arithmetic operations -----

proc `+`*(a, b: Value): Value {.inline, captureNumericError, raises: [RuntimeError].} =
  ## Addition for Values.
  ##
  ## Parameters:
  ## - a, b: the Values to add. Supported forms:
  ##   * two numbers: numeric addition
  ##   * two vectors of equal length: element-wise addition
  ##
  ## Returns:
  ## - A `vkNumber` Value for numeric addition, or a `vkVector` Value for
  ##   element-wise vector addition.
  ##
  ## Raises:
  ## - InvalidOperationError: when operands have incompatible kinds (e.g. number + vector)
  ## - VectorLengthMismatchError: when adding two vectors of different sizes
  ## - ArithmeticError variants (wrapped via `captureNumericError`) for numeric issues
  if a.kind == vkNumber and b.kind == vkNumber:
    return newValue(a.number + b.number)
  elif a.kind == vkVector and b.kind == vkVector:
    # Element-wise vector addition
    let va = a.vector
    let vb = b.vector
    if va.size != vb.size:
      raise newVectorLengthMismatchError(va.size, vb.size)
    result = Value(kind: vkVector)
    result.vector = applyVectorOp(`+`, va, vb)
  else:
    raise newInvalidOperationError("addition", $a.kind, $b.kind)

proc `-`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Subtraction for Values.
  ##
  ## Parameters:
  ## - a, b: the Values to subtract. Supported forms:
  ##   * two numbers: numeric subtraction
  ##   * two vectors of equal length: element-wise subtraction
  ##
  ## Returns:
  ## - A `vkNumber` Value for numeric subtraction, or a `vkVector` Value for
  ##   element-wise vector subtraction.
  ##
  ## Raises:
  ## - InvalidOperationError: when operands have incompatible kinds
  ## - VectorLengthMismatchError: when subtracting vectors of different sizes
  ## - ArithmeticError variants (wrapped via `captureNumericError`) for numeric issues
  if a.kind == vkNumber and b.kind == vkNumber:
    return newValue(a.number - b.number)
  elif a.kind == vkVector and b.kind == vkVector:
    # Element-wise vector subtraction
    let va = a.vector
    let vb = b.vector
    if va.size != vb.size:
      raise newVectorLengthMismatchError(va.size, vb.size)
    result = Value(kind: vkVector)
    result.vector = applyVectorOp(`-`, va, vb)
  else:
    raise newInvalidOperationError("subtraction", $a.kind, $b.kind)

proc `*`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Multiplication for Values.
  ##
  ## Supported forms:
  ## - number * number: numeric multiplication
  ## - vector * vector: dot product (element-wise multiply then sum)
  ## - number * vector or vector * number: scalar multiplication (element-wise)
  ##
  ## Returns:
  ## - A `vkNumber` Value for numeric multiplication and vector dot product,
  ##   or a `vkVector` Value for scalar-vector multiplication.
  ##
  ## Raises:
  ## - InvalidOperationError for unsupported operand kinds
  ## - VectorLengthMismatchError for vector-vector operations of different sizes
  ## - ArithmeticError variants (wrapped via `captureNumericError`) for numeric issues
  if a.kind == vkNumber and b.kind == vkNumber:
    return newValue(a.number * b.number)
  elif a.kind == vkVector and b.kind == vkVector:
    # Dot product of two vectors (using Value * Value)
    let va = a.vector
    let vb = b.vector
    if va.size != vb.size:
      raise newVectorLengthMismatchError(va.size, vb.size)
    result = newValue(0)
    for i in 0 ..< va.size:
      result = result + va[i] * vb[i]
    return result
  elif a.kind == vkNumber and b.kind == vkVector:
    # Multiply scalar by vector: element-wise
    let vb = b.vector
    result = Value(kind: vkVector, vector: applyScalarOp(`*`, a, vb))
  elif a.kind == vkVector and b.kind == vkNumber:
    # Multiply vector by scalar: element-wise
    let va = a.vector
    result = Value(kind: vkVector, vector: applyScalarOp(`*`, b, va))
  else:
    raise newInvalidOperationError("multiplication", $a.kind, $b.kind)

proc `/`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Division for Values.
  ##
  ## Supported forms:
  ## - number / number: numeric division (raises on division by zero)
  ## - vector / number: element-wise division of each vector element by the scalar
  ##
  ## Returns:
  ## - A `vkNumber` Value for numeric division, or a `vkVector` Value for
  ##   element-wise division.
  ##
  ## Raises:
  ## - ZeroDivisionError (wrapped to `newZeroDivisionError`) when dividing by zero
  ## - InvalidOperationError for unsupported operand kinds
  ## - ArithmeticError variants (wrapped via `captureNumericError`) for numeric issues
  if a.kind == vkNumber and b.kind == vkNumber:
    if b.number.isZero:
      raise newZeroDivisionError()
    return newValue(a.number / b.number)
  elif a.kind == vkVector and b.kind == vkNumber:
    if b.number.isZero:
      raise newZeroDivisionError()
    # Element-wise division of vector by scalar
    let va = a.vector
    result = Value(kind: vkVector, vector: applyScalarOpRight(`/`, va, b))
  else:
    raise newInvalidOperationError("division", $a.kind, $b.kind)

proc `%`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Modulus (remainder) for Values.
  ##
  ## Supported forms:
  ## - number % number: numeric modulus (raises on division by zero)
  ## - vector % number: element-wise modulus of each vector element by the scalar
  ##
  ## Returns:
  ## - A `vkNumber` Value for numeric modulus, or a `vkVector` Value for
  ##   element-wise modulus.
  ##
  ## Raises:
  ## - ZeroDivisionError (wrapped to `newZeroDivisionError`) when divisor is zero
  ## - InvalidOperationError for unsupported operand kinds
  ## - ComplexModulusError if modulus on complex numbers (wrapped by `captureNumericError`)
  if a.kind == vkNumber and b.kind == vkNumber:
    if b.number.isZero:
      raise newZeroDivisionError()
    return newValue(a.number % b.number)
  elif a.kind == vkVector and b.kind == vkNumber:
    if b.number.isZero:
      raise newZeroDivisionError()
    # Element-wise modulus of vector by scalar
    let va = a.vector
    result = Value(kind: vkVector, vector: applyScalarOpRight(`%`, va, b))

proc `^`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Exponentiation for Values.
  ##
  ## Supported forms:
  ## - number ^ number: numeric exponentiation
  ## - vector ^ number: element-wise power of vector elements by scalar
  ##
  ## Returns:
  ## - A `vkNumber` Value for numeric exponentiation, or a `vkVector` Value for
  ##   element-wise exponentiation.
  ##
  ## Raises:
  ## - InvalidOperationError for unsupported operand kinds
  ## - ArithmeticError variants (wrapped via `captureNumericError`) for numeric issues
  if a.kind == vkNumber and b.kind == vkNumber:
    return newValue(a.number ^ b.number)
  elif a.kind == vkVector and b.kind == vkNumber:
    let va = a.vector
    result = Value(kind: vkVector, vector: applyScalarOpRight(`^`, va, b))
  else:
    raise newInvalidOperationError("exponentiation", "vector", $b.kind)

proc `+=`*(a: var Value, b: Value) {.inline.} =
  ## In-place addition alias (a += b).
  ##
  ## This simply reassigns `a` to the result of `a + b` and preserves the
  ## same semantics and error handling as `+`.
  a = a + b

# ----- Unary Arithmetic operations -----
proc `-`*(a: Value): Value {.inline, captureNumericError.} =
  ## Numeric negation (unary minus).
  ##
  ## Parameters:
  ## - a: the Value to negate. If `vkNumber`, returns the numeric negative.
  ##   If `vkVector`, returns a vector with each element negated.
  ##
  ## Returns:
  ## - A new `Value` holding the negated number or a `vkVector` with element-wise negation.
  ##
  ## Raises:
  ## - TypeError / InvalidOperationError: if `a` is not a number or vector.
  ## - ArithmeticError (wrapped by `captureNumericError`): for numeric errors (division by zero,
  ##   complex-related errors, etc.) that may occur during numeric operations.
  if a.kind == vkNumber:
    return newValue(-a.number)
  elif a.kind == vkVector:
    # Element-wise negation of vector
    let va = a.vector
    result = Value(kind: vkVector, vector: applyScalarOp(`-`, newValue(0), va))
  else:
    raise newInvalidOperationError("negation", $a.kind, "")

# ----- logical operations -----
proc `not`*(a: Value): Value {.inline.} =
  ## Logical NOT for boolean Values.
  ##
  ## Parameters:
  ## - a: the Value to invert. Must be of kind `vkBool`.
  ##
  ## Returns:
  ## - A new `Value` of kind `vkBool` containing the logical negation of `a`.
  ##
  ## Raises:
  ## - TypeError: if `a` is not a boolean Value.
  if a.kind != vkBool:
    raise newTypeError(
      "Cannot negate a non-boolean value, expected: bool but got: " & $a.kind
    )
  result = newValue(not a.boolean)

template `and`*(a, b: Value): Value =
  ## Compute the logical AND of two boolean values
  ##
  ## Parameters:
  ## - a: first boolean value
  ## - b: second boolean value
  ##
  ## Returns:
  ## - a new Value object with the result of the logical AND
  ##
  ## Raises:
  ## - TypeError: if any operand is not a boolean
  let left = a
  if left.kind != vkBool:
    raise newTypeError("Cannot perform logical AND on non-boolean values")
  if not left.boolean:
    newValue(false)
  else:
    let right = b
    if right.kind != vkBool:
      raise newTypeError("Cannot perform logical AND on non-boolean values")
    newValue(right.boolean)

template `or`*(a, b: Value): Value =
  ## Compute the logical OR of two boolean values
  ##
  ## Parameters:
  ## - a: first boolean value
  ## - b: second boolean value
  ##
  ## Returns:
  ## - a new Value object with the result of the logical OR
  ##
  ## Raises:
  ## - TypeError: if any operand is not a boolean
  let left = a
  if left.kind != vkBool:
    raise newTypeError("Cannot perform logical OR on non-boolean values")
  if left.boolean:
    newValue(true)
  else:
    let right = b
    if right.kind != vkBool:
      raise newTypeError("Cannot perform logical OR on non-boolean values")
    newValue(right.boolean)

# ----- Comparison operations -----

proc `<`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Numeric less-than comparison.
  ##
  ## Parameters:
  ## - a, b: Values to compare. Only numeric Values (`vkNumber`) are supported
  ##   for the default `<` operator.
  ##
  ## Returns:
  ## - A `vkBool` Value containing true if `a` is strictly less than `b`, false
  ##   otherwise.
  ##
  ## Raises:
  ## - TypeError: when operands are not numbers.
  ## - InvalidOperationError / ArithmeticError variants when numeric comparison
  ##   cannot be performed (e.g. complex comparisons) — these are normalized by
  ##   the `captureNumericError` macro.
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.number < b.number)
  else:
    raise newTypeError("'<' operands are not numbers")

proc `<=`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Numeric less-than-or-equal comparison.
  ##
  ## Parameters:
  ## - a, b: Values to compare; only `vkNumber` values are supported by the
  ##   default `<=` operator.
  ##
  ## Returns:
  ## - A `vkBool` Value set to true when `a` is less than or equal to `b`.
  ##
  ## Raises:
  ## - TypeError when operands are not numbers.
  ## - Numeric/InvalidOperation errors are wrapped by `captureNumericError`.
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.number <= b.number)
  else:
    raise newTypeError("'<=' operands are not numbers")

proc `>`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Numeric greater-than comparison.
  ##
  ## Parameters:
  ## - a, b: Values to compare. Default `>` supports only `vkNumber` values.
  ##
  ## Returns:
  ## - A `vkBool` Value indicating if `a` is greater than `b`.
  ##
  ## Raises:
  ## - TypeError when operands are not numeric.
  ## - Numeric errors normalized by `captureNumericError` (e.g. complex comparisons).
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.number > b.number)
  else:
    raise newTypeError("'>' operands are not numbers")

proc `>=`*(a, b: Value): Value {.inline, captureNumericError.} =
  ## Numeric greater-than-or-equal comparison.
  ##
  ## Parameters:
  ## - a, b: Values to compare; default implementation supports `vkNumber` only.
  ##
  ## Returns:
  ## - A `vkBool` Value set to true when `a` is greater than or equal to `b`.
  ##
  ## Raises:
  ## - TypeError for non-numeric operands.
  ## - Numeric/InvalidOperation errors are wrapped by `captureNumericError`.
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.number >= b.number)
  else:
    raise newTypeError("'>=' operands are not numbers")

template `!=`*(a, b: Value): Value =
  ## Inequality operator: returns the logical negation of `==`.
  ##
  ## Parameters:
  ## - a, b: Values to compare. Uses the same dispatch and comparisons as `==`.
  ##
  ## Returns:
  ## - A `vkBool` Value containing true when `a` and `b` are not equal.
  ##
  ## Raises:
  ## - Same errors as `==` (e.g. ArithmeticError when number comparisons fail).
  not (a == b)

proc `==`*(a, b: Value): Value {.inline.} =
  ## Equality comparison between Values.
  ##
  ## Behavior:
  ## - Numbers: numeric equality using underlying `Number` equality.
  ## - Vectors: equal if same size and all corresponding elements are equal.
  ## - Types: equal when the `BMathType` values are equal.
  ## - Bool, String, Native function: direct content or pointer equality as
  ##   appropriate.
  ## - All other combinations return false.
  ##
  ## Parameters:
  ## - a, b: Values to compare.
  ##
  ## Returns:
  ## - A `vkBool` Value set to true when values are considered equal according
  ##   to the rules above, otherwise false.
  ##
  ## Raises:
  ## - ArithmeticError: when numeric comparisons encounter numeric errors; these
  ##   are surfaced via the `captureNumericError` macro where numeric ops are used.
  if a.kind == vkNumber and b.kind == vkNumber:
    result = newValue(a.number == b.number)
  elif a.kind == vkVector and b.kind == vkVector:
    if a.vector.size != b.vector.size:
      result = newValue(false)
    else:
      var eq = true
      for i in 0 ..< a.vector.size:
        if (a.vector[i] != b.vector[i]).boolean:
          eq = false
          break
      result = newValue(eq)
  elif a.kind == vkType and b.kind == vkType:
    result = newValue(a.typ == b.typ)
  elif a.kind == vkBool and b.kind == vkBool:
    result = newValue(a.boolean == b.boolean)
  elif a.kind == vkNativeFunc and b.kind == vkNativeFunc:
    result = newValue(a.nativeFn == b.nativeFn)
  elif a.kind == vkString and b.kind == vkString:
    result = newValue(a.content == b.content)
  else:
    result = newValue(false)

when defined(showSize):
  static:
    echo "Value type size analysis:"
    echo "└─ Size of Value: ", sizeof(Value), " bytes"
    echo "   ├─ Base size (kind discriminator): ", sizeof(ValueKind), " bytes"
    echo "   ├─ vkNumber variant"
    echo "   │  └─ Number component: ", sizeof(Number), " bytes"
    echo "   ├─ vkBool variant"
    echo "   │  └─ Bool component: ", sizeof(bool), " bytes"
    echo "   ├─ vkNativeFunc variant"
    echo "   │  ├─ NativeFn whole: ", sizeof(NativeFn), " bytes"
    echo "   │  ├─  - callable (proc type): ",
      sizeof(proc(args: openArray[Value], invoker: FnInvoker): Value), " bytes"
    echo "   │  └─  - signatures (seq[Signature]): ",
      sizeof(seq[Signature]), " bytes"
    echo "   ├─ vkFunction variant"
    echo "   │  ├─ Function ref size: ", sizeof(ref Function), " bytes"
    echo "   │  └─  Function fields:"
    echo "   │     - body (ref Expression): ", sizeof(ref Expression), " bytes"
    echo "   │     - env (ref Environment): ", sizeof(ref Environment), " bytes"
    echo "   │     - params (seq[Parameter]): ", sizeof(seq[Parameter]), " bytes"
    echo "   │     - signature (Signature): ", sizeof(Signature), " bytes"
    echo "   │       - Signature.params (seq[Parameter]): ",
      sizeof(seq[Parameter]), " bytes"
    echo "   │       - Signature.returnType (BMathType): ",
      sizeof(BMathType), " bytes"
    echo "   ├─ vkVector variant"
    echo "   │  └─ Vector ref size: ", sizeof(Vector[Value]), " bytes"
    echo "   ├─ vkSeq variant"
    echo "   │  ├─ Sequence ref size: ", sizeof(ref Sequence), " bytes"
    echo "   │  ├─  - Generator: ", sizeof(Generator), " bytes"
    echo "   │  │    - atEnd (proc): ", sizeof(proc(): bool), " bytes"
    echo "   │  │    - next (proc): ", sizeof(proc(peek: bool): Value), " bytes"
    echo "   │  └─  - Transformer (seq): ", sizeof(seq[Transformer]), " bytes"
    echo "   │       - Transformer size: ", sizeof(Transformer), " bytes"
    echo "   │         - kind (TransformerKind): ", sizeof(TransformerKind), " bytes"
    echo "   │         - fun (proc): ", sizeof(proc(x: Value): Value), " bytes"
    echo "   ├─ vkType variant"
    echo "   │  ├─ BMathType whole: ", sizeof(BMathType), " bytes"
    echo "   │  ├─  - simple type enum: ", sizeof(BMathSimpleType), " bytes"
    echo "   │  ├─  - sum types set: ", sizeof(HashSet[BMathSimpleType]), " bytes"
    echo "   │  └─  - error cstring: ", sizeof(cstring), " bytes"
    echo "   ├─ vkString variant"
    echo "   │  └─ string component: ", sizeof(string), " bytes"
    echo "   └─ vkError variant"
    echo "      └─ error component (string): ", sizeof(string), " bytes"
