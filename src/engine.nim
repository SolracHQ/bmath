## engine.nim - Evaluation Pipeline Coordinator
##
## Orchestrates the complete expression evaluation process:
## 1. Lexical analysis (tokenization)
## 2. Syntax tree construction (parsing)
## 3. Expression evaluation (interpretation)
##
## Provides the main `run()` procedure that serves as the primary
## API endpoint for expression evaluation.

import lexer, parser, interpreter, logging, types
export types

type Engine* = ref object ## Stateful evaluation engine maintaining interpreter context
  interpreter*: Interpreter
  replMode*: bool

proc newEngine*(replMode: bool = false): Engine =
  ## Creates a new evaluation engine with fresh state
  new(result)
  result.interpreter = newInterpreter()
  result.replMode = replMode

iterator run*(engine: Engine, expression: string): LabeledValue =
  ## Executes expression while maintaining interpreter state
  debug("Running expression: ", expression)
  var lexer = newLexer(expression)

  while not lexer.atEnd:
    debug("Starting lexing process")
    let tokens = wrapError("LEXING", fatal = not engine.replMode):
      lexer.tokenizeExpression()

    debug("Tokens: ", tokens)
    if tokens.len == 0:
      continue

    debug("Starting parsing process")
    let ast = wrapError("PARSING", fatal = not engine.replMode):
      tokens.parse()

    debug("AST: \n", ast)

    debug("Starting evaluation")
    wrapError("RUNTIME", fatal = not engine.replMode):
      yield engine.interpreter.eval(ast)
