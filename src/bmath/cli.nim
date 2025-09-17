## cli.nim - Command Line Interface Module
##
## Implements command-line argument parsing and validation logic.
## Defines the application's interface contrac  # Handle positional arguments
## - Supported options and arguments
## - Input validation rules
## - Help documentation generation
##
## Key Components:
## - `Arguments`: Structured representation of validated inputs
## - `parse()`: Command-line parsing entry point
## - InputError: Domain-specific error type for invalid inputs

import std/[parseopt, strutils, os]
import ../pipeline/optimization
import ../logging/logging

type
  ArgumentKind* = enum
    akHelp ## Show help documentation
    akFile ## Process input from file
    akExpression ## Process direct expression
    akRepl ## Start interactive REPL
    akSexp ## Output S-expressions for debugging
    akDiagnostics ## Run static analysis diagnostics

  Arguments* = object ## Structured representation of validated command-line arguments
    optimizationLevel*: OptimizationLevel
    disableGlobals*: bool ## Whether to disable global functions
    logLevel*: LogLevel ## Logging level
    showDiagnostics*: bool ## Whether to show diagnostics alongside execution
    noColors*: bool ## Disable colored output
    case kind*: ArgumentKind
    of akHelp: discard
    of akFile: filePath*: string
    of akExpression: expr*: string
    of akRepl: discard
    of akSexp:
      sexpFilePath*: string
      compact*: bool
    of akDiagnostics: diagnosticsFilePath*: string

  InputError* = object of ValueError

import std/[strformat, parsecfg, streams]

const VERSION = staticRead("../../bmath.nimble").newStringStream
  .loadConfig()
  .getSectionValue("", "version")

const
  RESET: string = "\x1B[0m"
  BOLD: string = "\x1B[1m"
  CYAN: string = "\x1B[36m"
  YELLOW: string = "\x1B[33m"
  GREEN: string = "\x1B[32m"
  MAGENTA: string = "\x1B[35m"
  GRAY: string = "\x1B[90m"

const HELP* =
  fmt"""
{BOLD}{CYAN}Basic Math CLI v{VERSION}{RESET}
{BOLD}{YELLOW}Usage:{RESET}
  bm {MAGENTA}[options]{RESET} {MAGENTA}[expression]{RESET}

{BOLD}{YELLOW}Options:{RESET}
  {GREEN}-h, --help{RESET}           Show this help message
  {GREEN}-f, --file{RESET}           Evaluate expressions from file
  {GREEN}-i, --interactive{RESET}      Start REPL mode
  {GREEN}-O, --opt-level{RESET}       Set optimization level (none, basic, full) [default: full]
  {GREEN}--disable-globals{RESET}      Disable global functions (use modules only)
  {GREEN}--sexp{RESET}               Output S-expressions for debugging/analysis
  {GREEN}--compact{RESET}            Use compact S-expression format
  {GREEN}--diagnostics{RESET}        Run static analysis diagnostics
  {GREEN}--log-level{RESET}          Set log level (debug, info, warn, error, fatal) [default: info]
  {GREEN}--no-colors{RESET}          Disable colored output

{BOLD}{YELLOW}Examples:{RESET}
  {GREEN}bm "2 + 2 * 2"{RESET}            {GRAY}# Direct expression evaluation{RESET}
  {GREEN}bm -f:input.txt{RESET}           {GRAY}# Evaluate from file{RESET}
  {GREEN}bm -O:none "x + 1"{RESET}         {GRAY}# Disable optimizations{RESET}
  {GREEN}bm --disable-globals "sqrt(4)"{RESET}  {GRAY}# Use modules only{RESET}
  {GREEN}bm --sexp input.bm{RESET}         {GRAY}# Show S-expressions{RESET}
  {GREEN}bm --sexp --compact input.bm{RESET}  {GRAY}# Compact S-expressions{RESET}
  {GREEN}bm --diagnostics input.bm{RESET}   {GRAY}# Check for issues{RESET}
  {GREEN}bm --log-level=debug --diagnostics input.bm{RESET}  {GRAY}# Verbose diagnostics{RESET}
  {GREEN}bm{RESET}                        {GRAY}# Start interactive REPL{RESET}"""

proc parseOptLevel(levelStr: string): OptimizationLevel =
  ## Parse optimization level string
  case levelStr.normalize
  of "none", "0":
    olNone
  of "basic", "1":
    olBasic
  of "full", "2":
    olFull
  else:
    raise newException(
      InputError,
      "Invalid optimization level: " & levelStr & " (expected: none, basic, full)",
    )

proc parse*(): Arguments =
  ## Parses command-line arguments into structured format
  var
    parser = initOptParser()
    positionalArgs: seq[string]
    optLevel = olFull # Default to full optimization
    compact = false
    disableGlobals = false
    logLevel = llInfo
    showDiagnostics = false
    noColors = false

  # First pass for option parsing
  while true:
    parser.next()
    case parser.kind
    of cmdEnd:
      break
    of cmdShortOption, cmdLongOption:
      case parser.key.normalize
      of "h", "help":
        return Arguments(
          kind: akHelp,
          optimizationLevel: optLevel,
          disableGlobals: disableGlobals,
          logLevel: logLevel,
          showDiagnostics: showDiagnostics,
          noColors: noColors,
        )
      of "f", "file":
        if parser.val.len == 0:
          raise newException(InputError, "File path cannot be empty")
        if not parser.val.fileExists:
          raise newException(InputError, "File not found: " & parser.val)
        return Arguments(
          kind: akFile,
          filePath: parser.val,
          optimizationLevel: optLevel,
          disableGlobals: disableGlobals,
          logLevel: logLevel,
          showDiagnostics: showDiagnostics,
          noColors: noColors,
        )
      of "i", "interactive":
        return Arguments(
          kind: akRepl,
          optimizationLevel: optLevel,
          disableGlobals: disableGlobals,
          logLevel: logLevel,
          showDiagnostics: showDiagnostics,
          noColors: noColors,
        )
      of "o", "opt-level":
        if parser.val.len == 0:
          raise newException(InputError, "Optimization level cannot be empty")
        optLevel = parseOptLevel(parser.val)
      of "disable-globals":
        disableGlobals = true
      of "log-level":
        if parser.val.len == 0:
          raise newException(InputError, "Log level cannot be empty")
        logLevel = parseLogLevel(parser.val)
      of "diagnostics":
        let filePath =
          if parser.val.len > 0:
            parser.val
          else:
            if positionalArgs.len > 0:
              positionalArgs[0]
            else:
              ""
        if filePath.len == 0:
          raise newException(InputError, "Diagnostics command requires a file path")
        if not filePath.fileExists:
          raise newException(InputError, "File not found: " & filePath)
        return Arguments(
          kind: akDiagnostics,
          diagnosticsFilePath: filePath,
          optimizationLevel: optLevel,
          disableGlobals: disableGlobals,
          logLevel: logLevel,
          showDiagnostics: showDiagnostics,
          noColors: noColors,
        )
      of "show-diagnostics":
        showDiagnostics = true
      of "no-colors":
        noColors = true
      of "sexp":
        let filePath =
          if parser.val.len > 0:
            parser.val
          else:
            if positionalArgs.len > 0:
              positionalArgs[0]
            else:
              ""
        if filePath.len == 0:
          raise newException(InputError, "S-expression command requires a file path")
        if not filePath.fileExists:
          raise newException(InputError, "File not found: " & filePath)
        return Arguments(
          kind: akSexp,
          sexpFilePath: filePath,
          compact: compact,
          optimizationLevel: optLevel,
          disableGlobals: disableGlobals,
          logLevel: logLevel,
          showDiagnostics: showDiagnostics,
          noColors: noColors,
        )
      of "compact":
        compact = true
      else:
        raise newException(InputError, "Unknown option: " & parser.key)
    of cmdArgument:
      positionalArgs.add parser.key

  # Handle positional arguments
  case positionalArgs.len
  of 0:
    Arguments(
      kind: akRepl,
      optimizationLevel: optLevel,
      disableGlobals: disableGlobals,
      logLevel: logLevel,
      showDiagnostics: showDiagnostics,
      noColors: noColors,
    )
  # Default to REPL mode
  of 1:
    Arguments(
      kind: akExpression,
      expr: positionalArgs[0],
      optimizationLevel: optLevel,
      disableGlobals: disableGlobals,
      logLevel: logLevel,
      showDiagnostics: showDiagnostics,
      noColors: noColors,
    )
  else:
    raise
      newException(InputError, "Too many positional arguments: " & $positionalArgs.len)
