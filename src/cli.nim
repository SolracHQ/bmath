## cli.nim - Command Line Interface Module
##
## Implements command-line argument parsing and validation logic.
## Defines the application's interface contract including:
## - Supported options and arguments
## - Input validation rules
## - Help documentation generation
##
## Key Components:
## - `Arguments`: Structured representation of validated inputs
## - `parse()`: Command-line parsing entry point
## - InputError: Domain-specific error type for invalid inputs

import std/[parseopt, strutils, os]
import pipeline/optimization

type
  ArgumentKind* = enum
    akHelp ## Show help documentation
    akFile ## Process input from file
    akExpression ## Process direct expression
    akRepl ## Start interactive REPL
    akFormat ## Format a file and output formatted code
    akSexp ## Output S-expressions for debugging

  Arguments* = object ## Structured representation of validated command-line arguments
    optimizationLevel*: OptimizationLevel
    case kind*: ArgumentKind
    of akHelp: discard
    of akFile: filePath*: string
    of akExpression: expr*: string
    of akRepl: discard
    of akFormat: 
      formatFilePath*: string
      outputPath*: string  # optional, stdout if empty
    of akSexp:
      sexpFilePath*: string
      compact*: bool

  InputError* = object of ValueError

import std/[strformat, parsecfg, streams]

const VERSION = staticRead("../bmath.nimble").newStringStream
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
  {GREEN}-h, --help{RESET}       Show this help message
  {GREEN}-f, --file{RESET}       Evaluate expressions from file
  {GREEN}-i, --interactive{RESET}  Start REPL mode
  {GREEN}-O, --opt-level{RESET}   Set optimization level (none, basic, full) [default: full]
  {GREEN}--format{RESET}         Format a BMath file with pretty-printing
  {GREEN}--sexp{RESET}           Output S-expressions for debugging/analysis
  {GREEN}--compact{RESET}        Use compact S-expression format
  {GREEN}-o, --output{RESET}      Output file path (for formatting operations)

{BOLD}{YELLOW}Examples:{RESET}
  {GREEN}bm "2 + 2 * 2"{RESET}        {GRAY}# Direct expression evaluation{RESET}
  {GREEN}bm -f:input.txt{RESET}       {GRAY}# Evaluate from file{RESET}
  {GREEN}bm -O:none "x + 1"{RESET}     {GRAY}# Disable optimizations{RESET}
  {GREEN}bm --format input.bm{RESET}   {GRAY}# Format file to stdout{RESET}
  {GREEN}bm --format input.bm -o:formatted.bm{RESET}  {GRAY}# Format to file{RESET}
  {GREEN}bm --sexp input.bm{RESET}     {GRAY}# Show S-expressions{RESET}
  {GREEN}bm --sexp --compact input.bm{RESET}  {GRAY}# Compact S-expressions{RESET}
  {GREEN}bm{RESET}                    {GRAY}# Start interactive REPL{RESET}"""

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
    raise newException(InputError, "Invalid optimization level: " & levelStr & " (expected: none, basic, full)")

proc parse*(): Arguments =
  ## Parses command-line arguments into structured format
  var
    parser = initOptParser()
    positionalArgs: seq[string]
    optLevel = olFull  # Default to full optimization
    outputPath = ""
    compact = false

  # First pass for option parsing
  while true:
    parser.next()
    case parser.kind
    of cmdEnd:
      break
    of cmdShortOption, cmdLongOption:
      case parser.key.normalize
      of "h", "help":
        return Arguments(kind: akHelp, optimizationLevel: optLevel)
      of "f", "file":
        if parser.val.len == 0:
          raise newException(InputError, "File path cannot be empty")
        if not parser.val.fileExists:
          raise newException(InputError, "File not found: " & parser.val)
        return Arguments(kind: akFile, filePath: parser.val, optimizationLevel: optLevel)
      of "i", "interactive":
        return Arguments(kind: akRepl, optimizationLevel: optLevel)
      of "o", "opt-level":
        if parser.val.len == 0:
          raise newException(InputError, "Optimization level cannot be empty")
        optLevel = parseOptLevel(parser.val)
      of "format":
        let filePath = if parser.val.len > 0: parser.val else:
          if positionalArgs.len > 0: positionalArgs[0] else: ""
        if filePath.len == 0:
          raise newException(InputError, "Format command requires a file path")
        if not filePath.fileExists:
          raise newException(InputError, "File not found: " & filePath)
        return Arguments(kind: akFormat, formatFilePath: filePath, outputPath: outputPath, optimizationLevel: optLevel)
      of "sexp":
        let filePath = if parser.val.len > 0: parser.val else:
          if positionalArgs.len > 0: positionalArgs[0] else: ""
        if filePath.len == 0:
          raise newException(InputError, "S-expression command requires a file path")
        if not filePath.fileExists:
          raise newException(InputError, "File not found: " & filePath)
        return Arguments(kind: akSexp, sexpFilePath: filePath, compact: compact, optimizationLevel: optLevel)
      of "compact":
        compact = true
      of "output":
        if parser.val.len == 0:
          raise newException(InputError, "Output path cannot be empty")
        outputPath = parser.val
      else:
        raise newException(InputError, "Unknown option: " & parser.key)
    of cmdArgument:
      positionalArgs.add parser.key

  # Handle positional arguments
  case positionalArgs.len
  of 0:
    Arguments(kind: akRepl, optimizationLevel: optLevel)
  # Default to REPL mode
  of 1:
    Arguments(kind: akExpression, expr: positionalArgs[0], optimizationLevel: optLevel)
  else:
    raise newException(InputError, "Too many positional arguments")
