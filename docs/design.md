# Formal Design Document for Math CLI Language

## Overview
This document defines the syntax and semantics of a mathematical command-line interface language. BMath is designed with a clear philosophy:

- **Expression-oriented**: Every construct is an expression that returns a value
- **Mathematical focus**: Optimized for mathematical operations and numerical computations
- **Simplicity**: Minimal syntax with powerful semantics
- **Consistency**: No "void" or "nil" values - everything evaluates to something concrete

The language operates primarily on expressions, with every source line (outside blocks) treated as a standalone expression. Functions are first-class citizens defined inline with optional parameters. The language supports both eager evaluation (vectors) and lazy evaluation (sequences) for collections.

## Formal Syntax

The grammar is defined as follows:

```
expression       -> ( assignation | chain_expression )

chain_expression -> simple_expression ( "->" functionInvocation )*
simple_expression-> ( assignation | block | if_expression | boolean )

block            -> "{" expression ( "\n" expression )* "}"

assignation      -> ( "local" )? ( IDENTIFIER "=" )? ( IDENTIFIER "=" )* boolean

if_expression    -> "if(" expression ")" expression ( "elif(" expression ")" expression )* "else" expression

boolean          -> comparison ( ("&" | "|") comparison )*

comparison       -> term ( ("==" | "!=" | "<" | "<=" | ">" | ">=") term )* 

term             -> factor ( ("+" | "-") factor )*

factor           -> power ( ("*" | "/") power )*

power            -> unary ("^" unary)*

unary            -> ("-")? primary

primary          -> function | NUMBER | "(" expression ")" | IDENTIFIER | vector | BOOLEAN | functionInvocation | block | if_expression

NUMBER          -> [0-9]* ("." [0-9]+)? ("e" [0-9]* ("." [0-9]+)?)? ("i")?

functionInvocation -> IDENTIFIER "(" ( expression ("," expression)* )? ")" 
           | "(" expression ")" "(" ( expression ("," expression)* )? ")"

function         -> "|" ( ( IDENTIFIER ) ( "," IDENTIFIER )* )? "|" expression

vector           -> "[" ( expression ("," expression)* )? "]"
```

## Language Constructs

### Block Expressions
Block expressions group multiple expressions enclosed in curly braces `{ }`. They evaluate all contained expressions but return only the value of the last expression. Blocks create their own scope and can be used anywhere a primary expression is expected.

Example:
```
result = { 
  a = 5
  b = 7
  a * b  # This value (35) becomes the result of the block
}
```

Blocks can be used in place of grouped expressions:
```
{4 + 4} * 2  # Evaluates to 16
```

### If Expressions
If expressions provide conditional logic and always evaluate to a value. They consist of:
- An `if(condition)` followed by an expression to evaluate when the condition is true
- Optional `elif(condition)` clauses with their corresponding expressions
- An `else` clause with an expression that executes when all conditions are false

Example:
```
value = if(x > 0) 
          x * 2
        elif(x < 0) 
          x * -1
        else 0
```

### Function Definition
Functions are first-class values defined as lambda expressions. They capture their lexical environment as closures and can be assigned to variables or passed as arguments.

Functions with parameters:
```
square = |x| x * x
add = |a, b| a + b
```

Functions without parameters:
```
getNextValue = || counter = counter + 1
```

### Chain Expressions (Arrow Operator)
The arrow operator `->` provides syntactic sugar for function chaining. An expression of the form:
```
expr -> func(arg1, arg2)
```
is desugared to:
```
func(expr, arg1, arg2)
```

This enables readable pipelines:
```
[1, 2, 3, 4] -> filter(|n| n % 2 == 0) -> map(|n| n^2) -> sum()
```

## Evaluation and Scoping Rules

### Evaluation Order
- Expressions are evaluated strictly left-to-right
- In function calls, the function expression is resolved first, then all arguments are evaluated in order, and finally the function is called

### Scoping Rules
- Only block expressions and functions create their own scopes
- Variables in inner scopes can access and modify variables from outer scopes
- The `local` keyword creates a new variable that shadows any existing variable with the same name
- Function parameters are local by default and shadow outer variables with the same name

## Lexical Structure

### Tokens and Whitespace
- Whitespace (spaces, tabs) has no semantic meaning except to separate tokens
- Line breaks (`\n`) serve as expression separators outside of blocks
- The backslash character (`\`) at the end of a line allows for multi-line expressions
- Comments begin with `#` and continue to the end of the line

### Identifiers
Identifiers must start with a letter (uppercase or lowercase) or underscore, followed by any number of letters, digits, or underscores. They are case-sensitive.

Valid identifiers: `x`, `_temp`, `myVariable`, `PI`

### Multi-line Expressions
Besides blocks, other constructs that can span multiple lines include:
- Grouped expressions with parentheses: `(a + b + c)`
- Vector expressions: `[1, 2, 3, 4]`
- Function calls with multiple arguments

## Data Types

### Numbers
- Integers: `42`, `-7`
- Floating-point: `3.14`, `-0.5`
- Complex numbers: `3i`, `4+2i`, `1.5i`

### Complex Numbers
Complex numbers are represented as regular numbers with an `i` suffix. Due to operator precedence, expressions with complex numbers might behave differently than in mathematical notation:

```
c1 = 4 + 3i  # parses as 4 plus 3i, which is correct  
c2 = 4+3i *2  # parses as 4 plus (3i * 2), yielding 4 + 6i  
c3 = (4 + 4i) * 2  # forces addition before multiplication, yielding 8 + 8i
```

### Collections
BMath provides two collection types: vectors and sequences, each with different evaluation strategies and use cases.

#### Vectors
Vectors are eagerly evaluated collections where all elements are computed immediately. They're created using square brackets notation or the `vec` function:

```
# Direct vector creation with values
myVector = [1, 2, 3, 4]

# Create a vector of size 5 filled with the value 0
zeros = vec(5, 0)  

# Create a vector with a generator function
squares = vec(10, |i| i^2)  # [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]
```

Vectors support common operations like indexing, length calculation, and mathematical operations:

```
v = [1, 2, 3, 4]
v[0]      # Access first element (returns 1)
len(v)    # Get vector length (returns 4)
v * 2     # Scalar multiplication [2, 4, 6, 8]
```

#### Sequences
Sequences are lazily evaluated collections where elements are computed only when needed. BMath supports both finite and infinite sequences:

##### Finite Sequences
```
# Create a sequence of 5 elements
finiteSeq = sequence(5, |i| i * 3)  # Represents [0, 3, 6, 9, 12]

# Create a sequence from a vector
fromVector = sequence([1, 2, 3])
```

##### Infinite Sequences
```
# Infinite sequence of a constant value
ones = sequence(1)  # Represents [1, 1, 1, ...]

# Infinite sequence of generated values
naturals = sequence(|i| i)  # Represents [0, 1, 2, ...]
```

Sequences support transformation operations that are also lazily evaluated:

```
# Create a sequence, filter it, map it, and then collect the results
evenSquares = sequence(10, |i| i) -> filter(|n| n % 2 == 0) -> map(|n| n^2) -> collect()
# Results in [0, 4, 16, 36, 64]
```

Sequences can be consumed using iteration functions:

```
seq = sequence(5, |i| i * 2)
hasNext(seq)  # Check if more elements exist
next(seq)     # Get the next element
collect(seq)  # Convert entire sequence to a vector
```

For a complete reference of vector and sequence operations, see the [Standard Library Documentation](stdlib.md).

### Booleans
- `true` and `false` literals
- Result of comparison operations: `==`, `!=`, `<`, `<=`, `>`, `>=`
- Combined with logical operators: `&` (and), `|` (or)