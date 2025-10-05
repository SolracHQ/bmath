<!-- Auto-generated from stdlib_signatures.json - DO NOT EDIT MANUALLY -->
<!-- Version: 0.12.0 -->

# BMath Standard Library Reference

Complete reference documentation for all BMath standard library functions.

## Table of Contents

- [Core Functions](#core-functions)
- [Arithmetic](#arithmetic)
- [Trigonometric](#trigonometric)
- [Vector Operations](#vector-operations)
- [Sequence Operations](#sequence-operations)
- [Functional](#functional)
- [Comparison](#comparison)
- [Assertions](#assertions)
- [Type System](#type-system)

---
## Core Functions

### `exit`

Exits the program with an optional exit code

**Signature:**

```bmath
|code?: Int| -> Any
```

**Parameters:**

- `code: Int` (optional): Exit code (defaults to 0)

**Returns:** `Any`

---

### `try_or`

Executes a function and returns its result, or a default value if an exception occurs

**Signature:**

```bmath
|fn: Function, default: Any| -> Any
```

**Parameters:**

- `fn: Function`: Function to try executing
- `default: Any`: Default value to return on error

**Returns:** `Any`

---

### `try_catch`

Executes a function and returns its result, or passes the exception to a handler function

**Signature:**

```bmath
|fn: Function, handler: Function| -> Any
```

**Parameters:**

- `fn: Function`: Function to try executing
- `handler: Function`: Handler function that receives error

**Returns:** `Any`

---

### `print`

Prints any number of values separated by a single space

**Signature:**

```bmath
|...values: Any| -> Any | Vec
```

**Parameters:**

- `values: Any` (variadic): Values to print

**Returns:** `Any | Vec`

---

### `help`

Display help information for a function or value

**Signature:**

```bmath
|value?: Any| -> String
```

**Parameters:**

- `value: Any` (optional): Function or value to get help for

**Returns:** `String`

**Examples:**

```bm
help(sqrt)
```

```bm
help(print)
```

```bm
help(map)
```

---

## Arithmetic

### `pow`

Raise base to exponent power

**Signature:**

```bmath
|base: Number, exp: Number| -> Number
```

**Returns:** `Number`

---

### `sqrt`

Square root of a number

**Signature:**

```bmath
|a: Number| -> Number
```

**Parameters:**

- `a: Number`: Value to take the square root of

**Returns:** `Number`

---

### `abs`

Absolute value of a number

**Signature:**

```bmath
|a: Number| -> Number
```

**Parameters:**

- `a: Number`: Value to take the absolute value of

**Returns:** `Number`

---

### `floor`

Round down to nearest integer

**Signature:**

```bmath
|a: Int | Real| -> Int
```

**Returns:** `Int`

---

### `ceil`

Round up to nearest integer

**Signature:**

```bmath
|a: Int | Real| -> Int
```

**Returns:** `Int`

---

### `round`

Round to nearest integer

**Signature:**

```bmath
|a: Int | Real| -> Int
```

**Returns:** `Int`

---

### `re`

Real part of a complex number

**Signature:**

```bmath
|a: Number| -> Real
```

**Returns:** `Real`

---

### `im`

Imaginary part of a complex number

**Signature:**

```bmath
|a: Number| -> Real
```

**Returns:** `Real`

---

## Trigonometric

### `sin`

Sine trigonometric function

**Signatures:**

```bmath
|a: Number| -> Number
```

**Returns:** `Number`

```bmath
|a: Vec| -> Vec
```

**Returns:** `Vec`

---

### `cos`

Cosine trigonometric function

**Signatures:**

```bmath
|a: Number| -> Number
```

**Returns:** `Number`

```bmath
|a: Vec| -> Vec
```

**Returns:** `Vec`

---

### `tan`

Tangent trigonometric function

**Signatures:**

```bmath
|a: Number| -> Number
```

**Returns:** `Number`

```bmath
|a: Vec| -> Vec
```

**Returns:** `Vec`

---

### `cot`

Cotangent trigonometric function

**Signatures:**

```bmath
|a: Number| -> Number
```

**Returns:** `Number`

```bmath
|a: Vec| -> Vec
```

**Returns:** `Vec`

---

### `sec`

Secant trigonometric function

**Signatures:**

```bmath
|a: Number| -> Number
```

**Returns:** `Number`

```bmath
|a: Vec| -> Vec
```

**Returns:** `Vec`

---

### `csc`

Cosecant trigonometric function

**Signatures:**

```bmath
|a: Number| -> Number
```

**Returns:** `Number`

```bmath
|a: Vec| -> Vec
```

**Returns:** `Vec`

---

### `log`

Logarithm with optional base

**Signatures:**

```bmath
|a: Number, base: Number| -> Number
```

**Returns:** `Number`

```bmath
|a: Vec, base: Number| -> Vec
```

**Returns:** `Vec`

---

### `exp`

Exponential function (e^x)

**Signatures:**

```bmath
|a: Number| -> Number
```

**Returns:** `Number`

```bmath
|a: Vec| -> Vec
```

**Returns:** `Vec`

---

## Vector Operations

### `vec`

Create a vector of specified length

**Signature:**

```bmath
|length: Int, fn_or_value: Any| -> Vec
```

**Parameters:**

- `length: Int`: Length of the vector
- `fn_or_value: Any`: Function to apply to each index or value to repeat

**Returns:** `Vec`

---

### `dot`

Dot product of two vectors

**Signature:**

```bmath
|a: Vec, b: Vec| -> Number
```

**Returns:** `Number`

---

### `first`

First element of a vector

**Signature:**

```bmath
|vector: Vec| -> Any
```

**Returns:** `Any`

---

### `last`

Last element of a vector

**Signature:**

```bmath
|vector: Vec| -> Any
```

**Returns:** `Any`

---

### `len`

Length of a vector

**Signature:**

```bmath
|vector: Vec| -> Int
```

**Returns:** `Int`

---

### `merge`

Merge two vectors

**Signature:**

```bmath
|a: Vec, b: Vec| -> Vec
```

**Returns:** `Vec`

---

### `slice`

Extract a slice from a vector

**Signatures:**

```bmath
|vector: Vec, end: Int| -> Vec
```

**Parameters:**

- `end: Int`: End index (when only 2 args)

**Returns:** `Vec`

```bmath
|vector: Vec, start: Int, end: Int| -> Vec
```

**Parameters:**

- `start: Int`: Start index
- `end: Int`: End index

**Returns:** `Vec`

---

### `set`

Set an element in a vector

**Signature:**

```bmath
|vector: Vec, index: Int, value: Any| -> Vec
```

**Returns:** `Vec`

---

## Sequence Operations

### `seq`

Create a sequence

**Signatures:**

```bmath
|value_or_fn: Any| -> Seq
```

**Parameters:**

- `value_or_fn: Any`: Value for infinite sequence or function with counter

**Returns:** `Seq`

```bmath
|length: Int, fn: Function| -> Seq
```

**Parameters:**

- `length: Int`: Length of finite sequence
- `fn: Function`: Function to generate values

**Returns:** `Seq`

---

### `skip`

Skip n elements from a sequence

**Signature:**

```bmath
|sequence: Seq, n: Int| -> Seq
```

**Returns:** `Seq`

---

### `take`

Take first n elements from a sequence

**Signature:**

```bmath
|sequence: Seq, n: Int| -> Seq
```

**Returns:** `Seq`

---

### `has_next`

Check if sequence has more elements

**Signature:**

```bmath
|sequence: Seq| -> Bool
```

**Returns:** `Bool`

---

### `next`

Get next element from sequence

**Signature:**

```bmath
|sequence: Seq| -> Any
```

**Returns:** `Any`

---

### `collect`

Collect all elements from a sequence into a vector

**Signature:**

```bmath
|s: Seq| -> Vec
```

**Returns:** `Vec`

---

### `zip`

Zip two sequences together

**Signature:**

```bmath
|seq1: Seq, seq2: Seq| -> Seq
```

**Returns:** `Seq`

---

## Functional

### `map`

Apply a function to each element of a collection

**Signatures:**

```bmath
|collection: Vec, fn: Function| -> Vec
```

**Parameters:**

- `collection: Vec`: Vector to map over
- `fn: Function`: Function to apply to each element

**Returns:** `Vec`

```bmath
|collection: Seq, fn: Function| -> Seq
```

**Parameters:**

- `collection: Seq`: Sequence to map over
- `fn: Function`: Function to apply to each element

**Returns:** `Seq`

---

### `filter`

Filter elements by predicate function

**Signatures:**

```bmath
|collection: Vec, fn: Function| -> Seq
```

**Parameters:**

- `collection: Vec`: Vector to filter
- `fn: Function`: Predicate function

**Returns:** `Seq`

```bmath
|collection: Seq, fn: Function| -> Seq
```

**Parameters:**

- `collection: Seq`: Sequence to filter
- `fn: Function`: Predicate function

**Returns:** `Seq`

---

### `reduce`

Reduce collection with accumulator function

**Signatures:**

```bmath
|collection: Vec, initial: Any, fn: Function| -> Any
```

**Parameters:**

- `collection: Vec`: Vector to reduce
- `initial: Any`: Initial accumulator value
- `fn: Function`: Binary accumulator function

**Returns:** `Any`

```bmath
|collection: Seq, initial: Any, fn: Function| -> Any
```

**Parameters:**

- `collection: Seq`: Sequence to reduce
- `initial: Any`: Initial accumulator value
- `fn: Function`: Binary accumulator function

**Returns:** `Any`

---

### `sum`

Sum all numeric elements in a collection

**Signature:**

```bmath
|a: Vec | Seq| -> Number
```

**Returns:** `Number`

---

### `any`

Check if any element is truthy

**Signature:**

```bmath
|a: Vec | Seq| -> Bool
```

**Returns:** `Bool`

---

### `all`

Check if all elements are truthy

**Signature:**

```bmath
|a: Vec | Seq| -> Bool
```

**Returns:** `Bool`

---

### `nth`

Get nth element from a vector or sequence

**Signature:**

```bmath
|value: Vec | Seq, index: Int| -> Any
```

**Returns:** `Any`

---

### `at`

Alias for nth - get element at index

**Signature:**

```bmath
|sequence: Vec | Seq, index: Int| -> Any
```

**Returns:** `Any`

---

## Comparison

### `min`

Find minimum value from multiple arguments, vector, or sequence

**Signatures:**

```bmath
|...values: Any| -> Any
```

**Parameters:**

- `values: Any` (variadic): Values to compare

**Returns:** `Any`

```bmath
|collection: Vec | Seq| -> Any
```

**Parameters:**

- `collection: Vec | Seq`: Collection to find minimum in

**Returns:** `Any`

```bmath
|collection: Vec | Seq, compareFn: Function| -> Any
```

**Parameters:**

- `collection: Vec | Seq`: Collection to find minimum in
- `compareFn: Function`: Custom comparison function

**Returns:** `Any`

```bmath
|...values: Any| -> Any
```

**Parameters:**

- `values: Any` (variadic): Values to compare (last one is compare function)

**Returns:** `Any`

---

### `max`

Find maximum value from multiple arguments, vector, or sequence

**Signatures:**

```bmath
|...values: Any| -> Any
```

**Parameters:**

- `values: Any` (variadic): Values to compare

**Returns:** `Any`

```bmath
|collection: Vec | Seq| -> Any
```

**Parameters:**

- `collection: Vec | Seq`: Collection to find maximum in

**Returns:** `Any`

```bmath
|collection: Vec | Seq, compareFn: Function| -> Any
```

**Parameters:**

- `collection: Vec | Seq`: Collection to find maximum in
- `compareFn: Function`: Custom comparison function

**Returns:** `Any`

```bmath
|...values: Any| -> Any
```

**Parameters:**

- `values: Any` (variadic): Values to compare (last one is compare function)

**Returns:** `Any`

---

## Assertions

### `assert`

Assert condition is true

**Signature:**

```bmath
|condition: Bool, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Parameters:**

- `condition: Bool`: Condition to check
- `failureMessage: String` (optional): Message to display on failure
- `successMessage: String` (optional): Message to return on success

**Returns:** `Bool | String`

---

### `assert_eq`

Assert two values are equal

**Signature:**

```bmath
|expected: Any, actual: Any, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Returns:** `Bool | String`

---

### `assert_neq`

Assert two values are not equal

**Signature:**

```bmath
|first: Any, second: Any, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Returns:** `Bool | String`

---

### `assert_lt`

Assert first value is less than second

**Signature:**

```bmath
|a: Any, b: Any, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Returns:** `Bool | String`

---

### `assert_gt`

Assert first value is greater than second

**Signature:**

```bmath
|a: Any, b: Any, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Returns:** `Bool | String`

---

### `assert_type`

Assert value has expected type

**Signature:**

```bmath
|value: Any, expected_type: Type, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Returns:** `Bool | String`

---

### `assert_error`

Assert function throws an error

**Signature:**

```bmath
|fn: Function, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Returns:** `Bool | String`

---

## Type System

### `type`

Get the type of a value

**Signature:**

```bmath
|value: Any| -> Type
```

**Returns:** `Type`

---

