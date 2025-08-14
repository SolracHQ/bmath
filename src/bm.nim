## bm.nim - Main Application Module
## 
## Provides the entry point for the Basic Math CLI application.
## Handles command-line arguments, input sources, and coordinates
## the evaluation pipeline.
## 
## The main flow is:
## 1. Parse CLI arguments
## 2. Read input (file or direct expression)
## 3. Execute through engine.run()
## 4. Output result
import std/terminal
import cli, engine, types/value, types, errors

proc handleHelp() =
  echo HELP

proc handleExpression(expr: string) =
  let engine = newEngine()
  for value in engine.run(expr):
    echo value

proc handleFile(filePath: string) =
  let engine = newEngine()
  let content = readFile(filePath)
  for result in engine.run(content):
    echo result

proc handleRepl() =
  let isatty = stdin.isatty

  # Handle non-interactive input as a script
  if not isatty:
    handleExpression(stdin.readAll())
    return

  let engine = newEngine(replMode = true)

  # Interactive REPL mode
  var input: string
  var incompleteMode = false
  while true:
    if not incompleteMode:
      stdout.write "bm> "
    else:
      stdout.write "... "
    try:
      if incompleteMode:
        input.add "\n"
        input &= stdin.readLine()
      else:
        input = stdin.readLine()
      for result in engine.run(input):
        echo "==> ", result
      incompleteMode = false
    except IncompleteInputError:
      incompleteMode = true
      continue
    except BMathError as e:
      discard
    # error already handled
    except IOError as e:
      quit() # EOF reached or Ctrl+C

proc main() =
  let args =
    try:
      parse()
    except InputError as e:
      stderr.writeLine HELP
      stderr.writeLine "[ERROR] " & e.msg
      quit(1)

  case args.kind
  of akHelp:
    handleHelp()
  of akExpression:
    handleExpression(args.expr)
  of akFile:
    handleFile(args.filePath)
  of akRepl:
    handleRepl()

when isMainModule:
  main()
