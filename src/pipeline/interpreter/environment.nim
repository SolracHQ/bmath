import std/[sets, tables, macros]
import value
import ../../types/[value, errors, expression]

const CORE_NAMES* = toHashSet(
  [
    "pow", "exit", "sqrt", "floor", "ceil", "round", "dot", "vec", "nth", "first",
    "last", "sin", "cos", "tan", "log", "exp", "len", "map", "filter", "reduce", "sum",
    "any", "all",
  ]
)

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
    funcCall.add:
      quote:
        `evaluator`(`param`[`i`])

  # Construct NativeFunc using quote for clarity
  result = quote:
    Value(
      kind: vkNativeFunc,
      nativeFunc: NativeFunc(
        argc: `callArgs`,
        fun: proc(`param`: openArray[Expression], `evaluator`: Evaluator): Value =
          `funcCall`,
      ),
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
      "round": native(round(number)),
      "dot": native(dotProduct(vector, vector)),
      "nth": native(nth(vector, number)),
      "first": native(first(vector)),
      "last": native(last(vector)),
      "vec": newValue(NativeFunc(argc: 2, fun: createVector)),
      "map": newValue(NativeFunc(argc: 2, fun: map)),
      "filter": newValue(NativeFunc(argc: 2, fun: filter)),
      "reduce": newValue(NativeFunc(argc: 2, fun: reduce)),
      "sin": native(sin(number)),
      "cos": native(cos(number)),
      "tan": native(tan(number)),
      "log": native(log(number, base)),
      "exp": native(exp(number)),
      "len": native(len(vector)),
      "sum": native(sum(vector)),
      "any": native(any(vector)),
      "all": native(all(vector)),
    }
  ),
)

proc newEnv*(parent: Environment = nil): Environment =
  if parent == nil:
    return global
  new(result)
  result.parent = parent

proc `[]`*(env: Environment, name: string): Value =
  var currentEnv = env
  while currentEnv != nil:
    if name in currentEnv.values:
      return currentEnv.values[name]
    currentEnv = currentEnv.parent
  raise newException(BMathError, "Variable '" & name & "' is not defined")

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
