## stdlib.nim - Unified Standard Library Module
##
## Creates a single comprehensive standard library module that includes all
## mathematical, functional, and utility functions from the separate stdlib
## modules. This provides a convenient single import point while maintaining
## the modular organization for development and maintenance.

import std/complex
import ../types/[value, environment]
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
from utils import native

proc createStdModule*(): Value =
  ## Creates and returns a unified standard library module containing all functions.
  ##
  ## Returns:
  ##   Value - A module value containing all standard library functions
  let moduleEnv = newEnv()
  
  # Core functions
  moduleEnv["exit", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: exit, signatures: @[]))
  moduleEnv["try_or", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: try_or, signatures: @[]))
  moduleEnv["try_catch", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: try_catch, signatures: @[]))
  moduleEnv["print", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: print, signatures: @[]))
  moduleEnv["sqrt", true] = native(sqrt(a))
  moduleEnv["abs", true] = native(abs(a))
  moduleEnv["vec", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: vec, signatures: @[]))
  moduleEnv["seq", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: seq, signatures: @[]))
  
  # Constants (directly from math module and complex)
  moduleEnv["PI", true] = newValue(PI)
  moduleEnv["E", true] = newValue(E)
  moduleEnv["I", true] = newValue(complex[float](0.0, 1.0))
  moduleEnv["pi", true] = newValue(PI)
  moduleEnv["e", true] = newValue(E)
  moduleEnv["i", true] = newValue(complex[float](0.0, 1.0))
  
  # Arithmetic functions
  moduleEnv["pow", true] = native(`^`(base, exp))
  moduleEnv["floor", true] = native(floor(a))
  moduleEnv["ceil", true] = native(ceil(a))
  moduleEnv["round", true] = native(round(a))
  moduleEnv["re", true] = native(re(a))
  moduleEnv["im", true] = native(im(a))
  
  # Trigonometry functions
  moduleEnv["sin", true] = native(sin(a))
  moduleEnv["cos", true] = native(cos(a))
  moduleEnv["tan", true] = native(tan(a))
  moduleEnv["cot", true] = native(cot(a))
  moduleEnv["sec", true] = native(sec(a))
  moduleEnv["csc", true] = native(csc(a))
  moduleEnv["log", true] = native(log(a, base))
  moduleEnv["exp", true] = native(exp(a))
  
  # Vector functions
  moduleEnv["dot", true] = native(dotProduct(a, b))
  moduleEnv["first", true] = native(first(vector))
  moduleEnv["last", true] = native(last(vector))
  moduleEnv["len", true] = native(len(vector))
  moduleEnv["merge", true] = native(merge(a, b))
  moduleEnv["slice", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: slice, signatures: @[]))
  moduleEnv["set", true] = native(set(vector, index, value))
  
  # Sequence functions
  moduleEnv["skip", true] = native(skip(sequence, n))
  moduleEnv["take", true] = native(take(sequence, n))
  moduleEnv["has_next", true] = native(hasNext(sequence))
  moduleEnv["next", true] = native(next(sequence))
  moduleEnv["collect", true] = native(collect(s))
  moduleEnv["zip", true] = native(zip(seq1, seq2))
  
  # Functional programming functions
  moduleEnv["map", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: map, signatures: @[]))
  moduleEnv["filter", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: filter, signatures: @[]))
  moduleEnv["reduce", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: reduce, signatures: @[]))
  moduleEnv["sum", true] = native(sum(a))
  moduleEnv["any", true] = native(any(a))
  moduleEnv["all", true] = native(all(a))
  moduleEnv["nth", true] = native(nth(value, index))
  moduleEnv["at", true] = native(nth(sequence, index)) # 'at' is an alias for 'nth'
  
  # Comparison functions
  moduleEnv["min", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: min, signatures: @[]))
  moduleEnv["max", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: max, signatures: @[]))
  
  # Assertion functions
  moduleEnv["assert", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: assert, signatures: @[]))
  moduleEnv["assert_eq", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: assert_eq, signatures: @[]))
  moduleEnv["assert_neq", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: assert_neq, signatures: @[]))
  moduleEnv["assert_lt", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: assert_lt, signatures: @[]))
  moduleEnv["assert_gt", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: assert_gt, signatures: @[]))
  moduleEnv["assert_type", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: assert_type, signatures: @[]))
  moduleEnv["assert_error", true] = Value(kind: vkNativeFunc, nativeFn: NativeFn(callable: assert_error, signatures: @[]))
  
  # Type functions
  moduleEnv["type", true] = native(extractType(value))
  
  result = Value(kind: vkModule, environment: moduleEnv)