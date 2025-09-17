## diagnostics.nim - Static analysis for BMath files
##
## Analyzes BMath source code for common issues:
## - Undeclared variables
## - Unused variables  
## - Immutable reassignment
## - Type mismatches
## - Shadowing variables
## - Module import issues

import std/[sets, tables, strutils, strformat]
import ../types/[expression, errors, position, core, value, bm_types]
import lexer, parser, optimization

type
  DiagnosticKind* = enum
    dkUndeclaredVariable ## Variable used but not declared
    dkUnusedVariable ## Variable declared but never used
    dkReassignImmutable ## Attempt to reassign immutable variable
    dkTypeMismatch ## Type mismatch in assignment or operation
    dkShadowingVariable ## Variable shadows outer scope
    dkModuleNotFound ## Module file not found
    dkCircularImport ## Circular module dependency
    dkUnreachableCode ## Code after return/control flow

  DiagnosticSeverity* = enum
    dsError
    dsWarning
    dsInfo

  Diagnostic* = object
    kind*: DiagnosticKind
    severity*: DiagnosticSeverity
    position*: Position
    message*: string
    suggestion*: string

  # Scope tracking for fake interpretation
  VariableInfo* = object
    position*: Position ## Where declared
    isMutable*: bool ## Can be reassigned
    isUsed*: bool ## Has been read
    varType*: string ## Inferred type (simple tracking)

  ModuleInfo* = object
    path*: string
    exports*: HashSet[string] ## What this module exports

  AnalysisScope* = ref object
    kind*: EnvironmentKind
    variables*: Table[string, VariableInfo]
    parent*: AnalysisScope

  FileAnalyzer* = object
    filePath*: string
    source*: string
    diagnostics*: seq[Diagnostic]
    currentScope*: AnalysisScope
    globalScope*: AnalysisScope
    loadedModules*: Table[string, ModuleInfo]

  AnalysisResult* = object ## Results from static analysis
    diagnostics*: seq[Diagnostic]
    globalScope*: AnalysisScope ## Global scope with variable information

proc newAnalysisScope*(
    kind: EnvironmentKind, parent: AnalysisScope = nil
): AnalysisScope =
  AnalysisScope(
    kind: kind, variables: initTable[string, VariableInfo](), parent: parent
  )

proc addDiagnostic(
    analyzer: var FileAnalyzer,
    kind: DiagnosticKind,
    pos: Position,
    msg: string,
    suggestion = "",
) =
  let severity =
    case kind
    of dkUndeclaredVariable, dkReassignImmutable, dkCircularImport, dkModuleNotFound:
      dsError
    of dkTypeMismatch:
      dsError
    of dkUnusedVariable, dkShadowingVariable:
      dsWarning
    else:
      dsInfo

  analyzer.diagnostics.add(
    Diagnostic(
      kind: kind,
      severity: severity,
      position: pos,
      message: msg,
      suggestion: suggestion,
    )
  )

proc lookupVariable*(scope: AnalysisScope, name: string): var VariableInfo =
  ## Look up variable in scope chain, raises KeyError if not found
  var current = scope
  while current != nil:
    if name in current.variables:
      return current.variables[name]
    current = current.parent
  raise newException(KeyError, "Variable not found: " & name)

proc declareVariable(scope: AnalysisScope, name: string, info: VariableInfo): bool =
  ## Declare variable in current scope, returns false if already exists
  if name in scope.variables:
    return false
  scope.variables[name] = info
  true

# Forward declaration for mutual recursion
proc analyzeExpression*(analyzer: var FileAnalyzer, expr: Expression)

# Type inference functions
proc inferExpressionType(analyzer: var FileAnalyzer, expr: Expression): string =
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
      var varInfo = analyzer.currentScope.lookupVariable(expr.identifier.ident)
      if varInfo.varType.len > 0:
        return varInfo.varType
      else:
        return "Unknown"
    except KeyError:
      return "Unknown"
  of ekVector:
    if expr.vector.len == 0:
      return "Vec"
    else:
      # Try to infer element type from first element
      let firstType = analyzer.inferExpressionType(expr.vector[0])
      if firstType != "Unknown":
        return "Vec<" & firstType & ">"
      else:
        return "Vec"
  of ekFuncDef:
    return "Function"
  of ekFuncCall:
    # Try to infer return type of built-in functions
    if expr.functionCall.function.kind == ekIdent:
      let funcName = expr.functionCall.function.identifier.ident
      case funcName
      of "abs", "sqrt", "floor", "ceil", "round":
        return "Real"
      of "sin", "cos", "tan", "cot", "sec", "csc", "exp", "log":
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
    else:
      return "Unknown"
  of ekAdd, ekSub, ekMul, ekDiv, ekPow:
    # Infer from operands
    let leftType = analyzer.inferExpressionType(expr.binaryOp.left)
    let rightType = analyzer.inferExpressionType(expr.binaryOp.right)
    if leftType == "Complex" or rightType == "Complex":
      return "Complex"
    elif leftType == "Real" or rightType == "Real":
      return "Real"
    elif leftType == "Int" and rightType == "Int":
      return "Int"
    else:
      return "Number"
  of ekEq, ekNe, ekLt, ekLe, ekGt, ekGe, ekAnd, ekOr:
    return "Bool"
  of ekNot:
    return "Bool"
  of ekNeg:
    return analyzer.inferExpressionType(expr.unaryOp.operand)
  of ekGroup:
    return analyzer.inferExpressionType(expr.groupExpr)
  of ekBlock:
    if expr.blockExpr.expressions.len > 0:
      # Return type of last expression
      return analyzer.inferExpressionType(expr.blockExpr.expressions[^1])
    else:
      return "Unknown"
  of ekIf:
    # Return common type of then/else branches
    if expr.ifExpr.branches.len > 0:
      let thenType = analyzer.inferExpressionType(expr.ifExpr.branches[0].then)
      let elseType = analyzer.inferExpressionType(expr.ifExpr.elseBranch)
      if thenType == elseType:
        return thenType
      else:
        return "Unknown"
    else:
      return "Unknown"
  else:
    return "Unknown"

proc analyzeExpressions(analyzer: var FileAnalyzer, expressions: seq[Expression]) =
  for expr in expressions:
    analyzer.analyzeExpression(expr)

proc analyzeIdentifier(analyzer: var FileAnalyzer, expr: Expression) =
  let name = expr.identifier.ident

  try:
    # Mark as used by directly modifying the variable in scope
    analyzer.currentScope.lookupVariable(name).isUsed = true
  except KeyError:
    analyzer.addDiagnostic(
      dkUndeclaredVariable,
      expr.position,
      fmt"Variable '{name}' is not declared",
      "Check spelling or declare it with ':=' or ';='",
    )

proc analyzeImmutableDecl(analyzer: var FileAnalyzer, expr: Expression) =
  let name = expr.immutableDecl.lvalue.identifier.ident

  # Check for shadowing
  if name in analyzer.currentScope.variables:
    analyzer.addDiagnostic(
      dkShadowingVariable,
      expr.position,
      fmt"Variable '{name}' shadows existing variable",
    )

  # Analyze the value expression first and infer its type
  analyzer.analyzeExpression(expr.immutableDecl.expr)
  let inferredType = analyzer.inferExpressionType(expr.immutableDecl.expr)

  # Declare the variable with inferred type
  let info = VariableInfo(
    position: expr.position, isMutable: false, isUsed: false, varType: inferredType
  )

  if not analyzer.currentScope.declareVariable(name, info):
    analyzer.addDiagnostic(
      dkShadowingVariable, expr.position, fmt"Variable '{name}' is already declared"
    )

proc analyzeMutableDecl(analyzer: var FileAnalyzer, expr: Expression) =
  let name = expr.mutableDecl.lvalue.identifier.ident

  # Check for shadowing  
  if name in analyzer.currentScope.variables:
    analyzer.addDiagnostic(
      dkShadowingVariable,
      expr.position,
      fmt"Variable '{name}' shadows existing variable",
    )

  # Analyze the value expression first and infer its type
  analyzer.analyzeExpression(expr.mutableDecl.expr)
  let inferredType = analyzer.inferExpressionType(expr.mutableDecl.expr)

  # Declare the variable with inferred type
  let info = VariableInfo(
    position: expr.position, isMutable: true, isUsed: false, varType: inferredType
  )

  if not analyzer.currentScope.declareVariable(name, info):
    analyzer.addDiagnostic(
      dkShadowingVariable, expr.position, fmt"Variable '{name}' is already declared"
    )

proc analyzeAssign(analyzer: var FileAnalyzer, expr: Expression) =
  case expr.assign.lvalue.kind
  of ekIdent:
    let name = expr.assign.lvalue.identifier.ident

    try:
      let varInfo = analyzer.currentScope.lookupVariable(name)
      if not varInfo.isMutable:
        analyzer.addDiagnostic(
          dkReassignImmutable,
          expr.position,
          fmt"Cannot assign to immutable variable '{name}'",
          "Declare with ';=' to make it mutable",
        )
      else:
        # Mark as used by directly modifying the variable in scope
        analyzer.currentScope.lookupVariable(name).isUsed = true
    except KeyError:
      analyzer.addDiagnostic(
        dkUndeclaredVariable,
        expr.position,
        fmt"Cannot assign to undeclared variable '{name}'",
        "Declare it with ':=' or ';=' first",
      )
  else:
    # Analyze the lvalue (could be complex expression)
    analyzer.analyzeExpression(expr.assign.lvalue)

  # Analyze the value expression
  analyzer.analyzeExpression(expr.assign.expr)

proc analyzeBlock(analyzer: var FileAnalyzer, expr: Expression) =
  # Create new block scope
  let oldScope = analyzer.currentScope
  analyzer.currentScope = newAnalysisScope(ekBlock, oldScope)

  # Analyze all expressions in block
  for blockExpr in expr.blockExpr.expressions:
    analyzer.analyzeExpression(blockExpr)

  # Check for unused variables in this scope
  for name, info in analyzer.currentScope.variables:
    if not info.isUsed:
      analyzer.addDiagnostic(
        dkUnusedVariable,
        info.position,
        fmt"Variable '{name}' is declared but never used",
        "Remove it or prefix with '_' if intentionally unused",
      )

  # Restore previous scope
  analyzer.currentScope = oldScope

proc analyzeFunctionDef(analyzer: var FileAnalyzer, expr: Expression) =
  # Create function scope
  let oldScope = analyzer.currentScope
  analyzer.currentScope = newAnalysisScope(ekFunction, oldScope)

  # Add parameters to scope with their declared types
  for param in expr.functionDef.params:
    let paramType =
      if param.typ == AnyType:
        "Any"
      else:
        $param.typ
    let info = VariableInfo(
      position: expr.position,
        # Use function position since parameters don't have positions
      isMutable: false, # Parameters are immutable by default
      isUsed: false,
      varType: paramType,
    )
    if not analyzer.currentScope.declareVariable(param.name, info):
      analyzer.addDiagnostic(
        dkShadowingVariable,
        expr.position,
        fmt"Parameter '{param.name}' is already declared",
      )

  # Analyze function body
  analyzer.analyzeExpression(expr.functionDef.body)

  # Check for unused parameters
  for name, info in analyzer.currentScope.variables:
    if not info.isUsed:
      analyzer.addDiagnostic(
        dkUnusedVariable,
        info.position,
        fmt"Parameter '{name}' is never used",
        "Prefix with '_' if intentionally unused",
      )

  # Restore previous scope
  analyzer.currentScope = oldScope

proc analyzeUse(analyzer: var FileAnalyzer, expr: Expression) =
  let path = expr.useModule.path

  # Only check for .bm extension if it looks like a file path (contains / or .)
  # Built-in modules like 'std' don't need .bm extension
  if path.contains('/') and not path.endsWith(".bm"):
    analyzer.addDiagnostic(
      dkModuleNotFound,
      expr.position,
      fmt"File module path '{path}' should end with '.bm'",
    )

  # TODO: Track module exports and imports for unused import detection

proc analyzeModuleAccess(analyzer: var FileAnalyzer, expr: Expression) =
  # Analyze the target (usually 'this' or a module variable)
  analyzer.analyzeExpression(expr.moduleAccess.target)

  # If target is 'this' and member is an identifier, mark it as used in global scope
  if expr.moduleAccess.target.kind == ekThis:
    let memberName = expr.moduleAccess.member
    # Look up the variable in global scope and mark as used
    try:
      analyzer.globalScope.lookupVariable(memberName).isUsed = true
    except KeyError:
      # Variable not found in global scope, that's okay for module access
      discard

  # Member access doesn't need declaration checking since it's resolved at runtime

proc analyzeExpression(analyzer: var FileAnalyzer, expr: Expression) =
  case expr.kind
  of ekIdent:
    analyzer.analyzeIdentifier(expr)
  of ekImmutableDecl:
    analyzer.analyzeImmutableDecl(expr)
  of ekMutableDecl:
    analyzer.analyzeMutableDecl(expr)
  of ekAssign:
    analyzer.analyzeAssign(expr)
  of ekBlock:
    analyzer.analyzeBlock(expr)
  of ekFuncDef:
    analyzer.analyzeFunctionDef(expr)
  of ekUse:
    analyzer.analyzeUse(expr)
  of ekModAccess:
    analyzer.analyzeModuleAccess(expr)
  of ekFuncCall:
    # Analyze function and arguments
    analyzer.analyzeExpression(expr.functionCall.function)
    for arg in expr.functionCall.params:
      analyzer.analyzeExpression(arg)
  of ekAdd, ekSub, ekMul, ekDiv, ekMod, ekPow, ekEq, ekNe, ekLt, ekLe, ekGt, ekGe,
      ekAnd, ekOr:
    analyzer.analyzeExpression(expr.binaryOp.left)
    analyzer.analyzeExpression(expr.binaryOp.right)
  of ekNeg, ekNot:
    analyzer.analyzeExpression(expr.unaryOp.operand)
  of ekVector:
    for i in 0 ..< expr.vector.len:
      analyzer.analyzeExpression(expr.vector[i])
  of ekVecIndex:
    analyzer.analyzeExpression(expr.vectorIndex.vector)
    analyzer.analyzeExpression(expr.vectorIndex.index)
  of ekGroup:
    analyzer.analyzeExpression(expr.groupExpr)
  of ekIf:
    for branch in expr.ifExpr.branches:
      analyzer.analyzeExpression(branch.condition)
      analyzer.analyzeExpression(branch.then)
    analyzer.analyzeExpression(expr.ifExpr.elseBranch)
  else:
    # Value literals, this, module definitions don't need analysis
    discard

proc analyzeFile*(filePath: string, source: string): seq[Diagnostic] =
  ## Main entry point - analyze entire file and return diagnostics
  var analyzer = FileAnalyzer(
    filePath: filePath,
    source: source,
    diagnostics: @[],
    loadedModules: initTable[string, ModuleInfo](),
  )

  # Create global scope
  analyzer.globalScope = newAnalysisScope(ekModule)
  analyzer.currentScope = analyzer.globalScope

  # Parse the entire file
  try:
    var lexer = newLexer(source, filePath)
    var parser = newParser(olNone)

    while not lexer.atEnd:
      let tokens = lexer.tokenizeExpression(includeComments = false)
      if tokens.len > 0:
        let ast = parser.parse(tokens)
        analyzer.analyzeExpression(ast)
  except BMathError as e:
    # Add parse errors as diagnostics
    let errorPos =
      if e.stack.len > 0:
        e.stack[0]
      else:
        Position(line: 1, column: 1, filePath: filePath)
    analyzer.addDiagnostic(dkTypeMismatch, errorPos, fmt"Parse error: {e.msg}")

  # Check for unused variables in global scope
  for name, info in analyzer.globalScope.variables:
    if not info.isUsed:
      analyzer.addDiagnostic(
        dkUnusedVariable,
        info.position,
        fmt"Global variable '{name}' is declared but never used",
        "Remove it or use it in an expression",
      )

  result = analyzer.diagnostics

# Pretty printing for diagnostics
proc `$`*(diag: Diagnostic): string =
  let severityStr =
    case diag.severity
    of dsError: "ERROR"
    of dsWarning: "WARN"
    of dsInfo: "INFO"

  fmt"{severityStr} {diag.position.filePath} {diag.position.line}:{diag.position.column}: {diag.message}"

proc showDiagnostics*(diagnostics: seq[Diagnostic], source: string = "") =
  ## Display diagnostics with source context
  for diag in diagnostics:
    echo diag
    if diag.suggestion.len > 0:
      echo "  Suggestion: ", diag.suggestion

    # Show source context if available
    if source.len > 0:
      let lines = source.splitLines()
      if diag.position.line <= lines.len and diag.position.line > 0:
        let line = lines[diag.position.line - 1]
        echo "  ", line
        if diag.position.column > 0 and diag.position.column <= line.len:
          echo "  ", " ".repeat(diag.position.column - 1), "^"
    echo ""
