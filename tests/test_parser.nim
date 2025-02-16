## test_parser.nim
## test_parser.nim
import unittest, ../src/[lexer, parser, types], math

suite "Parser tests":

  test "parses addition of identifiers":
    var lexer = newLexer("a + b")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == nkAdd
    check ast.left.kind == nkIdent
    check ast.left.name == "a"
    check ast.right.kind == nkIdent
    check ast.right.name == "b"

  test "constant folding addition":
    var lexer = newLexer("2 + 3")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == nkNumber
    check ast.value.ivalue == 5

  test "unary negation constant folding":
    var lexer = newLexer("-4")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == nkNumber
    check ast.value.ivalue == -4

  test "group constant folding":
    var lexer = newLexer("(5.8)")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == nkNumber
    check ast.value.fvalue == 5.8

  test "power constant folding":
    var lexer = newLexer("2 ^ 3")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == nkNumber
    check ast.value.ivalue == 8

  test "multiplication without full constant folding":
    var lexer = newLexer("a * 3e0")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == nkMul
    check ast.left.kind == nkIdent
    check ast.left.name == "a"
    check ast.right.kind == nkNumber
    check ast.right.value.fvalue == 3.0

  test "lambda function definition with block":
    ## Test that a lambda function with a block is parsed correctly.
    let src = "|| { a = 5\n b = 10\n (a + b) * 2 }"
    var lexer = newLexer(src)
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == nkFunc
    # Assuming the lambda node contains a block with several expressions.
    check ast.body.kind == nkBlock
    # Check that the last expression in the block is a multiplication.
    let lastExpr = ast.body.expressions[^1]
    check lastExpr.kind == nkMul

  test "function call":
    ## Test that a function call (e.g., main()) is parsed as a call node.
    var lexer = newLexer("main()")
    let tokens = tokenizeExpression(lexer)
    var ast = parse(tokens)
    check ast.kind == nkFuncCall
    check ast.fun == "main"


