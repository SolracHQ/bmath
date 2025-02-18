## test_parser.nim
## test_parser.nim
import unittest, ../src/[lexer, parser, types], math

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

  test "constant folding addition":
    var lexer = newLexer("2 + 3")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekValue
    check ast.value.ivalue == 5

  test "unary negation constant folding":
    var lexer = newLexer("-4")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekValue
    check ast.value.ivalue == -4

  test "group constant folding":
    var lexer = newLexer("(5.8)")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekValue
    check ast.value.fvalue == 5.8

  test "power constant folding":
    var lexer = newLexer("2 ^ 3")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekValue
    check ast.value.ivalue == 8

  test "multiplication without full constant folding":
    var lexer = newLexer("a * 3e0")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekMul
    check ast.left.kind == ekIdent
    check ast.left.name == "a"
    check ast.right.kind == ekValue
    check ast.right.value.fvalue == 3.0

  test "lambda function definition with block":
    ## Test that a lambda function with a block is parsed correctly.
    let src = "|| { a = 5\n b = 10\n (a + b) * 2 }"
    var lexer = newLexer(src)
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekFunc
    # Assuming the lambda node contains a block with several expressions.
    check ast.body.kind == ekBlock
    # Check that the last expression in the block is a multiplication.
    let lastExpr = ast.body.expressions[^1]
    check lastExpr.kind == ekMul

  test "function call":
    ## Test that a function call (e.g., main()) is parsed as a call node.
    var lexer = newLexer("main()")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekFuncCall
    check ast.fun == "main"
   
  test "vector literal parsing":
    var lexer = newLexer("v = [1, 2, 3]")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekAssign
    check ast.ident == "v"
    check ast.expr.kind == ekVector
    check ast.expr.values.len == 3
    check ast.expr.values[0].kind == ekValue
    check ast.expr.values[1].kind == ekValue
    check ast.expr.values[2].kind == ekValue

  test "vec function call parsing":
    var lexer = newLexer("v2 = vec(3, 4)")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekAssign
    check ast.ident == "v2"
    check ast.expr.kind == ekFuncCall
    check ast.expr.fun == "vec"
    check ast.expr.args.len == 2
    check ast.expr.args[0].kind == ekValue
    check ast.expr.args[1].kind == ekValue

  test "parses well formed if expression with elif" :
    let src = "if(a == b) 1 elif(a != b) 2 else 3 endif"
    var lexer = newLexer(src)
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekIf
    check ast.branches.len == 2
    check ast.elseBranch.kind == ekValue

  test "parses well formed if expression without elif" :
    let src = "if(a < b) 10 else 20 endif"
    var lexer = newLexer(src)
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == ekIf
    check ast.branches.len == 1

  test "malformed if expression missing endif throws exception" :
    let src = "if(a > b) 100 else 200"
    var lexer = newLexer(src)
    let tokens = tokenizeExpression(lexer)
    expect(BMathError):
      discard parse(tokens)

  test "parses comparison and boolean operators" :
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
