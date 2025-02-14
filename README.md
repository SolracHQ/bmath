# bmath (bm)

A lightweight command-line tool for evaluating mathematical expressions with REPL support, file input handling, and immediate execution. Designed for quick calculations and batch processing.

## Features

- Interactive REPL with persistent variable storage
- File-based batch processing
- Direct expression evaluation
- Support for variables and functions
- Basic arithmetic (+, -, *, /, ^, %)
- Math functions: pow, sqrt, floor, ceil, round
- Type promotion (int/float)
- Error handling with source positioning


## Installation

```bash
git clone https://github.com/solrachq/bmath
cd bmath
nimble build -d:release
```
Binary will be created in `bin/bm`

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


Basic Operations:
```
  2 + 3 * 4      # Order of operations
  (5 - 2)^3      # Parentheses grouping
  17 % 4         # Modulo operation
```

Variables:
```
  radius = 7.5
  2 * pi * radius
```

Functions:
```
  pow(2, 8)      # 256
  floor(4.8)     # 4
  round(3.1415)  # 3
```

For more information please refer to [example](examples/example.bm)

## Error Handling
Shows contextual error messages with source positions:

```text
21:44:33.089 [RUNTIME ERROR] (line: 1, column: 3): Division by zero
```

## Development

### Build Options
```bash
nimble build             # Debug build
nimble build -d:release  # Optimized release
nimble test              # For run tests
```

### Architecture

1. CLI Argument Parsing
2. Lexical Analysis (lexer.nim)
3. Syntax Parsing (parser.nim)
4. AST Evaluation (interpreter.nim)
5. Result Output


## License
MIT License - See [LICENSE](LICENSE) file for details