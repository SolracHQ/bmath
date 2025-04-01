import std/[strutils, sequtils]

import position
import number
import types
import vector

type
  ExpressionKind* = enum
    ## Abstract Syntax Tree (AST) node categories (now called Expressions).
    ## 
    ## Each variant corresponds to a different language construct with
    ## associated child nodes or values.

    # Literals
    ekNumber ## Numeric literal (integer or float)
    ekVector ## Vector literal
    ekBoolean ## Boolean literal (true or false)
    ekType ## Type literal (type name)

    # Unary operations
    ekNeg ## Unary negation operation (-operand)

    # Binary operations
    ekAdd ## Addition operation (left + right)
    ekSub ## Subtraction operation (left - right)
    ekMul ## Multiplication operation (left * right)
    ekDiv ## Division operation (left / right)
    ekPow ## Exponentiation operation (left ^ right)
    ekMod ## Modulus operation (left % right)

    # Comparison operations
    ekEq ## Equality comparison (left == right)
    ekNe ## Inequality comparison (left != right)
    ekLt ## Less-than comparison (left < right)
    ekLe ## Less-than-or-equal comparison (left <= right)
    ekGt ## Greater-than comparison (left > right)
    ekGe ## Greater-than-or-equal comparison (left >= right)

    # Logical operations
    ekAnd ## Logical AND operation (left & right)
    ekOr ## Logical OR operation (left | right)
    ekNot ## Logical NOT operation (!operand)

    # Identifiers and assignments
    ekIdent ## Identifier reference
    ekAssign ## Variable assignment (ident = expr)

    # Function constructs
    ekFuncDef ## Function definition
    ekFuncCall ## Function invocation

    # Block expression
    ekBlock ## Block expression (sequence of statements)

    # Control flow
    ekIf ## If-else conditional expression

  Parameter* = object
    ## Represents a function parameter.
    ##
    ## Contains the parameter name and its type.
    name*: string
    typ*: Type = AnyType

  # New specialized types for each expression variant
  NumberLiteral* = object
    number*: Number ## Number value

  BoolLiteral* = object
    boolean*: bool ## Boolean value

  VectorLiteral* = object
    vector*: Vector[Expression] ## Elements of the vector literal

  UnaryOp* = object
    operand*: Expression ## Operand for unary operation

  BinaryOp* = object
    left*: Expression ## Left operand of binary operation
    right*: Expression ## Right operand of binary operation

  Identifier* = object
    ident*: string ## Identifier name

  Assign* = object
    ident*: string ## Target identifier for assignment
    expr*: Expression ## Assigned expression
    isLocal*: bool ## Flag indicating if the assignment is to a local variable
    typ*: Type = AnyType ## Type of the assigned expression

  FunctionCall* = object
    function*: Expression ## Expression that evaluates to a function
    params*: seq[Expression] ## params for the invocation

  Block* = object
    expressions*: seq[Expression] ## Sequence of statements in the block

  FunctionDef* = object
    body*: Expression ## Function body expression
    params*: seq[Parameter] ## Function parameter names

  Branch* = object
    ## Represents a condition in an if-elif expression.
    ##
    ## Contains the condition expression and the corresponding branch expression.
    condition*: Expression
    then*: Expression

  IfExpr* = object
    branches*: seq[Branch]
    elseBranch*: Expression ## Else branch expression

  TypeCast* = object
    typ*: Type ## Type to cast to
    value*: Expression ## Expression to cast

  Expression* = ref object
    ## Abstract Syntax Tree (AST) node (renamed to Expression).
    ##
    ## The active fields depend on the node kind specified in the discriminator.
    ## Each kind maps to a specialized type.
    position*: Position ## Original source location
    case kind*: ExpressionKind
    of ekNumber:
      number*: Number
    of ekBoolean:
      boolean*: bool
    of ekVector:
      vector*: Vector[Expression]
    of ekType:
      typ*: Type
    of ekNeg, ekNot:
      unaryOp*: UnaryOp
    of ekAdd, ekSub, ekMul, ekDiv, ekMod, ekPow, ekEq, ekNe, ekLt, ekLe, ekGt, ekGe,
        ekAnd, ekOr:
      binaryOp*: BinaryOp
    of ekIdent:
      identifier*: Identifier
    of ekAssign:
      assign*: Assign
    of ekFuncCall:
      functionCall*: FunctionCall
    of ekBlock:
      blockExpr*: Block
    of ekFuncDef:
      functionDef*: FunctionDef
    of ekIf:
      ifExpr*: IfExpr

proc newLiteralExpr*[T](pos: Position, value: T): Expression =
  ## Creates a new literal expression based on the type of value.
  when T is int:
    result = newNumberExpr(pos, newNumber(value))
  elif T is float:
    result = newNumberExpr(pos, newNumber(value))
  elif T is Number:
    result = newNumberExpr(pos, value)
  elif T is bool:
    result = newBoolExpr(pos, value)
  elif T is seq[Expression]:
    result = newVectorExpr(pos, value)
  else:
    raise newException(ValueError, "Invalid type for literal expression")

proc newTypeExpr*(pos: Position, typ: Type): Expression {.inline.} =
  result = Expression(
    kind: ekType, 
    position: pos, 
    typ: typ
  )

proc newNotExpr*(pos: Position, operand: Expression): Expression {.inline.} =
  result = Expression(
    kind: ekNot, 
    position: pos, 
    unaryOp: UnaryOp(operand: operand)
  )

proc newNumberExpr*(pos: Position, value: Number): Expression {.inline.} =
  result = Expression(
    kind: ekNumber, 
    position: pos, 
    number: value
  )

proc newBoolExpr*(pos: Position, value: bool): Expression {.inline.} =
  result = Expression(
    kind: ekBoolean, 
    position: pos, 
    boolean: value
  )

proc newVectorExpr*(pos: Position, values: seq[Expression]): Expression {.inline.} =
  result = Expression(
    kind: ekVector, 
    position: pos, 
    vector: fromSeq[Expression](values)
  )

proc newNegExpr*(pos: Position, operand: Expression): Expression {.inline.} =
  result = Expression(
    kind: ekNeg, 
    position: pos, 
    unaryOp: UnaryOp(operand: operand)
  )

proc newBinaryExpr*(
    pos: Position, kind: static[ExpressionKind], left: Expression, right: Expression
): Expression {.inline.} =
  result = Expression(
    kind: kind, 
    position: pos, 
    binaryOp: BinaryOp(left: left, right: right)
  )

proc newIdentExpr*(pos: Position, ident: string): Expression {.inline.} =
  result = Expression(
    kind: ekIdent, 
    position: pos, 
    identifier: Identifier(ident: ident)
  )

proc newAssignExpr*(
    pos: Position, ident: string, expr: Expression, isLocal: bool, typ: Type
): Expression {.inline.} =
  result = Expression(
    kind: ekAssign, 
    position: pos, 
    assign: Assign(ident: ident, expr: expr, isLocal: isLocal, typ: typ)
  )

proc newFuncCallExpr*(
    pos: Position, function: Expression, args: seq[Expression]
): Expression {.inline.} =
  result = Expression(
    kind: ekFuncCall, 
    position: pos, 
    functionCall: FunctionCall(function: function, params: args)
  )

proc newBlockExpr*(pos: Position, expressions: seq[Expression]): Expression {.inline.} =
  result = Expression(
    kind: ekBlock, 
    position: pos, 
    blockExpr: Block(expressions: expressions)
  )

proc newFuncExpr*(
    pos: Position, params: seq[Parameter], body: Expression
): Expression {.inline.} =
  result = Expression(
    kind: ekFuncDef, 
    position: pos, 
    functionDef: FunctionDef(params: params, body: body)
  )

proc newIfExpr*(
    pos: Position, branches: seq[Branch], elseBranch: Expression
): Expression {.inline.} =
  result = Expression(
    kind: ekIf, 
    position: pos, 
    ifExpr: IfExpr(branches: branches, elseBranch: elseBranch)
  )

proc newBranch*(
    conditionExpr: Expression, thenExpr: Expression
): Branch {.inline.} =
  Branch(condition: conditionExpr, then: thenExpr)

proc newParameter*(name: string, typ: Type = AnyType): Parameter {.inline.} =
  ## Creates a new function parameter with the given name and type.
  Parameter(name: name, typ: typ)

proc stringify(node: Expression, indent: int): string =
  ## Helper for AST string representation (internal use)
  let indentation = " ".repeat(indent)
  result = indentation & "position: " & $node.position & "\n"
  if node.isNil:
    result.add indentation & "nil\n"
  case node.kind
  of ekNumber:
    result.add indentation & "number: " & $node.number & "\n"
  of ekBoolean:
    result.add indentation & "bool: " & $node.boolean & "\n"
  of eKAdd, eKSub, eKMul, eKDiv, eKMod, eKPow, eKEq, eKNe, eKLt, eKLe, eKGt, eKGe,
      eKAnd, eKOr:
    let kindStr = toLowerAscii($node.kind).substr(2)
    result.add indentation & kindStr & ":\n"
    result.add(indentation & "  left:\n")
    result.add(node.binaryOp.left.stringify(indent + 4))
    result.add("\n" & indentation & "  right:\n")
    result.add(node.binaryOp.right.stringify(indent + 4))
  of eKNeg:
    result.add indentation & "neg:\n"
    result.add(node.unaryOp.operand.stringify(indent + 2))
  of eKNot:
    result.add indentation & "not:\n"
    result.add(node.unaryOp.operand.stringify(indent + 2))
  of eKIdent:
    result.add indentation & "ident: " & node.identifier.ident & "\n"
  of eKAssign:
    result.add indentation & "assign: " & node.assign.ident & "\n"
    result.add("\n" & indentation & "  isLocal: " & $node.assign.isLocal & "\n")
    result.add(node.assign.expr.stringify(indent + 2))
  of eKBlock:
    result.add indentation & "block:\n"
    for expr in node.blockExpr.expressions:
      result.add(expr.stringify(indent + 2))
  of ekFuncDef:
    result.add indentation & "function:\n"
    result.add(indentation & "  params: " & $node.functionDef.params & "\n")
    result.add(node.functionDef.body.stringify(indent + 2))
  of eKVector:
    result.add indentation & "vector:\n"
    for val in node.vector:
      result.add(val.stringify(indent + 2))
  of ekFuncCall:
    result.add indentation & "function call:\n"
    result.add(node.functionCall.function.stringify(indent + 2))
    result.add("\n" & indentation & "  params:\n")
    for arg in node.functionCall.params:
      result.add(arg.stringify(indent + 4))
  of eKIf:
    result.add indentation & "if:\n"
    for branch in node.ifExpr.branches:
      result.add(indentation & "  condition:\n")
      result.add(branch.condition.stringify(indent + 4))
      result.add("\n" & indentation & "  then:\n")
      result.add(branch.then.stringify(indent + 4))
    if node.ifExpr.elseBranch != nil:
      result.add("\n" & indentation & "else:\n")
      result.add(node.ifExpr.elseBranch.stringify(indent + 2))
  of eKType:
    result.add indentation & "type: " & $node.typ & "\n"

proc `$`*(node: Expression): string =
  ## Returns multi-line string representation of AST structure
  if node.isNil:
    return "nil"
  for line in node.stringify(0).splitLines:
    if line.len > 0:
      result.add(line)
      result.add("\n")
  result = result.strip

proc `$`(param: Parameter): string =
  ## Returns string representation of function parameter
  return param.name & ": " & $param.typ

proc asSource*(expr: Expression, ident: int = 0): string =
  ## Returns a string representation of the expression in source code format
  case expr.kind
  of ekNumber:
    return $expr.number
  of ekBoolean:
    return $expr.boolean
  of ekAdd:
    return asSource(expr.binaryOp.left) & " + " & asSource(expr.binaryOp.right)
  of ekSub:
    return asSource(expr.binaryOp.left) & " - " & asSource(expr.binaryOp.right)
  of ekMul:
    return asSource(expr.binaryOp.left) & " * " & asSource(expr.binaryOp.right)
  of ekDiv:
    return asSource(expr.binaryOp.left) & " / " & asSource(expr.binaryOp.right)
  of ekPow:
    return asSource(expr.binaryOp.left) & " ^ " & asSource(expr.binaryOp.right)
  of ekMod:
    return asSource(expr.binaryOp.left) & " % " & asSource(expr.binaryOp.right)
  of ekEq:
    return asSource(expr.binaryOp.left) & " == " & asSource(expr.binaryOp.right)
  of ekNe:
    return asSource(expr.binaryOp.left) & " != " & asSource(expr.binaryOp.right)
  of ekLt:
    return asSource(expr.binaryOp.left) & " < " & asSource(expr.binaryOp.right)
  of ekLe:
    return asSource(expr.binaryOp.left) & " <= " & asSource(expr.binaryOp.right)
  of ekGt:
    return asSource(expr.binaryOp.left) & " > " & asSource(expr.binaryOp.right)
  of ekGe:
    return asSource(expr.binaryOp.left) & " >= " & asSource(expr.binaryOp.right)
  of ekAnd:
    return asSource(expr.binaryOp.left) & " & " & asSource(expr.binaryOp.right)
  of ekOr:
    return asSource(expr.binaryOp.left) & " | " & asSource(expr.binaryOp.right)
  of ekNot:
    return "!" & asSource(expr.unaryOp.operand)
  of ekNeg:
    return "-" & asSource(expr.unaryOp.operand)
  of ekIdent:
    return expr.identifier.ident
  of ekAssign:
    return expr.assign.ident & " = " & asSource(expr.assign.expr)
  of ekFuncCall:
    return asSource(expr.functionCall.function) & "(" & 
      expr.functionCall.params.mapIt(asSource(it)).join(", ") & ")"
  of ekBlock:
    let indentation = " ".repeat(ident * 2)
    if expr.blockExpr.expressions.len == 1:
      return "{" & asSource(expr.blockExpr.expressions[0]) & "}"
    else:
      let innerIndent = " ".repeat((ident + 1) * 2)
      return "{" & "\n" &
        expr.blockExpr.expressions.mapIt(innerIndent & asSource(it, ident + 1)).join("\n") & "\n" &
        indentation & "}"
  of ekFuncDef:
    return "|" & expr.functionDef.params.join(", ") & "| " & asSource(expr.functionDef.body)
  of ekVector:
    return "[" & expr.vector.toSeq().mapIt(asSource(it)).join(", ") & "]"
  of ekIf:
    var src = ""
    if expr.ifExpr.branches.len > 0:
      src.add(
        "if (" & asSource(expr.ifExpr.branches[0].condition) & ") " &
          asSource(expr.ifExpr.branches[0].then)
      )
      for branch in expr.ifExpr.branches[1 .. ^1]:
        src.add(" elif (" & asSource(branch.condition) & ") " & asSource(branch.then))
    if expr.ifExpr.elseBranch != nil:
      src.add(" else " & asSource(expr.ifExpr.elseBranch))
    return src
  of ekType:
    return $expr.typ
