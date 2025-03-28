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

type
  ArgumentKind* = enum
    akHelp ## Show help documentation
    akFile ## Process input from file
    akExpression ## Process direct expression
    akRepl ## Start interactive REPL

  Arguments* = object ## Structured representation of validated command-line arguments
    case kind*: ArgumentKind
    of akHelp: discard
    of akFile: filePath*: string
    of akExpression: expr*: string
    of akRepl: discard

  InputError* = object of ValueError

import std/[strformat, parsecfg, streams]

const VERSION = staticRead("../bmath.nimble").newStringStream.loadConfig().getSectionValue("", "version")

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
  {GREEN}-h, --help{RESET}     Show this help message
  {GREEN}-f, --file{RESET}     Evaluate expressions from file
  {GREEN}-i, --interactive{RESET}  Start REPL mode

{BOLD}{YELLOW}Examples:{RESET}
  {GREEN}bm "2 + 2 * 2"{RESET}     {GRAY}# Direct expression evaluation{RESET}
  {GREEN}bm -f:input.txt{RESET}    {GRAY}# Evaluate from file{RESET}
  {GREEN}bm{RESET}                 {GRAY}# Start interactive REPL{RESET}"""

proc parse*(): Arguments =
  ## Parses command-line arguments into structured format
  var
    parser = initOptParser()
    positionalArgs: seq[string]

  # First pass for option parsing
  while true:
    parser.next()
    case parser.kind
    of cmdEnd:
      break
    of cmdShortOption, cmdLongOption:
      case parser.key.normalize
      of "h", "help":
        return Arguments(kind: akHelp)
      of "f", "file":
        if parser.val.len == 0:
          raise newException(InputError, "File path cannot be empty")
        if not parser.val.fileExists:
          raise newException(InputError, "File not found: " & parser.val)
        return Arguments(kind: akFile, filePath: parser.val)
      of "i", "interactive":
        return Arguments(kind: akRepl)
      else:
        raise newException(InputError, "Unknown option: " & parser.key)
    of cmdArgument:
      positionalArgs.add parser.key

  # Handle positional arguments
  case positionalArgs.len
  of 0:
    Arguments(kind: akRepl)
  # Default to REPL mode
  of 1:
    Arguments(kind: akExpression, expr: positionalArgs[0])
  else:
    raise newException(InputError, "Too many positional arguments")
