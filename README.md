# bmath (bm)

bmath is a lightweight command-line tool for evaluating mathematical expressions. It adopts a pure expression-oriented design where every line computes to a value. Unlike many tools where only function calls return values, here even function definitions yield a function as a first-class value, empowering you to compose and reassign as needed.

## Highlights

- **Pure Expression Philosophy:** Every expression—from assignments and conditionals to inline lambdas—yields a result.
- **Mathematical Focus:** First-class support for complex numbers, vectors, and sequences for advanced mathematical operations.
- **Minimal Core:** No loops or dedicated string types. Instead, leverage vectors and sequences for iteration and data handling.
- **First-Class Functions:** Define functions inline; they return functions as values, making functional composition both natural and powerful.
- **Verbal Conditionals:** Use if/elif/else constructs where every branch returns a value.
- **Chaining Operations:** Utilize the arrow operator (`->`) to streamline chaining operations like map, filter, and reduce.
- **Rich Standard Library:** Access a comprehensive suite of built-in functions for arithmetic, trigonometry, logarithms, complex numbers, vector operations, sequences, and more. See the [Standard Library Documentation](docs/stdlib.md) for complete details.

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

I started this project with a simple idea: create a lightweight tool for terminal-based mathematical calculations that is not only practical for everyday use but also a platform for exploring the full potential of an expression-based language. Every element in this language is designed to return a value, whether it's an assignment, a function definition, or a conditional, yields a concrete result.

- **Expression-First:** Every construct is an expression that produces a tangible value.
- **Concrete Results:** No operation can result in no value (void or unit) or invalid value (nil)
- **Simplicity and Clarity:** The language employs a minimal set of keywords with clear, concise syntax for easier readability and writing.
- **Single Expression Orientation:** Tailored for REPL environments, the lexer and parser are designed to process one instruction at a time.

I invite everyone to join in the evolution of bmath. Whether through pull requests, issue reports, or simply sharing your thoughts, your contributions are essential. Help shape bmath into a powerful and intuitive tool for scripting and daily calculations, and let's continue to refine and expand its capabilities together.

## Example Files

Explore the capabilities of bmath through these new examples:

- **[basic_examples.bm](examples/basic_examples.bm)**  
  Basic language features including variables, blocks, and conditionals.
- **[arithmetic_examples.bm](examples/arithmetic_examples.bm)**  
  Basic and advanced arithmetic operations including complex number arithmetic.
- **[function_examples.bm](examples/function_examples.bm)**  
  Function definition, lambda expressions, higher-order functions, and closures.
- **[recursive_examples.bm](examples/recursive_examples.bm)**  
  Recursive algorithms including factorial, fibonacci, and tree recursion.
- **[vector_examples.bm](examples/vector_examples.bm)**  
  Vector creation, operations, and higher-order functions on vectors.
- **[numeric_examples.bm](examples/numeric_examples.bm)**  
  Working with different numeric types including complex numbers.
- **[sequence_examples.bm](examples/sequence_examples.bm)**  
  Lazy sequence creation, transformation, and evaluation.
- **[comparison_logical_examples.bm](examples/comparison_logical_examples.bm)**  
  Comparison operators, logical operators, and their applications.
- **[trigonometric_examples.bm](examples/trigonometric_examples.bm)**  
  Trigonometric functions and their applications.
- **[advanced_math_examples.bm](examples/advanced_math_examples.bm)**  
  Advanced mathematical operations including statistics, numerical methods, and vector math.

## Standard Library

The bmath standard library has been significantly expanded to include:

- Comprehensive arithmetic operations (including complex number support)
- Trigonometric, logarithmic, and exponential functions
- Vector operations (creation, manipulation, mathematical operations)
- Sequence operations (lazy evaluation, transformation, collection)
- Iteration utilities (map, filter, reduce)
- Statistical functions

For a complete reference, see the [Standard Library Documentation](docs/stdlib.md).

## Error Handling

bmath provides clear error messages that include position information to help locate issues in your code. The error handling system includes:

- Detailed error messages with the specific type of error
- Stack traces showing the execution path leading to the error, for example:
  ```
  [DivideByZeroError] Division by zero is not allowed
  Stack Trace:
    - 4:3
    - 2:9
    - 1:11
  ```
- Position information to help locate the exact point of failure

Future enhancements will include:
- Planned support for error handling expressions (implementation details still being considered)

## ToDo

See the [ToDo](TODO.md) file for a list of planned features and improvements.

## Development

### Build Options

- Debug build: `nimble build`
- Optimized release: `nimble build -d:release`
- Run tests: `nimble test`

### Architecture Overview

1. **CLI Parsing:** Process command-line arguments.
2. **Lexical Analysis:** Tokenize source code.
3. **Syntax Parsing:** Construct the abstract syntax tree.
4. **AST Evaluation:** Execute the expressions.
5. **Output:** Display results or error messages.

## Changelog

For a complete history of updates and feature additions, please refer to the [Changelog](changelog).

## License

MIT License – See [LICENSE](LICENSE) for details.