# Formal Design Document for Math CLI Language

## Overview
This document formally defines the syntax and semantics of a math CLI language focused on pure mathematical expressions. Every source line is an expression, except for block expressions, which group multiple expressions enclosed in curly braces (`{ }`) and evaluate to the value of their last expression. Unlike many languages, the language omits constructs such as strings or a nil value. Functions are defined inline, and lambda expressions can have optional arguments. If parameters are provided, they are listed as identifiers separated by commas between pipes; an expression must always follow the closing pipe.

The language now also supports chaining function calls using the arrow operator (->) as syntactic sugar. In addition, a new lazy-evaluated data type, seq, is introduced alongside the traditional vec type.

## Formal Syntax

The grammar is informally defined as follows:

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

NUMBER          -> [0-9]* ("." [0-9]+)? ("i")?

functionInvocation -> IDENTIFIER "(" ( expression ("," expression)* )? ")" 
           | "(" expression ")" "(" ( expression ("," expression)* )? ")"

function         -> "|" ( ( IDENTIFIER ) ( "," IDENTIFIER )* )? "|" expression

vector           -> "[" ( expression ("," expression)* )? "]"
```

### Comments
BMath only supports single-line comments, which start with `#` and continue until the end of the line. Multi-line comments are not supported.

### Syntax Sugar: Arrow Operator for Chained Function Calls

Expressions using the arrow operator are transformed as follows: given an expression of the form  
  A -> f(arg1, arg2, …)  
it is rewritten to:  
  f(A, arg1, arg2, …)

For chained calls, such as:  
  A -> f -> g(arg1)  
the transformation produces:  
  g(f(A), arg1)

We choose the arrow operator over the dot notation for clarity.

## Expression Semantics and Line Structure

- Every line in the source (outside of a block) is treated as a standalone expression.
- Block expressions, denoted by curly braces, consist of multiple expressions. All expressions are evaluated, but only the result of the last expression is produced as the block’s value.

## Variable Scoping and Assignment

- **Assignment:** Variables are assigned using `=`.
- **Scope Behavior:**
  - If an assignment targets a variable already declared in an outer scope, the inner assignment modifies the outer variable; shadowing does not occur. For example:
  ```
  a = 8
  {
    a = 9
  }
  a  // evaluates to 9 since the inner block alters the outer variable.
  ```
  - If a variable is not declared in any outer scope, an assignment within a block creates a new local variable:
  ```
  a = 8
  {
    b = 9
  }
  b  // error: variable 'b' does not exist in the outer scope.
  ```
  - The local keyword can be used to declare a variable as local:
  ```
  a = 8
  {
    local b = 9
  }
  b  // error: variable 'b' does not exist in the outer scope.
  ```
  - If a variable declared as local is already declared in an outer scope, the inner variable shadows the outer variable:
  ```
  a = 8
  {
    local a = 9
  }
  a  // evaluates to 8 since the inner block shadows the outer variable.
  ```

## Function Definition and Closure Behavior

- **Function Definition:**  
  Functions are first-class citizens and are defined inline as lambda expressions.  
  For example, a lambda with parameters:
  ```
  myFunc = |x, y| x + y
  ```
  A lambda without parameters:
  ```
  inc = || a = a + 1
  ```

- **Closure Semantics:**  
  Functions capture variable references, not static values. This means that changes to an external variable are observed in subsequent function calls:
  ```
  a = 1
  inc = || a = a + 1
  inc()  // updates a to 2
  inc()  // updates a to 3
  a      // now evaluates to 3
  ```

- **Closure Uniqueness:**
  Since functions capture references to variables rather than copies, all functions referencing the same variable will observe the same changes:
  ```
  a = 1
  inc = || a = a + 1
  dec = || a = a - 1
  a = 5
  inc()  // updates a to 6
  dec()  // updates a to 5
  a      // now evaluates to 5
  ```
  Function parameters are local by default, and they shadow outer variables:
  ```
  a = 1
  inc = |a| a = a + 1
  inc(5)  // updates a to 6
  a       // now evaluates to 1
  ```

## Language Decisions

- Every source line outside of blocks is an expression.
- Block expressions use newline separation without semicolons, and they evaluate to the result of their last expression.
- Variable assignments in inner scopes modify outer variables if they exist; otherwise, they are local to the block. The specific local keyword can be used to declare a variable as local.
- Functions capture and manipulate variable references rather than static values.
  
Additional Notes:
- Syntactic Sugar for Chained Function Calls: The arrow operator (->) allows an expression on its left to be seamlessly passed as the first argument into a function call on its right. For example,  
  ```
  [1, 2, 3, 4] -> filter(|n| n % 2 == 0) -> map(|n| n^2) -> sum()
  ```  
  is equivalent to:  
  ```
  sum(map(filter([1, 2, 3, 4], |n| n % 2 == 0), |n| n^2))
  ```
- Lazy seq Data Type: A new lazy-evaluated sequence type is available via the constructor seq(size, generator), similar to vec. Operations such as map and filter now return a seq. To convert a seq to a vec, use the collect(seq) function.

## Note on Complex Numbers

Complex numbers are treated like other numbers but must end with "i". Note that due to operator precedence, expressions can behave differently than in pure math. For example:
  
  c1 = 4 + 3i  # parses as 4 plus 3i, which is correct  
  c2 = 4+3i *2  # parses as 4 plus (3i * 2), yielding 4 + 6i  
  c3 = (4 + 4i) * 2  # forces addition before multiplication, yielding 8 + 8i

This behavior occurs because the * operator has higher precedence than +.