# bmath (bm)

bmath is a powerful, expression-oriented mathematical programming language designed for numerical computation, data analysis, and interactive mathematical exploration. Every construct in bmath produces a value, creating a consistent and composable programming experience ideal for both REPL usage and script development.

## Key Features

- **Pure Expression Philosophy:** Every construct—assignments, conditionals, functions, modules—yields a result, enabling seamless composition
- **Rich Mathematical Types:** First-class support for integers, real numbers, complex numbers, vectors, and lazy sequences
- **Advanced Function System:** Higher-order functions with closure capture, pipeline chaining, and flexible parameter handling
- **Module System:** Organize code with modules and flexible import mechanisms using the `use` expression
- **Interactive & Scriptable:** Optimized for both REPL exploration and file-based script execution
- **Comprehensive Standard Library:** Built-in functions for arithmetic, trigonometry, testing, vector operations, and more

## Quick Examples

```bmath
# Mathematical expressions with rich numeric types
sqrt(9) + 2^3                    # => 11.0
(3 + 4i) * (1 - 2i)             # => (11-2i)

# Function definitions and chaining (use \ for multiline)
square = |x| x * x
[1, 2, 3, 4] \
  -> map(square) \
  -> sum()  # => 30

# Conditional expressions (all branches return values)
grade = if(score > 90) "A" elif(score > 80) "B" else "C"

# Block expressions with scoped variables
result = {
  local a = 5
  local b = 7
  a * b + 10  # => 45
}

# Modules and imports
mod mathUtils {
  pi = 3.14159
  circleArea = |r| pi * r^2
}
use(mathUtils::{pi, circleArea})  # Bind specific functions
circleArea(5)  # => 78.53975
```

## Installation

Clone and build bmath:

```bash
git clone https://github.com/solrachq/bmath
cd bmath
nimble build -d:release
```

The binary will be available at `bin/bm`.

## Usage

### REPL Mode

Start an interactive session:

```bash
$ bm
bm> 2 + 3 * 4
=> 14
bm> factorial = |n| if(n <= 1) 1 else n * factorial(n-1)
=> factorial = <function>
bm> factorial(5)
=> 120
bm> exit()
```

### Single Expression Evaluation

```bash
$ bm "sqrt(16) + (2^3)/4"
=> 6.0
```

### Script Execution

Create `calculations.bm`:

```bmath
# Define some mathematical functions
mod geometry {
  pi = 3.14159265359
  circleArea = |r| pi * r^2
  sphereVolume = |r| (4/3) * pi * r^3
}

use(geometry::{circleArea, sphereVolume})  # Bind specific functions

# Calculate for radius 5
radius = 5
area = circleArea(radius)
volume = sphereVolume(radius)

# Assignments return values, so this works:
total = (area = circleArea(10)) + (volume = sphereVolume(10))
```

Run with:

```bash
bm -f:calculations.bm
```

## Language Overview

### Expression-Oriented Design

Every construct in bmath produces a value:

```bmath
# Assignments return values, enabling composition
chain = a = b = 42  # Both a and b are set to 42
result = (area = calculateArea(r)) * PI  # Uses assignment result

# Conditionals always return a value (else clause required)
result = if(condition) "yes" else "no"

# Blocks return their last expression
computed = { 
  temp = expensive_calculation()
  temp * 2  # This value is returned
}

# Function definitions return function values
double = |x| x * 2  # double now holds a function
```

### Rich Type System

```bmath
# Numeric types with seamless interoperation
integer = 42
real = 3.14159
complex = 3 + 4i
scientific = 1.5e-10

# Type checking
42 is Int        # => true
3.14 is Number   # => true (Number includes Int, Real, Complex)
(2+3i) is Complex # => true

# Collections
vector = [1, 2, 3, 4, 5]           # Eager evaluation
lazy_seq = seq(10, |i| i^2)        # Lazy evaluation: [0, 1, 4, 9, ...]
```

### Advanced Function Features

```bmath
# Basic functions
add = |a, b| a + b
no_params = || "Hello, World!"

# Closure capture with !
counter = 0
increment = || {
  counter! = counter! + 1  # ! captures outer scope variable
  counter!
}

# Pipeline chaining (use \ for multiline)
[1, 2, 3, 4, 5] \
  -> filter(|x| x % 2 == 0) \
  -> map(|x| x^2) \
  -> reduce(|acc, x| acc + x, 0)  # => 20
```

### Module System

```bmath
# Define modules
mod utils {
  helper = |x| x * 2
  constant = 42
}

# Import patterns
utils = use(utils)                # Import entire module (no automatic binding)
use(utils::helper as helper)      # Import specific function with binding
use(utils::{helper, constant})    # Import multiple items with bindings
std = use(utils as std)           # Import with explicit alias

# Module nesting and file imports
utils = use("path/to/module.bm")  # Load from file (returns module, no binding)
std = use("std/collections" as std)  # Standard library module with alias
```

### Array Operations

```bmath
# Creation and access
arr = [10, 20, 30, 40]
first = arr[0]     # => 10
last = arr[-1]     # => 40

# Modification
arr[1] = 25        # arr becomes [10, 25, 30, 40]

# Multi-dimensional
matrix = [[1, 2], [3, 4]]
element = matrix[0][1]  # => 2
```

### Line Continuation for Long Expressions

```bmath
# Use backslash \ for multiline expressions
result = [1, 2, 3, 4, 5] \
  -> filter(|x| x > 2) \    # comments allowed after \
  -> map(|x| x * x) \       # each line needs \ except the last
  -> sum()                  # => 54

# Complex calculations
value = sqrt(a^2 + b^2) + \
        log(c) + \
        sin(d)
```

### Error Handling

```bmath
# Error-safe computation with fallbacks
result = try_or(risky_operation(), default_value)

# Error handling with custom logic
result = try_catch(dangerous_calc(), |error| {
  print("Error occurred: " + error)
  fallback_value
})
```

## Standard Library Highlights

### Core Functions

- **System:** `exit`, `try_or`, `try_catch`, `print`
- **Arithmetic:** `abs`, `sqrt`, `pow`, `floor`, `ceil`, `round`
- **Complex:** `re`, `im` (real and imaginary parts)
- **Trigonometry:** `sin`, `cos`, `tan`, `cot`, `sec`, `csc`
- **Logarithmic:** `log`, `exp`

### Collection Operations

- **Vector:** `vec`, `len`, `sum`, `first`, `last`, `merge`, `slice`, `set`, `dot`
- **Sequence:** `seq`, `skip`, `take`, `has_next`, `next`, `collect`, `zip`
- **Higher-Order:** `map`, `filter`, `reduce`, `any`, `all`, `nth`, `at`
- **Comparison:** `min`, `max`

### Testing & Debugging

- **Assertions:** `assert`, `assert_eq`, `assert_neq`, `assert_lt`, `assert_gt`, `assert_type`, `assert_error`
- **Type System:** `type` (get type of value)

### Constants

- **Mathematical:** `PI`, `E`, `I` (and lowercase variants `pi`, `e`, `i`)

For complete documentation of all available functions, see [Standard Library Reference](docs/stdlib.md).

## Advanced Features

### Type Annotations

```bmath
# Optional type annotations for clarity
distance = |x: Number, y: Number| => Number {
  sqrt(x^2 + y^2)
}

# Local variables with types
local count: Int = 0
local data: Vec = [1, 2, 3]
```

### Lazy Sequences

```bmath
# Finite sequences
naturals = seq(10, |i| i)              # [0, 1, 2, 3, ..., 9]
fibonacci = seq(10, |i| fib(i))        # [0, 1, 1, 2, 3, 5, ...]

# Lazy transformations
evens = naturals \
  -> filter(|x| x % 2 == 0) \
  -> take(10)
# Only computes what's needed
```

### Debug Utilities

```bmath
# print function for debugging
data = [1, 2, 3, 4]
print(data)                   # Prints: [1, 2, 3, 4]
result = data \
  -> filter(|x| x > 2) \
  -> print() \                # Debug intermediate results
  -> sum()
```

## Error Messages and Debugging

bmath provides clear, simplified error messages with position-based stack traces:

```bash
[DivideByZeroError] Division by zero is not allowed
Stack Trace:
  - 4:3
  - 2:9
  - 1:11
```

Since all functions in bmath are anonymous values, stack traces show position information (line:column) rather than function names, making debugging straightforward by pointing directly to code locations.

## Examples Gallery

Explore comprehensive examples across multiple domains:

### Core Language Features

- **[basic_examples.bm](examples/basic_examples.bm)** - Variables, blocks, conditionals
- **[function_examples.bm](examples/function_examples.bm)** - Functions, closures, higher-order functions  
- **[comparison_logical_examples.bm](examples/comparison_logical_examples.bm)** - Logic and comparison operators

### Mathematical Operations

- **[arithmetic_examples.bm](examples/arithmetic_examples.bm)** - Basic and advanced arithmetic
- **[numeric_examples.bm](examples/numeric_examples.bm)** - Complex numbers and numeric types
- **[trigonometric_examples.bm](examples/trigonometric_examples.bm)** - Trigonometric functions
- **[advanced_math_examples.bm](examples/advanced_math_examples.bm)** - Statistics and numerical methods

### Data Structures & Algorithms

- **[vector_examples.bm](examples/vector_examples.bm)** - Vector operations and transformations
- **[sequence_examples.bm](examples/sequence_examples.bm)** - Lazy sequences and infinite data
- **[recursive_examples.bm](examples/recursive_examples.bm)** - Recursive algorithms and patterns

### Development & Testing

- **[assertion_examples.bm](examples/assertion_examples.bm)** - Testing and assertions
- **[simple_assertion_demo.bm](examples/simple_assertion_demo.bm)** - Basic assertion usage
- **[print_usage_examples.bm](examples/print_usage_examples.bm)** - Debugging and output
- **[run_examples.bm](examples/run_examples.bm)** - Example runner utility

## Development

### Building from Source

```bash
# Debug build
nimble build

# Optimized release
nimble build -d:release

# Run Nim unit tests
nimble test

# Run bmath integration tests (implementation-independent)
./bmath_test/run_tests.sh
```

### Contributing

Contributions are welcome! Please:

1. Open an issue for major changes
2. Add tests for new features
3. Update documentation as needed
4. Format code with `nph` before submitting

Quick contributor setup:

```bash
nimble build bm           # Build binary
nimble test               # Run Nim unit tests
./bmath_test/run_tests.sh # Run bmath integration tests (implementation-independent)
./format_all.sh           # Format code
```

The project maintains both Nim-based unit tests and implementation-independent bmath integration tests in the `bmath_test/` directory, ensuring the language specification can be tested across different implementations.

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## Roadmap & Current Development

**Current Version:** v0.12.0 (in development)

### v0.12.0 Focus Areas

- **Module System Enhancements** - Advanced import patterns, visibility controls
- **Variable Scoping Overhaul** - Symbol-based capture system with `!` syntax  
- **Pure Function System** - Runtime purity tracking and automatic parallelization
- **Error Handling Redesign** - Error values as default with optional panic mode

See [MAIN-v0.12.0-GOALS.md](MAIN-v0.12.0-GOALS.md) for detailed progress tracking.

### Future Enhancements

- Enhanced error handling expressions
- Performance optimizations for large datasets  
- IDE integration and language server
- Package management system

See [TODO.md](TODO.md) for detailed planned features.

## Design Philosophy

bmath embraces these principles:

- **Everything is an expression** - No void operations or null values
- **Mathematical focus** - Optimized for numerical computation and data analysis
- **Composability** - Every construct can be combined with others naturally
- **Simplicity** - Minimal syntax with maximum expressiveness
- **Interactive-friendly** - Designed for REPL exploration and scripting

## License

MIT License - See [LICENSE](LICENSE) for details.
