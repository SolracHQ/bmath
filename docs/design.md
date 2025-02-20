# Formal Design Document for Math CLI Language

## Overview
This document formally defines the syntax and semantics of a math CLI language focused on pure mathematical expressions. 
Every source line is an expression, except for block expressions, which group multiple expressions enclosed in curly braces (`{ }`) and evaluate to the value of their last expression. 
Unlike many languages, the language omits constructs strings, or a nil value. Functions are defined inline, and lambda expressions can have optional arguments. 
If parameters are provided, they are listed as identifiers separated by commas between pipes; an expression must always follow the closing pipe.

## Formal Syntax

The grammar is informally defined as follows:

```
expression -> ( assignation | block | if_expression )

block -> "{" (expression)* "}"

assignation -> ( "local" )? ( IDENTIFIER "=" )? ( IDENTIFIER "=" )* boolean

if_expression -> "if(" expression ")" expression ( "elif(" expression ")" expression )* "else" expression "endif"

boolean -> comparison ( ("&" | "|") comparison )*

comparison -> term ( ("==" | "!=" | "<" | "<=" | ">" | ">=") term )* 

term -> factor ( ("+" | "-") factor )*

factor -> power ( ("*" | "/") power )*

power -> unary ("^" unary)*

unary -> ("-")? primary

primary -> function | NUMBER | "(" expression ")" | IDENTIFIER | vector | BOOLEAN | functionInvocation

functionInvocation -> IDENTIFIER "(" ( expression ("," expression)* )? ")" | "(" expression ")" "(" ( expression ("," expression)* )? ")"

function -> "|" ( ( IDENTIFIER ) ( "," IDENTIFIER )* )? "|" expression

vector -> "[" ( expression ("," expression)* )? "]"
```

### If Expression details
- The if expression is a conditional expression that evaluates to the value of the first expression that matches the condition.
- The if expression can have multiple elif clauses, each with a condition and an expression.
- The else clause is mandatory and is evaluated if none of the conditions match.
- The endif keyword marks the end of the if expression.

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
  - local keyword can be used to declare a variable as local:
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
  Since functions capture reference to the variable and not a copy, all functions that reference the same variable will observe the same changes:
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
- Variable assignments in inner scopes modify outer variables if they exist; otherwise, they are local to the block, specific local keyword can be used to declare a variable as local.  
- Functions capture and manipulate variable references rather than static values. 


