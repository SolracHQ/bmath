# bmath Language Development TODO

## Functions and Values

- [ ] Implement functions that allow print values inside blocks (not top level)
  - [ ] Design syntax for defining these functions
  - [ ] Ensure functions return the printed value
  - [ ] Example: `x = block { print(42) }` should make x = 42

## Type System Enhancements

- [ ] Implement types as runtime values
  - [ ] Define core type representations
  - [ ] Add support for type inspection
- [ ] Add "is" keyword for type checking
  - [ ] Example: `if (num is int) num else round(num)`
  - [ ] Determine precedence and associativity rules

## Control Flow Extensions

- [ ] Implement error handling functions
  - [ ] `try_or(lambda, default)` - returns default if lambda throws
  - [ ] `try_catch(lambda, lambda_that_receives_error_type)` - error handling without exposing error details
  - [ ] Only expose error type, not the specific error details to user

## Type Conversions

- [ ] Add explicit type casting
  - [ ] Function-style syntax: `type(value)`
  - [ ] Arrow-style syntax: `value->type`
  - [ ] Define valid conversion paths between types

## Vector Destructuring

- [ ] Implement vector destructuring syntax
  - [ ] Support basic destructuring: `a, b, c = [1, 2, 3]`
  - [ ] Consider alternative syntax options:
    - [ ] Parentheses style: `(a, b, c) = [1, 2, 3]`
    - [ ] Brackets style: `[a, b, c] = [1, 2, 3]`
  - [ ] Add underscore symbol for value discarding: `a, _, c = [1, 2, 3]`
  - [ ] Implement error handling for binding mismatches
    - [ ] Raise error when not enough variables: `(a, b) = [1, 2, 3]`
    - [ ] Raise error when too many variables: `(a, b, c, d) = [1, 2, 3]`
  - [ ] Consider support for rest pattern (discarding remaining elements)
    - [ ] Example: `[a, _] = [1, 2, 3]` where `_` discards remaining elements

## Under Consideration

- [ ] Input functions
  - [ ] Function to read raw data from stdin
  - [ ] Function to read numbers from stdin
  - [ ] Function to read text as vector/sequence of bytes

## Experimental Features Under Consideration

- [ ] Module/Namespace system
  - [ ] Define syntax for module declarations: `mod mod_name { ... }`
  - [ ] Decide on access syntax: `mod_name::function` vs `mod_name.function`
  - [ ] Support for module-level variables and functions
  - [ ] Define scope and visibility rules

- [ ] File I/O operations
  - [ ] Add special path value syntax: `$/path/to/file`
  - [ ] Implement file read operations returning vectors/sequences of bytes
  - [ ] Implement file write operations accepting vectors/sequences
  - [ ] Define appropriate error handling for file operations

- [ ] Code inclusion and dynamic execution
  - [ ] Support for including other bmath script files
  - [ ] Allow execution of arbitrary bmath code at runtime
  - [ ] Define a module resolution strategy
  - [ ] Consider security implications

- [ ] Character and string syntax sugar
  - [ ] Add character literals (`'a'` → `97`) representing ASCII values
  - [ ] Add string literals (`"abc"` → `[97, 98, 99]`) creating vectors of ASCII values
  - [ ] Ensure compatibility with math-oriented language philosophy
  - [ ] Add appropriate standard library functions for ASCII manipulation

## REPL Enhancements

- [ ] Improve REPL with interactive features
  - [ ] Implement in-line editing capabilities
  - [ ] Add arrow key navigation within current expression
  - [ ] Support cursor positioning and text manipulation
- [ ] Add expression history functionality
  - [ ] Store previous expressions in memory
  - [ ] Navigate history with up/down arrow keys
  - [ ] Implement history search (Ctrl+R)
  - [ ] Allow recalling, editing, and re-executing past expressions

