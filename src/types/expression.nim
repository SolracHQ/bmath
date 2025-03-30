import std/[strutils, sequtils]

import position
import number

type
  ExpressionKind* = enum
    ## Abstract Syntax Tree (AST) node categories (now called Expressions).
    ## 
    ## Each variant corresponds to a different language construct with
    ## associated child nodes or values.

    # Literals
    ekNumber ## Numeric literal (integer or float)
    ekVector ## Vector literal
    ekBool ## Boolean literal (true or false)

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
    ekFunc ## Function definition
    ekFuncInvoke ## Function invocation 

    # Block expression
    ekBlock ## Block expression (sequence of statements)

    # Control flow
    ekIf ## If-else conditional expression

  Condition* = object
    ## Represents a condition in an if-elif expression.
    ##
    ## Contains the condition expression and the corresponding branch expression.
    condition*: Expression
    then*: Expression

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
    of ekNumber:
      nValue*: Number ## Integer value
    of ekAdd, ekSub, ekMul, ekDiv, ekMod, ekPow, ekEq, ekNe, ekLt, ekLe, ekGt, ekGe,
        ekAnd, ekOr:
      left*: Expression ## Left operand of binary operation
      right*: Expression ## Right operand of binary operation
    of ekNeg, ekNot:
      operand*: Expression ## Operand for unary negation
    of ekIdent:
      name*: string ## Identifier name
    of ekAssign:
      ident*: string ## Target identifier for assignment
      expr*: Expression ## Assigned expression
      isLocal*: bool ## Flag indicating if the assignment is to a local variable
    of ekFuncInvoke:
      fun*: Expression ## Expression that evaluates to a function
      arguments*: seq[Expression] ## Arguments for the invocation
    of ekBlock:
      expressions*: seq[Expression] ## Sequence of statements in the block
    of ekFunc:
      body*: Expression ## Function body expression
      params*: seq[string] ## Function parameter names
    of ekVector:
      values*: seq[Expression] ## Elements of the vector literal
    of ekIf:
      branches*: seq[Condition]
      elseBranch*: Expression ## Else branch expression 
    of ekBool:
      bValue*: bool ## Boolean value

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

proc newNotExpr*(pos: Position, operand: Expression): Expression {.inline.} =
  result = Expression(kind: ekNot, position: pos, operand: operand)

proc newNumberExpr*(pos: Position, value: Number): Expression {.inline.} =
  result = Expression(kind: ekNumber, position: pos, nValue: value)

proc newBoolExpr*(pos: Position, value: bool): Expression {.inline.} =
  result = Expression(kind: ekBool, position: pos, bValue: value)

proc newVectorExpr*(pos: Position, values: seq[Expression]): Expression {.inline.} =
  result = Expression(kind: ekVector, position: pos, values: values)

proc newNegExpr*(pos: Position, operand: Expression): Expression {.inline.} =
  result = Expression(kind: ekNeg, position: pos, operand: operand)

proc newBinaryExpr*(
    pos: Position, kind: static[ExpressionKind], left: Expression, right: Expression
): Expression {.inline.} =
  result = Expression(kind: kind, position: pos, left: left, right: right)

proc newIdentExpr*(pos: Position, name: string): Expression {.inline.} =
  result = Expression(kind: ekIdent, position: pos, name: name)

proc newAssignExpr*(
    pos: Position, ident: string, expr: Expression, isLocal: bool
): Expression {.inline.} =
  result = Expression(
    kind: ekAssign, position: pos, ident: ident, expr: expr, isLocal: isLocal
  )

proc newFuncCallExpr*(
    pos: Position, funName: string, args: seq[Expression]
): Expression {.inline.} =
  result = Expression(
    kind: ekFuncInvoke, position: pos, fun: newIdentExpr(pos, funName), arguments: args
  )

proc newFuncInvokeExpr*(
    pos: Position, fun: Expression, args: seq[Expression]
): Expression {.inline.} =
  result = Expression(kind: ekFuncInvoke, position: pos, fun: fun, arguments: args)

proc newBlockExpr*(pos: Position, expressions: seq[Expression]): Expression {.inline.} =
  result = Expression(kind: ekBlock, position: pos, expressions: expressions)

proc newFuncExpr*(
    pos: Position, params: seq[string], body: Expression
): Expression {.inline.} =
  result = Expression(kind: ekFunc, position: pos, params: params, body: body)

proc newIfExpr*(
    pos: Position, branches: seq[Condition], elseBranch: Expression
): Expression {.inline.} =
  result =
    Expression(kind: ekIf, position: pos, branches: branches, elseBranch: elseBranch)

proc newCondition*(
    conditionExpr: Expression, thenExpr: Expression
): Condition {.inline.} =
  Condition(condition: conditionExpr, then: thenExpr)

proc stringify(node: Expression, indent: int): string =
  ## Helper for AST string representation (internal use)
  let indentation = " ".repeat(indent)
  result = indentation & "position: " & $node.position & "\n"
  if node.isNil:
    result.add indentation & "nil\n"
  case node.kind
  of ekNumber:
    result.add indentation & "number: " & $node.nValue & "\n"
  of ekBool:
    result.add indentation & "bool: " & $node.bValue & "\n"
  of eKAdd, eKSub, eKMul, eKDiv, eKMod, eKPow, eKEq, eKNe, eKLt, eKLe, eKGt, eKGe,
      eKAnd, eKOr:
    let kindStr = toLowerAscii($node.kind).substr(2)
    result.add indentation & kindStr & ":\n"
    result.add(indentation & "  left:\n")
    result.add(node.left.stringify(indent + 4))
    result.add("\n" & indentation & "  right:\n")
    result.add(node.right.stringify(indent + 4))
  of eKNeg:
    result.add indentation & "neg:\n"
    result.add(node.operand.stringify(indent + 2))
  of eKNot:
    result.add indentation & "not:\n"
    result.add(node.operand.stringify(indent + 2))
  of eKIdent:
    result.add indentation & "ident: " & node.name & "\n"
  of eKAssign:
    result.add indentation & "assign: " & node.ident & "\n"
    result.add("\n" & indentation & "  isLocal: " & $node.isLocal & "\n")
    result.add(node.expr.stringify(indent + 2))
  of eKBlock:
    result.add indentation & "block:\n"
    for expr in node.expressions:
      result.add(expr.stringify(indent + 2))
  of eKFunc:
    result.add indentation & "function:\n"
    result.add(indentation & "  params: " & $node.params & "\n")
    result.add(node.body.stringify(indent + 2))
  of eKVector:
    result.add indentation & "vector:\n"
    for val in node.values:
      result.add(val.stringify(indent + 2))
  of eKFuncInvoke:
    result.add indentation & "function call:\n"
    result.add(node.fun.stringify(indent + 2))
    result.add("\n" & indentation & "  arguments:\n")
    for arg in node.arguments:
      result.add(arg.stringify(indent + 4))
  of eKIf:
    result.add indentation & "if:\n"
    for branch in node.branches:
      result.add(indentation & "  condition:\n")
      result.add(branch.condition.stringify(indent + 4))
      result.add("\n" & indentation & "  then:\n")
      result.add(branch.then.stringify(indent + 4))
    if node.elseBranch != nil:
      result.add("\n" & indentation & "else:\n")
      result.add(node.elseBranch.stringify(indent + 2))

proc `$`*(node: Expression): string =
  ## Returns multi-line string representation of AST structure
  if node.isNil:
    return "nil"
  for line in node.stringify(0).splitLines:
    if line.len > 0:
      result.add(line)
      result.add("\n")
  result = result.strip

proc `==`*(a, b: Expression): bool =
  ## Compares two AST nodes for equality
  if a.isNil and b.isNil:
    return true
  elif a.isNil or b.isNil:
    return false
  elif a.position != b.position:
    return false
  elif a.kind != b.kind:
    return false
  if a.kind != b.kind:
    return false
  case a.kind
  of ekNumber:
    return a.nValue == b.nValue
  of ekBool:
    return a.bValue == b.bValue
  of ekAdd, ekSub, ekMul, ekDiv, ekPow, ekMod, ekEq, ekNe, ekLt, ekLe, ekGt, ekGe,
      ekAnd, ekOr:
    return a.left == b.left and a.right == b.right
  of ekNeg:
    return a.operand == b.operand
  of ekNot:
    return a.operand == b.operand
  of ekIdent:
    return a.name == b.name
  of ekAssign:
    return a.ident == b.ident and a.expr == b.expr and a.isLocal == b.isLocal
  of ekFuncInvoke:
    if not (a.fun == b.fun):
      return false
    if a.arguments.len != b.arguments.len:
      return false
    for i in 0 ..< a.arguments.len:
      if not (a.arguments[i] == b.arguments[i]):
        return false
    return true
  of ekBlock:
    if a.expressions.len != b.expressions.len:
      return false
    for i in 0 ..< a.expressions.len:
      if not (a.expressions[i] == b.expressions[i]):
        return false
    return true
  of ekFunc:
    if a.params.len != b.params.len:
      return false
    for i in 0 ..< a.params.len:
      if a.params[i] != b.params[i]:
        return false
    return a.body == b.body
  of ekVector:
    if a.values.len != b.values.len:
      return false
    for i in 0 ..< a.values.len:
      if not (a.values[i] == b.values[i]):
        return false
    return true
  of ekIf:
    if a.branches.len != b.branches.len:
      return false
    for i in 0 ..< a.branches.len:
      if not (a.branches[i].condition == b.branches[i].condition):
        return false
      if not (a.branches[i].then == b.branches[i].then):
        return false
    if a.elseBranch == nil and b.elseBranch == nil:
      return true
    elif a.elseBranch != nil and b.elseBranch != nil:
      return a.elseBranch == b.elseBranch
    else:
      return false

proc asSource*(expr: Expression, ident: int = 0): string =
  ## Returns a string representation of the expression in source code format
  case expr.kind
  of ekNumber:
    return $expr.nValue
  of ekBool:
    return $expr.bValue
  of ekAdd:
    return asSource(expr.left) & " + " & asSource(expr.right)
  of ekSub:
    return asSource(expr.left) & " - " & asSource(expr.right)
  of ekMul:
    return asSource(expr.left) & " * " & asSource(expr.right)
  of ekDiv:
    return asSource(expr.left) & " / " & asSource(expr.right)
  of ekPow:
    return asSource(expr.left) & " ^ " & asSource(expr.right)
  of ekMod:
    return asSource(expr.left) & " % " & asSource(expr.right)
  of ekEq:
    return asSource(expr.left) & " == " & asSource(expr.right)
  of ekNe:
    return asSource(expr.left) & " != " & asSource(expr.right)
  of ekLt:
    return asSource(expr.left) & " < " & asSource(expr.right)
  of ekLe:
    return asSource(expr.left) & " <= " & asSource(expr.right)
  of ekGt:
    return asSource(expr.left) & " > " & asSource(expr.right)
  of ekGe:
    return asSource(expr.left) & " >= " & asSource(expr.right)
  of ekAnd:
    return asSource(expr.left) & " & " & asSource(expr.right)
  of ekOr:
    return asSource(expr.left) & " | " & asSource(expr.right)
  of ekNot:
    return "!" & asSource(expr.operand)
  of ekNeg:
    return "-" & asSource(expr.operand)
  of ekIdent:
    return expr.name
  of ekAssign:
    return expr.ident & " = " & asSource(expr.expr)
  of ekFuncInvoke:
    return
      asSource(expr.fun) & "(" & expr.arguments.mapIt(asSource(it)).join(", ") & ")"
  of ekBlock:
    let indentation = " ".repeat(ident * 2)
    if expr.expressions.len == 1:
      return "{" & asSource(expr.expressions[0]) & "}"
    else:
      let innerIndent = " ".repeat((ident + 1) * 2)
      return
        "{" & "\n" &
        expr.expressions.mapIt(innerIndent & asSource(it, ident + 1)).join("\n") & "\n" &
        indentation & "}"
  of ekFunc:
    return "|" & expr.params.join(", ") & "| " & asSource(expr.body)
  of ekVector:
    return "[" & expr.values.mapIt(asSource(it)).join(", ") & "]"
  of ekIf:
    var src = ""
    if expr.branches.len > 0:
      src.add(
        "if (" & asSource(expr.branches[0].condition) & ") " &
          asSource(expr.branches[0].then)
      )
      for branch in expr.branches[1 .. ^1]:
        src.add(" elif (" & asSource(branch.condition) & ") " & asSource(branch.then))
    if expr.elseBranch != nil:
      src.add(" else " & asSource(expr.elseBranch))
    return src
