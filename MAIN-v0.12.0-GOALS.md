# Main v0.12.0 Goals

## Module System Implementation

### Core Module Infrastructure

- [ ] Design module value representation (modules as first-class values vs symbols)
- [ ] Implement module namespace isolation
- [ ] Create module loading and caching system
- [ ] Define module file resolution strategy (relative/absolute paths)

### Module Syntax Design

- [ ] Chosen module declaration syntax: `mod name { ... }` (file-level modules allowed)
- [ ] Chosen member access syntax: `module::member` (explicit, avoids dot ambiguity)
- [ ] Import syntax to implement:
  - [ ] `import module` (binds module value to `module`)
  - [ ] `import module::{a, b as alias}` (selective imports)
  - [ ] `import module::*` (explicit wildcard, discouraged)
  - [ ] Allow relative path imports: `import "../../path/to/module.bm"` or `import ../math`
- [ ] File-as-module semantics:
  - [ ] Each file is a module by default (like Rust/Nim)
  - [ ] Module name inferred from file stem; plan to add unicode filename support
  - [ ] Document filename restrictions and plan to add unicode support for file names
- [ ] Versioning and package management notes:
  - [ ] No built-in `module@version` syntax; prefer external package manager
  - [ ] Project is small — package manager is optional for now

### Examples

````bmath
# inline module
mod linear_algebra {
  export vec, dot
  vec = |items| ...
  dot = |v1, v2| ...
}

# file-based module import
import math
res = math::sin(1.0) + math::cos(1.0)

# alias
import math as m
res2 = m::sin(0.5)

# selective import
import math::{sin, cos as c}
res3 = sin(0.1) + c(0.2)

# relative file import
import ../utils/linear_algebra # .bm is impicit
````

### Module Visibility & Purity Notes

- [ ] `export` keyword to mark public members
- [ ] Non-exported members are private to module
- [ ] Importing a module does not make the caller impure; calling impure functions does
- [ ] Top-level side-effects in modules mark import as impure; consider explicit opt-in for side-effecting modules

## Variable Scoping Overhaul (Symbol-Based Capture System)

### Language Design Changes

- [ ] **Symbol-Based Capture Syntax**:
  - [ ] Use `!` suffix for captured variables: `captured! = captured! + 1`
  - [ ] Make local scoping the default behavior (variables without `!` are local)
  - [ ] Only function bodies `|| { ... }` create isolated scopes by default
  - [ ] Regular blocks `{ ... }` remain non-isolating (current behavior)

### Capture Semantics Design

- [ ] Define capture behavior with `!` syntax:
  - [ ] `variable!` captures from outer scope (read/write access)
  - [ ] Variables without `!` are always local to function
  - [ ] Error on undefined captures: `undefined_var!` should fail clearly
- [ ] Design capture resolution rules:
  - [ ] Capture from immediate parent scope first, then traverse upward
  - [ ] Module-level variables require explicit capture
  - [ ] Built-in functions always accessible (no capture needed)

### Implementation Changes

- [ ] Update lexer to recognize `!` suffix on identifiers
- [ ] Modify parser for new capture syntax
- [ ] Redesign symbol resolution system in interpreter
- [ ] Update environment management for capture tracking
- [ ] Implement capture validation and error reporting
- [ ] Add Unicode/UTF-8 support to lexer and file name handling

### Documentation and Examples Updates

- [ ] Update language manual for new scoping rules
- [ ] Revise all example files (.bm files in examples/)
- [ ] Update test files to use new scoping syntax
- [ ] Create migration guide from old to new syntax

## Pure Function System with Runtime Purity Tracking

### Runtime Purity Analysis

- [ ] **Dynamic Purity Determination**:
  - [ ] Functions with no `!` captures are pure
  - [ ] Functions with `!` captures need runtime analysis:
    - [ ] If captured value is a pure function → calling function remains pure
    - [ ] If captured value is an impure function → calling function becomes impure
    - [ ] If captured value is a variable → calling function becomes impure
  - [ ] Runtime tracking of function purity status
  - [ ] Purity inheritance: functions calling impure functions become impure
  - [ ] Cache purity results to avoid repeated analysis

### Purity for Parallelization

- [ ] **Iterator Parallelization**:
  - [ ] `map`, `filter`, `reduce` operations check lambda purity
  - [ ] Pure lambdas can be automatically parallelized
  - [ ] Impure lambdas run sequentially
  - [ ] Runtime decision making for parallel execution

### Pure Function Optimizations

- [ ] Implement function memoization for pure functions
- [ ] Add compile-time evaluation for pure expressions
- [ ] Create pure function call optimization
- [ ] Design immutable data structure optimizations

### Advanced Pure Function Features

- [ ] **Function Auto-Differentiation** (if feasible):
  - [ ] Implement automatic derivative computation
  - [ ] Support forward-mode differentiation
  - [ ] Support reverse-mode differentiation
  - [ ] Add gradient computation for multi-variable functions
- [ ] **Function Composition Optimizations**:
  - [ ] Automatic function fusion
  - [ ] Loop fusion for vector operations
  - [ ] Lazy evaluation optimizations
- [ ] **Mathematical Properties Detection**:
  - [ ] Commutativity detection
  - [ ] Associativity detection
  - [ ] Identity element detection
  - [ ] Inverse function detection

## Additional Pure Function Opportunities

### Parallelization

- [ ] Automatic parallelization of pure vector operations
- [ ] Parallel map/reduce implementations
- [ ] Safe concurrent execution of pure functions

### Mathematical Verification

- [ ] Property-based testing for pure functions
- [ ] Symbolic execution for pure functions
- [ ] Formal verification helpers

### Performance Optimizations

- [ ] Dead code elimination in pure functions
- [ ] Common subexpression elimination
- [ ] Constant folding and propagation
- [ ] Tail call optimization

## Error Handling System Redesign

### Dual Error Handling Modes

- [ ] **Default Mode: Error Values**:
  - [ ] Functions return Error type instead of throwing exceptions
  - [ ] Use `is` keyword for error checking: `if (result is Error)`
  - [ ] Error propagation through pure function chains
  - [ ] Integrate error values with existing type system

- [ ] **Exception Mode with `--panic-on-error` Flag**:
  - [ ] Command-line flag to enable exception throwing
  - [ ] Backward compatibility with existing exception-based code
  - [ ] Clear migration path between modes

### Assert Function Behavior

- [ ] **Assert Implementation Strategy**:
  - [ ] **Default mode**: `assert(condition)` calls `exit()` on failure (clean termination)
  - [ ] **Panic mode**: `assert(condition)` throws exception on failure (with stack trace)
  - [ ] **Both modes terminate the program** - assertions are not recoverable
  - [ ] **Assert variants**:
    - [ ] `assert_eq(a, b)` for equality assertions
    - [ ] `assert_ne(a, b)` for inequality assertions
    - [ ] `assert_approx(a, b, epsilon)` for floating-point comparisons
  - [ ] Integration with test framework and unit testing

### Error Integration with Pure Functions

- [ ] Ensure error values don't break function purity
- [ ] Design error propagation in parallel contexts
- [ ] Error handling in module system
- [ ] Performance optimization for error-returning functions

## Language Enhancements

### Type System Integration

- [ ] Add purity information to function types
- [ ] Ensure module types work with existing type system
- [ ] Design module type checking and validation
- [ ] Error type integration with existing types

### Standard Library Reorganization

- [ ] **Modularize Standard Library**:
  - [ ] `core` module: basic operations, arithmetic, comparisons
  - [ ] `math` module: advanced mathematical functions, trigonometry
  - [ ] `io` module: input/output operations, file handling
  - [ ] `test` module: assertion functions, unit testing utilities
  - [ ] `vector` module: vector operations and transformations
  - [ ] `sequence` module: lazy sequences and functional operations

## Development Infrastructure

### Migration and Compatibility

- [ ] **Migration Tools**:
  - [ ] Create automatic migration script for `local` → `!` syntax
  - [ ] Add compatibility warnings for deprecated features
  - [ ] Design gradual migration strategy with both syntaxes supported

### Testing

- [ ] **Comprehensive Test Suite**:
  - [ ] Module system tests with import/export scenarios
  - [ ] Purity analysis tests with various capture patterns
  - [ ] Parallelization tests for iterator operations
  - [ ] Error handling tests for both modes (`--panic-on-error` on/off)
  - [ ] Performance benchmarks for pure function optimizations

### Documentation

- [ ] **Updated Documentation**:
  - [ ] Complete module system documentation with examples
  - [ ] Pure function benefits and usage patterns
  - [ ] Migration guide from v0.11.x syntax
  - [ ] Error handling best practices guide

- [ ] **Example Updates**:
  - [ ] Revise all example files (`.bm` files in `examples/`) for new syntax
  - [ ] Create advanced examples showcasing pure functions and modules
  - [ ] Update test files (`bmath_test/`) to use new scoping syntax
  - [ ] Create parallelization examples with iterator operations

### Development Tools

- [ ] **LSP Server Enhancements**:
  - [ ] Add support for new `!` capture syntax
  - [ ] Implement purity analysis in diagnostics
  - [ ] Module-aware code completion and navigation
  - [ ] Error value integration in type checking

- [ ] **VSCode Extension Updates**:
  - [ ] Syntax highlighting for `!` captures and module syntax
  - [ ] Intelligent code completion for module members
  - [ ] Purity indicators in function signatures
  - [ ] Error handling snippets and templates

## Parser Optimizations Modularization

- [x] Extract parser optimization passes (constant folding, numeric folding, trivial-if simplification, etc.) into a separate `parser_opt` module
- [x] Make optimizations toggleable via CLI flag and runtime config (enable/disable per-run)
- [x] Add tests validating parser output with optimizations enabled vs disabled (added s-expression output for easy parser tests)
- [x] Ensure optimizer module has no global side-effects and is safe to import in parallel parsing contexts
- [x] Pratt parser implemented and integrated into the parser pipeline

## Codebase Refactor & Tooling

- [x] Create a dedicated `formatter` module for BMath source formatting and S-expression output
  - [x] S-expression output API for AST/tests
  - [x] Token-aware pretty-printer with comment preservation
  - [x] CLI integration for `--format` and `--sexp` modes
- [x] Refactor core operations out of `std` and into the `types/value` (or `core`) module
  - [x] Implement arithmetic, comparison and vector ops as methods on `Value`/`Number` types
  - [x] Remove unnecessary std dependencies from core modules
  - [x] Update stdlib to use refactored core ops
- [x] Further modularize the parser pipeline
  - [x] Clear separation: `lexer` -> `parser` (Pratt) -> `parser_opt` -> `interpreter`
  - [x] Add stable S-expression output during parse stage for easy, deterministic parser tests
  - [x] Make parser passes individually toggleable for testing and benchmarking
