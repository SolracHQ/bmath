## formatter.nim - Code formatting and output utilities for BMath
##
## This module provides comprehensive formatting capabilities for BMath expressions,
## including S-expression output, source code formatting with configurable rules,
## and pretty-printing utilities.
##
## Features:
## - S-expression output for AST visualization
## - Source code formatting with customizable style rules
## - Line width management with intelligent wrapping
## - Indentation control and code beautification

import std/[strutils, sequtils, math, strformat, tables]
import types/[expression, core, position, vector]

## formatter.nim - Code formatting and output utilities for BMath
##
## This module provides comprehensive formatting capabilities for BMath expressions,
## including S-expression output, source code formatting with configurable rules,
## and pretty-printing utilities.
##
## Features:
## - S-expression output for AST visualization
## - Source code formatting with customizable style rules
## - Line width management with intelligent wrapping
## - Indentation control and code beautification
## - Comment handling via token analysis

import std/[strutils, sequtils, math, strformat, tables]
import types/[expression, core, position, value, token]

type
  OutputFormat* = enum
    ofSource     ## Original BMath source code format
    ofSexp       ## S-expression format
    ofPretty     ## Pretty-printed source with formatting

  FormatterConfig* = object
    ## Configuration for code formatting behavior
    maxLineWidth*: int        ## Maximum line width before wrapping (default: 80)
    indentSize*: int          ## Number of spaces per indent level (default: 2)
    preserveEmptyLines*: bool ## Keep empty lines in source (default: true)
    maxEmptyLines*: int       ## Maximum consecutive empty lines (default: 1)
    wrapOperators*: bool      ## Wrap long binary operations (default: true)
    alignAssignments*: bool   ## Align assignment operators (default: false)
    spacesAroundOps*: bool    ## Add spaces around binary operators (default: true)
    compactVectors*: bool     ## Keep vectors on single line when possible (default: true)
    compactBlocks*: bool      ## Keep simple blocks on single line (default: true)
    wrapComments*: bool       ## Wrap long comments (default: true)
    commentMinWrapLength*: int ## Minimum comment length before wrapping (default: 60)
    preserveInlineComments*: bool ## Try to keep comments inline when possible (default: true)

  CommentInfo* = object
    ## Information about a comment token
    content*: string    ## Comment text (without '#')
    position*: Position ## Source position
    
  FormatterWithTokens* = object
    config*: FormatterConfig
    tokens*: seq[Token]
    comments*: Table[int, seq[CommentInfo]]  ## Map line numbers to comments
    usedComments*: Table[int, bool]  ## Track which comment lines have been used inline
    currentIndent: int
    currentLine: string
    lines: seq[string]

proc newFormatterConfig*(): FormatterConfig =
  ## Creates a default formatter configuration
  FormatterConfig(
    maxLineWidth: 80,
    indentSize: 2,
    preserveEmptyLines: true,
    maxEmptyLines: 1,
    wrapOperators: true,
    alignAssignments: false,
    spacesAroundOps: true,
    compactVectors: true,
    compactBlocks: true,
    wrapComments: true,
    commentMinWrapLength: 60,
    preserveInlineComments: true
  )

proc newFormatterWithTokens*(tokens: seq[Token], config: FormatterConfig = newFormatterConfig()): FormatterWithTokens =
  ## Creates a new formatter with tokens for comment analysis
  var comments = initTable[int, seq[CommentInfo]]()
  
  # Extract comments from tokens and organize by line
  for token in tokens:
    if token.kind == tkComment:
      let lineNum = token.position.line
      if lineNum notin comments:
        comments[lineNum] = @[]
      comments[lineNum].add(CommentInfo(content: token.comment, position: token.position))
  
  FormatterWithTokens(
    config: config,
    tokens: tokens,
    comments: comments,
    usedComments: initTable[int, bool](),
    currentIndent: 0,
    currentLine: "",
    lines: @[]
  )

# =============================================================================
# S-EXPRESSION FORMATTING
# =============================================================================

# Forward declaration
proc formatSexpPretty(expr: Expression, depth: int): string

proc formatSexp*(expr: Expression, compact: bool = false): string

proc formatSexpPretty(expr: Expression, depth: int): string =
  ## Pretty-prints S-expression with proper indentation
  if expr.isNil:
    return "nil"
  
  let indent = "  ".repeat(depth)
  let sexp = expr.asSexp()
  
  # If it's a simple expression or short enough, keep it compact
  if not sexp.startsWith("(") or sexp.len <= 40:
    return sexp
  
  # For complex expressions, add indentation and line breaks
  case expr.kind:
  of ekAdd, ekSub, ekMul, ekDiv, ekMod, ekPow,
     ekEq, ekNe, ekLt, ekLe, ekGt, ekGe, ekAnd, ekOr:
    let op = case expr.kind:
      of ekAdd: "+"
      of ekSub: "-" 
      of ekMul: "*"
      of ekDiv: "/"
      of ekMod: "%"
      of ekPow: "^"
      of ekEq: "=="
      of ekNe: "!="
      of ekLt: "<"
      of ekLe: "<="
      of ekGt: ">"
      of ekGe: ">="
      of ekAnd: "&"
      of ekOr: "|"
      else: "?"
    
    return fmt"""({op}
{indent}  {formatSexpPretty(expr.binaryOp.left, depth + 1)}
{indent}  {formatSexpPretty(expr.binaryOp.right, depth + 1)})"""
  
  of ekFuncCall:
    let funcStr = formatSexpPretty(expr.functionCall.function, depth + 1)
    let argsStr = expr.functionCall.params
      .mapIt(formatSexpPretty(it, depth + 1))
      .join("\n" & indent & "  ")
    return fmt"""(call
{indent}  {funcStr}
{indent}  {argsStr})"""
  
  of ekBlock:
    let exprsStr = expr.blockExpr.expressions
      .mapIt(formatSexpPretty(it, depth + 1))
      .join("\n" & indent & "  ")
    return fmt"""(block
{indent}  {exprsStr})"""
  
  else:
    return sexp

# =============================================================================
# SOURCE CODE FORMATTING WITH TOKEN-BASED COMMENTS
# =============================================================================

proc getCommentsForLine(formatter: FormatterWithTokens, lineNum: int): seq[CommentInfo] =
  ## Gets all comments for a specific line number
  if lineNum in formatter.comments:
    return formatter.comments[lineNum]
  else:
    return @[]

proc getCommentsInRange(formatter: FormatterWithTokens, startLine: int, endLine: int): seq[CommentInfo] =
  ## Gets all comments in a line range
  result = @[]
  for line in startLine..endLine:
    result.add(formatter.getCommentsForLine(line))

proc formatComment(formatter: FormatterWithTokens, comment: CommentInfo, baseIndent: int): string =
  ## Formats a single comment with proper indentation
  let indent = " ".repeat(baseIndent * formatter.config.indentSize)
  return indent & "# " & comment.content.strip()

proc addLine(formatter: var FormatterWithTokens, line: string = "") =
  ## Adds a line to the formatter output
  if line.strip().len > 0 or formatter.config.preserveEmptyLines:
    formatter.lines.add(line)

proc getIndent(formatter: FormatterWithTokens): string =
  ## Returns current indentation string
  " ".repeat(formatter.currentIndent * formatter.config.indentSize)

proc formatExpression(formatter: var FormatterWithTokens, expr: Expression): string =
  ## Formats a single expression according to current rules
  if expr.isNil:
    return ""
  
  # Format the main expression without comment interference
  let mainExpr = case expr.kind:
  of ekValue:
    $expr.value
  
  of ekIdent:
    expr.identifier.ident
  
  of ekAssign:
    let left = expr.assign.ident
    let right = formatExpression(formatter, expr.assign.expr)
    let op = if formatter.config.spacesAroundOps: " = " else: "="
    let localPrefix = if expr.assign.isLocal: "local " else: ""
    localPrefix & left & op & right
  
  of ekAdd, ekSub, ekMul, ekDiv, ekMod, ekPow,
     ekEq, ekNe, ekLt, ekLe, ekGt, ekGe, ekAnd, ekOr:
    let op = case expr.kind:
      of ekAdd: 
        if formatter.config.spacesAroundOps: " + " else: "+"
      of ekSub: 
        if formatter.config.spacesAroundOps: " - " else: "-"
      of ekMul: 
        if formatter.config.spacesAroundOps: " * " else: "*"
      of ekDiv: 
        if formatter.config.spacesAroundOps: " / " else: "/"
      of ekMod: 
        if formatter.config.spacesAroundOps: " % " else: "%"
      of ekPow: 
        if formatter.config.spacesAroundOps: " ^ " else: "^"
      of ekEq: 
        if formatter.config.spacesAroundOps: " == " else: "=="
      of ekNe: 
        if formatter.config.spacesAroundOps: " != " else: "!="
      of ekLt: 
        if formatter.config.spacesAroundOps: " < " else: "<"
      of ekLe: 
        if formatter.config.spacesAroundOps: " <= " else: "<="
      of ekGt: 
        if formatter.config.spacesAroundOps: " > " else: ">"
      of ekGe: 
        if formatter.config.spacesAroundOps: " >= " else: ">="
      of ekAnd: 
        if formatter.config.spacesAroundOps: " & " else: "&"
      of ekOr: 
        if formatter.config.spacesAroundOps: " | " else: "|"
      else: " ? "
    
    let left = formatExpression(formatter, expr.binaryOp.left)
    let right = formatExpression(formatter, expr.binaryOp.right)
    left & op & right
  
  of ekNeg:
    "-" & formatExpression(formatter, expr.unaryOp.operand)
  
  of ekNot:
    "!" & formatExpression(formatter, expr.unaryOp.operand)
  
  of ekGroup:
    "(" & formatExpression(formatter, expr.groupExpr) & ")"
  
  of ekVector:
    let elements = expr.vector.toSeq().mapIt(formatExpression(formatter, it))
    let content = elements.join(", ")
    "[" & content & "]"
  
  of ekFuncCall:
    let funcExpr = formatExpression(formatter, expr.functionCall.function)
    let args = expr.functionCall.params.mapIt(formatExpression(formatter, it))
    let argsStr = args.join(", ")
    funcExpr & "(" & argsStr & ")"
  
  of ekFuncDef:
    let params = expr.functionDef.params.mapIt(it.name).join(", ")
    let body = formatExpression(formatter, expr.functionDef.body)
    "|" & params & "| " & body
  
  of ekBlock:
    formatter.currentIndent += 1
    let indent = formatter.getIndent()
    let bodyIndent = " ".repeat((formatter.currentIndent + 1) * formatter.config.indentSize)
    
    var bodyLines: seq[string] = @[]
    
    # Format each expression in the block with potential inline comments
    for blockExpr in expr.blockExpr.expressions:
      let formattedExpr = formatExpression(formatter, blockExpr)
      let exprLine = blockExpr.position.line
      
      # Check if there are comments on the same line as this expression
      var lineWithComment = bodyIndent & formattedExpr
      if exprLine in formatter.comments:
        for comment in formatter.comments[exprLine]:
          # Add inline comment with proper spacing
          lineWithComment &= "     # " & comment.content.strip()
          # Mark this comment line as used so it doesn't get duplicated later
          formatter.usedComments[exprLine] = true
          break  # Only use the first comment on the same line
      
      bodyLines.add(lineWithComment)
    
    formatter.currentIndent -= 1
    
    "{\n" & bodyLines.join("\n") & "\n" & indent & "}"
  
  of ekIf:
    var ifResult = ""
    
    if expr.ifExpr.branches.len > 0:
      let condition = formatExpression(formatter, expr.ifExpr.branches[0].condition)
      let thenExpr = formatExpression(formatter, expr.ifExpr.branches[0].then)
      ifResult.add("if(" & condition & ") " & thenExpr)
      
      for branch in expr.ifExpr.branches[1..^1]:
        let cond = formatExpression(formatter, branch.condition)
        let then = formatExpression(formatter, branch.then)
        ifResult.add(" elif(" & cond & ") " & then)
    
    if expr.ifExpr.elseBranch != nil:
      let elseExpr = formatExpression(formatter, expr.ifExpr.elseBranch)
      ifResult.add(" else " & elseExpr)
    
    ifResult
  
  return mainExpr

proc formatSourceWithTokens*(expr: Expression, tokens: seq[Token], config: FormatterConfig = newFormatterConfig()): string =
  ## Formats expression as properly formatted BMath source code using tokens for comments
  var formatter = newFormatterWithTokens(tokens, config)
  return formatExpression(formatter, expr)

proc formatSourceWithTokens*(expressions: seq[Expression], tokens: seq[Token], config: FormatterConfig = newFormatterConfig()): string =
  ## Formats expressions with comments reconstructed from tokens
  var formatter = newFormatterWithTokens(tokens, config)
  var lines: seq[string] = @[]
  
  # Extract comments and group them by approximate line ranges
  var commentsByLine: Table[int, seq[string]] = initTable[int, seq[string]]()
  for token in tokens:
    if token.kind == tkComment:
      let line = token.position.line
      if line notin commentsByLine:
        commentsByLine[line] = @[]
      commentsByLine[line].add("# " & token.comment)
  
  # Track what lines we've already added comments for
  var lastCommentLine = 0
  
  # For each expression, add any comments that appear before it
  for i, expr in expressions:
    let exprLine = expr.position.line
    
    # Add any comments that appear between the last expression and this one
    for line in (lastCommentLine + 1)..exprLine:
      if line in commentsByLine and line notin formatter.usedComments:
        for comment in commentsByLine[line]:
          lines.add(comment)
        lastCommentLine = line
    
    # Add the formatted expression
    let formatted = formatExpression(formatter, expr)
    lines.add(formatted)
    
    # Add spacing between expressions (but not after the last one)
    if i < expressions.len - 1:
      lines.add("")
  
  # Add any remaining comments at the end
  let maxLine = if expressions.len > 0: expressions[^1].position.line else: 0
  for line in (lastCommentLine + 1)..1000:  # Reasonable upper bound
    if line in commentsByLine and line notin formatter.usedComments:
      for comment in commentsByLine[line]:
        lines.add(comment)
  
  return lines.join("\n")

# =============================================================================
# PUBLIC FORMATTING API
# =============================================================================

proc formatSexp*(expr: Expression, compact: bool = false): string =
  ## Formats expression as S-expression with optional compact mode
  if compact:
    return expr.asSexp()
  else:
    return formatSexpPretty(expr, 0)

proc format*(expr: Expression, tokens: seq[Token], format: OutputFormat, config: FormatterConfig = newFormatterConfig()): string =
  ## Main formatting function with token-based comment support
  case format:
  of ofSource:
    return expr.asSource()
  of ofSexp:
    return formatSexp(expr, compact = false)
  of ofPretty:
    return formatSourceWithTokens(expr, tokens, config)

proc format*(expressions: seq[Expression], tokens: seq[Token], format: OutputFormat, config: FormatterConfig = newFormatterConfig()): string =
  ## Main formatting function with token-based comment support for multiple expressions
  case format:
  of ofSource:
    return expressions.mapIt(it.asSource()).join("\n\n")
  of ofSexp:
    return expressions.mapIt(formatSexp(it, compact = false)).join("\n\n")
  of ofPretty:
    return formatSourceWithTokens(expressions, tokens, config)