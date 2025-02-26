# bmath (bm)

A lightweight command-line tool for evaluating mathematical expressions. bmath now supports advanced language constructs including conditional expressions (if/elif/else), local variables, vector operations, recursive functions, and inline lambda invocations. For full details on the language design and semantics, please refer to the [Formal Design Document](docs/design.md).

## Features

- Interactive REPL with persistent variable storage
- File-based batch processing and direct expression evaluation
- Enhanced expression language:
  - Basic arithmetic and math functions (pow, sqrt, floor, ceil, round)
  - Variables, inline lambda expressions, and function closures
  - Conditional expressions with if/elif/else/endif
  - Advanced scoping with local variable declarations
  - Vectors with element-wise arithmetic, dot product, and utility functions (nth, first, last)
  - Logical operators with short-circuit evaluation
  - Recursive functions for complex calculations
- Type promotion (int/float) and contextual error handling with source positioning

## Example Files

- **[vector_examples.bm](examples/vector_examples.bm)**  
  demonstrates vector creation, element-wise arithmetic, dot product calculations, and higher-order functions like map, filter, and reduce.

- **[numeric_examples.bm](examples/numeric_examples.bm)**  
  showcases integer and floating-point literals, scientific notation, and combining numeric expressions.

- **[function_examples.bm](examples/function_examples.bm)**  
  contains examples of basic function definitions, higher-order functions, function closures, recursion, and inline lambda invocations.

- **[recursive_examples.bm](examples/recursive_examples.bm)**  
  provides recursive implementations for calculating factorials and fibonacci numbers.

- **[arithmetic_examples.bm](examples/arithmetic_examples.bm)**  
  highlights basic arithmetic operations such as addition, subtraction, multiplication, division, exponentiation, modulus, and complex arithmetic expressions using core math functions.

- **[advanced_core_functions.bm](examples/advanced_core_functions.bm)**  
  introduces advanced math functions including trigonometric (sin, cos, tan), logarithmic, and exponential functions along with combined expressions.

- **[comparison_examples.bm](examples/comparison_examples.bm)**  
  explains equality, inequality, relational comparisons, chained conditions, and the usage of logical operators.

## Installation

```bash
git clone https://github.com/solrachq/bmath
cd bmath
nimble build -d:release
```

The binary is created in `bin/bm`.

## Usage

### REPL Mode
```bash
$ bm
bm> 2 + 3 * 4
=> 14
bm> x = 5
=> x = 5
bm> x^2 + 1
=> 26
bm> exit()
```

### Single Expression
```bash
$ bm "sqrt(9) + (2^5)/4"
=> 11.0
```

### File Processing
```bash
$ cat calcs.bm
3 + 4 * 2
pi = 3.1415
2 * pi * 10

$ bm -f:calcs.bm
11
pi = 3.1415
62.830000000000005
```

## Syntax Examples

bmath supports a rich syntax. Examples include:

- **Basic Operations**  
  2 + 3 * 4  
  (5 - 2)^3  
  17 % 4

- **Variables and Functions**  
  radius = 7.5  
  2 * pi * radius  
  pow(2, 8)  
  floor(4.8)  
  round(3.1415)

For more detailed examples, see the [example file](examples/example.bm).

## Development

### Build Options
```bash
nimble build             # Debug build
nimble build -d:release  # Optimized release
nimble test              # Run tests
```

### Architecture Overview

1. CLI Argument Parsing
2. Lexical Analysis (lexer.nim)
3. Syntax Parsing (parser.nim)
4. AST Evaluation (interpreter.nim)
5. Result Output

## Changelog

For a complete history of updates and feature additions, please review the [Changelog](changelog).

## License

MIT License - See [LICENSE](LICENSE) for details.
