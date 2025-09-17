## logging.nim - Simple, focused logging for BMath interpreter
##
## Core Philosophy:
## - Simple, focused logging - interpreter-specific, not generic application logging  
## - BMath-specific error recovery and display
## - Clear, colorized output for development

import std/[terminal, strformat, strutils]
import ../types/errors

type LogLevel* = enum
  llDebug
  llInfo
  llWarn
  llError
  llFatal

var currentLevel = llInfo
var useColors = stdout.isatty

proc setLogLevel*(level: LogLevel) =
  currentLevel = level

proc setColors*(enabled: bool) =
  useColors = enabled

const COLORS = [
  llDebug: "\x1b[36m", # cyan
  llInfo: "\x1b[34m", # blue  
  llWarn: "\x1b[33m", # yellow
  llError: "\x1b[31m", # red
  llFatal: "\x1b[31;1m", # bold red
]

const NAMES = [
  llDebug: "DEBUG", llInfo: "INFO ", llWarn: "WARN ", llError: "ERROR", llFatal: "FATAL"
]

proc log(level: LogLevel, msg: string) =
  if level < currentLevel:
    return

  const RESET = "\x1b[0m"

  let output =
    if useColors:
      fmt"{COLORS[level]}{NAMES[level]}{RESET} {msg}"
    else:
      fmt"{NAMES[level]} {msg}"

  stderr.writeLine(output)
  stderr.flushFile()

# Simple templates for each log level
template debug*(msg: string) =
  log(llDebug, msg)

template info*(msg: string) =
  log(llInfo, msg)

template warn*(msg: string) =
  log(llWarn, msg)

template error*(msg: string) =
  log(llError, msg)

template fatal*(msg: string) =
  log(llFatal, msg)

# Multi-arg versions
template debug*(args: varargs[string, `$`]) =
  debug(args.join(" "))

template info*(args: varargs[string, `$`]) =
  info(args.join(" "))

template warn*(args: varargs[string, `$`]) =
  warn(args.join(" "))

template error*(args: varargs[string, `$`]) =
  error(args.join(" "))

template fatal*(args: varargs[string, `$`]) =
  fatal(args.join(" "))

proc logError*(error: ref BMathError, context: string) =
  ## Enhanced error logging with context
  error(fmt"[{context}] {error.name}: {error.msg}")

  # Show stack trace if available
  if error.stack.len > 0:
    error("Stack trace:")
    for pos in error.stack:
      error(fmt"  at {pos.line}:{pos.column}")

  when defined(debug):
    debug("Full stack trace:")
    debug(error.getStackTrace())

proc parseLogLevel*(levelStr: string): LogLevel =
  ## Parse log level from string
  case levelStr.normalize
  of "debug", "0":
    llDebug
  of "info", "1":
    llInfo
  of "warn", "warning", "2":
    llWarn
  of "error", "3":
    llError
  of "fatal", "4":
    llFatal
  else:
    warn(fmt"Unknown log level '{levelStr}', using 'info'")
    llInfo

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
    echo e.getStackTrace()
    if fatal:
      quit(1)
    else:
      raise e # Allow error propagation in REPL mode
