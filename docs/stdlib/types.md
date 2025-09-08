# BMath Type System and Functions

BMath features a rich type system that supports both simple types and type compositions. This document details the available types and type-related operations.

## Type Hierarchy

### Simple Types

- `Int`: Whole number values (e.g., `42`, `-7`)
- `Real`: Floating-point numbers (e.g., `3.14`, `-0.5`)
- `Complex`: Complex numbers with real and imaginary components (e.g., `3i`, `4+2i`)
- `Bool`: Logic values (`true` or `false`)
- `Vec`: Eager collections of values (e.g., `[1, 2, 3]`)
- `Seq`: Lazy collections of values
- `Function`: First-class callable values
- `Type`: Type values themselves

### Special Types

- `Any`: The union of all types (matches any value)
- `Number`: The union of Int, Real, and Complex types
- `Error`: Special type representing runtime errors

## Type Functions

### type(value)

Returns the type of the given value.

**Parameters:**

- `value`: Any BMath value

**Returns:**

- A type value representing the type of the input

**Examples:**

```
type(5)         # Returns Int
type(3.14)      # Returns Real
type([1, 2, 3]) # Returns Vec
type(|x| x + 1) # Returns Function
```

### Type Checking

To check if a value is of a specific type:

```
value is integer     # Checks if value is an integer
type(value) == real  # Checks if value is a real number
```

## Type Conversion

BMath supports two syntactically equivalent methods for type conversion:

### Arrow Operator Casting

Uses the arrow operator (`->`) followed by a type:

```
42 -> Real       # Converts Int 42 to Real (42.0)
3.14 -> Int      # Converts Real 3.14 to Int (3)
[1, 2, 3] -> Seq # Converts a Vec to a Seq
```

### Function-Style Casting

Uses a type name as a function:

```
Real(42)         # Same as 42 -> Real
Int(3.14)        # Same as 3.14 -> Int
Seq([1, 2])      # Same as [1, 2] -> Seq
```

## Type Conversion Rules

### Numeric Conversions

| From       | To         | Behavior                             | Example          |
|------------|------------|--------------------------------------|------------------|
| `Int`      | `Real`     | Preserves numeric value              | `5 -> Real` → 5.0 |
| `Int`      | `Complex`  | Creates Complex with zero imaginary  | `5 -> Complex` → 5+0i |
| `Real`     | `Int`      | Truncates decimal portion            | `5.7 -> Int` → 5 |
| `Real`     | `Complex`  | Creates Complex with zero imaginary  | `5.7 -> Complex` → 5.7+0i |
| `Complex`  | `Real`     | Extracts real part if im=0 or error  | `(5+0i) -> Real` → 5.0 |
| `Complex`  | `Int`      | Real part to Int if im=0 or error    | `(5+0i) -> Int` → 5 |

### Collection Conversions

| From       | To         | Behavior                             | Example          |
|------------|------------|--------------------------------------|------------------|
| `Vec`      | `Seq`      | Creates a lazy Seq from Vec          | `[1,2] -> Seq` |
| `Seq`      | `Vec`      | Evaluates and collects all elements  | `seq -> Vec` (like `collect()`) |

### Other Conversions

- Converting to `type` returns the type of the value
- Converting to `boolean` only works with boolean values
- Converting to `function` only works with function values

## Error Handling in Type Conversions

When a type conversion cannot be performed, an `InvalidArgumentError` is raised:

```
false -> Int  # Raises InvalidArgumentError
true -> Real  # Raises InvalidArgumentError
```

Use the `try_or` or `try_catch` functions to handle potential conversion errors:

```
safe_int = try_or(|| false -> integer, 0)  # Returns 0 as fallback

result = try_catch(
  || complex_num -> real,
  |error| handle_conversion_error(error)
)
```

## Type Compatibility

The `is` operator checks if a value matches a type:

```bm
5 is Number      # true (Int is a subtype of Number)
5 is Int         # true
5 is Real        # false
5 is Any         # true (all values match Any)
```
