## environment.nim - Environment Management Module
##
## Provides the hierarchical variable scope and function binding system:
## - Lookup of variables and functions in nested lexical scopes
## - Registration and validation of native Nim functions
## - Core built-in mathematical and utility functions
## - Environment creation and manipulation
##
## The environment system implements lexical scoping with parent-child
## relationships between environments, allowing for variable shadowing
## and proper closure behavior.

import std/[sets, tables, macros, complex]
import
  stdlib/[arithmetic, trigonometry, vector, sequence, functional, comparison, control]
import ../../types/[value, expression]
import errors

from math import E, PI

macro native(call: untyped): Value =
  ## Creates a NativeFunc from function call syntax.
  ## 
  ## This macro simplifies wrapping Nim functions as native functions
  ## in the interpreter, automatically validating argument counts and
  ## generating appropriate error messages.
  ## 
  ## Usage:
  ##   native(pow(a, b))  # Creates a NativeFunc that expects exactly 2 arguments
  ##   native(sqrt(x))    # Creates a NativeFunc that expects exactly 1 argument
  ##
  ## Params:
  ##   call: untyped - A function call expression to wrap as a native function
  ##
  ## Returns:
  ##   Value - A vkNativeFunc value that performs argument validation before
  ##           calling the wrapped function
  let funcSym: NimNode = call[0]
  let funcName = $funcSym
  let callArgs = call.len - 1
  let param = ident("args")
  # Generate argument unpacking
  var funcCall = newCall(funcSym)
  for i in 0 ..< callArgs:
    funcCall.add:
      quote:
        `param`[`i`]

  # Construct NativeFunc using quote for clarity
  result = quote:
    Value(
      kind: vkNativeFunc,
      nativeFn: proc(`param`: openArray[Value], _: FnInvoker): Value =
        if `callArgs` != `param`.len:
          raise newInvalidArgumentError(
            "Invalid number of arguments for function `" & `funcName` & "`" &
              " expected " & $`callArgs` & " got " & $`param`.len
          )
        `funcCall`,
    )

# global environment contains all the built-in functions
let global = Environment(
  parent: nil,
  values: toTable(
    {
      # Program Control
      "exit": Value(kind: vkNativeFunc, nativeFn: exit),

      # Mathematical Constants
      "pi": newValue(PI),
      "e": newValue(E),
      "i": newValue(complex[float](0.0, 1.0)),

      # Basic Arithmetic and Math Functions
      "pow": native(`^`(number, number)),
      "sqrt": native(sqrt(number)),
      "floor": native(floor(number)),
      "ceil": native(ceil(number)),
      "abs": native(abs(number)),
      "round": native(round(number)),

      # Trigonometric Functions
      "sin": native(sin(number)),
      "cos": native(cos(number)),
      "tan": native(tan(number)),
      "cot": native(cot(number)),
      "sec": native(sec(number)),
      "csc": native(csc(number)),
      "log": native(log(number, base)),
      "exp": native(exp(number)),

      # Vector Operations
      "vec": Value(kind: vkNativeFunc, nativeFn: vec),
      "len": native(len(vector)),
      "sum": native(sum(vector)),
      "dot": native(dotProduct(vector, vector)),
      "first": native(first(vector)),
      "last": native(last(vector)),
      "merge": native(merge(vector, vector)),
      "slice": Value(kind: vkNativeFunc, nativeFn: slice),
      "set": native(set(vector, number, value)),

      # Sequence Operations
      "seq": Value(kind: vkNativeFunc, nativeFn: sequence),
      "collect": native(collect(sequence)),
      "skip": native(skip(sequence, number)),
      "take": native(take(sequence, number)),
      "hasNext": native(hasNext(sequence)),
      "next": native(next(sequence)),
      "zip": native(zip(sequence, sequence)),

      # Functional Programming Utilities
      "map": Value(kind: vkNativeFunc, nativeFn: map),
      "filter": Value(kind: vkNativeFunc, nativeFn: filter),
      "reduce": Value(kind: vkNativeFunc, nativeFn: reduce),
      "any": native(any(vector)),
      "all": native(all(vector)),
      "nth": native(nth(vector, number)),
      "at": native(nth(vector, number)), # Alias for nth
      "min": Value(kind: vkNativeFunc, nativeFn: min),
      "max": Value(kind: vkNativeFunc, nativeFn: max),
    }
  ),
)

proc newEnv*(parent: Environment = nil): Environment =
  ## Creates a new environment with an optional parent.
  ##
  ## If no parent is provided, creates an environment with the global environment
  ## as its parent. The global environment contains all built-in functions and constants.
  ## Using parent environments establishes proper lexical scoping for variable lookup.
  ##
  ## Params:
  ##   parent: Environment - (optional) The parent environment for lexical scoping (default is nil)
  ##
  ## Returns:
  ##   Environment - A new environment instance with the appropriate parent chain
  new(result)
  if parent == nil:
    result.parent = global
  else:
    result.parent = parent

proc `[]`*(env: Environment, name: string): Value =
  ## Retrieves a value by name from the environment.
  ##
  ## Searches the current environment and traverses up the parent chain
  ## for a variable with the given name, implementing lexical scoping rules.
  ##
  ## Params:
  ##   env: Environment - The environment to start the search in
  ##   name: string - The name of the variable to retrieve
  ##
  ## Returns:
  ##   Value - The value associated with the given name
  ##
  ## Raises:
  ##   UndefinedVariableError - If the variable doesn't exist in any accessible scope
  var currentEnv = env
  while currentEnv != nil:
    if name in currentEnv.values:
      return currentEnv.values[name]
    currentEnv = currentEnv.parent
  raise newUndefinedVariableError(name)

proc `[]=`*(env: Environment, name: string, local: bool = false, value: Value) =
  ## Sets or creates a variable in the environment.
  ##
  ## By default, attempts to update an existing variable in the current
  ## or parent environments (lexical scoping). If local=true, always creates or
  ## updates the variable in the current environment regardless of parent scopes.
  ##
  ## Params:
  ##   env: Environment - The environment to modify
  ##   name: string - The name of the variable to set
  ##   local: bool - (optional) If true, forces creation in the current environment only (default is false)
  ##   value: Value - The value to assign to the variable
  ##
  ## Raises:
  ##   ValueError - If trying to write to a nil environment (programming error)
  ##   ReservedNameError - If trying to modify a built-in/reserved name in CORE_NAMES
  if env == nil:
    # If this is reached, it means there's a bug in the interpreter
    # because the environment should never be nil.
    raise newException(ValueError, "Trying to write on a nil environment")
  if name in global.values and not local and name notin env.values:
    raise newReservedNameError(name)
  if local:
    env.values[name] = value
    return
  var current = env
  while current != nil:
    if current.values.hasKey(name):
      current.values[name] = value
      return
    current = current.parent
  env.values[name] = value
