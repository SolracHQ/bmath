# Language Constructs and Design Notes

This file explains the language constructs of BMath at a design level. It focuses on intended semantics and usage rather than implementation details.

## Overview

BMath is expression-oriented: every construct produces a value. The language focuses on mathematical operations and numerical computation while aiming for a simple, consistent syntax. There are no void or nil values — every expression evaluates to something concrete.

The interpreter processes one expression at a time but can handle multiple expressions in sequence. Functions are first-class and can be defined inline with optional parameters. Collections support both eager (vectors) and lazy (sequences) evaluation strategies.

## Block Expressions

Blocks are delimited by `{` and `}`. They evaluate each contained expression in order and return the value of the last expression in the block. Blocks create a new lexical scope. Use blocks to group multi-expression computations, create temporary variables, and control scope lifetimes.

Example:

```bmath
result = { 
  a = 5
  b = 7
  a * b  # block value is 35
}
```

Blocks can appear anywhere a primary expression is allowed and can be used to delay evaluation or encapsulate side effects. Empty blocks are not permitted — every block must contain at least one expression.

## If Expressions

If expressions always evaluate to a value. An `if(condition)` is followed by an expression to evaluate when true, optional `elif(condition)` clauses, and a required `else` expression. This design ensures every branch produces a value and eliminates null-like fallthrough behavior.

Example:

```bmath
value = if(x > 0) 
          x * 2
        elif(x < 0) 
          x * -1
        else 0
```

The conditional expression can be used anywhere a value is expected, making it composable with other language constructs.

## Functions

Functions are first-class and expressed as lambda-like expressions. They create their own lexical environment and can access outer scope variables through the closure capture mechanism. Parameters are optional; functions with no parameters are allowed.

Examples:

```bmath
square = |x| x * x
add = |a, b| a + b
getNextValue = || counter! = counter! + 1
```

### Closure Capture

Functions create isolated scopes by default. To access variables from outer scopes, use the closure capture operator `!`:

```bmath
counter = 0
increment = || counter! = counter! + 1

# counter! creates a mutable reference to the outer counter variable
# allowing the function to modify the outer scope
```

Without the capture operator, functions cannot access outer scope variables, ensuring predictable scoping behavior.

## Chain Expressions (Arrow Operator)

The arrow operator `->` supports readable pipelines by forwarding the left-hand expression as the first argument to the right-hand function. This enables fluent chaining without nested parentheses and encourages point-free style where helpful.

Examples:

```bmath
# Simple chaining
[1, 2, 3, 4]->filter(|n| n % 2 == 0)  # equivalent to filter([1,2,3,4], |n| n % 2 == 0)

# Multi-step pipeline
[1, 2, 3, 4] 
  -> filter(|n| n % 2 == 0) 
  -> map(|n| n^2) 
  -> sum()

# Chain with additional arguments
data->reduce(|acc, x| acc + x, 0)  # equivalent to reduce(data, |acc, x| acc + x, 0)
```

Design note: chaining is syntactic sugar; semantics match the equivalent explicit function calls. The chain operator has high precedence, so `a + b->f()` parses as `a + (b->f())`.

## Modules and `use`

Modules are defined with `mod { ... }` or `mod identifier { ... }`. A `mod` expression evaluates to the module value. When an identifier is provided, `mod identifier { ... }` is syntactic sugar for `identifier = mod { ... }`, binding the module to the given name.

Examples:

```bmath
# Anonymous module
mathUtils = mod {
  pi = 3.14159
  square = |x| x * x
  area = |r| pi * square(r)
}

# Named module (syntactic sugar)
mod mathUtils {
  pi = 3.14159
  square = |x| x * x
  area = |r| pi * square(r)
}
```

### Module Usage

The `use` instruction loads and returns a module value. `use` takes a parenthesized target expression which describes what to import. The language provides convenient automatic binding for module member imports to improve developer experience while maintaining the expression-oriented design.

#### Basic `use` forms

```bmath
# Load module from file
math = use("path/to/module")

# Load and auto-bind specific member
use(math::sin)  # creates binding: sin = math::sin

# Load and auto-bind multiple members
use(math::{sin, cos, pi})  # creates: sin = math::sin, cos = math::cos, pi = math::pi

# Load module with explicit alias
myMath = use("math") as myMath  # equivalent to: myMath = use("math")
```

#### Advanced `use` patterns

```bmath
# Nested module access
use(graphics::primitives::{Circle, Rectangle})

# Mixed aliasing and destructuring
use(utils::{helper as h, formatter::{json, xml as xmlFormat}})

# String path imports
use("./local/module.bm")
use("std/collections")  # .bm extension inferred
```

The automatic binding behavior means that `use(std::PI)` creates a binding `PI = use(std::PI)`, making the PI constant available in the current scope without requiring explicit assignment.

### Module Member Access (`::`)

The `::` operator accesses members exported by a module value. It has high precedence and can be chained:

```bmath
# Simple access
value = math::pi

# Chained access
transform = graphics::primitives::transforms::rotate

# Access with function call
result = math::trig::sin(angle)
```

## Array Indexing

Arrays (vectors) support element access and assignment through the `[]` operator. Indexing is zero-based and supports negative indices for reverse access.

### Reading Elements

```bmath
arr = [10, 20, 30, 40]
first = arr[0]      # 10
last = arr[-1]      # 40
middle = arr[2]     # 30
```

### Writing Elements

```bmath
arr = [10, 20, 30, 40]
arr[1] = 25         # arr becomes [10, 25, 30, 40]
arr[-1] = 50        # arr becomes [10, 25, 30, 50]
```

### Multi-dimensional Arrays

```bmath
matrix = [[1, 2], [3, 4]]
element = matrix[0][1]  # 2
matrix[1][0] = 5        # matrix becomes [[1, 2], [5, 4]]
```

## Type System

BMath uses an expressive type hierarchy with numeric and structural types. Types are first-class values (e.g., you can refer to `Int`, `Real`, `Vec` as values). There are union-like concepts (`Any`, `Number`) for describing groups of types.

### Type Hierarchy

```bmath
# Primitive numeric types
Int      # Integer numbers
Real     # Floating-point numbers  
Complex  # Complex numbers with real and imaginary parts

# Unified numeric type
Number   # Union of Int, Real, Complex

# Other primitive types
Bool     # Boolean values: true, false
String   # Text strings

# Collection types
Vec      # Eager-evaluated vectors
Seq      # Lazy-evaluated sequences

# Function and meta types
Function # Function values
Type     # Type values themselves
Module   # Module values
Any      # Universal type (all values)
```

### Type Checking

Use the `is` operator for runtime type checking:

```bmath
value is Number    # true for Int, Real, or Complex values
data is Vec        # true for vector values
fn is Function     # true for function values
```

### Type Annotations

Optional type annotations can be provided on parameters and local variables:

```bmath
# Function with typed parameters
distance = |x: Number, y: Number| => Number {
  (x^2 + y^2)^0.5
}

# Local variable with type
local count: Int = 0
```

## Data Types

### Numbers

BMath supports three numeric types that can interoperate seamlessly:

- **Integers**: `42`, `-17`, `0`
- **Real numbers**: `3.14`, `1.5e-3`, `2.718e+0`
- **Complex numbers**: `3+4i`, `2i`, `i`, `1.5+0.5i`

Complex numbers use the `i` or `I` suffix. The imaginary unit alone is written as `i`.

### Collections

#### Vectors (Eager)

Vectors evaluate all elements immediately and store them in memory:

```bmath
numbers = [1, 2, 3, 4, 5]
mixed = [1, "hello", true, 3.14]
empty = []

# Vector operations
length = len(numbers)
doubled = numbers->map(|x| x * 2)
```

#### Sequences (Lazy)

Sequences evaluate elements on demand and can represent infinite streams:

```bmath
# Finite sequence
finiteSeq = sequence(5, |i| i * 3)  # [0, 3, 6, 9, 12]

# Infinite sequences
ones = sequence(1)           # [1, 1, 1, ...]
naturals = sequence(|i| i)   # [0, 1, 2, 3, ...]

# Lazy transformations
evens = naturals->filter(|x| x % 2 == 0)  # [0, 2, 4, 6, ...]
```

### Strings

String literals use double quotes and support escape sequences:

```bmath
message = "Hello, world!"
multiline = "Line 1\nLine 2\nLine 3"
quoted = "She said, \"Hello!\""
```

### Booleans

Boolean literals are `true` and `false`. They result from comparisons and combine with `&` and `|`:

```bmath
isValid = true
result = x > 0 & y < 10
condition = flag | backup
```

## Local Variables and Scoping

### Local Declaration

The `local` keyword introduces new variables in the current scope:

```bmath
{
  local x = 5
  local y: Number = 3.14
  x + y  # 8.14
}
```

### Scoping Rules

- Functions create new lexical scopes
- Blocks create new lexical scopes  
- Local variables shadow outer scope variables
- Function parameters are local to the function scope
- Closure capture (`!`) allows access to outer scope variables

```bmath
outer = 10
{
  local outer = 20    # shadows outer variable
  inner = outer       # refers to local outer (20)
  captured = outer!   # ERROR: outer! not accessible (would refer to global outer)
}
```

## Error Handling

Errors are represented as values and handled with higher-order utilities rather than exceptions. Common error categories include type mismatches, invalid values, division-by-zero, and undefined variables.

Primary utility patterns:

```bmath
# try_or: run computation with fallback on error
result = try_or(risky_computation(), fallback_value)

# try_catch: run computation with error handler
result = try_catch(risky_computation(), |error| handle_error(error))
```

This design keeps error control flow explicit and composable with other expression-oriented constructs.

## Control Flow and Function Application

Functions are applied with standard call syntax. Anonymous functions can be immediately invoked:

```bmath
# Named function call
result = square(5)

# Anonymous function call  
doubled = (|x| x * 2)(5)

# Pipeline application
result = value->transform->validate
```

Evaluation order is left-to-right: the callee is resolved first, then arguments are evaluated left-to-right, then the call executed.

## Debug and Utility Functions

Debug utilities return their input value to allow chaining:

```bmath
# print returns the printed value
result = data->filter(pred)->print()->map(transform)

# exit with optional status code
exit()      # exit with status 0
exit(1)     # exit with status 1
```

## Lexical Structure

- **Whitespace**: Separates tokens; spaces, tabs, carriage returns ignored
- **Line breaks**: Act as expression separators in top-level contexts
- **Line continuation**: Trailing backslash `\` continues expression on next line
- **Comments**: Start with `#` and continue to end of line

```bmath
# This is a comment
result = long_expression + \
         continued_on_next_line + \
         final_part
```

## Design Principles

### Expression-Oriented

Every construct produces a value and can be composed with other constructs:

```bmath
# Conditionals return values
message = if(score > 90) "Excellent" else "Good"

# Blocks return their last expression
computed = { 
  temp = expensive_calc()
  temp * 2 
}

# Assignments return the assigned value
chain = a = b = compute_value()
```

### Consistent Syntax

Similar constructs use similar syntax patterns:

- Function calls: `func(args)`
- Array indexing: `array[index]`  
- Module access: `module::member`
- Type checking: `value is Type`

### Mathematical Focus

Language design prioritizes mathematical computation:

- Rich numeric types (Int, Real, Complex)
- Mathematical operator precedence
- Vector and sequence operations
- Function composition and chaining

### Explicit Behavior

Important operations are explicit rather than implicit:

- Type conversions require casting
- Closure capture requires `!` operator  
- Error handling uses explicit utilities
- Module imports create explicit bindings
