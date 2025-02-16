# Formal Design Document for Math CLI Language

## Overview
This document formally defines the syntax and semantics of a math CLI language focused on pure mathematical expressions. Every source line is an expression, except for block expressions, which group multiple expressions enclosed in curly braces (`{ }`) and evaluate to the value of their last expression. Unlike many languages, the language omits constructs for booleans, strings, or a nil value. Functions are defined inline, and lambda expressions can have optional arguments. If parameters are provided, they are listed as identifiers separated by commas between pipes; an expression must always follow the closing pipe.

## Formal Syntax

The grammar is informally defined as follows:

```
expression -> ( assignation "\n" | block )

block -> "{" (expression)* "}"

assignation -> ( IDENTIFIER "=" )? ( term | expression )

term -> factor ( ("+" | "-") factor )*

factor -> power ( ("*" | "/") power )*

power -> unary ("^" unary)*

unary -> ("-")? primary

primary -> function | NUMBER | "(" expression ")" | IDENTIFIER | vector

function -> "|" ( IDENTIFIER )? ( "," IDENTIFIER )* "|" expression

vector -> "[" ( expression ("," expression)* )? "]"
```

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

## Language Decisions

- Every source line outside of blocks is an expression.  
- Block expressions use newline separation without semicolons, and they evaluate to the result of their last expression.  
- Variable assignments in inner scopes modify outer variables if they exist; otherwise, they are local to the block.  
- Functions capture and manipulate variable references rather than static values.  
- Future work includes the addition of vectors and vector operations, although control flow constructs will likely remain minimal.


