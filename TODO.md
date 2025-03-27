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

## Under Consideration

- [ ] Input functions
  - [ ] Function to read raw data from stdin
  - [ ] Function to read numbers from stdin
  - [ ] Function to read text as vector/sequence of bytes

