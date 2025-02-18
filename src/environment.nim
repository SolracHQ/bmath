import std/[sets, tables, macros]
import types, value

const CORE_NAMES = toHashSet(["pow", "exit", "sqrt", "floor", "ceil", "round", "dot", "vec", "nth", "first", "last"])

proc `[]`*(env: Environment, name: string): Value =
  if env == nil:
    raise newException(BMathError, "Variable '" & name & "' is not defined")
  elif name in env.values:
    return env.values[name]
  else:
    return env.parent[name]

proc `[]=`*(env: Environment, name: string, local: bool = false, value: Value) =
  if env == nil:
    raise newException(ValueError, "Trying to write on a nil environment")
  if name in CORE_NAMES:
    raise newException(BMathError, "Cannot overwrite the reserved name '" & name & "'")
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
  let evaluator = ident("evaluator")
  # Generate argument unpacking
  var funcCall = newCall(funcSym)
  for i in 0 ..< callArgs:
    funcCall.add: quote: `evaluator`(`param`[`i`])

  # Construct NativeFunc using quote for clarity
  result = quote:
    Value(
      kind: vkNativeFunc,
      nativeFunc: NativeFunc(
        argc: `callArgs`,
        fun: proc(`param`: openArray[Expression], `evaluator`: proc(node: Expression): Value): Value =
          `funcCall`,
      ),
    )

proc newEnv*(parent: Environment = nil): Environment =
  new(result)
  result.parent = parent
  if parent == nil:
    # Initialize with core functions
    result.values["exit"] = native(quit())
    result.values["pow"] = native(`^`(a, b))
    result.values["sqrt"] = native(sqrt(a))
    result.values["floor"] = native(floor(a))
    result.values["ceil"] = native(ceil(a))
    result.values["round"] = native(round(a))
    result.values["dot"] = native(dotProduct(a, b))
    result.values["nth"] = native(nth(a, b))
    result.values["first"] = native(first(a))
    result.values["last"] = native(last(a))
    result.values["vec"] = Value(kind: vkNativeFunc, nativeFunc: NativeFunc(argc: 2, fun: createVector) )