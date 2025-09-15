import std/[strutils, sequtils]

import position
import number
import bm_types
import vector

from core import
  Expression, ExpressionKind, UnaryOp, BinaryOp, Identifier, Value, ValueKind, Assign,
  FunctionCall, Block, Parameter, FunctionDef, IfExpr, Branch, ModuleDef, UseModule,
  ModuleAccess, VectorIndex
export
  Expression, ExpressionKind, Parameter, Branch, Assign, FunctionCall, Block, Parameter,
  FunctionDef, IfExpr, Branch, ModuleDef, UseModule, ModuleAccess, VectorIndex
export Expression, ExpressionKind, Parameter, Branch

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
  elif T is string:
    result = Expression(kind: ekString, position: pos, content: value)
  else:
    raise newException(ValueError, "Invalid type for literal expression")

proc newNotExpr*(pos: Position, operand: Expression): Expression {.inline.} =
  result = Expression(kind: ekNot, position: pos, unaryOp: UnaryOp(operand: operand))

proc newGroupExpr*(pos: Position, inner: Expression): Expression =
  result = Expression(position: pos, kind: ekGroup, groupExpr: inner)

proc newValueExpr*(pos: Position, value: Value): Expression {.inline.} =
  result = Expression(kind: ekValue, position: pos, value: value)

proc newVectorExpr*(pos: Position, values: seq[Expression]): Expression {.inline.} =
  result =
    Expression(kind: ekVector, position: pos, vector: fromSeq[Expression](values))

proc newNegExpr*(pos: Position, operand: Expression): Expression {.inline.} =
  result = Expression(kind: ekNeg, position: pos, unaryOp: UnaryOp(operand: operand))

proc newBinaryExpr*(
    pos: Position, kind: static[ExpressionKind], left: Expression, right: Expression
): Expression {.inline.} =
  result =
    Expression(kind: kind, position: pos, binaryOp: BinaryOp(left: left, right: right))

proc newIdentExpr*(pos: Position, ident: string): Expression {.inline.} =
  result =
    Expression(kind: ekIdent, position: pos, identifier: Identifier(ident: ident))

proc newAssignExpr*(
    pos: Position, lvalue: Expression, expr: Expression, isLocal: bool, typ: BMathType
): Expression {.inline.} =
  result = Expression(
    kind: ekAssign,
    position: pos,
    assign: Assign(lvalue: lvalue, expr: expr, isLocal: isLocal, typ: typ),
  )

proc newFuncCallExpr*(
    pos: Position, function: Expression, args: seq[Expression]
): Expression {.inline.} =
  result = Expression(
    kind: ekFuncCall,
    position: pos,
    functionCall: FunctionCall(function: function, params: args),
  )

proc newBlockExpr*(pos: Position, expressions: seq[Expression]): Expression {.inline.} =
  result =
    Expression(kind: ekBlock, position: pos, blockExpr: Block(expressions: expressions))

proc newModuleExpr*(pos: Position, content: seq[Expression]): Expression {.inline.} =
  result =
    Expression(kind: ekModule, position: pos, moduleDef: ModuleDef(content: content))

proc newUseModuleExpr*(pos: Position, path: string): Expression {.inline.} =
  result = Expression(kind: ekUse, position: pos, useModule: UseModule(path: path))

proc newModuleAccessExpr*(
    pos: Position, target: Expression, member: string
): Expression {.inline.} =
  result = Expression(
    kind: ekModAccess,
    position: pos,
    moduleAccess: ModuleAccess(target: target, member: member),
  )

proc newVectorIndexExpr*(
    pos: Position, vector: Expression, index: Expression
): Expression {.inline.} =
  result = Expression(
    kind: ekVecIndex,
    position: pos,
    vectorIndex: VectorIndex(vector: vector, index: index),
  )

proc newFuncExpr*(
    pos: Position,
    params: seq[Parameter],
    body: Expression,
    returnType: BMathType = AnyType,
): Expression {.inline.} =
  result = Expression(
    kind: ekFuncDef,
    position: pos,
    functionDef: FunctionDef(params: params, body: body, returnType: returnType),
  )

proc newIfExpr*(
    pos: Position, branches: seq[Branch], elseBranch: Expression
): Expression {.inline.} =
  result = Expression(
    kind: ekIf,
    position: pos,
    ifExpr: IfExpr(branches: branches, elseBranch: elseBranch),
  )

proc newBranch*(conditionExpr: Expression, thenExpr: Expression): Branch {.inline.} =
  Branch(condition: conditionExpr, then: thenExpr)

proc newParameter*(name: string, typ: BMathType = AnyType): Parameter {.inline.} =
  ## Creates a new function parameter with the given name and type.
  Parameter(name: name, typ: typ)

proc stringify(node: Expression, indent: int): string =
  ## Helper for AST string representation (internal use)
  let indentation = " ".repeat(indent)
  result = indentation & "position: " & $node.position & "\n"
  if node.isNil:
    result.add indentation & "nil\n"
  case node.kind
  of ekValue:
    result.add $indentation & "value: " & $node.value & "\n"
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
    result.add indentation & (if node.assign.isLocal: "local " else: "") & "assign:\n"
    result.add(indentation & "  lvalue:\n")
    result.add(node.assign.lvalue.stringify(indent + 4))
    result.add("\n" & indentation & "  expr:\n")
    result.add(node.assign.expr.stringify(indent + 4))
    result.add("\n" & indentation & "  type: " & $node.assign.typ & "\n")
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
  of ekGroup:
    result.add indentation & "group:\n"
    result.add(node.groupExpr.stringify(indent + 2))
  of ekModule:
    result.add indentation & "module:\n"
    for expr in node.moduleDef.content:
      result.add(expr.stringify(indent + 2))
  of ekUse:
    result.add indentation & "use module: '" & node.useModule.path & "'\n"
  of ekModAccess:
    result.add indentation & "module access: " & node.moduleAccess.member & "\n"
    result.add(indentation & "  target:\n")
    result.add(node.moduleAccess.target.stringify(indent + 4))
  of ekVecIndex:
    result.add indentation & "vector index:\n"
    result.add(indentation & "  vector:\n")
    result.add(node.vectorIndex.vector.stringify(indent + 4))
    result.add("\n" & indentation & "  index:\n")
    result.add(node.vectorIndex.index.stringify(indent + 4))

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

proc asSexp*(expr: Expression): string =
  ## Returns a string representation of the expression as an S-expression
  if expr.isNil:
    return "nil"

  case expr.kind
  of ekValue:
    case expr.value.kind
    of vkNumber:
      return $expr.value.number
    of vkBool:
      return $expr.value.boolean
    of vkString:
      return "\"" & expr.value.content & "\""
    of vkType:
      return $expr.value.typ
    else:
      return $expr.value
  of ekIdent:
    return expr.identifier.ident
  of ekNeg:
    return "(neg " & expr.unaryOp.operand.asSexp() & ")"
  of ekNot:
    return "(not " & expr.unaryOp.operand.asSexp() & ")"
  of ekAdd:
    return
      "(+ " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekSub:
    return
      "(- " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekMul:
    return
      "(* " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekDiv:
    return
      "(/ " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekMod:
    return
      "(% " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekPow:
    return
      "(^ " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekEq:
    return
      "(== " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekNe:
    return
      "(!= " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekLt:
    return
      "(< " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekLe:
    return
      "(<= " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekGt:
    return
      "(> " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekGe:
    return
      "(>= " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekAnd:
    return
      "(& " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekOr:
    return
      "(| " & expr.binaryOp.left.asSexp() & " " & expr.binaryOp.right.asSexp() & ")"
  of ekAssign:
    let localStr = if expr.assign.isLocal: "local " else: ""
    return
      "(" & localStr & "set " & expr.assign.lvalue.asSexp() & " " &
      expr.assign.expr.asSexp() & " : " & $expr.assign.typ & ")"
  of ekFuncCall:
    var argsStr = ""
    for i, arg in expr.functionCall.params:
      if i > 0:
        argsStr.add(" ")
      argsStr.add(arg.asSexp())
    return "(call " & expr.functionCall.function.asSexp() & " " & argsStr & ")"
  of ekFuncDef:
    var paramsStr = ""
    for i, param in expr.functionDef.params:
      if i > 0:
        paramsStr.add(" ")
      paramsStr.add(param.name)
    return "(lambda (" & paramsStr & ") " & expr.functionDef.body.asSexp() & ")"
  of ekVector:
    var elementsStr = ""
    for i in 0 ..< expr.vector.size:
      if i > 0:
        elementsStr.add(" ")
      elementsStr.add(expr.vector[i].asSexp())
    return "(vector " & elementsStr & ")"
  of ekBlock:
    var exprsStr = ""
    for i, e in expr.blockExpr.expressions:
      if i > 0:
        exprsStr.add(" ")
      exprsStr.add(e.asSexp())
    return "(block " & exprsStr & ")"
  of ekIf:
    var branchesStr = ""
    for branch in expr.ifExpr.branches:
      branchesStr.add(
        "(if " & branch.condition.asSexp() & " " & branch.then.asSexp() & ") "
      )
    branchesStr.add("(else " & expr.ifExpr.elseBranch.asSexp() & ")")
    return "(cond " & branchesStr & ")"
  of ekGroup:
    return "(group " & expr.groupExpr.asSexp() & ")"
  of ekModule:
    var exprsStr = ""
    for e in expr.moduleDef.content:
      if exprsStr.len > 0:
        exprsStr.add(" ")
      exprsStr.add(e.asSexp())
    return "(module " & exprsStr & ")"
  of ekUse:
    return "(use \"" & expr.useModule.path & "\")"
  of ekModAccess:
    return
      "(access " & expr.moduleAccess.target.asSexp() & " \"" & expr.moduleAccess.member &
      "\")"
  of ekVecIndex:
    return
      "(index " & expr.vectorIndex.vector.asSexp() & " " &
      expr.vectorIndex.index.asSexp() & ")"

# S-Expressions are better for debug than asSource so 
# I will remove asSource for the moment since it is hard to maintain when changing the AST
# but if some contributor wants to maintain it, feel free to re-add it :D
