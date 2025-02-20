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
  pipeline/parser/[parser, optimizer],
  pipeline/interpreter/interpreter,
  logging,
  types/[value, errors]
when defined(debug):
  import types/expression

type Engine* = ref object ## Stateful evaluation engine maintaining interpreter context
  interpreter*: Interpreter
  optimizer*: Optimizer
  replMode*: bool

proc newEngine*(replMode: bool = false): Engine =
  ## Creates a new evaluation engine with fresh state
  new(result)
  result.interpreter = newInterpreter()
  result.optimizer = newOptimizer()
  result.replMode = replMode

iterator run*(engine: Engine, source: string): LabeledValue =
  ## Executes source while maintaining interpreter state
  debug("Running source: ", source)
  var lexer = newLexer(source)

  while not lexer.atEnd:
    debug("Starting lexing process")

    let tokens = wrapError("LEXING", fatal = not engine.replMode):
      lexer.tokenizeExpression()

    if tokens.len == 0:
      continue

    debug("Tokens: ", tokens)

    debug("Starting parsing process")
    var ast = wrapError("PARSING", fatal = not engine.replMode):
      tokens.parse()

    debug("AST: \n", ast)

    debug("Starting optimization process")
    ast = wrapError("OPTIMIZATION", fatal = not engine.replMode):
      engine.optimizer.optimize(ast)
    debug("Optimized AST: \n", ast)

    debug("Starting evaluation")
    wrapError("RUNTIME", fatal = not engine.replMode):
      yield engine.interpreter.eval(ast)
