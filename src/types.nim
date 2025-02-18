## types.nim
## 
## This module contains all type definitions for the interpreter to avoid cyclic dependencies.
## It includes fundamental types for values, tokens, AST nodes, and errors, along with their
## string representation implementations.

import std/[strutils, tables, sequtils]

type
  ValueKind* = enum
    ## Discriminator for runtime value types stored in `Value` objects.
    vkInt ## Integer value stored in `iValue` field
    vkFloat ## Floating-point value stored in `fValue` field
    vkNativeFunc ## Native function stored in `nativeFunc` field
    vkFunction ## User-defined function
    vkVector ## Vector value
    vkBool ## Boolean value

  Value* = object
    ## Variant type representing runtime numeric values with type tracking.
    case kind*: ValueKind ## Type discriminator determining active field
    of vkInt:
      iValue*: int ## Integer storage when kind is `vkInt`
    of vkFloat:
      fValue*: float ## Float storage when kind is `vkFloat`
    of vkNativeFunc:
      nativeFunc*: NativeFunc
    of vkFunction:
      body*: Expression
      env*: Environment
      params*: seq[string]
    of vkVector:
      values*: seq[Value]
    of vkBool:
      bValue*: bool

  LabeledValue* = object
    label*: string
    value*: Value

  Evaluator* = proc(node: Expression): Value
    ## Function type for evaluating AST nodes in the interpreter.

  HostFunction* = proc(args: openArray[Expression], evaluator: Evaluator): Value
    ## Function in the host language callable from the interpreter.

  NativeFunc* = object
    ## Native function interface callable from the interpreter.
    ## Native functions get access to the interpreter capabilities using the evaluator.
    ## 
    ## Fields:
    ##   argc: Number of expected arguments
    ##   fun:  Procedure implementing the function logic
    argc*: int
    fun*: HostFunction

  Position* = object ## Source code location information
    line*: int ## 1-based line number in source
    column*: int ## 1-based column number in source

  TokenKind* = enum
    ## Lexical token categories produced by the lexer.
    ## 
    ## These represent fundamental syntactic elements including:
    ## - Operators (arithmetic, assignment)
    ## - Literal values
    ## - Structural characters
    ## - Identifiers

    # Operators
    tkAdd ## Addition operator '+'
    tkSub ## Subtraction operator '-'
    tkMul ## Multiplication operator '*'
    tkDiv ## Division operator '/'
    tkPow ## Exponentiation operator '^'
    tkMod ## Modulus operator '%'
    tkAssign ## Assignment operator '='

    # Boolean operators
    tkAnd ## Logical AND operator '&'
    # for tkOr we will reuse the tkLine '|' character
    tkNot ## Logical NOT operator '!'

    # Comparison operators
    tkEq ## Equality operator '=='
    tkNe ## Inequality operator '!='
    tkLt ## Less than operator '<'
    tkLe ## Less than or equal operator '<='
    tkGt ## Greater than operator '>'
    tkGe ## Greater than or equal operator '>='

    # Structural tokens
    tkLPar ## Left parenthesis '('
    tkRPar ## Right parenthesis ')'
    tkLCurly ## Left curly brace '{'
    tkRCurly ## Right curly brace '}'
    tkRSquare ## Square bracket '['
    tkLSquare ## Square bracket ']'
    tkLine ## Parameter delimiter '|'

    # Literals and identifiers
    tkValue ## literal (integer or float)
    tkIdent ## Identifier (variable/function name)

    # Keywords
    tkIf ## If keyword
    tkElse ## Else keyword
    tkElif ## Elif keyword
    tkEndIf ## EndIf keyword
    tkReturn ## Return keyword
    tkLocal ## Local keyword

    # Control tokens
    tkComma ## Argument separator ','
    tkNewline # End of expression marker for parser (due multiline blocks support)
    tkEoe ## End of expression marker for lexer

  Token* = object
    ## Lexical token with source position and type-specific data.
    ## 
    ## The active field depends on the token kind:
    ## - `value` for numeric literals (tkNum)
    ## - `name` for identifiers (tkIdent)
    position*: Position ## Source location of the token
    case kind*: TokenKind
    of tkValue:
      value*: Value ## Literal value for tkNum tokens
    of tkIdent:
      name*: string ## Identifier name for tkIdent tokens
    else:
      discard

  ExpressionKind* = enum
    ## Abstract Syntax Tree (AST) node categories (now called Expressions).
    ## 
    ## Each variant corresponds to a different language construct with
    ## associated child nodes or values.
    
    # Literals and grouping
    ekValue    ## Numeric literal value
    ekGroup    ## Parenthesized expression group

    # Unary operations
    ekNeg      ## Unary negation operation (-operand)

    # Binary operations
    ekAdd      ## Addition operation (left + right)
    ekSub      ## Subtraction operation (left - right)
    ekMul      ## Multiplication operation (left * right)
    ekDiv      ## Division operation (left / right)
    ekPow      ## Exponentiation operation (left ^ right)
    ekMod      ## Modulus operation (left % right)

    # Comparison operations
    ekEq       ## Equality comparison (left == right)
    ekNe       ## Inequality comparison (left != right)
    ekLt       ## Less-than comparison (left < right)
    ekLe       ## Less-than-or-equal comparison (left <= right)
    ekGt       ## Greater-than comparison (left > right)
    ekGe       ## Greater-than-or-equal comparison (left >= right)

    # Logical operations
    ekAnd      ## Logical AND operation (left & right)
    ekOr       ## Logical OR operation (left | right)

    # Identifiers and assignments
    ekIdent    ## Identifier reference
    ekAssign   ## Variable assignment (ident = expr)
    
    # Vector literal
    ekVector   ## Vector literal

    # Function constructs
    ekFunc         ## Function definition
    ekFuncCall     ## Function call with arguments
    ekFuncInvoke   ## Function invocation (internal use)

    # Block expression
    ekBlock    ## Block expression (sequence of statements)

    # Control flow
    ekIf       ## If-else conditional expression

  Expression* = ref object
    ## Abstract Syntax Tree (AST) node (renamed to Expression).
    ##
    ## The active fields depend on the node kind:
    ## - For ekValue: stores a literal value.
    ## - For binary operations (ekAdd, ekSub, etc.): stores left/right operand expressions.
    ## - For groups and unary operations: stores child nodes.
    ## - For identifiers and function calls: stores name and arguments.
    position*: Position ## Original source location
    case kind*: ExpressionKind
    of ekValue:
      value*: Value ## Literal value
    of ekAdd, ekSub, ekMul, ekDiv, ekMod, ekPow, ekEq, ekNe, ekLt, ekLe, ekGt, ekGe, ekAnd, ekOr:
      left*: Expression  ## Left operand of binary operation
      right*: Expression ## Right operand of binary operation
    of ekGroup:
      child*: Expression ## Expression inside parentheses
    of ekNeg:
      operand*: Expression ## Operand for unary negation
    of ekIdent:
      name*: string ## Identifier name
    of ekAssign:
      ident*: string ## Target identifier for assignment
      expr*: Expression ## Assigned expression
      isLocal*: bool ## Flag indicating if the assignment is to a local variable
    of ekFuncCall:
      fun*: string ## Function name to call
      args*: seq[Expression] ## Arguments for the function call
    of ekFuncInvoke:
      callee*: Value ## Function reference (value of type function)
      arguments*: seq[Expression] ## Arguments for the invocation
    of ekBlock:
      expressions*: seq[Expression] ## Sequence of statements in the block
    of ekFunc:
      body*: Expression ## Function body expression
      params*: seq[string] ## Function parameter names
    of ekVector:
      values*: seq[Expression] ## Elements of the vector literal
    of ekIf:
      branches*: seq[tuple[condition: Expression, thenBranch: Expression]] ## if/elif branches
      elseBranch*: Expression ## Else branch expression

  Environment* = ref object
    values*: Table[string, Value]
    parent*: Environment

  BMathError* = object of CatchableError
    ## Error type with contextual information for parser/runtime errors.
    position*: Position ## Source location where error occurred
    context*: string ## Additional error context/message
    source: string ## Source code snippet for context

proc `$`*(pos: Position): string =
  ## Returns human-readable string representation of source position
  $pos.line & ":" & $pos.column

proc `$`*(value: Value): string =
  ## Returns string representation of numeric value
  case value.kind
  of vkInt:
    $value.iValue
  of vkFloat:
    $value.fValue
  of vkNativeFunc:
    "<native func>"
  of vkFunction:
    "<function>"
  of vkVector:
    "[" & value.values.mapIt($it).join(", ") & "]"
  of vkBool:
    $value.bValue

proc stringify(node: Expression, indent: int): string =
  ## Helper for AST string representation (internal use)
  let indentation = " ".repeat(indent)
  case node.kind
  of ekValue:
    result = indentation & "value: " & $node.value & "\n"
  of eKAdd, eKSub, eKMul, eKDiv, eKMod, eKPow, eKEq, eKNe, eKLt, eKLe, eKGt, eKGe, eKAnd, eKOr:
    let kindStr = toLowerAscii($node.kind).substr(2)
    result = indentation & kindStr & ":\n"
    result.add(indentation & "  left:\n")
    result.add(node.left.stringify(indent + 4))
    result.add("\n" & indentation & "  right:\n")
    result.add(node.right.stringify(indent + 4))
  of eKGroup:
    result = indentation & "group:\n"
    result.add(node.child.stringify(indent + 2))
  of eKNeg:
    result = indentation & "neg:\n"
    result.add(node.operand.stringify(indent + 2))
  of eKIdent:
    result = indentation & "ident: " & node.name & "\n"
  of eKAssign:
    result = indentation & "assign: " & node.ident & "\n"
    result.add(node.expr.stringify(indent + 2))
  of eKFuncCall:
    result = indentation & "func: " & node.fun & "\n"
    for arg in node.args:
      result.add(arg.stringify(indent + 2))
  of eKBlock:
    result = indentation & "block:\n"
    for expr in node.expressions:
      result.add(expr.stringify(indent + 2))
  of eKFunc:
    result = indentation & "function:\n"
    result.add(indentation & "  params: " & $node.params & "\n")
    result.add(node.body.stringify(indent + 2))
  of eKVector:
    result = indentation & "vector:\n"
    for val in node.values:
      result.add(val.stringify(indent + 2))
  of eKFuncInvoke:
    result = indentation & "invoke:\n"
    result.add(indentation & "  callee: " & $node.callee & "\n")
    for arg in node.arguments:
      result.add(arg.stringify(indent + 2))
  of eKIf:
    result = indentation & "if:\n"
    for branch in node.branches:
      result.add(indentation & "  condition:\n")
      result.add(branch.condition.stringify(indent + 4))
      result.add("\n" & indentation & "  then:\n")
      result.add(branch.thenBranch.stringify(indent + 4))
    if node.elseBranch != nil:
      result.add("\n" & indentation & "else:\n")
      result.add(node.elseBranch.stringify(indent + 2))

proc `$`*(node: Expression): string =
  ## Returns multi-line string representation of AST structure
  if node.isNil:
    return "nil"
  node.stringify(0)

proc `$`*(token: Token): string =
  ## Returns human-readable token representation
  case token.kind
  # Operators
  of tkAdd:
    "'+'"
  of tkSub:
    "'-'"
  of tkMul:
    "'*'"
  of tkDiv:
    "'/'"
  of tkPow:
    "'^'"
  of tkMod:
    "'%'"
  of tkAssign:
    "'='"
  # Boolean operators
  of tkAnd:
    "'&'"  ## Logical AND operator
  of tkNot:
    "'!'"  ## Logical NOT operator
  # Comparison operators
  of tkEq:
    "'=='"
  of tkNe:
    "'!='"
  of tkLt:
    "'<'"
  of tkLe:
    "'<='"
  of tkGt:
    "'>'"
  of tkGe:
    "'>='"
  # Structural tokens
  of tkLPar:
    "'('"
  of tkRPar:
    "')'"
  of tkLCurly:
    "'{'"
  of tkRCurly:
    "'}'"
  of tkRSquare:
    "'['"
  of tkLSquare:
    "']'"
  of tkLine:
    "'|'"
  # Literals and identifiers
  of tkValue:
    "'" & $token.value & "'"
  of tkIdent:
    "'" & token.name & "'"
  # Keywords
  of tkIf:
    "if"
  of tkElse:
    "else"
  of tkElif:
    "elif"
  of tkEndIf:
    "endif"
  of tkReturn:
    "return"
  of tkLocal:
    "local"
  # Control tokens
  of tkComma:
    "','"
  of tkNewline:
    "'\\n'"
  of tkEoe:
    "EOF"

proc `$`*(val: LabeledValue): string =
  if val.label != "":
    result = val.label & " = "
  result &= $val.value

proc `$`*(env: Environment): string =
  ## Returns string representation of environment values
  if env.parent != nil:
    result = "Environment(parent: " & $env.parent & ", values: " & $env.values & ")"
  else:
    result = "Environment(values: " & $env.values & ")"
