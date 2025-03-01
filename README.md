# bmath (bm)

bmath is a lightweight command-line tool for evaluating mathematical expressions. It adopts a pure expression-oriented design where every line computes to a value. Unlike many tools where only function calls return values, here even function definitions yield a function as a first-class value, empowering you to compose and reassign as needed.

## Highlights

- **Pure Expression Philosophy:** Every expression—from assignments and conditionals to inline lambdas—yields a result.
- **Minimal Core:** No loops or dedicated string types. Instead, leverage vectors and sequences for iteration and data handling.
- **First-Class Functions:** Define functions inline; they return functions as values, making functional composition both natural and powerful.
- **Verbal Conditionals:** Use if/elif/else/endif constructs where every branch returns a value.
- **Chaining Operations:** Utilize the arrow operator (`->`) to streamline chaining operations like map, filter, and reduce.
- **Standard Library:** Access a suite of built-in functions for arithmetic, trigonometry, logarithms, and more. See the [Standard Library Documentation](docs/stdlib.md) for further details.

## Getting Started

### Installation

Clone and build bmath with:

```bash
git clone https://github.com/solrachq/bmath
cd bmath
nimble build -d:release
```

The binary will be available in `bin/bm`.

### Usage

#### REPL Mode

Start an interactive session:

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

#### Single Expression

Evaluate an expression directly:

```bash
$ bm "sqrt(9) + (2^5)/4"
=> 11.0
```

#### File Processing

Create a file (e.g., `calcs.bm`):

```bash
3 + 4 * 2
pi = 3.1415
2 * pi * 10
```

Then run:

```bash
$ bm -f:calcs.bm
11
pi = 3.1415
62.830000000000005
```

## Motivation and Design Principles

I started this project with a simple idea: create a lightweight tool for terminal-based mathematical calculations that is not only practical for everyday use but also a platform for exploring the full potential of an expression-based language. Every element in this language is designed to return a value, whether it’s an assignment, a function definition, or a conditional, yields a concrete result.

- **Expression-First:** Every construct is an expression that produces a tangible value.
- **Concrete Results:** No operation can result in no value (void or unit) or invalid value (nil)
- **Simplicity and Clarity:** The language employs a minimal set of keywords with clear, concise syntax for easier readability and writing.
- **Single Expression Orientation:** Tailored for REPL environments, the lexer and parser are designed to process one instruction at a time.

I invite everyone to join in the evolution of bmath. Whether through pull requests, issue reports, or simply sharing your thoughts, your contributions are essential. Help shape bmath into a powerful and intuitive tool for scripting and daily calculations, and let’s continue to refine and expand its capabilities together.


## Example Files

Discover the capabilities of bmath through these examples:

- **[vector_examples.bm](examples/vector_examples.bm)**  
  Vectors, arithmetic operations, dot products, and higher-order functions.
- **[numeric_examples.bm](examples/numeric_examples.bm)**  
  Working with integers, floating-point numbers, and scientific notations.
- **[function_examples.bm](examples/function_examples.bm)**  
  Inline lambda definitions, function composition, and recursion.
- **[recursive_examples.bm](examples/recursive_examples.bm)**  
  Recursive algorithms such as factorial and Fibonacci.
- **[arithmetic_examples.bm](examples/arithmetic_examples.bm)**  
  Various arithmetic operations and complex mathematical expressions.
- **[advanced_core_functions.bm](examples/advanced_core_functions.bm)**  
  Trigonometric, logarithmic, and exponential function examples.
- **[comparison_examples.bm](examples/comparison_examples.bm)**  
  Examples of relational, logical operations, and conditionals.
- **[seq_examples.bm](examples/seq_examples.bm)**  
  Sequences operations: generating, filtering, mapping, and reducing sequences.

## ToDo

- Add support for imaginary numbers.
- Evaluate the possibility of a bytecode-based VM to improve performance on recursive-heavy code.
- Enhance error handling – not just display the line and column, but highlight the exact location of the error.
  
## Development

### Build Options

- Debug build: `nimble build`
- Optimized release: `nimble build -d:release`
- Run tests: `nimble test`

### Architecture Overview

1. **CLI Parsing:** Process command-line arguments.
2. **Lexical Analysis:** Tokenize source code.
3. **Syntax Parsing:** Construct the abstract syntax tree.
4. **AST Optimization:** Optimize the AST.
5. **AST Evaluation:** Execute the expressions.
6. **Output:** Display results or error messages.

## Changelog

For a complete history of updates and feature additions, please refer to the [Changelog](changelog).

## License

MIT License – See [LICENSE](LICENSE) for details.