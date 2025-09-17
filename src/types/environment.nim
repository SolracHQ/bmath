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

from ../types/core import EnvironmentKind

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
      metadata: ValueMetadata(isMutable: false),
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
let empty_global =
  Environment(kind: ekModule, parent: nil, values: initTable[string, Value]())

# Minimal global environment with only essential functions
let minimal_global = Environment(
  kind: ekModule,
  parent: nil,
  values: toTable(
    {
      "exit": Value(
        kind: vkNativeFunc,
        metadata: ValueMetadata(isMutable: false),
        nativeFn: NativeFn(callable: exit, signatures: @[]),
      ),
      "print": Value(
        kind: vkNativeFunc,
        metadata: ValueMetadata(isMutable: false),
        nativeFn: NativeFn(callable: print, signatures: @[]),
      ),
      "try_or": Value(
        kind: vkNativeFunc,
        metadata: ValueMetadata(isMutable: false),
        nativeFn: NativeFn(callable: try_or, signatures: @[]),
      ),
      "try_catch": Value(
        kind: vkNativeFunc,
        metadata: ValueMetadata(isMutable: false),
        nativeFn: NativeFn(callable: try_catch, signatures: @[]),
      ),
      "concat": Value(
        kind: vkNativeFunc,
        metadata: ValueMetadata(isMutable: false),
        nativeFn: NativeFn(callable: concat, signatures: @[]),
      ),
      "sqrt": native(sqrt(a)),
      "abs": native(abs(a)),
      "vec": Value(
        kind: vkNativeFunc,
        metadata: ValueMetadata(isMutable: false),
        nativeFn: NativeFn(callable: vec, signatures: @[]),
      ),
      "seq": Value(
        kind: vkNativeFunc,
        metadata: ValueMetadata(isMutable: false),
        nativeFn: NativeFn(callable: seq, signatures: @[]),
      ),
    }
  ),
)

proc newEnv*(
    kind: EnvironmentKind = ekBlock,
    parent: Environment = nil,
    disableGlobals: bool = false,
): Environment =
  ## Creates a new environment with specified kind and optional parent.
  ##
  ## If no parent is provided, creates an environment with the appropriate global environment
  ## as its parent based on the disableGlobals flag.
  ##
  ## Params:
  ##   kind: EnvironmentKind - The kind of scope this environment represents
  ##   parent: Environment - (optional) The parent environment for lexical scoping (default is nil)
  ##   disableGlobals: bool - (optional) If true, use empty globals; if false, use minimal globals
  ##
  ## Returns:
  ##   Environment - A new environment instance with the appropriate parent chain
  new(result)
  result.kind = kind
  result.values = initTable[string, Value]()
  if parent == nil:
    result.parent = if disableGlobals: empty_global else: minimal_global
  else:
    result.parent = parent

proc `in`*(name: string, env: Environment): bool =
  ## Checks if a variable name exists in the current environment.
  ##
  ## This only checks the current environment and does not traverse parent scopes.
  ##
  ## Params:
  ##   name: string - The name of the variable to check
  ##   env: Environment - The environment to check in
  ##
  ## Returns:
  ##   bool - True if the variable exists in the current environment, false otherwise
  name in env.values

proc `[]`*(env: Environment, name: string): Value =
  ## Retrieves a value by name from the environment.
  ##
  ## Searches the current environment and traverses up the parent chain
  ## for a variable with the given name, implementing lexical scoping rules.
  ## Functions can only access variables from their capture environment,
  ## not traverse beyond function boundaries (must use this:: for module access).
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
  var foundFunctionBoundary = false

  while currentEnv != nil:
    if name in currentEnv.values:
      return currentEnv.values[name]

    # If we hit a function boundary and we're looking from within a function,
    # we should not traverse beyond it (except for the first function environment
    # which is the function we're executing in)
    if currentEnv.kind == ekFunction:
      if foundFunctionBoundary:
        break
      foundFunctionBoundary = true

    currentEnv = currentEnv.parent

  raise newUndefinedVariableError(name)

proc declareVariable*(env: Environment, name: string, value: Value) =
  ## Declares a new variable in the current environment.
  ##
  ## Creates a new variable binding in the local scope. This function enforces
  ## that declarations can only happen in the current scope (no traversal up
  ## the parent chain).
  ##
  ## Params:
  ##   env: Environment - The environment to declare the variable in
  ##   name: string - The name of the variable to declare
  ##   value: Value - The value to bind to the variable name
  ##
  ## Raises:
  ##   RedefinitionError - If the variable already exists in the current scope
  if name in env.values:
    raise
      newRedefinitionError("Variable '" & name & "' is already defined in this scope")

  env.values[name] = value

proc assignVariable*(env: Environment, name: string, value: Value) =
  ## Assigns a value to an existing mutable variable.
  ## This is used by assignment (=) and only modifies existing variables.
  ##
  ## Params:
  ##   env: Environment - The environment to start the search in
  ##   name: string - The name of the variable to assign to
  ##   value: Value - The value to assign
  ##
  ## Raises:
  ##   UndefinedVariableError - If the variable doesn't exist in any accessible scope
  ##   ImmutableAssignmentError - If trying to assign to an immutable variable
  var currentEnv = env
  var value = value
  while currentEnv != nil:
    if name in currentEnv.values:
      let existingValue = currentEnv.values[name]
      if not existingValue.metadata.isMutable:
        raise newImmutableAssignmentError(name)
      # set value as mutable
      value.metadata.isMutable = true
      currentEnv.values[name] = value
      return
    currentEnv = currentEnv.parent

  raise newUndefinedVariableError(name)

proc `[]=`*(env: Environment, name: string, local: bool = false, value: Value) =
  ## Legacy operator - now just calls declareVariable for local=true or assignVariable for local=false
  ## This is kept for stdlib compatibility (I will chage it in the future but is not my priority now)
  ## FIXME: Remove this in the future
  if local:
    env.declareVariable(name, value)
  else:
    env.assignVariable(name, value)
