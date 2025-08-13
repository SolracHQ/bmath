# BMath Language Manual

Welcome to the BMath Language Manual! This guide introduces the BMath CLI language, its philosophy, syntax, features, and practical usage. It is designed for both beginners and advanced users.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Language Basics](#language-basics)
4. [Type System](#type-system)
5. [Operators & Functions](#operators--functions)
6. [Vectors & Sequences](#vectors--sequences)
7. [Functional Programming](#functional-programming)
8. [Advanced Features](#advanced-features)
9. [Error Handling](#error-handling)
10. [Examples](#examples)
11. [Reference & Further Reading](#reference--further-reading)

---

## Introduction

BMath is a mathematical command-line language designed for expression-oriented, consistent, and powerful numerical computation. Every construct is an expression, and functions are first-class citizens. The language supports both eager (vectors) and lazy (sequences) evaluation.

## Getting Started

### Installation

Clone and build BMath with:

```bash
git clone https://github.com/solrachq/bmath
cd bmath
nimble build -d:release
```

The binary will be available in `bin/bm`.

### Running

Start the CLI with:

```bash
./bin/bm
```

### Basic Usage

You can evaluate expressions directly:

```bm
x = 42
y = 3.14
z = x + y
print(z)
```

## Language Basics

- **Variables:** Assignment with `=`
- **Blocks:** Group expressions with `{ ... }`
- **If Expressions:**

  ```bm
  abs = |x| if(x >= 0) x else -x
  ```

- **Comments:** Use `#` for single-line comments
- **Multi-line:** Use `\` for line continuation

## Type System

 BMath supports a rich type system, but types are optional in most places. You can write scripts without specifying types, and the language will infer them at runtime. This makes prototyping and quick calculations easy.

### Supported Types

- `integer`, `real`, `complex`, `boolean`, `vector`, `sequence`, `function`, `type`, `any`

### Type Checking and Future Plans

 Currently, type errors are only detected at runtime. In the future, BMath will include an optional static type checker for scripts, helping you catch type errors before execution and making your code safer and more robust.

### Type Features

- **Type Checking:**

   ```bm
   type(5)         # Returns: integer
   type([1,2,3])   # Returns: vector
   value is real   # Returns: true if value is a real number
   ```

- **Type Conversion (Casting):**
   You can cast values using either the arrow operator or function-style:

   ```bm
   42 -> real       # Converts integer 42 to real (42.0)
   real(42)         # Same as above
   [1,2,3] -> sequence  # Converts a vector to a sequence
   sequence([1,2,3])    # Same as above
   ```

- **Type Annotations (Optional):**
   You can annotate function parameters with types, but it's not required:

   ```bm
   add = |a: integer, b: integer| a + b
   ```

- **'is' Keyword:**
   Use `is` to check if a value matches a type:

   ```bm
   x = 3.14
   x is real      # true
   x is integer   # false
   ```

 Type features make your code more expressive and will enable better error checking in the future.

## Operators & Functions

### Arithmetic Operators

| Operator | Description                | Example           | Scalar Behavior         | Vector Behavior                |
|----------|----------------------------|-------------------|------------------------|--------------------------------|
| +        | Addition                   | 3 + 4             | Adds numbers           | Element-wise addition          |
| -        | Subtraction/Negation       | 10 - 5, -x        | Subtracts/negates      | Element-wise subtraction       |
| *        | Multiplication             | 2 * 3             | Multiplies numbers     | Scalar-vector or element-wise  |
| /        | Division                   | 8 / 2             | Always returns float    | Scalar-vector division         |
| %        | Modulo                     | 17 % 5            | Remainder (int/float)  | Element-wise modulo            |
| ^        | Exponentiation             | 2 ^ 3              | Raises to power        | Element-wise power             |

#### Examples

```bm
[1, 2, 3] + [4, 5, 6]   # [5, 7, 9]
2 * [1, 2, 3]            # [2, 4, 6]
[1, 2, 3] ^ 2            # [1, 4, 9]
```

### Comparison Operators

| Operator | Description      | Example      | Notes |
|----------|------------------|-------------|-------|
| ==       | Equality         | 3 == 3.0    | Type promotion applies |
| !=       | Inequality       | 3 != 4      |       |
| <, <=    | Less/Equal       | 2 < 5       | Complex numbers not allowed |
| >, >=    | Greater/Equal    | 5 >= 5      | Complex numbers not allowed |

### Logical Operators

| Operator | Description      | Example      | Accepted Types |
|----------|------------------|-------------|---------------|
| !        | Not              | !true       | Boolean       |
| &        | And              | true & false| Boolean       |
| \|        | Or               | true \| false| Boolean       |

### Built-in Functions

| Function   | Description                        | Example                  | Scalar | Vector | Sequence |
|------------|------------------------------------|--------------------------|--------|--------|----------|
| sqrt       | Square root                        | sqrt(16)                 | Yes    | Yes    | Yes      |
| pow        | Power                              | pow(2, 3)                | Yes    | Yes    | Yes      |
| abs        | Absolute value                     | abs(-5)                  | Yes    | Yes    | Yes      |
| floor      | Floor                              | floor(3.8)               | Yes    | Yes    | Yes      |
| ceil       | Ceiling                            | ceil(3.2)                | Yes    | Yes    | Yes      |
| round      | Round                              | round(3.5)               | Yes    | Yes    | Yes      |
| sin, cos   | Trigonometric                      | sin(pi/2)                | Yes    | Yes    | Yes      |
| log, exp   | Logarithm, exponential             | log(100, 10), exp(1)     | Yes    | Yes    | Yes      |
| min, max   | Minimum/maximum                    | min(1,2,3), max([1,2,3]) | Yes    | Yes    | Yes      |
| print      | Print value                        | print(x)                 | Yes    | Yes    | Yes      |
| exit       | Exit program                       | exit(1)                  | Yes    |        |          |
| try_or     | Try with default                   | try_or(\|\| risky(), 0)    | Yes    |        |          |
| try_catch  | Try with error handler             | try_catch(\|\| f(), \|e\| g)| Yes    |        |          |

#### Function Behavior by Type

- Most functions operate on scalars, vectors, and sequences. For vectors, operations are element-wise. For sequences, operations are lazy and may require collection.

#### More Examples

```bm
sqrt([4, 9, 16])         # [2, 3, 4]
abs([-1, -2, 3])         # [1, 2, 3]
min([5, 2, 8])           # 2
max(seq(10, |i| i^2))    # 81
print([1,2,3])           # prints vector
```

---

## Control Flow

BMath supports expression-oriented control flow:

### If / Elif / Else

```bm
sign = |x| if(x > 0) 1 elif(x < 0) -1 else 0
result = if(a > b) a else b
```

### Blocks

Group multiple expressions; last value is returned.

```bm
blockResult = {
  a = 5
  b = 7
  a * b   # Returns 35
}
```

### Local Variables

```bm
outer = 10
localExample = {
  local outer = 20
  outer * 2   # Uses local value (40)
}
# outer is still 10 here
```

### Multi-line Expressions

Use `\` for line continuation:

```bm
longExpr = 1 + 2 + 3 + \
           4 + 5 + 6
```

---

## Vectors & Sequences

- **Vectors:**

  ```bm
  v = [1, 2, 3]
  v2 = vec(5, |i| i^2)
  v->len
  v->map(|x| x*2)
  ```

- **Sequences:**

  ```bm
  s = seq(5, |i| i)
  s->collect
  s->skip(2)
  s->take(3)
  ```

## Functional Programming

- **Lambdas:** `|x| x*2`
- **Higher-order:** `map`, `filter`, `reduce`, `sum`, `any`, `all`
- **Partial Application & Composition:**

  ```bm
  add = |a, b| a + b
  addTo5 = |y| add(5, y)
  doubleThenAdd = |x| (|y| y+5)((|z| z*2)(x))
  ```

## Advanced Features

- **Complex Numbers:** `3 + 4i`, `sqrt(-1)`
- **Constants:** `pi`, `e`, `i`
- **Recursion:**

  ```bm
  factorial = |n| if(n <= 1) 1 else n * factorial(n-1)
  ```

- **Closures:** Functions capture their environment

## Error Handling

- **try_or:**

  ```bm
  result = try_or(|| risky(), default)
  ```

- **try_catch:**

  ```bm
  result = try_catch(|| risky(), |err| handle(err))
  ```

## Examples

See the `examples/` folder for:

- Basic usage
- Arithmetic
- Functions
- Sequences
- Vectors
- Trigonometric
- Advanced math

## Reference & Further Reading

- [Standard Library Documentation](./stdlib.md)
- [Design Document](./design.md)
- [Standard Library Index](./stdlib/index.md)

---

This manual is a living document. For deeper details, see the reference docs and examples.
