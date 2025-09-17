# Main v0.12.0 Goals

## ✅ COMPLETED: Module System Implementation

### Core Module Infrastructure (Related Github Issue #16) - ✅ DONE

- [x] Design module value representation (modules as first-class values)
- [x] Implement module namespace isolation
- [x] Create module loading and caching system

### Module Syntax Design (Related Github Issue #16) - ✅ DONE

- [x] Chosen module declaration syntax: `mod name { ... }`
- [x] Chosen member access syntax: `module::member`
- [x] Basic `use` import forms implemented:
  - [x] `use("module") as name` / `use(module) as name` — bind module value into scope
  - [x] `use(module::{a, b as alias})` — selective imports and automatic binding
  - [x] Relative/filename imports supported: `use("../path/to/module")` (`.bm` inferred when appropriate)
- [x] File-as-module semantics: basic behavior implemented

## ✅ COMPLETED: Declaration System & Scoping

### New Declaration System - ✅ DONE

- [x] **Immutable Declaration Syntax**: `:=` operator for immutable variables (default behavior)
- [x] **Mutable Declaration Syntax**: `;=` operator for mutable variables
- [x] **Assignment Syntax**: `=` operator (only works with mutable variables)
- [x] **Immutable-by-default Design**: Reflects mathematical nature of the language
- [x] **Type Annotation Support**: Optional type annotations on declarations

### Enhanced Scoping System - ✅ DONE

- [x] **Function Scope Isolation**: Functions create isolated scopes by default
- [x] **Block Scope Inheritance**: Regular blocks `{ }` remain non-isolating
- [x] **Explicit Module Access**: `this::` syntax for module-level variable access from functions
- [x] **Implicit Closure Capture**: Automatic capture from immediate parent function scope
- [x] **Clear Scope Separation**: Distinct local, function, and module scopes

## ✅ COMPLETED: Enhanced Diagnostics & Error System

### Improved Diagnostics - ✅ DONE

- [x] **Better Error Messages**: Precise location information and context
- [x] **Enhanced Type Errors**: Expected vs actual type reporting
- [x] **Improved Parse Errors**: Better context and suggestions
- [x] **Lexer Error Handling**: Character position details and recovery

### LSP Integration - ✅ DONE

- [x] **Memory-Efficient LSP**: Complete rewrite without caching to prevent RAM issues
- [x] **Real-time Diagnostics**: Integration with lexer/parser/interpreter errors
- [x] **Enhanced Hover**: Type information and documentation
- [x] **Context-Aware Completion**: Improved code completion with scope awareness
- [x] **Multi-line Support**: Proper handling of backslash continuation syntax

## ✅ COMPLETED: Development Tooling

### VSCode Extension v0.12.0 - ✅ DONE

- [x] **Updated Syntax Highlighting**: Real stdlib functions and new declaration syntax
- [x] **Declaration Syntax Support**: Highlighting for `:=` and `;=` operators
- [x] **Multi-line Expressions**: Support for backslash continuation (`\`)
- [x] **Accurate Code Snippets**: Real BMath constants and function names
- [x] **Modern LSP Client**: Updated Language Server Protocol implementation
- [x] **Enhanced Diagnostics**: Better error display and reporting

### Parser Infrastructure - ✅ DONE

- [x] **Pratt Parser**: Better precedence handling and extensibility
- [x] **Modular Optimizations**: Toggleable parser optimization passes
- [x] **S-expression Output**: Deterministic parser testing support
- [x] **Unicode Preparation**: Foundation for UTF-8 support
- [x] **Line Continuation**: Proper backslash syntax handling

### Code Quality Improvements - ✅ DONE

- [x] **Formatter Module**: BMath source formatting capabilities
- [x] **Parser Optimization Module**: Dedicated `optimization` module
- [x] **Core Operations Refactor**: Methods on Value types, reduced dependencies
- [x] **Modular Parser Pipeline**: Clear lexer → parser → optimizer → interpreter flow
- [x] **Comprehensive Testing**: Enhanced test coverage for new features

## 🚧 REMAINING WORK FOR v0.12.0

### Effect Tracking System Implementation

- [ ] **Effect Analysis**: Automatic tracking of function side effects
- [ ] **Purity Determination**: Runtime analysis of function purity
- [ ] **Effect Propagation**: Tracking effects through function call chains

### Vector Operation Parallelization

- [ ] **Parallel Map**: Automatically parallelize `map` operations on pure functions
- [ ] **Parallel Filter**: Automatically parallelize `filter` operations on pure functions  
- [ ] **Side Effect Detection**: Ensure only pure functions are parallelized
- [ ] **Performance Optimization**: Efficient parallel execution for large vectors

## 📋 FUTURE VERSIONS (Not for v0.12.0)

### Module Visibility & Purity Notes (Future)

- [ ] `export` keyword to mark public members
- [ ] Non-exported members are private to module
- [ ] Module purity tracking and side-effect analysis
- [ ] Top-level side-effects in modules mark import as impure

### Error Handling System Redesign (Future)

- [ ] **Error Values Mode**: Functions return Error type instead of exceptions
- [ ] **Exception Mode**: `--panic-on-error` flag for backward compatibility
- [ ] **Assert Variants**: `assert_eq`, `assert_ne`, `assert_approx`
- [ ] **Error Propagation**: Integration with pure function chains

### Advanced Pure Function Features (Future)

- [ ] **Function Auto-Differentiation**: Automatic derivative computation
- [ ] **Function Composition Optimizations**: Automatic fusion and lazy evaluation
- [ ] **Mathematical Properties Detection**: Commutativity, associativity, etc.
- [ ] **Function Memoization**: Caching for pure functions

### Migration and Compatibility Tools (Future)

- [ ] **Migration Scripts**: Automated syntax migration tools
- [ ] **Compatibility Warnings**: Deprecated feature notifications
- [ ] **Gradual Migration**: Support for mixed syntax during transition

## Parser Optimizations Modularization (Related Github Issue #16)

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
