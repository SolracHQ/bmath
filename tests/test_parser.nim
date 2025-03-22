## test_parser.nim
import unittest, math
import ../src/pipeline/parser/parser
import ../src/pipeline/lexer/lexer
import ../src/types/[expression]

suite "Parser tests":
  test "parses addition of identifiers":
    var lexer = newLexer("a + b")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekAdd
    check ast.left.kind == ekIdent
    check ast.left.name == "a"
    check ast.right.kind == ekIdent
    check ast.right.name == "b"

  test "addition of literals without constant folding":
    var lexer = newLexer("2 + 3")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    # now we expect an addition node and not a folded literal
    check ast.kind == ekAdd
    check ast.left.kind == ekNumber
    check ast.left.nValue.iValue == 2
    check ast.right.kind == ekNumber
    check ast.right.nValue.iValue == 3

  test "unary negation with constant folding":
    var lexer = newLexer("-4")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekNumber
    check ast.nValue.iValue == -4

  test "unary negation without constant folding":
    var lexer = newLexer("-a")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekNeg
    check ast.operand.kind == ekIdent
    check ast.operand.name == "a"

  test "group expression returns inner literal":
    var lexer = newLexer("(5.8)")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    # groups now simply return the inner expression
    check ast.kind == ekNumber
    check ast.nValue.fValue == 5.8

  test "power operation without constant folding":
    var lexer = newLexer("2 ^ 3")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    # expect a power node instead of a folded literal
    check ast.kind == ekPow
    check ast.left.kind == ekNumber
    check ast.left.nValue.iValue == 2
    check ast.right.kind == ekNumber
    check ast.right.nValue.iValue == 3

  test "multiplication without full constant folding":
    var lexer = newLexer("a * 3e0")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekMul
    check ast.left.kind == ekIdent
    check ast.left.name == "a"
    check ast.right.kind == ekNumber
    check ast.right.nValue.fValue == 3.0

  test "lambda function definition with block":
    ## Test that a lambda function with a block is parsed correctly.
    let src = "|| { a = 5\n b = 10\n (a + b) * 2 }"
    var lexer = newLexer(src)
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekFunc
    # The lambda node should contain a block with several expressions.
    check ast.body.kind == ekBlock
    # Check that the last expression in the block is a multiplication.
    let lastExpr = ast.body.expressions[^1]
    check lastExpr.kind == ekMul

  test "function call":
    ## Test that a function call (e.g., main()) is parsed as a call node.
    var lexer = newLexer("main()")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekFuncInvoke
    # Depending on the implementation, ast.fun can be a string or an identifier node.
    # Here we assume it is stored as an identifier.
    check ast.fun.kind == ekIdent
    check ast.fun.name == "main"

  test "vector literal parsing":
    var lexer = newLexer("v = [1, 2, 3]")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekAssign
    check ast.ident == "v"
    check ast.expr.kind == ekVector
    check ast.expr.values.len == 3
    check ast.expr.values[0].kind == ekNumber
    check ast.expr.values[0].nValue.iValue == 1
    check ast.expr.values[1].kind == ekNumber
    check ast.expr.values[1].nValue.iValue == 2
    check ast.expr.values[2].kind == ekNumber
    check ast.expr.values[2].nValue.iValue == 3

  test "vec function call parsing":
    var lexer = newLexer("v2 = vec(3, 4)")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekAssign
    check ast.ident == "v2"
    check ast.expr.kind == ekFuncInvoke
    # Assuming the function expression is an identifier.
    check ast.expr.fun.kind == ekIdent
    check ast.expr.fun.name == "vec"
    check ast.expr.arguments.len == 2
    check ast.expr.arguments[0].kind == ekNumber
    check ast.expr.arguments[0].nValue.iValue == 3
    check ast.expr.arguments[1].kind == ekNumber
    check ast.expr.arguments[1].nValue.iValue == 4

  test "parses well formed if expression with elif":
    let src = "if(a == b) 1 elif(a != b) 2 else 3"
    var lexer = newLexer(src)
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekIf
    check ast.branches.len == 2
    check ast.elseBranch.kind == ekNumber
    check ast.elseBranch.nValue.iValue == 3

  test "parses well formed if expression without elif":
    let src = "if(a < b) 10 else 20"
    var lexer = newLexer(src)
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekIf
    check ast.branches.len == 1

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

  test "parses chain operator with nested function calls":
    ## Test that the chain operator '->' is parsed correctly.
    ## a->f->g(x) should be converted to g(f(a), x)
    var lexer = newLexer("a->f->g(x)")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    # The outermost call should be g(f(a), x)
    check ast.kind == ekFuncInvoke
    check ast.fun.kind == ekIdent
    check ast.fun.name == "g"
    check ast.arguments.len == 2

    # First argument should be the result of f(a)
    let firstArg = ast.arguments[0]
    check firstArg.kind == ekFuncInvoke
    check firstArg.fun.kind == ekIdent
    check firstArg.fun.name == "f"
    check firstArg.arguments.len == 1
    check firstArg.arguments[0].kind == ekIdent
    check firstArg.arguments[0].name == "a"

    # Second argument should be the identifier x
    let secondArg = ast.arguments[1]
    check secondArg.kind == ekIdent
    check secondArg.name == "x"
