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
      body*: AstNode
      env*: Environment
      params*: seq[string]
    of vkVector:
      values*: seq[Value]

  LabeledValue* = object
    label*: string
    value*: Value

  Evaluator* = proc(node: AstNode): Value
    ## Function type for evaluating AST nodes in the interpreter.

  HostFunction* = proc(args: openArray[AstNode], evaluator: Evaluator): Value
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
    tkAdd ## Addition operator '+'
    tkSub ## Subtraction operator '-'
    tkMul ## Multiplication operator '*'
    tkDiv ## Division operator '/'
    tkPow ## Exponentiation operator '^'
    tkLPar ## Left parenthesis '('
    tkRPar ## Right parenthesis ')'
    tkLCurly ## Left curly brace '{'
    tkRCurly ## Right curly brace '}'
    tkRSquare ## Square bracket '['
    tkLSquare ## Square bracket ']'
    tkLine ## Parameter delimiter '|'
    tkNum ## Numeric literal (integer or float)
    tkMod ## Modulus operator '%'
    tkIdent ## Identifier (variable/function name)
    tkAssign ## Assignment operator '='
    tkComma ## Argument separator ','
    tkNewline
      ## Newline character '\n' # End of expression marker for parser (due multiline blocks support)
    tkEoe ## End of expression marker for lexer

  Token* = object
    ## Lexical token with source position and type-specific data.
    ## 
    ## The active field depends on the token kind:
    ## - `value` for numeric literals (tkNum)
    ## - `name` for identifiers (tkIdent)
    position*: Position ## Source location of the token
    case kind*: TokenKind
    of tkNum:
      value*: Value ## Numeric value for tkNum tokens
    of tkIdent:
      name*: string ## Identifier name for tkIdent tokens
    else:
      discard

  NodeKind* = enum
    ## Abstract Syntax Tree node categories.
    ## 
    ## Each variant corresponds to different language constructs
    ## with associated child nodes or values.
    nkValue ## Numeric literal value
    nkAdd ## Addition operation (left + right)
    nkSub ## Subtraction operation (left - right)
    nkMul ## Multiplication operation (left * right)
    nkDiv ## Division operation (left / right)
    nkPow ## Exponentiation operation (left ^ right)
    nkGroup ## Parenthesized expression group
    nkNeg ## Unary negation operation (-operand)
    nkMod ## Modulus operation (left % right)
    nkIdent ## Identifier reference
    nkAssign ## Variable assignment (ident = expr)
    nkVector ## Vector literal
    nkBlock ## Block expression (sequence of statements)
    nkFunc ## Function definition
    nkFuncCall ## Function call with arguments
    nkFuncInvoke ## Function invocation (internal use)

  AstNode* = ref object
    ## Abstract Syntax Tree node with source position information.
    ## 
    ## The active fields depend on the node kind:
    ## - Values for nkNumber
    ## - Left/right operands for binary operations
    ## - Child nodes for groups and unary operations
    ## - Name and arguments for identifiers and function calls
    position*: Position ## Original source location
    case kind*: NodeKind
    of nkValue:
      value*: Value ## Value for literals
    of nkAdd, nkSub, nkMul, nkDiv, nkMod, nkPow:
      left*: AstNode ## Left operand of binary operation
      right*: AstNode ## Right operand of binary operation
    of nkGroup:
      child*: AstNode ## Expression inside parentheses
    of nkNeg:
      operand*: AstNode ## Operand for unary negation
    of nkIdent:
      name*: string ## Identifier name
    of nkAssign:
      ident*: string ## Target identifier for assignment
      expr*: AstNode ## Assigned value expression
    of nkFuncCall:
      fun*: string ## Function name to call
      args*: seq[AstNode] ## Arguments for function call
    of nkFuncInvoke:
      callee*: Value ## Function reference
      arguments*: seq[AstNode] ## Arguments for function invocation
    of nkBlock:
      expressions*: seq[AstNode] ## Sequence of statements in block
    of nkFunc:
      body*: AstNode ## Function body expression
      params*: seq[string] ## Function parameter names
    of nkVector:
      values*: seq[AstNode] ## Vector literal values

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

proc stringify(node: AstNode, indent: int): string =
  ## Helper for AST string representation (internal use)
  let indentation = " ".repeat(indent)
  case node.kind
  of nkValue:
    result = indentation & "value: " & $node.value & "\n"
  of nkAdd, nkSub, nkMul, nkDiv, nkMod, nkPow:
    let kindStr = toLowerAscii($node.kind).substr(2)
    result = indentation & kindStr & ":\n"
    result.add(indentation & "  left:\n")
    result.add(node.left.stringify(indent + 4))
    result.add("\n" & indentation & "  right:\n")
    result.add(node.right.stringify(indent + 4))
  of nkGroup:
    result = indentation & "group:\n"
    result.add(node.child.stringify(indent + 2))
  of nkNeg:
    result = indentation & "neg:\n"
    result.add(node.operand.stringify(indent + 2))
  of nkIdent:
    result = indentation & "ident: " & node.name & "\n"
  of nkAssign:
    result = indentation & "assign: " & node.ident & "\n"
    result.add(node.expr.stringify(indent + 2))
  of nkFuncCall:
    result = indentation & "func: " & node.fun & "\n"
    for arg in node.args:
      result.add(arg.stringify(indent + 2))
  of nkBlock:
    result = indentation & "block:\n"
    for expr in node.expressions:
      result.add(expr.stringify(indent + 2))
  of nkFunc:
    result = indentation & "function:\n"
    result.add(indentation & "  params: " & $node.params & "\n")
    result.add(node.body.stringify(indent + 2))
  of nkVector:
    result = indentation & "vector:\n"
    for val in node.values:
      result.add(val.stringify(indent + 2))
  of nkFuncInvoke:
    result = indentation & "invoke:\n"
    result.add(indentation & "  callee: " & $node.callee & "\n")
    for arg in node.arguments:
      result.add(arg.stringify(indent + 2))

proc `$`*(node: AstNode): string =
  ## Returns multi-line string representation of AST structure
  if node.isNil:
    return "nil"
  node.stringify(0)

proc `$`*(token: Token): string =
  ## Returns human-readable token representation
  case token.kind
  of tkAdd:
    "'+'"
  of tkSub:
    "'-'"
  of tkMul:
    "'*'"
  of tkDiv:
    "'/'"
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
  of tkMod:
    "'%'"
  of tkPow:
    "'^'"
  of tkComma:
    "','"
  of tkAssign:
    "'='"
  of tkNewline:
    "'\\n'"
  of tkIdent:
    "'" & token.name & "'"
  of tkNum:
    "'" & $token.value & "'"
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
