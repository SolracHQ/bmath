## stdlib.nim - Unified Standard Library Module
##
## Creates a single comprehensive standard library module that includes all
## mathematical, functional, and utility functions from the separate stdlib
## modules. This provides a convenient single import point while maintaining
## the modular organization for development and maintenance.

import std/complex
import std/macros
import ../types/[value, environment, errors]
import ../data/stdlib_signatures
from math import E, PI

# Import all stdlib modules
import arithmetic
import assertions
import comparison
import core
import functional
import sequence
import trigonometry
import types
import vector

proc regFn(env: Environment, name: string, 
           fn: proc(args: openArray[Value], invoker: FnInvoker): Value) =
  ## Register a function that already has the correct signature with signatures loaded from JSON
  env[name, true] = Value(
    kind: vkNativeFunc,
    nativeFn: NativeFn(
      callable: fn,
      signatures: getSignaturesFor(name),
      metadata: getMetadataFor(name)
    ),
  )

macro regFnNative(env: Environment, name: string, call: untyped): untyped =
  ## Register a function using automatic argument wrapping with signatures loaded from JSON.
  ## 
  ## This macro wraps a simple function call (e.g., sqrt(a)) into a native function
  ## that validates argument counts and unpacks arguments automatically.
  let funcSym: NimNode = call[0]
  let funcName = $funcSym
  let callArgs = call.len - 1
  let param = ident("args")
  
  # Generate argument unpacking
  var funcCall = newCall(funcSym)
  for i in 0 ..< callArgs:
    funcCall.add(newTree(nnkBracketExpr, param, newLit(i)))
  
  result = quote do:
    `env`[`name`, true] = Value(
      kind: vkNativeFunc,
      nativeFn: NativeFn(
        callable: proc(`param`: openArray[Value], _: FnInvoker): Value =
          if `callArgs` != `param`.len:
            raise newInvalidArgumentError(
              "Invalid number of arguments for function `" & `funcName` & "`" &
                " expected " & $`callArgs` & " got " & $`param`.len
            )
          `funcCall`,
        signatures: getSignaturesFor(`name`),
        metadata: getMetadataFor(`name`)
      ),
    )

proc injectCoreGlobals*(env: Environment) =
  ## Injects essential core functions into the given environment.
  ## These are the minimal functions needed for basic operation.
  ##
  ## Parameters:
  ## - env: The environment to inject core globals into
  
  # Initialize signatures from JSON
  initSignaturesCache()
  
  # Inject only the most essential core functions
  env.regFn("exit", exit)
  env.regFn("print", print)
  env.regFn("help", help)
  env.regFnNative("type", extractType(value))

proc createStdModule*(): Value =
  ## Creates and returns a unified standard library module containing all functions.
  ##
  ## Returns:
  ##   Value - A module value containing all standard library functions
  let moduleEnv = newEnv()
  
  # Initialize signatures from JSON
  initSignaturesCache()

  # Core functions
  moduleEnv.regFn("exit", exit)
  moduleEnv.regFn("try_or", try_or)
  moduleEnv.regFn("try_catch", try_catch)
  moduleEnv.regFn("print", print)
  moduleEnv.regFn("help", help)
  moduleEnv.regFnNative("sqrt", sqrt(a))
  moduleEnv.regFnNative("abs", abs(a))
  moduleEnv.regFn("vec", vec)
  moduleEnv.regFn("seq", seq)

  # Constants (directly from math module and complex)
  moduleEnv["PI", true] = newValue(PI)
  moduleEnv["E", true] = newValue(E)
  moduleEnv["I", true] = newValue(complex[float](0.0, 1.0))
  moduleEnv["pi", true] = newValue(PI)
  moduleEnv["e", true] = newValue(E)
  moduleEnv["i", true] = newValue(complex[float](0.0, 1.0))

  # Arithmetic functions
  moduleEnv.regFnNative("pow", `^`(base, exp))
  moduleEnv.regFnNative("floor", floor(a))
  moduleEnv.regFnNative("ceil", ceil(a))
  moduleEnv.regFnNative("round", round(a))
  moduleEnv.regFnNative("re", re(a))
  moduleEnv.regFnNative("im", im(a))

  # Trigonometry functions
  moduleEnv.regFnNative("sin", sin(a))
  moduleEnv.regFnNative("cos", cos(a))
  moduleEnv.regFnNative("tan", tan(a))
  moduleEnv.regFnNative("cot", cot(a))
  moduleEnv.regFnNative("sec", sec(a))
  moduleEnv.regFnNative("csc", csc(a))
  moduleEnv.regFnNative("log", log(a, base))
  moduleEnv.regFnNative("exp", exp(a))

  # Vector functions
  moduleEnv.regFnNative("dot", dotProduct(a, b))
  moduleEnv.regFnNative("first", first(vector))
  moduleEnv.regFnNative("last", last(vector))
  moduleEnv.regFnNative("len", len(vector))
  moduleEnv.regFnNative("merge", merge(a, b))
  moduleEnv.regFn("slice", slice)
  moduleEnv.regFnNative("set", set(vector, index, value))

  # Sequence functions
  moduleEnv.regFnNative("skip", skip(sequence, n))
  moduleEnv.regFnNative("take", take(sequence, n))
  moduleEnv.regFnNative("has_next", hasNext(sequence))
  moduleEnv.regFnNative("next", next(sequence))
  moduleEnv.regFnNative("collect", collect(s))
  moduleEnv.regFnNative("zip", zip(seq1, seq2))

  # Functional programming functions
  moduleEnv.regFn("map", map)
  moduleEnv.regFn("filter", filter)
  moduleEnv.regFn("reduce", reduce)
  moduleEnv.regFnNative("sum", sum(a))
  moduleEnv.regFnNative("any", any(a))
  moduleEnv.regFnNative("all", all(a))
  moduleEnv.regFnNative("nth", nth(value, index))
  moduleEnv.regFnNative("at", nth(sequence, index)) # 'at' is an alias for 'nth'

  # Comparison functions
  moduleEnv.regFn("min", min)
  moduleEnv.regFn("max", max)

  # Assertion functions
  moduleEnv.regFn("assert", assert)
  moduleEnv.regFn("assert_eq", assert_eq)
  moduleEnv.regFn("assert_neq", assert_neq)
  moduleEnv.regFn("assert_lt", assert_lt)
  moduleEnv.regFn("assert_gt", assert_gt)
  moduleEnv.regFn("assert_type", assert_type)
  moduleEnv.regFn("assert_error", assert_error)

  # Type functions
  moduleEnv.regFnNative("type", extractType(value))

  result = Value(kind: vkModule, environment: moduleEnv)
