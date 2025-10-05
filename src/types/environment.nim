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

import std/[tables]
import ../types/[value, expression, errors]

from ../types/core import EnvironmentKind

proc newEnv*(
    kind: EnvironmentKind = ekBlock,
    parent: Environment = nil,
): Environment =
  ## Creates a new environment with specified kind and optional parent.
  ##
  ## Params:
  ##   kind: EnvironmentKind - The kind of scope this environment represents
  ##   parent: Environment - (optional) The parent environment for lexical scoping (default is nil)
  ##
  ## Returns:
  ##   Environment - A new environment instance
  new(result)
  result.kind = kind
  result.values = initTable[string, Value]()
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

proc declareMutableVariable*(env: Environment, name: string, value: Value) =
  ## Declares a mutable variable in the current environment.
  ## If the variable already exists and is mutable, it will be reassigned.
  ## If the variable exists but is immutable, raises an error.
  ##
  ## This is useful for use() expressions where you want to allow redeclaration:
  ##   use(std::print)("hello")
  ##   use(std::print)("world")  # This should work
  ##
  ## Params:
  ##   env: Environment - The environment to declare the variable in
  ##   name: string - The name of the variable to declare
  ##   value: Value - The value to bind to the variable name (must be mutable)
  ##
  ## Raises:
  ##   ImmutableAssignmentError - If trying to redeclare an immutable variable
  if name in env.values:
    let existingValue = env.values[name]
    if not existingValue.metadata.isMutable:
      raise newImmutableAssignmentError(name)
    # Variable exists and is mutable, so we can reassign it
    env.values[name] = value
  else:
    # Variable doesn't exist, create it
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
