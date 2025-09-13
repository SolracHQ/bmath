# Language Constructs and Design Notes

This file explains the language constructs of BMath at a design level. It focuses on intended semantics and usage rather than implementation details.

## Overview

BMath is expression-oriented: every construct produces a value. The language focuses on mathematical operations and numerical computation while aiming for a simple, consistent syntax. There are no void or nil values — every expression evaluates to something concrete.

Top-level source lines (outside of blocks) are treated as standalone expressions. Functions are first-class and can be defined inline with optional parameters. Collections support both eager (vectors) and lazy (sequences) evaluation strategies.

## Block Expressions

Blocks are delimited by `{` and `}`. They evaluate each contained expression in order and return the value of the last expression in the block. Blocks create a new lexical scope. Use blocks to group multi-expression computations, create temporary variables, and control scope lifetimes.

Example:

```text
result = { 
  a = 5
  b = 7
  a * b  # block value is 35
}
```

Blocks can appear anywhere a primary expression is allowed and can be used to delay evaluation or encapsulate side effects.

## If Expressions

If expressions always evaluate to a value. An `if(condition)` is followed by an expression to evaluate when true, optional `elif(condition)` clauses, and a required `else` expression. This design ensures every branch produces a value and eliminates null-like fallthrough behavior.

Example:

```text
value = if(x > 0) 
          x * 2
        elif(x < 0) 
          x * -1
        else 0
```

## Functions

Functions are first-class and expressed as lambda-like expressions. They capture their lexical environment (closures) and can be stored in variables, passed to other functions, or returned from functions. Parameters are optional; functions with no parameters are allowed.

Examples:

```text
square = |x| x * x
add = |a, b| a + b
getNextValue = || counter = counter + 1
```

Function expressions are concise and intended for both short inline transforms (e.g., map/filter) and more complex closures.

## Chain Expressions (Arrow Operator)

The arrow operator `->` supports readable pipelines by forwarding the left-hand expression as the first argument to the right-hand function. This enables fluent chaining without nested parentheses and encourages point-free style where helpful.

Example:

```text
[1, 2, 3, 4] -> filter(|n| n % 2 == 0) -> map(|n| n^2) -> sum()
```

Design note: chaining is syntactic sugar; semantics should match the equivalent explicit function calls.

## Modules and `use`

Modules are defined with `mod { ... }` or `mod identifier { ... }`. A `mod` expression evaluates to the module value. When an identifier is provided, `mod identifier { ... }` is syntactic sugar for `identifier = mod { ... }`, binding the module to the given name.

Examples:

```text
# Anonymous module
mathUtils = mod {
  pi = 3.14159
  square = |x| x * x
}

# Named module (syntactic sugar)
mod mathUtils {
  pi = 3.14159
  square = |x| x * x
}
```

The `use` instruction loads and returns a module value. The language provides convenient automatic binding for module member imports to improve developer experience while maintaining the expression-oriented design.

### Basic `use` forms

- `use "path/to/module"` — loads and returns a module from a file path
- `use moduleValue` — returns the module value (useful for re-exporting)
- `use module::member` — loads module, returns the specific member, and automatically binds it as `member = use module::member`
- `use module::{id1, id2}` — returns `[id1 = module::id1, id2 = module::id2]` as a vector of assignments, automatically binding each identifier

### `use` with `as` (explicit aliasing)

- `use module as identifier` — equivalent to `identifier = use module`
- `use module::member as identifier` — equivalent to `identifier = use module::member`
- `use module::{id1 as a, id2 as b}` — equivalent to `[a = module::id1, b = module::id2]`

The automatic binding behavior means that `use std::PI` will create a binding `PI = use std::PI`, making the PI constant available in the current scope without requiring explicit assignment. Similarly, `use std::{PI, sin}` creates bindings for both `PI` and `sin`.

When explicit aliasing is used with the `as` keyword, it overrides the automatic binding behavior. The `as` syntax provides convenient renaming while maintaining the expression-oriented design. Since assignments are expressions that return the assigned value, both automatic and explicit binding forms return vectors of the assigned values while creating the desired bindings as side effects.

When given a string path, the interpreter will try to load a file; the `.bm` extension may be omitted and inferred when appropriate. If a file uses a custom extension, the extension must be provided. If multiple matching files exist (for example `file.custom` and `file.custom.bm`) the interpreter decides which file to load — this is a runtime resolution detail and is not specified at the design level.

Design note: both `mod` and `use` evaluate to module-related values so they can be used inside expressions and chained in pipelines when appropriate. For `use` expressions, automatic binding provides convenient access to imported members while maintaining expression-oriented semantics.

Module member access (`::`):

The `::` operator is used to access members exported by a module value. It is a postfix/access operation that pairs with module values (or expressions that evaluate to module-like values). Examples:

- `m::x` — access member `x` from module value `m`.
- `use "math"::sin` — load the `math` module, access its `sin` member, and automatically bind it as `sin = use "math"::sin`
- `vals = use modName::{a, b}` — automatically bind both `a` and `b` from `modName`, equivalent to `[a = use modName::a, b = use modName::b]`

Design note: `::` returns the referred member value and creates automatic bindings for `use` expressions. For direct module access (without `use`), no automatic binding occurs—binding is explicit via assignment.

## Type System (Design-level)

BMath uses an expressive type hierarchy with numeric and structural types. Types are first-class values (e.g., you can refer to `Int`, `Real`, `Vec` as values). There are also union-like concepts (`Any`, `Number`) for describing groups of types.

Simple types include `Int`, `Real`, `Complex`, `Bool`, `Vec`, `Seq`, and `Function`. Special types include `Any` and `Number` (the numeric union of `Int`, `Real`, and `Complex`).

Type conversions are explicit and available via casting syntax. Conversions follow mathematical expectations (e.g., Int -> Real preserves value, Real -> Int truncates). Some conversions may fail (e.g., Complex -> Real when imaginary part is non-zero) and should surface as errors.

## Error Handling

Errors are represented as values and handled with higher-order utilities rather than exceptions. Common error categories include type mismatches, invalid values, division-by-zero, and undefined variables.

Two primary utility patterns:

- `try_or` — run a computation and return a fallback value on error
- `try_catch` — run a computation and pass the error information to a handler

This design keeps error control flow explicit and composable with other expression-oriented constructs.

For program exit, `exit()` with an optional status code is provided.

## Control Flow and Function Application

Functions are applied with a standard call syntax. Anonymous functions can be immediately invoked. Evaluation order is left-to-right: the callee is resolved first, then arguments are evaluated left-to-right, then the call executed.

Debug utilities such as `print(value)` return the value after printing to allow chaining and inspection within pipelines.

## Evaluation and Scoping Rules

- Evaluation order: strict left-to-right for expressions and function arguments.
- Scopes are created by block expressions and function definitions only.
- The `local` keyword introduces a new variable in the current block scope, shadowing outer names.
- Function parameters are local and shadow outer variables with the same name.

Design consideration: shadowing core names is allowed but discouraged at top level to avoid permanently hiding built-ins.

## Lexical Structure

- Whitespace separates tokens; line breaks act as expression separators outside of blocks.
- A trailing backslash (`\`) allows expressions to continue on the next line.
- Comments start with `#` and continue to the end of the line.

Identifiers follow the common rule: start with letter or underscore, then letters, digits, or underscores.

## Data Types (Design-level)

Numbers: integers, floating-point, and complex numbers are supported. Complex numbers are denoted with an `i` suffix for the imaginary part.

Design notes on complex numbers: operator precedence can affect expressions that mix real and complex literals; parentheses are recommended when mixing operations to avoid ambiguity.

Collections: vectors (eager) and sequences (lazy) are primary collection types. Vectors evaluate all elements immediately; sequences evaluate elements on demand and can represent infinite streams when needed.

Vector examples:

```text
v = [1, 2, 3, 4]
len(v)
v * 2  # scalar multiply
```

Sequence examples:

```text
finiteSeq = sequence(5, |i| i * 3)
ones = sequence(1)  # infinite constant sequence
naturals = sequence(|i| i)  # infinite sequence of naturals
```

Sequences support lazy transformations (filter, map) and can be collected into vectors when needed.

## Booleans

Boolean literals are `true` and `false`. They result from comparisons and combine with `&` and `|` for logical operations.

## Vector indexing and write operator `[]` (access operator)

Design addition: the bracket operator `[]` is used for element access and assignment for vector-like values. It is an access operator and can be chained, for example `matrix[0][1]`.

- Reading: `v[i]` returns the element at index `i` for vector-like values.
- Writing: `v[i] = x` assigns `x` to the location `i` in `v` when `v` is mutable; indexed expressions are l-values when used on the left-hand side of an assignment.

This operator is intended to be easy to read and write. The exact semantics for indexing out-of-bounds, or for immutable vectors, are runtime behaviors and should be defined by the interpreter (for example raising an error or extending the vector depending on chosen semantics).
