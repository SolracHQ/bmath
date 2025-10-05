# BMath v0.12.0 Development Goals

---

## COMPLETED

### Module System Implementation (Issue #16)

**Core Module Infrastructure**

- [x] Design module value representation (modules as first-class values)
- [x] Implement module namespace isolation
- [x] Create module loading and caching system

**Module Syntax Design**

- [x] Chosen module declaration syntax: `mod name { ... }`
- [x] Chosen member access syntax: `module::member`
- [x] Basic `use` import forms implemented:
  - [x] `use("module") as name` / `use(module) as name` — bind module value into scope
  - [x] `use(module::{a, b as alias})` — selective imports and automatic binding
  - [x] Relative/filename imports supported: `use("../path/to/module")` (`.bm` inferred when appropriate)
- [x] File-as-module semantics: basic behavior implemented

### Declaration System & Scoping

**New Declaration System**

- [x] **Immutable Declaration Syntax**: `:=` operator for immutable variables (default behavior)
- [x] **Mutable Declaration Syntax**: `;=` operator for mutable variables
- [x] **Assignment Syntax**: `=` operator (only works with mutable variables)
- [x] **Immutable-by-default Design**: Reflects mathematical nature of the language
- [x] **Type Annotation Support**: Optional type annotations on declarations

**Enhanced Scoping System**

- [x] **Function Scope Isolation**: Functions create isolated scopes by default
- [x] **Block Scope Inheritance**: Regular blocks `{ }` remain non-isolating
- [x] **Explicit Module Access**: `this::` syntax for module-level variable access from functions
- [x] **Implicit Closure Capture**: Automatic capture from immediate parent function scope
- [x] **Clear Scope Separation**: Distinct local, function, and module scopes

### Enhanced Diagnostics & Error System

**Improved Diagnostics**

- [x] **Better Error Messages**: Precise location information and context
- [x] **Enhanced Type Errors**: Expected vs actual type reporting
- [x] **Improved Parse Errors**: Better context and suggestions
- [x] **Lexer Error Handling**: Character position details and recovery

**LSP Integration**

- [x] **Memory-Efficient LSP**: Complete rewrite without caching to prevent RAM issues
- [x] **Real-time Diagnostics**: Integration with lexer/parser/interpreter errors
- [x] **Enhanced Hover**: Type information and documentation
- [x] **Context-Aware Completion**: Improved code completion with scope awareness
- [x] **Multi-line Support**: Proper handling of backslash continuation syntax

### Development Tooling

**VSCode Extension v0.12.0**

- [x] **Updated Syntax Highlighting**: Real stdlib functions and new declaration syntax
- [x] **Declaration Syntax Support**: Highlighting for `:=` and `;=` operators
- [x] **Multi-line Expressions**: Support for backslash continuation (`\`)
- [x] **Accurate Code Snippets**: Real BMath constants and function names
- [x] **Modern LSP Client**: Updated Language Server Protocol implementation
- [x] **Enhanced Diagnostics**: Better error display and reporting

**Parser Infrastructure**

- [x] **Pratt Parser**: Better precedence handling and extensibility
- [x] **Modular Optimizations**: Toggleable parser optimization passes
- [x] **S-expression Output**: Deterministic parser testing support
- [x] **Unicode Preparation**: Foundation for UTF-8 support
- [x] **Line Continuation**: Proper backslash syntax handling

**Code Quality Improvements**

- [x] **Formatter Module**: BMath source formatting capabilities
- [x] **Parser Optimization Module**: Dedicated `optimization` module
- [x] **Core Operations Refactor**: Methods on Value types, reduced dependencies
- [x] **Modular Parser Pipeline**: Clear lexer → parser → optimizer → interpreter flow
- [x] **Comprehensive Testing**: Enhanced test coverage for new features

**Parser Optimizations Modularization (Issue #16)**

- [x] Extract parser optimization passes (constant folding, numeric folding, trivial-if simplification, etc.) into a separate `parser_opt` module
- [x] Make optimizations toggleable via CLI flag and runtime config (enable/disable per-run)
- [x] Add tests validating parser output with optimizations enabled vs disabled (added s-expression output for easy parser tests)
- [x] Ensure optimizer module has no global side-effects and is safe to import in parallel parsing contexts
- [x] Pratt parser implemented and integrated into the parser pipeline

**Codebase Refactor & Tooling**

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

---

## IN PROGRESS

### Type System Redesign

**Core Type System Refactoring** ✅ Phase 1 Complete

- [x] Keep `Signature` type with `params: seq[Parameter]` and `returnType: BMathType`
- [x] Add `isVariadic: bool` field to `Parameter` type for varargs support
- [x] Update `Function` to use single `signature: Signature`
- [x] Update `NativeFn` to use `signatures: seq[Signature]` for overloading
- [x] Update parser to populate `signature` correctly in function definitions
- [x] Update interpreter to use `function.signature.params` instead of `function.params`
- [x] Move `getType()` from `stdlib/types.nim` to `types/bm_types.nim`
- [x] Update all references across codebase (parser, interpreter, expression, value, hover, diagnostics)

**Stdlib Type Annotations** 🔄 Phase 2 In Progress

- [x] Create `nativeFn()` helper to simplify native function creation with signatures
- [x] Add `Signature` annotations to all ~50 stdlib functions:
  - [x] Core functions (6): `exit`, `try_or`, `try_catch`, `print` (varargs), `vec` (2 sigs), `seq` (4 sigs)
  - [x] Arithmetic functions (8): `sqrt`, `abs`, `pow`, `floor`, `ceil`, `round`, `re`, `im`
  - [x] Trigonometry functions (8): `sin`, `cos`, `tan`, `cot`, `sec`, `csc`, `log` (2 sigs), `exp`
  - [x] Vector functions (7): `dot`, `first`, `last`, `len`, `merge`, `slice` (2 sigs), `set`
  - [x] Sequence functions (6): `skip`, `take`, `has_next`, `next`, `collect`, `zip`
  - [x] Functional functions (7): `map`, `filter`, `reduce`, `sum`, `any`, `all`, `nth`
  - [x] Comparison functions (2): `min` (varargs), `max` (varargs)
  - [x] Assertion functions (7): `assert` (2 sigs), `assert_eq` (2 sigs), `assert_neq` (2 sigs), `assert_lt` (2 sigs), `assert_gt` (2 sigs), `assert_type` (2 sigs), `assert_error` (2 sigs)
  - [x] Type functions (1): `type`

**Type Checker Implementation** 🔄 Phase 3 Planned

- [ ] Create `types/type_checker.nim` module
- [ ] Implement `TypeCheckMode` enum (tcmNone, tcmWarn, tcmStrict)
- [ ] Implement `matchesSignature(args, signature)` with varargs support (last param with `isVariadic: true`)
- [ ] Implement `findMatchingSignature(args, signatures)` for overload resolution (try each signature)
- [ ] Implement `checkCall()` with multi-signature matching
- [ ] Add `typeCheckMode` field to `Interpreter`
- [ ] Integrate type checking into `callFunction()` and `callUserFunction()`
- [ ] Add `--type-check=none|warn|strict` CLI flag

**LSP Integration** 📋 Phase 4 Planned

- [ ] Update hover to show function signatures (parse `signatures` array for native functions)
- [ ] Update diagnostics to show type mismatches as warnings/errors
- [ ] Add signature help for function calls with multiple overloads
- [ ] Show inferred types for variables on hover
- [ ] Display parameter types for user-defined functions

**User-Defined Function Type Annotations** ✅ Partially Complete

- [x] Parser extracts type annotations from function literals `|x: Int| => Real { ... }`
- [x] Store annotations in `Function.signature`
- [x] Interpreter uses `signature.params` for parameter binding
- [ ] Enable type checking for user-defined functions in `callUserFunction()`
- [ ] Add syntax support for varargs in user functions (e.g., `|x: Int, rest...: Int|`)

### Effect Tracking System Implementation

**Effect Analysis**

- [ ] Design effect representation system
- [ ] Implement automatic tracking of function side effects
- [ ] Create effect categories (IO, mutation, randomness, etc.)

**Purity Determination**

- [ ] Implement runtime analysis of function purity
- [ ] Track function call graphs for effect propagation
- [ ] Mark functions as pure when no effects detected

**Effect Propagation**

- [ ] Track effects through function call chains
- [ ] Propagate effects from called functions to callers
- [ ] Integrate with module system (detect top-level effects)

### Vector Operation Parallelization

**Parallel Map**

- [ ] Detect pure functions in map operations
- [ ] Implement parallel map for pure functions
- [ ] Add threshold for parallelization (avoid overhead on small vectors)

**Parallel Filter**

- [ ] Detect pure predicates in filter operations
- [ ] Implement parallel filter for pure predicates
- [ ] Optimize for large vector processing

**Side Effect Detection**

- [ ] Ensure only pure functions are parallelized
- [ ] Fall back to sequential execution for impure functions
- [ ] Provide debug mode to show parallelization decisions

**Performance Optimization**

- [ ] Benchmark parallel vs sequential execution
- [ ] Tune parallelization thresholds
- [ ] Add performance metrics and profiling