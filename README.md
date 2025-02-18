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

For a thorough demonstration of these capabilities, see the [example file](examples/example.bm).

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
