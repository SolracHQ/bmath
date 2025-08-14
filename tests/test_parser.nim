## test_parser.nim
import unittest, math
import ../src/pipeline/parser
import ../src/pipeline/lexer
import ../src/types/[expression, vector, bm_types]
import ../src/types

suite "Parser tests":
  test "parses addition of identifiers":
    var lexer = newLexer("a + b")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekAdd
    check ast.binaryOp.left.kind == ekIdent
    check ast.binaryOp.left.identifier.ident == "a"
    check ast.binaryOp.right.kind == ekIdent
    check ast.binaryOp.right.identifier.ident == "b"

  test "addition of literals without constant folding":
    var lexer = newLexer("a + 3")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    # now we expect an addition node and not a folded literal
    check ast.kind == ekAdd
    check ast.binaryOp.left.kind == ekIdent
    check ast.binaryOp.left.identifier.ident == "a"
    check ast.binaryOp.right.kind == ekValue
    check ast.binaryOp.right.value.number.integer == 3

  test "unary negation with constant folding":
    var lexer = newLexer("-4")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekValue
    check ast.value.number.integer == -4

  test "unary negation without constant folding":
    var lexer = newLexer("-a")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekNeg
    check ast.unaryOp.operand.kind == ekIdent
    check ast.unaryOp.operand.identifier.ident == "a"

  test "group expression returns inner literal":
    var lexer = newLexer("(5.8)")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    # groups now simply return the inner expression
    check ast.kind == ekValue
    check ast.value.number.real == 5.8

  test "power operation without constant folding":
    var lexer = newLexer("b ^ 3")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    # expect a power node instead of a folded literal
    check ast.kind == ekPow
    check ast.binaryOp.left.kind == ekIdent
    check ast.binaryOp.left.identifier.ident == "b"
    check ast.binaryOp.right.kind == ekValue
    check ast.binaryOp.right.value.number.integer == 3

  test "multiplication without full constant folding":
    var lexer = newLexer("a * 3e0")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekMul
    check ast.binaryOp.left.kind == ekIdent
    check ast.binaryOp.left.identifier.ident == "a"
    check ast.binaryOp.right.kind == ekValue
    check ast.binaryOp.right.value.number.real == 3.0

  test "lambda function definition with block":
    ## Test that a lambda function with a block is parsed correctly.
    let src = "|| { a = 5\n b = 10\n (a + b) * 2 }"
    var lexer = newLexer(src)
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekFuncDef
    # The lambda node should contain a block with several expressions.
    check ast.functionDef.body.kind == ekBlock
    # Check that the last expression in the block is a multiplication.
    let lastExpr = ast.functionDef.body.blockExpr.expressions[^1]
    check lastExpr.kind == ekMul

  test "function call":
    ## Test that a function call (e.g., main()) is parsed as a call node.
    var lexer = newLexer("main()")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekFuncCall
    # Depending on the implementation, ast.fun can be a string or an identifier node.
    # Here we assume it is stored as an identifier.
    check ast.functionCall.function.kind == ekIdent
    check ast.functionCall.function.identifier.ident == "main"

  test "vector literal parsing":
    var lexer = newLexer("v = [1, 2, 3]")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekAssign
    check ast.assign.ident == "v"
    check ast.assign.expr.kind == ekVector
    check ast.assign.expr.vector.size == 3
    check ast.assign.expr.vector[0].kind == ekValue
    check ast.assign.expr.vector[0].value.number.integer == 1
    check ast.assign.expr.vector[1].kind == ekValue
    check ast.assign.expr.vector[1].value.number.integer == 2
    check ast.assign.expr.vector[2].kind == ekValue
    check ast.assign.expr.vector[2].value.number.integer == 3

  test "vec function call parsing":
    var lexer = newLexer("v2 = vec(3, 4)")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekAssign
    check ast.assign.ident == "v2"
    check ast.assign.expr.kind == ekFuncCall
    # Assuming the function expression is an identifier.
    check ast.assign.expr.functionCall.function.kind == ekIdent
    check ast.assign.expr.functionCall.function.identifier.ident == "vec"
    check ast.assign.expr.functionCall.params.len == 2
    check ast.assign.expr.functionCall.params[0].kind == ekValue
    check ast.assign.expr.functionCall.params[0].value.number.integer == 3
    check ast.assign.expr.functionCall.params[1].kind == ekValue
    check ast.assign.expr.functionCall.params[1].value.number.integer == 4

  test "parses well formed if expression with elif":
    let src = "if(a == b) 1 elif(a != b) 2 else 3"
    var lexer = newLexer(src)
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekIf
    check ast.ifExpr.branches.len == 2
    check ast.ifExpr.elseBranch.kind == ekValue
    check ast.ifExpr.elseBranch.value.number.integer == 3

  test "parses well formed if expression without elif":
    let src = "if(a < b) 10 else 20"
    var lexer = newLexer(src)
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekIf
    check ast.ifExpr.branches.len == 1

  test "parses comparison and boolean operators":
    # Equality operator ==
    var lexer = newLexer("a == b")
    var tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekEq

    # Inequality operator !=
    lexer = newLexer("a != b")
    tokens = tokenizeExpression(lexer)
    ast = parse(tokens)
    check ast.kind == ekNe

    # Less than operator <
    lexer = newLexer("a < b")
    tokens = tokenizeExpression(lexer)
    ast = parse(tokens)
    check ast.kind == ekLt

    # Greater than operator >
    lexer = newLexer("a > b")
    tokens = tokenizeExpression(lexer)
    ast = parse(tokens)
    check ast.kind == ekGt

    # Less than or equal operator <=
    lexer = newLexer("a <= b")
    tokens = tokenizeExpression(lexer)
    ast = parse(tokens)
    check ast.kind == ekLe

    # Greater than or equal operator >=
    lexer = newLexer("a >= b")
    tokens = tokenizeExpression(lexer)
    ast = parse(tokens)
    check ast.kind == ekGe

    # Boolean AND operator &
    lexer = newLexer("a & b")
    tokens = tokenizeExpression(lexer)
    ast = parse(tokens)
    check ast.kind == ekAnd

    # Boolean OR operator |
    lexer = newLexer("a | b")
    tokens = tokenizeExpression(lexer)
    ast = parse(tokens)
    check ast.kind == ekOr

  test "parses chain operator with nested function calls":
    ## Test that the chain operator '->' is parsed correctly.
    ## a->f->g(x) should be converted to g(f(a), x)
    var lexer = newLexer("a->f->g(x)")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    # The outermost call should be g(f(a), x)
    check ast.kind == ekFuncCall
    check ast.functionCall.function.kind == ekIdent
    check ast.functionCall.function.identifier.ident == "g"
    check ast.functionCall.params.len == 2

    # First argument should be the result of f(a)
    let firstArg = ast.functionCall.params[0]
    check firstArg.kind == ekFuncCall
    check firstArg.functionCall.function.kind == ekIdent
    check firstArg.functionCall.function.identifier.ident == "f"
    check firstArg.functionCall.params.len == 1
    check firstArg.functionCall.params[0].kind == ekIdent
    check firstArg.functionCall.params[0].identifier.ident == "a"

    # Second argument should be the identifier x
    let secondArg = ast.functionCall.params[1]
    check secondArg.kind == ekIdent
    check secondArg.identifier.ident == "x"

  test "parses function definition inside block":
    var lexer = newLexer("{ a = |x| if(x == 2) 2 else x\na(x) }")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekBlock
    check ast.blockExpr.expressions.len == 2
    
    # First expression should be a function assignment
    let assignment = ast.blockExpr.expressions[0]
    check assignment.kind == ekAssign
    check assignment.assign.ident == "a"
    check assignment.assign.expr.kind == ekFuncDef
    
    # Second expression should be a function call
    let call = ast.blockExpr.expressions[1]
    check call.kind == ekFuncCall
    check call.functionCall.function.kind == ekIdent
    check call.functionCall.function.identifier.ident == "a"

  test "parses arrow operator with addition":
    var lexer = newLexer("4->double + 4->double")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    
    # Top level should be addition
    check ast.kind == ekAdd
    
    # Both sides should be function calls from arrow operation
    check ast.binaryOp.left.kind == ekFuncCall
    check ast.binaryOp.right.kind == ekFuncCall
    
    # Check the function name is "double" on both sides
    check ast.binaryOp.left.functionCall.function.kind == ekIdent
    check ast.binaryOp.left.functionCall.function.identifier.ident == "double"
    check ast.binaryOp.right.functionCall.function.kind == ekIdent
    check ast.binaryOp.right.functionCall.function.identifier.ident == "double"
    
    # Check that the argument to both functions is 4
    check ast.binaryOp.left.functionCall.params.len == 1
    check ast.binaryOp.left.functionCall.params[0].kind == ekValue
    check ast.binaryOp.left.functionCall.params[0].value.number.integer == 4
    check ast.binaryOp.right.functionCall.params.len == 1
    check ast.binaryOp.right.functionCall.params[0].kind == ekValue
    check ast.binaryOp.right.functionCall.params[0].value.number.integer == 4

  test "parses nested arrow operations":
    var lexer = newLexer("5->double->increment->square")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    
    # Should be nested function calls
    check ast.kind == ekFuncCall
    check ast.functionCall.function.kind == ekIdent
    check ast.functionCall.function.identifier.ident == "square"
    check ast.functionCall.params.len == 1
    
    # First argument should be increment(double(5))
    let firstArg = ast.functionCall.params[0]
    check firstArg.kind == ekFuncCall
    check firstArg.functionCall.function.kind == ekIdent
    check firstArg.functionCall.function.identifier.ident == "increment"
    check firstArg.functionCall.params.len == 1
    
    let innerArg = firstArg.functionCall.params[0]
    check innerArg.kind == ekFuncCall
    check innerArg.functionCall.function.kind == ekIdent
    check innerArg.functionCall.function.identifier.ident == "double"
    check innerArg.functionCall.params.len == 1
    check innerArg.functionCall.params[0].kind == ekValue
    check innerArg.functionCall.params[0].value.number.integer == 5

  test "parses complex if-else inside function definition":
    var lexer = newLexer("|x| if(x > 10) 1 elif(x > 5) 2 else 3")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    
    # Should be a function node
    check ast.kind == ekFuncDef
    check ast.functionDef.params.len == 1
    check ast.functionDef.params[0].name == "x"
    
    # Body should be an if expression
    check ast.functionDef.body.kind == ekIf
    check ast.functionDef.body.ifExpr.branches.len == 2
    check ast.functionDef.body.ifExpr.elseBranch.kind == ekValue
    check ast.functionDef.body.ifExpr.elseBranch.value.number.integer == 3
    
    # Check conditions
    let firstCondition = ast.functionDef.body.ifExpr.branches[0].condition
    check firstCondition.kind == ekGt
    let secondCondition = ast.functionDef.body.ifExpr.branches[1].condition
    check secondCondition.kind == ekGt
    
    # Check branch values are numbers
    let firstBranchValue = ast.functionDef.body.ifExpr.branches[0].then
    check firstBranchValue.kind == ekValue
    check firstBranchValue.value.number.integer == 1
    
    let secondBranchValue = ast.functionDef.body.ifExpr.branches[1].then
    check secondBranchValue.kind == ekValue
    check secondBranchValue.value.number.integer == 2

  test "parses type checking with is operator":
    var lexer = newLexer("x is complex")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    
    # Should be an is expression
    check ast.kind == ekEq
    check ast.binaryOp.left.kind == ekFuncCall
    check ast.binaryOp.left.functionCall.function.kind == ekType
    check ast.binaryOp.left.functionCall.params.len == 1
    check ast.binaryOp.left.functionCall.params[0].kind == ekIdent
    check ast.binaryOp.left.functionCall.params[0].identifier.ident == "x"
    check ast.binaryOp.right.kind == ekType
    check ast.binaryOp.right.typ.kind == tkSimple
    check ast.binaryOp.right.typ.simpleType == SimpleType.Complex
    
  test "parses function with type checking":
    var lexer = newLexer("|x| if(x is complex) 1 else 2")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    
    # Should be a function definition
    check ast.kind == ekFuncDef
    check ast.functionDef.params.len == 1
    check ast.functionDef.params[0].name == "x"
    
    # Body should be if expression
    check ast.functionDef.body.kind == ekIf
    
    # Check the condition (x is complex)
    let condition = ast.functionDef.body.ifExpr.branches[0].condition
    check condition.kind == ekEq
    check condition.binaryOp.left.kind == ekFuncCall
    check condition.binaryOp.left.functionCall.function.kind == ekType
    check condition.binaryOp.left.functionCall.params.len == 1
    check condition.binaryOp.left.functionCall.params[0].kind == ekIdent
    check condition.binaryOp.left.functionCall.params[0].identifier.ident == "x"
    check condition.binaryOp.right.kind == ekType
    check condition.binaryOp.right.typ.kind == tkSimple
    check condition.binaryOp.right.typ.simpleType == SimpleType.Complex
    
    # Check branches
    check ast.functionDef.body.ifExpr.branches.len == 1
    check ast.functionDef.body.ifExpr.branches[0].then.kind == ekValue
    check ast.functionDef.body.ifExpr.branches[0].then.value.number.integer == 1
    check ast.functionDef.body.ifExpr.elseBranch.kind == ekValue
    check ast.functionDef.body.ifExpr.elseBranch.value.number.integer == 2
    
  test "parses function with type checking and function call":
    var lexer = newLexer("|x| if(x is complex) x->re elif(x is integer) x->real else x")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    
    # Should be a function definition
    check ast.kind == ekFuncDef
    check ast.functionDef.params.len == 1
    check ast.functionDef.params[0].name == "x"
    
    # Body should be if expression
    check ast.functionDef.body.kind == ekIf
    check ast.functionDef.body.ifExpr.branches.len == 2
    
    # Check the first condition (x is complex)
    let firstCondition = ast.functionDef.body.ifExpr.branches[0].condition
    check firstCondition.kind == ekEq
    check firstCondition.binaryOp.left.kind == ekFuncCall
    check firstCondition.binaryOp.left.functionCall.function.kind == ekType
    check firstCondition.binaryOp.left.functionCall.params.len == 1
    check firstCondition.binaryOp.left.functionCall.params[0].kind == ekIdent
    check firstCondition.binaryOp.left.functionCall.params[0].identifier.ident == "x"
    check firstCondition.binaryOp.right.kind == ekType
    check firstCondition.binaryOp.right.typ.simpleType == SimpleType.Complex
    
    # Check the first "then" branch (x->re)
    let firstThenBranch = ast.functionDef.body.ifExpr.branches[0].then
    check firstThenBranch.kind == ekFuncCall
    check firstThenBranch.functionCall.function.kind == ekIdent
    check firstThenBranch.functionCall.function.identifier.ident == "re"
    check firstThenBranch.functionCall.params.len == 1
    check firstThenBranch.functionCall.params[0].kind == ekIdent
    check firstThenBranch.functionCall.params[0].identifier.ident == "x"
    
    # Check the second condition (x is integer)
    let secondCondition = ast.functionDef.body.ifExpr.branches[1].condition
    check secondCondition.kind == ekEq
    check secondCondition.binaryOp.left.kind == ekFuncCall
    check secondCondition.binaryOp.left.functionCall.function.kind == ekType
    check secondCondition.binaryOp.left.functionCall.params.len == 1
    check secondCondition.binaryOp.left.functionCall.params[0].kind == ekIdent
    check secondCondition.binaryOp.left.functionCall.params[0].identifier.ident == "x"
    check secondCondition.binaryOp.right.kind == ekType
    check secondCondition.binaryOp.right.typ.simpleType == SimpleType.Integer
    
    # Check the second "then" branch (x->real)
    let secondThenBranch = ast.functionDef.body.ifExpr.branches[1].then
    check secondThenBranch.kind == ekFuncCall
    check secondThenBranch.functionCall.function.kind == ekType
    check secondThenBranch.functionCall.function.typ.simpleType == SimpleType.Real
    check secondThenBranch.functionCall.params.len == 1
    check secondThenBranch.functionCall.params[0].kind == ekIdent
    check secondThenBranch.functionCall.params[0].identifier.ident == "x"
    
    # Check the "else" branch (x)
    let elseBranch = ast.functionDef.body.ifExpr.elseBranch
    check elseBranch.kind == ekIdent
    check elseBranch.identifier.ident == "x"
