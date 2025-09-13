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
import ../stdlib/core
import ../types/[value, expression, errors]

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
      nativeFn: NativeFn(
        callable: proc(`param`: openArray[Value], _: FnInvoker): Value =
          if `callArgs` != `param`.len:
            raise newInvalidArgumentError(
              "Invalid number of arguments for function `" & `funcName` & "`" &
                " expected " & $`callArgs` & " got " & $`param`.len
            )
          `funcCall`,
        signatures: @[],
      ),
    )

# Empty global environment for when globals are completely disabled
let empty_global = Environment(
  parent: nil,
  values: initTable[string, Value](),
)

# Minimal global environment with only essential functions
let minimal_global = Environment(
  parent: nil,
  values: toTable(
    {
      "exit": Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: exit, signatures: @[])),
      "print": Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: print, signatures: @[])),
      "try_or": Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: try_or, signatures: @[])),
      "try_catch": Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: try_catch, signatures: @[])),
      "concat": Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: concat, signatures: @[])),
      "sqrt": native(sqrt(a)),
      "abs": native(abs(a)),
      "vec": Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: vec, signatures: @[])),
      "seq": Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: seq, signatures: @[])),
    }
  ),
)

proc newEnv*(parent: Environment = nil, disableGlobals: bool = false): Environment =
  ## Creates a new environment with an optional parent.
  ##
  ## If no parent is provided, creates an environment with the appropriate global environment
  ## as its parent based on the disableGlobals flag.
  ##
  ## Params:
  ##   parent: Environment - (optional) The parent environment for lexical scoping (default is nil)
  ##   disableGlobals: bool - (optional) If true, use empty globals; if false, use minimal globals
  ##
  ## Returns:
  ##   Environment - A new environment instance with the appropriate parent chain
  new(result)
  if parent == nil:
    result.parent = if disableGlobals: empty_global else: minimal_global
  else:
    result.parent = parent

proc `[]`*(env: Environment, name: string): var Value =
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
  if local:
    env.values[name] = value
    return
  var current = env
  while current != nil and current != minimal_global and current != empty_global:
    if current.values.hasKey(name):
      current.values[name] = value
      return
    current = current.parent
  env.values[name] = value
