## hover.nim - LSP Hover Information Provider
##
## Provides hover information for BMath symbols including:
## - Keywords, types, and built-in functions
## - Type inference for user-defined identifiers  
## - Enhanced context-aware documentation with scope analysis

import std/[strutils, strformat, tables]
import protocol
import bmath_knowledge
import ../pipeline/[diagnostics as diag, lexer, parser, optimization]
import ../types/[core, expression, errors, bm_types]

# Text analysis utilities
proc extractWordAtPosition(text: string, line: int, character: int): string =
  ## Extract the word at the cursor position (0-based line/character)
  let lines = text.splitLines()
  if line < 0 or line >= lines.len:
    return ""

  let currentLine = lines[line]
  if character < 0 or character >= currentLine.len:
    return ""

  var start = character
  var `end` = character

  # Extend backwards to find word start
  while start > 0 and currentLine[start - 1] in {
    'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'
  }
  :
    dec start

  # Extend forwards to find word end
  while `end` < currentLine.len and
      currentLine[`end`] in {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}:
    inc `end`

  if start >= `end`:
    return ""

  return currentLine[start ..< `end`]

proc isNumericLiteral(word: string): bool =
  ## Check if a word is a numeric literal
  try:
    discard parseFloat(word)
    return true
  except ValueError:
    return false

type
  SymbolInfo = object
    name: string
    symbolType: string
    scope: string # "global", "local", "parameter", "captured"
    isParameter: bool
    isMutable: bool
    isUsed: bool
    declaredAt: Position

  HoverAnalyzer = object
    targetLine: int # 0-based 
    targetChar: int # 0-based
    targetWord: string
    symbolInfo: SymbolInfo
    currentScope: diag.AnalysisScope
    globalScope: diag.AnalysisScope
    isInFunction: bool
    foundSymbol: bool

# Forward declarations
proc findSymbolAtPosition(analyzer: var HoverAnalyzer, expr: Expression)
proc inferExpressionType(analyzer: var HoverAnalyzer, expr: Expression): string

proc inferExpressionType(analyzer: var HoverAnalyzer, expr: Expression): string =
  ## Infer the type of an expression based on its structure  
  case expr.kind
  of ekValue:
    case expr.value.kind
    of vkNumber:
      case expr.value.number.kind
      of nkInteger:
        return "Int"
      of nkReal:
        return "Real"
      of nkComplex:
        return "Complex"
    of vkBool:
      return "Bool"
    of vkString:
      return "String"
    of vkFunction:
      return "Function"
    of vkVector:
      return "Vec"
    of vkSeq:
      return "Seq"
    of vkType:
      return "Type"
    of vkModule:
      return "Module"
    else:
      return "Unknown"
  of ekIdent:
    try:
      let varInfo = analyzer.currentScope.lookupVariable(expr.identifier.ident)
      return if varInfo.varType.len > 0: varInfo.varType else: "Unknown"
    except KeyError:
      return "Unknown"
  of ekVector:
    if expr.vector.len == 0:
      return "Vec"
    let firstType = inferExpressionType(analyzer, expr.vector[0])
    return
      if firstType != "Unknown":
        "Vec<" & firstType & ">"
      else:
        "Vec"
  of ekFuncDef:
    return "Function"
  of ekFuncCall:
    if expr.functionCall.function.kind == ekIdent:
      let funcName = expr.functionCall.function.identifier.ident
      case funcName
      of "abs", "sqrt", "floor", "ceil", "round", "sin", "cos", "tan", "cot", "sec",
          "csc", "exp", "log":
        return "Real"
      of "re", "im":
        return "Real"
      of "len":
        return "Int"
      of "type":
        return "Type"
      of "vec":
        return "Vec"
      of "seq":
        return "Seq"
      else:
        return "Unknown"
    return "Unknown"
  of ekAdd, ekSub, ekMul, ekDiv, ekPow:
    let leftType = inferExpressionType(analyzer, expr.binaryOp.left)
    let rightType = inferExpressionType(analyzer, expr.binaryOp.right)
    if leftType == "Complex" or rightType == "Complex":
      return "Complex"
    elif leftType == "Real" or rightType == "Real":
      return "Real"
    elif leftType == "Int" and rightType == "Int":
      return "Int"
    else:
      return "Number"
  of ekEq, ekNe, ekLt, ekLe, ekGt, ekGe, ekAnd, ekOr, ekNot:
    return "Bool"
  of ekNeg:
    return inferExpressionType(analyzer, expr.unaryOp.operand)
  of ekGroup:
    return inferExpressionType(analyzer, expr.groupExpr)
  else:
    return "Unknown"

proc findSymbolAtPosition(analyzer: var HoverAnalyzer, expr: Expression) =
  ## Recursively search AST to find symbol at target position and collect info
  if analyzer.foundSymbol:
    return

  # Check if this expression contains our target position
  let pos = expr.position
  if pos.line == analyzer.targetLine + 1 and pos.column <= analyzer.targetChar + 1:
    case expr.kind
    of ekIdent:
      let name = expr.identifier.ident
      if name == analyzer.targetWord:
        analyzer.foundSymbol = true
        analyzer.symbolInfo.name = name

        # Look up symbol in scope chain
        try:
          let varInfo = analyzer.currentScope.lookupVariable(name)
          analyzer.symbolInfo.symbolType = varInfo.varType
          analyzer.symbolInfo.isMutable = varInfo.isMutable
          analyzer.symbolInfo.isUsed = varInfo.isUsed
          analyzer.symbolInfo.declaredAt = varInfo.position

          # Determine scope context
          if analyzer.currentScope.kind == ekFunction:
            # Check if it's a parameter by looking in current function scope only
            if name in analyzer.currentScope.variables:
              analyzer.symbolInfo.scope = "parameter"
              analyzer.symbolInfo.isParameter = true
            else:
              analyzer.symbolInfo.scope = "captured"
          elif analyzer.currentScope.kind == ekBlock and analyzer.isInFunction:
            analyzer.symbolInfo.scope = "local"
          else:
            analyzer.symbolInfo.scope = "global"
        except KeyError:
          analyzer.symbolInfo.symbolType = "undeclared"
          analyzer.symbolInfo.scope = "unknown"
        return
    of ekImmutableDecl:
      if expr.immutableDecl.lvalue.kind == ekIdent:
        let name = expr.immutableDecl.lvalue.identifier.ident
        if name == analyzer.targetWord:
          analyzer.foundSymbol = true
          analyzer.symbolInfo.name = name
          analyzer.symbolInfo.isMutable = false
          analyzer.symbolInfo.symbolType =
            inferExpressionType(analyzer, expr.immutableDecl.expr)
          analyzer.symbolInfo.scope = if analyzer.isInFunction: "local" else: "global"
          analyzer.symbolInfo.declaredAt = expr.position
          return
      analyzer.findSymbolAtPosition(expr.immutableDecl.expr)
    of ekMutableDecl:
      if expr.mutableDecl.lvalue.kind == ekIdent:
        let name = expr.mutableDecl.lvalue.identifier.ident
        if name == analyzer.targetWord:
          analyzer.foundSymbol = true
          analyzer.symbolInfo.name = name
          analyzer.symbolInfo.isMutable = true
          analyzer.symbolInfo.symbolType =
            inferExpressionType(analyzer, expr.mutableDecl.expr)
          analyzer.symbolInfo.scope = if analyzer.isInFunction: "local" else: "global"
          analyzer.symbolInfo.declaredAt = expr.position
          return
      analyzer.findSymbolAtPosition(expr.mutableDecl.expr)
    of ekFuncDef:
      # Enter function scope
      let wasInFunction = analyzer.isInFunction
      analyzer.isInFunction = true

      # Check function parameters
      for param in expr.functionDef.params:
        if param.name == analyzer.targetWord:
          analyzer.foundSymbol = true
          analyzer.symbolInfo.name = param.name
          analyzer.symbolInfo.isParameter = true
          analyzer.symbolInfo.isMutable = false
          analyzer.symbolInfo.symbolType = $param.typ
          analyzer.symbolInfo.scope = "parameter"
          analyzer.symbolInfo.declaredAt = expr.position
          return

      # Analyze function body
      analyzer.findSymbolAtPosition(expr.functionDef.body)
      analyzer.isInFunction = wasInFunction
    of ekBlock:
      for blockExpr in expr.blockExpr.expressions:
        analyzer.findSymbolAtPosition(blockExpr)
        if analyzer.foundSymbol:
          return
    of ekFuncCall:
      analyzer.findSymbolAtPosition(expr.functionCall.function)
      if analyzer.foundSymbol:
        return
      for param in expr.functionCall.params:
        analyzer.findSymbolAtPosition(param)
        if analyzer.foundSymbol:
          return
    of ekAdd, ekSub, ekMul, ekDiv, ekMod, ekPow, ekEq, ekNe, ekLt, ekLe, ekGt, ekGe,
        ekAnd, ekOr:
      analyzer.findSymbolAtPosition(expr.binaryOp.left)
      if analyzer.foundSymbol:
        return
      analyzer.findSymbolAtPosition(expr.binaryOp.right)
    of ekNeg, ekNot:
      analyzer.findSymbolAtPosition(expr.unaryOp.operand)
    of ekVector:
      for i in 0 ..< expr.vector.len:
        analyzer.findSymbolAtPosition(expr.vector[i])
        if analyzer.foundSymbol:
          return
    of ekAssign:
      analyzer.findSymbolAtPosition(expr.assign.lvalue)
      if analyzer.foundSymbol:
        return
      analyzer.findSymbolAtPosition(expr.assign.expr)
    of ekGroup:
      analyzer.findSymbolAtPosition(expr.groupExpr)
    of ekIf:
      for branch in expr.ifExpr.branches:
        analyzer.findSymbolAtPosition(branch.condition)
        if analyzer.foundSymbol:
          return
        analyzer.findSymbolAtPosition(branch.then)
        if analyzer.foundSymbol:
          return
      analyzer.findSymbolAtPosition(expr.ifExpr.elseBranch)
    of ekVecIndex:
      analyzer.findSymbolAtPosition(expr.vectorIndex.vector)
      if analyzer.foundSymbol:
        return
      analyzer.findSymbolAtPosition(expr.vectorIndex.index)
    of ekModAccess:
      analyzer.findSymbolAtPosition(expr.moduleAccess.target)
    of ekUse:
      discard # Use statements don't contain identifiers at cursor typically
    else:
      discard

# Basic hover information
proc getBasicHoverInfo*(text: string, line: int, character: int): string =
  ## Get basic hover information for built-in language elements
  try:
    let word = extractWordAtPosition(text, line, character)
    if word.len == 0:
      return ""

    # Check if it's a known language element
    let doc = getDocumentation(word)
    if doc.len > 0:
      return doc

    # Handle numeric literals
    if isNumericLiteral(word):
      if "." in word or "e" in word.toLowerAscii:
        return &"**{word}** - Real number literal"
      else:
        return &"**{word}** - Integer literal"

    # Handle operators and special symbols
    case word
    of "true", "false":
      return &"**{word}** - Boolean literal"
    else:
      return ""
  except Exception as e:
    writeLog(&"Error in getBasicHoverInfo: {e.msg}")
    return ""

# Enhanced hover with AST analysis
proc getEnhancedHoverInfo*(
    filePath: string, text: string, line: int, character: int
): string =
  ## Get enhanced hover information using AST analysis and type inference
  try:
    let word = extractWordAtPosition(text, line, character)
    if word.len == 0:
      return ""

    # First try basic hover for built-in elements  
    let basicHover = getBasicHoverInfo(text, line, character)
    if basicHover.len > 0:
      return basicHover

    # For user-defined identifiers, parse and analyze AST
    try:
      var lexer = newLexer(text, filePath)
      var parser = newParser(olNone)
      var analyzer = HoverAnalyzer(
        targetLine: line, targetChar: character, targetWord: word, foundSymbol: false
      )

      # Set up analysis scopes
      analyzer.globalScope = diag.newAnalysisScope(ekModule)
      analyzer.currentScope = analyzer.globalScope

      # Parse and analyze each expression in the file
      while not lexer.atEnd:
        try:
          let tokens = lexer.tokenizeExpression(includeComments = false)
          if tokens.len > 0:
            let ast = parser.parse(tokens)

            # Build symbol table similar to diagnostics
            var fileAnalyzer = diag.FileAnalyzer(
              filePath: filePath,
              source: text,
              diagnostics: @[],
              globalScope: analyzer.globalScope,
              currentScope: analyzer.currentScope,
            )
            fileAnalyzer.analyzeExpression(ast)

            # Update our analyzer's scope references
            analyzer.globalScope = fileAnalyzer.globalScope
            analyzer.currentScope = fileAnalyzer.currentScope

            # Search for our target symbol in this AST
            analyzer.findSymbolAtPosition(ast)
            if analyzer.foundSymbol:
              break
        except BMathError:
          # Skip invalid expressions and continue
          continue

      # Generate hover info from symbol information
      if analyzer.foundSymbol:
        let info = analyzer.symbolInfo
        var hoverText = &"**{info.name}**"

        if info.symbolType.len > 0 and info.symbolType != "Unknown":
          hoverText.add(&" : {info.symbolType}")

        hoverText.add("\n\n")

        if info.isParameter:
          hoverText.add("(parameter) ")

        case info.scope
        of "global":
          hoverText.add("Global variable")
        of "local":
          hoverText.add("Local variable")
        of "parameter":
          hoverText.add("Function parameter")
        of "captured":
          hoverText.add("Captured variable")
        else:
          hoverText.add("Variable")

        if info.isMutable:
          hoverText.add(" (mutable)")
        else:
          hoverText.add(" (immutable)")

        if info.declaredAt.line > 0:
          hoverText.add(&"\n\nDeclared at line {info.declaredAt.line}")

        return hoverText
      else:
        return &"**{word}** - Identifier"
    except Exception as e:
      writeLog(&"Error in AST analysis: {e.msg}")
      return &"**{word}** - Identifier"
  except Exception as e:
    writeLog(&"Error in getEnhancedHoverInfo: {e.msg}")
    return getBasicHoverInfo(text, line, character)

# Main hover provider function
proc provideHoverInfo*(
    filePath: string, text: string, line: int, character: int
): string =
  ## Main entry point for hover information
  ## Returns markdown-formatted hover text or empty string if no info available

  # Try enhanced hover first (includes type inference)
  let enhanced = getEnhancedHoverInfo(filePath, text, line, character)
  if enhanced.len > 0:
    return enhanced

  # Fall back to basic hover
  return getBasicHoverInfo(text, line, character)

# Hover for expressions (future enhancement)
proc getExpressionHoverInfo*(text: string, line: int, character: int): string =
  ## Get hover information for complex expressions (future feature)
  ## This would show evaluated results or type information for entire expressions

  # This could be enhanced to:
  # 1. Parse expressions at cursor
  # 2. Show type information
  # 3. Show evaluated results for constants
  # 4. Show function signatures when hovering over calls

  return ""
