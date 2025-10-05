## diagnostics.nim - Enhanced static analysis for BMath files
##
## Analyzes BMath source code for common issues with improved type checking:
## - Undeclared variables
## - Unused variables  
## - Immutable reassignment
## - Type mismatches with signature-based validation
## - Function call validation (arity, argument types)
## - Stdlib function usage validation (must be imported)
## - Shadowing variables
## - Module import issues

import std/[sets, tables, strutils, strformat, sequtils, terminal]
import ../types/[expression, errors, position, core, bm_types]
import ../data/stdlib_signatures
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
    dkArityMismatch ## Wrong number of arguments to function
    dkStdlibNotImported ## Stdlib function used without import
    dkArgumentTypeMismatch ## Argument type doesn't match signature

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
    varType*: BMathType ## Inferred type

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
    importedStdlibFunctions*: HashSet[string] ## Track imported stdlib functions

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
    of dkUndeclaredVariable, dkReassignImmutable, dkCircularImport, dkModuleNotFound,
        dkStdlibNotImported:
      dsError
    of dkTypeMismatch, dkArityMismatch, dkArgumentTypeMismatch:
      dsWarning # Warnings since BMath is dynamically typed
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
proc inferExpressionType(analyzer: var FileAnalyzer, expr: Expression): BMathType =
  ## Infer the type of an expression based on its structure
  case expr.kind
  of ekValue:
    return getType(expr.value)
  of ekIdent:
    try:
      var varInfo = analyzer.currentScope.lookupVariable(expr.identifier.ident)
      return varInfo.varType
    except KeyError:
      return AnyType
  of ekVector:
    return newType(stVector)
  of ekFuncDef:
    return newType(stFunction)
  of ekFuncCall:
    # Try to infer return type from signatures
    if expr.functionCall.function.kind == ekIdent:
      let funcName = expr.functionCall.function.identifier.ident
      let signatures = getSignaturesFor(funcName)
      if signatures.len > 0:
        # Return the return type of the first matching signature
        # In a more sophisticated analysis, we'd match based on argument types
        return signatures[0].returnType
      else:
        # Check if it's a known variable
        try:
          var varInfo = analyzer.currentScope.lookupVariable(funcName)
          if varInfo.varType.kind == tkSimple and
              varInfo.varType.simpleType == stFunction:
            return AnyType # User function, return type unknown
        except KeyError:
          discard
    return AnyType
  of ekAdd, ekSub, ekMul, ekDiv, ekPow:
    # Infer from operands
    let leftType = analyzer.inferExpressionType(expr.binaryOp.left)
    let rightType = analyzer.inferExpressionType(expr.binaryOp.right)
    # If either is Any, result is Any
    if leftType == AnyType or rightType == AnyType:
      return AnyType
    # Check for complex propagation
    if leftType.kind == tkSimple and leftType.simpleType == stComplex:
      return newType(stComplex)
    if rightType.kind == tkSimple and rightType.simpleType == stComplex:
      return newType(stComplex)
    # Check for real propagation
    if leftType.kind == tkSimple and leftType.simpleType == stReal:
      return newType(stReal)
    if rightType.kind == tkSimple and rightType.simpleType == stReal:
      return newType(stReal)
    # Both integers
    if leftType.kind == tkSimple and rightType.kind == tkSimple and
        leftType.simpleType == stInteger and rightType.simpleType == stInteger:
      return newType(stInteger)
    # Fall back to Number
    return NumberType
  of ekMod:
    return newType(stInteger)
  of ekEq, ekNe, ekLt, ekLe, ekGt, ekGe, ekAnd, ekOr:
    return newType(stBoolean)
  of ekNot:
    return newType(stBoolean)
  of ekNeg:
    return analyzer.inferExpressionType(expr.unaryOp.operand)
  of ekGroup:
    return analyzer.inferExpressionType(expr.groupExpr)
  of ekBlock:
    if expr.blockExpr.expressions.len > 0:
      # Return type of last expression
      return analyzer.inferExpressionType(expr.blockExpr.expressions[^1])
    else:
      return AnyType
  of ekIf:
    # Return common type of then/else branches
    if expr.ifExpr.branches.len > 0:
      let thenType = analyzer.inferExpressionType(expr.ifExpr.branches[0].then)
      let elseType = analyzer.inferExpressionType(expr.ifExpr.elseBranch)
      if thenType === elseType:
        return thenType
      else:
        return AnyType
    else:
      return AnyType
  else:
    return AnyType

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
      fmt"Variable '{name}' shadows variable in same scope",
      "Use a different name",
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
      dkShadowingVariable, expr.position, fmt"Variable '{name}' already declared"
    )

proc analyzeMutableDecl(analyzer: var FileAnalyzer, expr: Expression) =
  let name = expr.mutableDecl.lvalue.identifier.ident

  # Check for shadowing  
  if name in analyzer.currentScope.variables:
    analyzer.addDiagnostic(
      dkShadowingVariable,
      expr.position,
      fmt"Variable '{name}' shadows variable in same scope",
      "Use a different name",
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
      dkShadowingVariable, expr.position, fmt"Variable '{name}' already declared"
    )

proc analyzeAssign(analyzer: var FileAnalyzer, expr: Expression) =
  case expr.assign.lvalue.kind
  of ekIdent:
    let name = expr.assign.lvalue.identifier.ident
    try:
      var varInfo = analyzer.currentScope.lookupVariable(name)
      if not varInfo.isMutable:
        analyzer.addDiagnostic(
          dkReassignImmutable,
          expr.position,
          fmt"Cannot reassign immutable variable '{name}'",
          "Declare with ';=' instead of ':=' to make it mutable",
        )
      else:
        # Check type compatibility if we have type info
        let assignedType = analyzer.inferExpressionType(expr.assign.expr)
        if varInfo.varType != AnyType and assignedType != AnyType:
          # Only warn if types are definitely incompatible
          if not (assignedType == varInfo.varType):
            analyzer.addDiagnostic(
              dkTypeMismatch,
              expr.position,
              fmt"Type mismatch: assigning {assignedType} to variable of type {varInfo.varType}",
              "Types may not be compatible",
            )
    except KeyError:
      analyzer.addDiagnostic(
        dkUndeclaredVariable,
        expr.position,
        fmt"Variable '{name}' is not declared",
        "Declare it first with ':=' or ';='",
      )
  of ekVecIndex:
    # Vector element assignment
    analyzer.analyzeExpression(expr.assign.lvalue)
  else:
    analyzer.addDiagnostic(
      dkTypeMismatch, expr.position, "Invalid assignment target"
    )

  # Analyze the value expression
  analyzer.analyzeExpression(expr.assign.expr)

proc analyzeFunctionCall(analyzer: var FileAnalyzer, expr: Expression) =
  ## Analyze function call with signature-based validation
  let funcExpr = expr.functionCall.function
  let args = expr.functionCall.params

  # Analyze function expression
  analyzer.analyzeExpression(funcExpr)

  # Analyze all arguments
  for arg in args:
    analyzer.analyzeExpression(arg)

  # If it's a simple identifier, try to validate against signatures
  if funcExpr.kind == ekIdent:
    let funcName = funcExpr.identifier.ident
    let signatures = getSignaturesFor(funcName)

    # Check if it's a stdlib function
    if signatures.len > 0:
      # Check if it's imported (only matters for stdlib functions)
      if funcName notin analyzer.importedStdlibFunctions:
        analyzer.addDiagnostic(
          dkStdlibNotImported,
          expr.position,
          fmt"Stdlib function '{funcName}' used without import",
          fmt"Add 'use(std::{funcName})' before using it",
        )

      # Find matching signature
      var foundMatch = false
      for sig in signatures:
        # Check arity
        let minArgs = sig.params.countIt(not it.isOptional and not it.isVariadic)
        let hasVariadic = sig.params.anyIt(it.isVariadic)

        if hasVariadic:
          # With variadic, we need at least minArgs
          if args.len >= minArgs:
            foundMatch = true
            break
        else:
          # Without variadic, check exact or optional match
          let maxArgs = sig.params.len
          if args.len >= minArgs and args.len <= maxArgs:
            foundMatch = true
            # Optionally check argument types if we have concrete type info
            var typesMatch = true
            for i in 0 ..< args.len:
              let argType = analyzer.inferExpressionType(args[i])
              let paramType = sig.params[i].bmath_type
              # Only warn if we have concrete types and they don't match
              if argType != AnyType and paramType != AnyType:
                if not (argType == paramType):
                  analyzer.addDiagnostic(
                    dkArgumentTypeMismatch,
                    args[i].position,
                    fmt"Argument {i + 1} type mismatch: expected {paramType}, got {argType}",
                    "Type may not be compatible",
                  )
                  typesMatch = false
            if typesMatch:
              break

      # If no signature matched, report arity mismatch
      if not foundMatch:
        let sigStrs = signatures.mapIt(
          fmt"{it.params.len} arg(s)" & (if it.params.anyIt(it.isVariadic): "+" else: "")
        )
        let expectedStr = sigStrs.join(" or ")
        analyzer.addDiagnostic(
          dkArityMismatch,
          expr.position,
          fmt"Function '{funcName}' called with {args.len} arguments, expected: {expectedStr}",
          "Check function signature",
        )

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
        dkUnusedVariable, info.position, fmt"Variable '{name}' is never used"
      )

  # Restore previous scope
  analyzer.currentScope = oldScope

proc analyzeFunctionDef(analyzer: var FileAnalyzer, expr: Expression) =
  # Create function scope
  let oldScope = analyzer.currentScope
  analyzer.currentScope = newAnalysisScope(ekFunction, oldScope)

  # Add parameters to scope with their declared types
  for param in expr.functionDef.signature.params:
    let paramInfo = VariableInfo(
      position: expr.position,
      isMutable: false,
      isUsed: false,
      varType: param.bmath_type,
    )
    discard analyzer.currentScope.declareVariable(param.name, paramInfo)

  # Analyze function body
  analyzer.analyzeExpression(expr.functionDef.body)

  # Check for unused parameters
  for name, info in analyzer.currentScope.variables:
    if not info.isUsed:
      analyzer.addDiagnostic(
        dkUnusedVariable, info.position, fmt"Parameter '{name}' is never used"
      )

  # Restore previous scope
  analyzer.currentScope = oldScope

proc analyzeUse(analyzer: var FileAnalyzer, expr: Expression) =
  ## Analyze use expression and track imported stdlib functions
  let path = expr.useModule.path

  # Only check for .bm extension if it looks like a file path (contains / or .)
  # Built-in modules like 'std' don't need .bm extension
  if path.contains('/') and not path.endsWith(".bm"):
    analyzer.addDiagnostic(
      dkModuleNotFound,
      expr.position,
      fmt"Module path '{path}' should end with .bm extension",
      "Add .bm extension to module path",
    )

  # Track stdlib imports
  # Handle patterns like: use(std::sin), use(std::{sin, cos}), etc.
  # For now, we'll mark that we're using std module generally
  # A more sophisticated analysis would track specific imports
  if path == "std" or path.startsWith("std::"):
    # Parse the import to extract function names
    if path == "std":
      # Importing entire std module - all functions available
      for funcName in getAllFunctionNames():
        analyzer.importedStdlibFunctions.incl(funcName)
    elif "::" in path:
      # Specific import like std::sin
      let parts = path.split("::")
      if parts.len >= 2 and parts[0] == "std":
        let funcName = parts[1]
        analyzer.importedStdlibFunctions.incl(funcName)

proc analyzeModuleAccess(analyzer: var FileAnalyzer, expr: Expression) =
  # Analyze the target (usually 'this' or a module variable)
  analyzer.analyzeExpression(expr.moduleAccess.target)

  # If target is 'this' and member is an identifier, mark it as used in global scope
  if expr.moduleAccess.target.kind == ekThis:
    let member = expr.moduleAccess.member
    try:
      # Try to mark as used in global scope
      analyzer.globalScope.lookupVariable(member).isUsed = true
    except KeyError:
      # Member not found in global scope
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
    analyzer.analyzeFunctionCall(expr)
  of ekAdd, ekSub, ekMul, ekDiv, ekMod, ekPow, ekEq, ekNe, ekLt, ekLe, ekGt, ekGe,
      ekAnd, ekOr:
    analyzer.analyzeExpression(expr.binaryOp.left)
    analyzer.analyzeExpression(expr.binaryOp.right)
  of ekNeg, ekNot:
    analyzer.analyzeExpression(expr.unaryOp.operand)
  of ekVector:
    for elem in expr.vector:
      analyzer.analyzeExpression(elem)
  of ekVecIndex:
    analyzer.analyzeExpression(expr.vectorIndex.vector)
    analyzer.analyzeExpression(expr.vectorIndex.index)
  of ekGroup:
    analyzer.analyzeExpression(expr.groupExpr)
  of ekIf:
    analyzer.analyzeExpression(expr.ifExpr.branches[0].condition)
    analyzer.analyzeExpression(expr.ifExpr.branches[0].then)
    for i in 1 ..< expr.ifExpr.branches.len:
      analyzer.analyzeExpression(expr.ifExpr.branches[i].condition)
      analyzer.analyzeExpression(expr.ifExpr.branches[i].then)
    analyzer.analyzeExpression(expr.ifExpr.elseBranch)
  else:
    discard # Other expression types don't need special handling

proc analyzeFile*(filePath: string, source: string): seq[Diagnostic] =
  ## Main entry point - analyze entire file and return diagnostics
  var analyzer = FileAnalyzer(
    filePath: filePath,
    source: source,
    diagnostics: @[],
    loadedModules: initTable[string, ModuleInfo](),
    importedStdlibFunctions: initHashSet[string](),
  )

  # Initialize stdlib signatures
  initSignaturesCache()

  # Create global scope
  analyzer.globalScope = newAnalysisScope(ekModule)
  analyzer.currentScope = analyzer.globalScope

  # Parse the entire file
  try:
    var lexer = newLexer(source, filePath)
    var parser = newParser(olNone)

    while not lexer.atEnd:
      let tokens = lexer.tokenizeExpression()
      if tokens.len > 0:
        let ast = parser.parse(tokens)
        analyzer.analyzeExpression(ast)
  except BMathError as e:
    # Add parse error as diagnostic
    let errorPos = if e.stack.len > 0: e.stack[0] else: Position(line: 0, column: 0, filePath: filePath)
    analyzer.diagnostics.add(
      Diagnostic(
        kind: dkTypeMismatch, # Reuse for parse errors
        severity: dsError,
        position: errorPos,
        message: e.msg,
        suggestion: "",
      )
    )

  # Check for unused variables in global scope
  for name, info in analyzer.globalScope.variables:
    if not info.isUsed:
      analyzer.addDiagnostic(
        dkUnusedVariable, info.position, fmt"Variable '{name}' is never used"
      )

  return analyzer.diagnostics

# Pretty printing for diagnostics
proc `$`*(diag: Diagnostic): string =
  let severityStr =
    case diag.severity
    of dsError:
      "ERROR"
    of dsWarning:
      "WARNING"
    of dsInfo:
      "INFO"
  fmt"[{severityStr}] {diag.position.filePath}:{diag.position.line}:{diag.position.column} - {diag.message}"

proc showDiagnostics*(diagnostics: seq[Diagnostic], source: string = "") =
  ## Display diagnostics with source context
  for diag in diagnostics:
    # Print severity and message
    case diag.severity
    of dsError:
      stdout.styledWrite(fgRed, styleBright, "[ERROR] ")
    of dsWarning:
      stdout.styledWrite(fgYellow, styleBright, "[WARNING] ")
    of dsInfo:
      stdout.styledWrite(fgCyan, styleBright, "[INFO] ")

    echo fmt"{diag.position.filePath}:{diag.position.line}:{diag.position.column}"
    echo "  ", diag.message

    if diag.suggestion.len > 0:
      stdout.styledWrite(fgGreen, "  Suggestion: ")
      echo diag.suggestion

    # Show source line if available
    if source.len > 0 and diag.position.line > 0:
      let lines = source.split('\n')
      if diag.position.line <= lines.len:
        let line = lines[diag.position.line - 1]
        echo "  ", line
        if diag.position.column > 0:
          let marker = " ".repeat(diag.position.column + 1) & "^"
          stdout.styledWrite(fgRed, styleBright, marker)
          echo ""

    echo "" # Blank line between diagnostics
