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
import std/[terminal, sequtils]
import cli, engine, formatter
import types/[value, errors, expression, core]
import pipeline/[optimization, parser, lexer]

proc handleHelp() =
  echo HELP

proc handleExpression(expr: string, optLevel: OptimizationLevel) =
  let engine = newEngine(optimizationLevel = optLevel)
  for value in engine.run(expr):
    echo value

proc handleFile(filePath: string, optLevel: OptimizationLevel) =
  let engine = newEngine(optimizationLevel = optLevel)
  let content = readFile(filePath)
  for result in engine.run(content):
    echo result

proc handleFormat(filePath, outputPath: string, optLevel: OptimizationLevel) =
  ## Handles file formatting with pretty-printing
  try:
    let content = readFile(filePath)
    var lexer = newLexer(content)
    var expressions: seq[Expression] = @[]
    var allTokens: seq[Token] = @[]
    
    # Parse all expressions in the file and collect tokens
    while not lexer.atEnd:
      let tokens = lexer.tokenizeExpression()
      if tokens.len > 0:
        allTokens.add(tokens)
        # Filter out comments before parsing
        let filteredTokens = tokens.filterIt(it.kind != tkComment)
        if filteredTokens.len > 0:
          let ast = filteredTokens.parse(optLevel)
          expressions.add(ast)
    
    let config = newFormatterConfig()
    let formatted = format(expressions, allTokens, ofPretty, config)
    
    if outputPath.len > 0:
      writeFile(outputPath, formatted)
      echo "Formatted file written to: ", outputPath
    else:
      echo formatted
      
  except IOError as e:
    stderr.writeLine "[ERROR] IO Error: " & e.msg
    quit(1)
  except BMathError as e:
    stderr.writeLine "[ERROR] Parse Error: " & e.msg
    quit(1)

proc handleSexp(filePath: string, compact: bool, optLevel: OptimizationLevel) =
  ## Handles S-expression output for debugging
  try:
    let content = readFile(filePath)
    var lexer = newLexer(content)
    
    # Parse and output S-expressions for all expressions in the file
    while not lexer.atEnd:
      let tokens = lexer.tokenizeExpression()
      if tokens.len > 0:
        # Filter out comments before parsing
        let filteredTokens = tokens.filterIt(it.kind != tkComment)
        if filteredTokens.len > 0:
          let ast = filteredTokens.parse(optLevel)
          let sexp = formatSexp(ast, compact)
          echo sexp
          if not compact:
            echo ""  # Add separator between expressions
        
  except IOError as e:
    stderr.writeLine "[ERROR] IO Error: " & e.msg
    quit(1)
  except BMathError as e:
    stderr.writeLine "[ERROR] Parse Error: " & e.msg
    quit(1)
  let isatty = stdin.isatty

  # Handle non-interactive input as a script
  if not isatty:
    handleExpression(stdin.readAll(), optLevel)
    return

  let engine = newEngine(replMode = true, optimizationLevel = optLevel)

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

proc handleRepl(optLevel: OptimizationLevel) =
  let isatty = stdin.isatty

  # Handle non-interactive input as a script
  if not isatty:
    handleExpression(stdin.readAll(), optLevel)
    return

  let engine = newEngine(replMode = true, optimizationLevel = optLevel)

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
    handleExpression(args.expr, args.optimizationLevel)
  of akFile:
    handleFile(args.filePath, args.optimizationLevel)
  of akRepl:
    handleRepl(args.optimizationLevel)
  of akFormat:
    handleFormat(args.formatFilePath, args.outputPath, args.optimizationLevel)
  of akSexp:
    handleSexp(args.sexpFilePath, args.compact, args.optimizationLevel)

when isMainModule:
  main()
