## logging.nim

import std/strformat
import types/errors
import pipeline/lexer/errors

proc logError*(error: ref BMathError, context: string) =
  ## Central error logging with context
  const RED = "\x1b[31m"
  const RESET = "\x1b[0m"
  stderr.writeLine fmt"[{RED}{error.name}{RESET}] {error.msg}"
  stderr.writeLine fmt"{RED}Stack Trace{RESET}:"
  while error.stack.len > 0:
    let pos = error.stack.pop()
    stderr.writeLine fmt"  - {pos.line}:{pos.column}"

when defined(debug):
  import std/strutils
  proc debugInternal*(msg: string) =
    ## Debug logging
    const CYAN = "\x1b[36m"
    const RESET = "\x1b[0m"
    for line in msg.splitLines():
      stderr.writeLine fmt"[{CYAN}DEBUG{RESET}] {line}"

  template debug*(args: varargs[string, `$`]) =
    ## Debug logging with multiple arguments
    debugInternal(args.join(" "))

else:
  template debug*(_: varargs[untyped, `$`]) =
    discard

template wrapError*(ctx: string, fatal: bool = true, body: untyped): untyped =
  ## Unified error handling context wrapper
  ## 
  ## Parameters:
  ##   ctx: string - Error context description for diagnostics
  ##   body: untyped - Code block to execute with error wrapping
  ## 
  ## Effects:
  ##   - Captures BMathError exceptions
  ##   - Adds context information to errors
  ##   - Logs errors with full context before exiting
  try:
    body
  except IncompleteInputError as e:
    raise e
  except BMathError as e:
    logError(e, ctx)
    if fatal:
      quit(1)
    else:
      raise e # Allow error propagation in REPL mode
