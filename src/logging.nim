## logging.nim

import std/[times, strformat]
import types 

proc logError*(error: ref BMathError) =
  ## Central error logging with context
  let timeStamp = now().format("HH:mm:ss'.'fff")
  const RED = "\x1b[31m"
  const RESET = "\x1b[0m"
  stderr.writeLine fmt"{timeStamp} [{error.context} {RED}ERROR{RESET}] {error.position}: {error.msg}"
  #when defined(debug): stderr.writeLine error.getStackTrace

when defined(debug):
  import std/strutils
  proc debugInternal*(msg: string) =
    ## Debug logging
    const CYAN = "\x1b[36m"
    const RESET = "\x1b[0m"
    for line in msg.splitLines():
      let timeStamp = now().format("HH:mm:ss'.'fff")
      stderr.writeLine fmt"{timeStamp} [{CYAN}DEBUG{RESET}] {line}"

  template debug*(args: varargs[string, `$`]) =
    ## Debug logging with multiple arguments
    debugInternal(args.join(" "))
else:
  template debug*(_: varargs[untyped]) = discard

template newBMathError*(message: string, pos: Position): ref BMathError =
  ## Creates a new BMathError with given position and message
  (ref BMathError)(position: pos, msg: message)

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
  except BMathError as e:
    e.context = ctx
    when defined(expression):
      e.source = expression
    logError(e)
    if fatal:
      quit(1)
    else:
      raise e  # Allow error propagation in REPL mode

