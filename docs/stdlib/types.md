# BMath Type System and Functions

BMath features a rich type system that supports both simple types and type compositions. This document details the available types and type-related operations.

## Type Hierarchy

### Simple Types
- `integer`: Whole number values (e.g., `42`, `-7`)
- `real`: Floating-point numbers (e.g., `3.14`, `-0.5`)
- `complex`: Complex numbers with real and imaginary components (e.g., `3i`, `4+2i`)
- `boolean`: Logic values (`true` or `false`)
- `vector`: Eager collections of values (e.g., `[1, 2, 3]`)
- `sequence`: Lazy collections of values 
- `function`: First-class callable values
- `type`: Type values themselves

### Special Types
- `any`: The union of all types (matches any value)
- `number`: The union of integer, real, and complex types
- `error`: Special type representing runtime errors

## Type Functions

### type(value)

Returns the type of the given value.

**Parameters:**
- `value`: Any BMath value

**Returns:**
- A type value representing the type of the input

**Examples:**
```
type(5)         # Returns integer
type(3.14)      # Returns real
type([1, 2, 3]) # Returns vector
type(|x| x + 1) # Returns function
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
42 -> real       # Converts integer 42 to real (42.0)
3.14 -> integer  # Converts real 3.14 to integer (3)
[1, 2, 3] -> sequence  # Converts a vector to a sequence
```

### Function-Style Casting

Uses a type name as a function:

```
real(42)         # Same as 42 -> real
integer(3.14)    # Same as 3.14 -> integer 
sequence([1, 2]) # Same as [1, 2] -> sequence
```

## Type Conversion Rules

### Numeric Conversions

| From       | To         | Behavior                             | Example          |
|------------|------------|--------------------------------------|------------------|
| `integer`  | `real`     | Preserves numeric value              | `5 -> real` → 5.0 |
| `integer`  | `complex`  | Creates complex with zero imaginary  | `5 -> complex` → 5+0i |
| `real`     | `integer`  | Truncates decimal portion            | `5.7 -> integer` → 5 |
| `real`     | `complex`  | Creates complex with zero imaginary  | `5.7 -> complex` → 5.7+0i |
| `complex`  | `real`     | Extracts real part if im=0 or error  | `(5+0i) -> real` → 5.0 |
| `complex`  | `integer`  | Real part to int if im=0 or error    | `(5+0i) -> integer` → 5 |

### Collection Conversions

| From       | To         | Behavior                             | Example          |
|------------|------------|--------------------------------------|------------------|
| `vector`   | `sequence` | Creates a lazy sequence from vector  | `[1,2] -> sequence` |
| `sequence` | `vector`   | Evaluates and collects all elements  | `seq -> vector` (like `collect()`) |

### Other Conversions

- Converting to `type` returns the type of the value
- Converting to `boolean` only works with boolean values
- Converting to `function` only works with function values

## Error Handling in Type Conversions

When a type conversion cannot be performed, an `InvalidArgumentError` is raised:

```
false -> integer  # Raises InvalidArgumentError
true -> real        # Raises InvalidArgumentError
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

```
5 is number      # true (integer is a subtype of number)
5 is integer     # true
5 is real        # false
5 is any         # true (all values match any)
```
