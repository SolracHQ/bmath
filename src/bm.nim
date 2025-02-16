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

import cli, engine

proc main =
  let args = try: parse()
  except InputError as e:
    stderr.writeLine HELP
    stderr.writeLine "[ERROR] " & e.msg
    quit(1)

  case args.kind
  of akHelp:
    echo HELP
  of akExpression:
    let engine = newEngine()
    for value in engine.run(args.expr): echo value
  of akFile:
    let engine = newEngine()
    let content = readFile(args.filePath)
    for result in engine.run(content):
      echo result
  of akRepl:
    let engine = newEngine(replMode = true)
    var input: string
    while true:
      stdout.write "bm> "
      try:
        input = stdin.readLine()
        for result in engine.run(input):
          echo "=> ", result
      except BMathError: discard # already handled by engine
      except:
        echo "Unexpected error: ", getCurrentExceptionMsg()

when isMainModule:
  main()
