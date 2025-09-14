## utils.nim - Utility functions and macros for stdlib modules
##
## Contains common utilities used across multiple stdlib modules,
## including the native macro for creating native function wrappers.

import std/macros
import ../types/[value, core, errors]

macro native*(call: untyped): Value =
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
