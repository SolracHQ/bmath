# Contributing to bmath (Nim side)

This document describes how to get started contributing to the Nim implementation of bmath, how standard-library functions are organized, how to add simple and advanced functions, how errors are mapped, and special testing guidance when changing the lexer, parser or interpreter.

Please keep changes small and well tested. If you're unsure about an API or type, open an issue or a draft PR first.

Checklist for this contribution

- [ ] Brief description of change in PR title and body
- [ ] Add/modify tests under `tests/` and/or `bmath_test/` depending on scope
- [ ] Update `docs/stdlib/*.md` for any stdlib changes
- [ ] Use existing error constructors from `src/types/errors.nim`
- [ ] Run local tests before opening PR
- [ ] Format code with `nph` before submitting (run `./format_all.sh` or `nph --check src/**/*.nim`)

## Quick start (developer environment)

- Code lives in `src/` (interpreter, pipeline, stdlib) and `src/types/` (Value, Number, Errors, etc.).
- CLI entry points: `src/cli.nim`, `bin/bm`.
- Standard library implementations are in `src/stdlib/`.
- Tests: unit tests live in `tests/` and there are higher-level BM tests in `bmath_test/`.

Common local commands (zsh):

> Highly unrecommended: avoid using plain `nim` for builds or tests. Use `nimble`.

```bash
# build the `bm` binary via nimble
nimble build bm

# run Nim unit tests (runs test suite configured by the nimble task)
nimble test

# run the project's BM-style integration tests (language-level tests)
./bmath_test/run_tests.sh
```

If your environment uses a different workflow (CI with nimble, docker, etc.), adapt accordingly.

## Important files and types to know

- `src/pipeline/lexer.nim` — tokenization. Changing it affects token shapes, positions, and error classes for malformed input.
- `src/pipeline/parser.nim` — produces the AST. Changes influence how expressions are represented to the interpreter.
- `src/pipeline/interpreter/interpreter.nim` — evaluation engine, uses `Environment` and `Value` types.
- `src/pipeline/interpreter/environment.nim` — environment, native registration helpers and the `global` table.
- `src/stdlib/` — stdlib functions grouped by domain (e.g. `arithmetic.nim`, `functional.nim`, `sequence.nim`).
- `src/stdlib/utils.nim` — utility macros like `captureNumericError`.
- `src/types/` — runtime types, error constructors and helper functions. `Value` and `Number` are the key runtime structures.

Key runtime types:

- `Value` (kinds: `vkNumber`, `vkBool`, `vkVector`, `vkSeq`, `vkFunction`, `vkNativeFunc`, `vkString`, `vkType`, `vkError`, ...)
- `Number` (kinds: `nkInteger`, `nkReal`, `nkComplex`)
- `Vector[Value]` and `Sequence` (generator + transformers)
- `FnInvoker` — the callback provided to stdlib functions that need to call language-level functions; use it as `invoker(fnValue, @[args...])`.

## How stdlib functions are organized (conventions)

- Exported procs use `*`, e.g. `proc sin*(a: Value): Value`.
- Prefer small, focused procs. Group related ops in their domain files.
- Use `.inline.` for thin wrappers where appropriate. Use `.captureNumericError.` (macro in `src/stdlib/utils.nim`) on numeric functions to convert low-level numeric exceptions into interpreter errors.
- validate `Value.kind` before accessing `.number`, `.vector`, `.sequence`, etc.
- For callbacks accept both `vkFunction` and `vkNativeFunc`.

Example patterns:

- Simple numeric function (accepts a `Value`):

```nim
proc myfn*(a: Value): Value {.inline, captureNumericError.} =
  if a.kind == vkNumber:
    return newValue( /* computed Number or use arithmetic operators */ )
  else:
    raise newTypeError("myfn expects a number")
```

- Vectorized form (optional) for functions that should accept vectors:

```nim
proc myfn*(v: Vector[Value]): Value {.inline, captureNumericError.} =
  result = Value(kind: vkVector)
  result.vector = newVector[Value](v.size)
  for i in 0 ..< v.size:
    result.vector[i] = myfn(v[i])
```

## Adding a stdlib function to the language and registering it in `global`

This is a short, concrete recipe for adding a new stdlib function so it becomes available to the language runtime.

1. Implement the function in `src/stdlib/<module>.nim`.

- Export the proc with `*` and follow the project conventions (validate `Value.kind`, use `captureNumericError` when appropriate).
- Provide a vectorized overload if needed (accept `Vector[Value]`) and a unary/binary `Value` overload for normal usage.

2. Register the function in the global environment so it's callable from user code.

- Open `src/pipeline/interpreter/environment.nim` and add an entry in the `global` table.
- Two common registration patterns:

- Simple native wrappers (use the `native` macro): for functions with a fixed, simple signature like `sqrt(number)` or `pow(number, number)` you can write:

  ```nim
  "pi": newValue(PI),
  "sqrt": native(sqrt(number)),
  "pow": native(`^`(number, number)),
  "myfn": native(myfn(number)),
  ```

    The `native(call)` macro generates a `vkNativeFunc` Value that validates the argument count and forwards the call to the Nim proc you implemented.

  - Manual `NativeFn` registration: use this when the function needs the `FnInvoker` or takes an open array of `Value` (e.g. `map`, `filter`, `sequence`), or when you need custom argument handling. Example pattern already used in the repo:

      ```nim
      "map": Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: functional.map, signatures: @[])),
      "seq": Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: sequence, signatures: @[])),
      ```

      Here you register the Nim proc directly as the `callable` of `NativeFn`. The interpreter will call that `callable` with the raw args and an `FnInvoker` so the stdlib proc can invoke user-supplied functions.

3. Add tests and docs.

- Add unit tests under `tests/` (lexer/parser/interpreter) or integration tests under `bmath_test/` depending on scope. If your function is a runtime primitive, prefer `tests/test_interpreter.nim` patterns.
- Add a brief docs entry in `docs/stdlib/<module>.md` with examples.

4. Run the nimble workflow:

  ```bash
  nimble build bm
  nimble test
  ```

Notes:

- Prefer `native(...)` for straightforward, fixed-arity functions — it reduces boilerplate and gives consistent argument-count errors.
- Prefer manual `NativeFn` registration for functions that need the `FnInvoker` or custom argument handling (sequences, higher-order functions, functions that accept `openArray[Value]`).
- Always use the error constructors from `src/types/errors.nim` when validating arguments to produce consistent interpreter-visible errors.

## Adding an advanced function that uses the function invoker (map/filter/reduce)

- Signature pattern: `proc map*(values: openArray[Value], invoker: FnInvoker): Value`.
- Validate the number of args and types early (e.g. source sequence/vector and function).
- When calling the language-level function use the invoker: `let out = invoker(fnVal, @[arg])`.
- Let errors bubble up — the invoker call may raise interpreter errors which should be visible to the user.

Example:

```nim
proc map*(values: openArray[Value], invoker: FnInvoker): Value =
  if values.len != 2:
    raise newInvalidArgumentError("map expects 2 args")
  let src = values[0]
  let fnVal = values[1]
  if fnVal.kind != vkFunction and fnVal.kind != vkNativeFunc:
    raise newTypeError("map: second arg must be a function")

  case src.kind
  of vkVector:
    result = Value(kind: vkVector)
    result.vector = newVector[Value](src.vector.size)
    for i in 0 ..< src.vector.size:
      result.vector[i] = invoker(fnVal, @[src.vector[i]])
  of vkSeq:
    # create a derived sequence which calls invoker on each produced element
  else:
    raise newTypeError("map expects a vector or sequence")
```

## Exception hierarchy and numeric error mapping

- Use the error constructors in `src/types/errors.nim` (e.g. `newTypeError`, `newInvalidArgumentError`, `newZeroDivisionError`, `newVectorLengthMismatchError`, `newArithmeticError`).
- `captureNumericError` (in `src/stdlib/utils.nim`) wraps a proc body in try/except and converts low-level exceptions into the interpreter's errors (division by zero, complex-modulus, complex comparison, unsupported operations, general numeric errors). Prefer this macro on arithmetic/trig/number-manipulation procs.

## Tests: what to change and where to add tests

- Unit tests that validate parser/lexer/token shapes and interpreter behavior are in `tests/` (Nim unit tests) — keep them green. The files in that folder exercise `lexer`, `parser` and `interpreter` directly.
- High-level, language-level tests and examples live in `bmath_test/` (helper scripts and BM-language test files).

When modifying the lexer, parser or interpreter:

- Update or add unit tests in `tests/` that exercise the exact component you changed. Examples in repo:
  - `tests/test_lexer.nim`
  - `tests/test_parser.nim`
  - `tests/test_interpreter.nim`
- For lexer changes validate:
  - token kinds and token ordering for representative inputs
  - token `position` information (line/column) if affected
  - error classes on malformed inputs (expect `IncompleteInputError`, `InvalidNumberFormatError`, ...)
- For parser changes validate:
  - AST node kinds and shapes for changed grammar constructs
  - spacing/newline normalization if applicable (parser consumes token stream produced by lexer)
- For interpreter changes validate:
  - evaluation results for small expressions
  - errors and their types when misuse occurs (type errors, undefined variable, invalid argument counts)
  - semantics of closures, scoping and environment changes (use `tests/test_interpreter.nim` patterns)

Run tests locally after edits:

```bash
# run a single test file
nim c -r tests/test_lexer.nim

# run all unit tests (example using a simple loop)
for f in tests/*.nim; do nim c -r "$f" || break; done

# run BM style integration tests
./bmath_test/run_tests.sh
```

Note: the repository contains multiple test layers. Fast iteration is usually done by running the single, relevant test file first.

## Documentation and style

- Add a short documentation entry in `docs/stdlib/<module>.md` for any public stdlib addition.
- Keep doc comments above procs concise and mention parameters, return values and raised errors.

## PR checklist (what reviewers look for)

- Clear description of the change and motivation.
- Small, focused commits with tests.
- All added/modified tests pass locally.
- Documentation updated for public behavior changes (docs/stdlib).
- Error messages use existing error constructors.
- For lexer/parser/interpreter changes: include unit tests that exercise the change and edge cases (positions, incomplete input, precedence).

## If you need help

- Open an issue describing the design/behavior you want to change.
- Prefer small PRs. For large refactors open a draft PR first and link tests/examples.

Thank you for contributing!
