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
import std/[terminal, sequtils, strformat]
import cli, engine, ../logging/logging
import ../types/[value, errors, expression]
import ../pipeline/[optimization, parser, lexer, diagnostics as diag]

proc handleHelp() =
  echo HELP

proc handleExpression(
    expr: string,
    optLevel: OptimizationLevel,
    disableGlobals: bool,
    showDiagnostics: bool,
) =
  if showDiagnostics:
    let diagnostics = diag.analyzeFile("<expression>", expr)
    diag.showDiagnostics(diagnostics, expr)
    if diagnostics.len > 0:
      info("Found issues, but continuing execution...")

  let engine = newEngine(optimizationLevel = optLevel, disableGlobals = disableGlobals)
  for value in engine.run(expr):
    echo value

proc handleFile(
    filePath: string,
    optLevel: OptimizationLevel,
    disableGlobals: bool,
    showDiagnostics: bool,
) =
  let content = readFile(filePath)

  if showDiagnostics:
    let diagnostics = diag.analyzeFile(filePath, content)
    diag.showDiagnostics(diagnostics, content)
    if diagnostics.len > 0:
      let errorCount = diagnostics.countIt(it.severity == diag.dsError)
      if errorCount > 0:
        error(fmt"Found {errorCount} error(s), stopping execution")
        quit(1)
      else:
        info("Found warnings, but continuing execution...")

  let engine = newEngine(
    optimizationLevel = optLevel, scriptPath = filePath, disableGlobals = disableGlobals
  )
  for result in engine.run(content):
    echo result

proc handleDiagnostics(filePath: string) =
  ## Handle standalone diagnostics mode
  let content = readFile(filePath)
  let diagnostics = diag.analyzeFile(filePath, content)

  if diagnostics.len == 0:
    info("No issues found.")
  else:
    diag.showDiagnostics(diagnostics, content)
    let errorCount = diagnostics.countIt(it.severity == diag.dsError)
    let warningCount = diagnostics.countIt(it.severity == diag.dsWarning)
    let infoCount = diagnostics.countIt(it.severity == diag.dsInfo)

    echo fmt"Summary: {errorCount} errors, {warningCount} warnings, {infoCount} info"

    if errorCount > 0:
      quit(1)

proc handleSexp(filePath: string, compact: bool, optLevel: OptimizationLevel) =
  ## Handles S-expression output for debugging
  try:
    let content = readFile(filePath)
    var lexer = newLexer(content)
    var parser = newParser(optLevel)

    # Parse and output S-expressions for all expressions in the file
    while not lexer.atEnd:
      let tokens = lexer.tokenizeExpression(includeComments = false)
      if tokens.len > 0:
        let ast = parser.parse(tokens)
        let sexp = ast.asSexp()
        echo sexp
        if not compact:
          echo "" # Add separator between expressions
  except IOError as e:
    stderr.writeLine "[ERROR] IO Error: " & e.msg
    quit(1)
  except BMathError as e:
    stderr.writeLine "[ERROR] Parse Error: " & e.msg
    quit(1)

proc handleRepl(optLevel: OptimizationLevel, disableGlobals: bool) =
  let isatty = stdin.isatty

  # Handle non-interactive input as a script
  if not isatty:
    handleExpression(stdin.readAll(), optLevel, disableGlobals, false)
    return

  let engine = newEngine(
    replMode = true, optimizationLevel = optLevel, disableGlobals = disableGlobals
  )

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

proc main*() =
  let args = parse()

  # Set up logging based on CLI args
  setLogLevel(args.logLevel)
  setColors(not args.noColors)

  case args.kind
  of akHelp:
    handleHelp()
  of akExpression:
    handleExpression(
      args.expr, args.optimizationLevel, args.disableGlobals, args.showDiagnostics
    )
  of akFile:
    handleFile(
      args.filePath, args.optimizationLevel, args.disableGlobals, args.showDiagnostics
    )
  of akRepl:
    handleRepl(args.optimizationLevel, args.disableGlobals)
  of akSexp:
    handleSexp(args.sexpFilePath, args.compact, args.optimizationLevel)
  of akDiagnostics:
    handleDiagnostics(args.diagnosticsFilePath)
