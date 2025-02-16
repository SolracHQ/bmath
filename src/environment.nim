import std/[sets, tables, macros]
import types, value

const CORE_NAMES = toHashSet(["pow", "exit", "sqrt", "floor", "ceil", "round"])

proc `[]`*(env: Environment, name: string): Value =
  if env == nil:
    raise newException(BMathError, "Variable '" & name & "' is not defined")
  elif not (name in env.values):
    return env.parent[name]
  else:
    return env.values[name]

proc `[]=`*(env: Environment, name: string, value: Value) =
  if env == nil:
    raise newException(ValueError, "Trying to write on a nil environment")
  if name in CORE_NAMES:
    raise newException(BMathError, "Cannot overwrite the reserved name '" & name & "'")
  var current = env
  while current != nil:
    if current.values.hasKey(name):
      current.values[name] = value
      return
    current = current.parent
  env.values[name] = value

proc hasKey*(env: Environment, name: string): bool =
  if env == nil:
    return false
  elif name in env.values:
    return true
  else:
    return env.parent.hasKey(name)

macro native(call: untyped): Value =
  ## Creates a NativeFunc from function call syntax.
  ## 
  ## Usage:
  ##   native(pow(a, b))  # Creates NativeFunc with argc=2
  
  let funcSym = call[0]
  let callArgs = call.len - 1
  let param = ident("args")

  # Generate argument unpacking
  var funcCall = newCall(funcSym)
  for i in 0..<callArgs:
    funcCall.add nnkBracketExpr.newTree(param, newLit(i))

  # Construct NativeFunc using quote for clarity
  result = quote do:
    Value(kind: vkNativeFunc, nativeFunc: NativeFunc(argc: `callArgs`, fun: proc(`param`: seq[Value]): Value = `funcCall`))

proc newEnv*(parent: Environment = nil): Environment =
  new(result)
  result.parent = parent
  if parent == nil:
    # Initialize with core functions
    result.values["exit"] = Value(kind: vkNativeFunc, nativeFunc: NativeFunc(fun: proc(args: seq[Value]): Value = quit(0)))
    result.values["pow"] = native(`^`(a, b))
    result.values["sqrt"] = native(sqrt(a))
    result.values["floor"] = native(floor(a))
    result.values["ceil"] = native(ceil(a))
    result.values["round"] = native(round(a))

