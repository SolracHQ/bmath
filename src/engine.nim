## engine.nim - Evaluation Pipeline Coordinator
##
## Orchestrates the complete expression evaluation process:
## 1. Lexical analysis (tokenization)
## 2. Syntax tree construction (parsing)
## 3. Expression evaluation (interpretation)
##
## Provides the main `run()` procedure that serves as the primary
## API endpoint for expression evaluation.

import
  pipeline/lexer,
  pipeline/parser,
  pipeline/interpreter,
  pipeline/optimization,
  logging,
  types/[value, errors, core]

when defined(debug):
  import types/expression

type Engine* = ref object ## Stateful evaluation engine maintaining interpreter context
  interpreter*: Interpreter
  replMode*: bool
  optimizationLevel*: OptimizationLevel
  disableGlobals*: bool

proc newEngine*(replMode: bool = false, optimizationLevel: OptimizationLevel = olFull, scriptPath: string = "", disableGlobals: bool = false): Engine =
  ## Creates a new evaluation engine with fresh state
  new(result)
  result.interpreter = newInterpreter(scriptPath, disableGlobals)
  result.replMode = replMode
  result.optimizationLevel = optimizationLevel
  result.disableGlobals = disableGlobals

iterator run*(engine: Engine, source: string): Value =
  ## Executes source while maintaining interpreter state
  var lexer = newLexer(source)

  while not lexer.atEnd:
    debug("Starting lexing process")

    let tokens = wrapError("LEXING", fatal = not engine.replMode):
      lexer.tokenizeExpression()

    if tokens.len == 0:
      continue

    if tokens.len == 0:
      continue

    debug("Tokens: ", tokens)

    debug("Starting parsing process")
    var ast = wrapError("PARSING", fatal = not engine.replMode):
      parse(tokens, engine.optimizationLevel)

    debug("AST: \n", $ast)

    debug("Starting evaluation")
    wrapError("RUNTIME", fatal = not engine.replMode):
      yield engine.interpreter.eval(ast)
