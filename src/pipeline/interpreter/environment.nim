## environment.nim - Environment Management Module
##
## Provides the variable scope and function binding system:
## - Lookup of variables and functions in hierarchical scopes
## - Registration of native functions with argument validation
## - Core built-in function implementation
## - Environment creation and management
##
## The environment system implements lexical scoping with parent-child
## relationships between environments.

import std/[sets, tables, macros]
import stdlib/[arithmetic, trigonometry, vector, sequence, itertools]
import ../../types/[value, expression]
import errors

from math import E, PI

const CORE_NAMES* = toHashSet(
  [
    "pow", "exit", "sqrt", "floor", "ceil", "round", "dot", "vec", "nth", "first",
    "last", "sin", "cos", "tan", "cot", "sec", "csc", "log", "exp", "len", "map",
    "filter", "reduce", "sum", "any", "all", "collect", "seq", "skip", "hasNext",
    "next", "e", "pi", "abs",
  ]
)

macro native(call: untyped): Value =
  ## Creates a NativeFunc from function call syntax.
  ## 
  ## This macro simplifies wrapping Nim functions as native functions
  ## in the interpreter, automatically validating argument counts.
  ## 
  ## Usage:
  ##   native(pow(a, b))  # Creates NativeFunc that validates the number of arguments amd calls pow(a, b)
  ##
  ## Params:
  ##   call: untyped - A function call expression to wrap
  ##
  ## Returns:
  ##   Value - A vkNativeFunc value that wraps the given function
  let funcSym: NimNode = call[0]
  let funcName = $funcSym
  let callArgs = call.len - 1
  let param = ident("args")
  # Generate argument unpacking
  var funcCall = newCall(funcSym)
  for i in 0 ..< callArgs:
    funcCall.add:
      quote: `param`[`i`]

  # Construct NativeFunc using quote for clarity
  result = quote:
    Value(
      kind: vkNativeFunc,
      nativeFn: proc(`param`: openArray[Value], _: FnInvoker): Value =
                  if `callArgs` != `param`.len:
                    raise newInvalidArgumentError(
                      "Invalid number of arguments for function `" & `funcName` & "`" & " expected " &
                      $`callArgs` & " got " & $`param`.len,
                    )
                  `funcCall`
    )

# global environment contains all the built-in functions
let global = Environment(
  parent: nil,
  values: toTable(
    {
      "exit": native(quit()),
      "pow": native(`^`(number, number)),
      "sqrt": native(sqrt(number)),
      "floor": native(floor(number)),
      "ceil": native(ceil(number)),
      "abs": native(abs(number)),
      "round": native(round(number)),
      "dot": native(dotProduct(vector, vector)),
      "nth": native(nth(vector, number)),
      "first": native(first(vector)),
      "last": native(last(vector)),
      "vec": Value(kind: vkNativeFunc,nativeFn:vec),
      "seq": Value(kind: vkNativeFunc, nativeFn: sequence),
      "map": Value(kind: vkNativeFunc, nativeFn: itertools.map),
      "filter": Value(kind: vkNativeFunc, nativeFn: itertools.filter),
      "reduce": Value(kind: vkNativeFunc, nativeFn: itertools.reduce),
      "collect": native(collect(sequence)),
      "sin": native(sin(number)),
      "cos": native(cos(number)),
      "tan": native(tan(number)),
      "cot": native(cot(number)),
      "sec": native(sec(number)),
      "csc": native(csc(number)),
      "log": native(log(number, base)),
      "exp": native(exp(number)),
      "len": native(len(vector)),
      "sum": native(sum(vector)),
      "any": native(any(vector)),
      "all": native(all(vector)),
      "skip": native(skip(sequence, number)),
      "hasNext": native(hasNext(sequence)),
      "next": native(next(sequence)),
      "e": newValue(E),
      "pi": newValue(PI),
    }
  ),
)

proc newEnv*(parent: Environment = nil): Environment =
  ## Creates a new environment with an optional parent.
  ##
  ## If no parent is provided, returns the global environment containing
  ## all built-in functions. Otherwise, creates a new environment with the
  ## specified parent, establishing lexical scoping.
  ##
  ## Params:
  ##   parent: Environment - (optional) The parent environment (default is nil)
  ##
  ## Returns:
  ##   Environment - A new environment instance
  if parent == nil:
    return global
  new(result)
  result.parent = parent

proc `[]`*(env: Environment, name: string): Value =
  ## Retrieves a value by name from the environment.
  ##
  ## Searches the current environment and all parent environments
  ## for a variable with the given name.
  ##
  ## Params:
  ##   env: Environment - The environment to search in
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
  ## or parent environments. If local=true, always creates/updates the variable
  ## in the current environment regardless of parent scopes.
  ##
  ## Params:
  ##   env: Environment - The environment to modify
  ##   name: string - The name of the variable to set
  ##   local: bool - (optional) If true, forces creation in the current environment (default is false)
  ##   value: Value - The value to assign to the variable
  ##
  ## Raises:
  ##   ValueError - If trying to write to a nil environment (programming error)
  ##   ReservedNameError - If trying to modify a built-in/reserved name
  if env == nil:
    # If this is reached, it means there's a bug in the interpreter
    # because the environment should never be nil.
    raise newException(ValueError, "Trying to write on a nil environment")
  if name in CORE_NAMES:
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
