import unittest, math, strutils
import ../src/pipeline/lexer
import ../src/pipeline/parser/parser
import ../src/pipeline/parser/optimizer
import ../src/types/expression

suite "Optimizer Tests":
  test "Constant Folding Addition":
    var l = newLexer("2 + 3")
    let tokens = tokenizeExpression(l)
    var ast = parse(tokens)
    var opt = newOptimizer()
    let optimized = optimize(opt, ast)
    check optimized.kind == ekInt
    check optimized.iValue == 5

  test "Constant Folding Multiplication":
    var l = newLexer("4 * 5")
    let tokens = tokenizeExpression(l)
    var ast = parse(tokens)
    var opt = newOptimizer()
    let optimized = optimize(opt, ast)
    check optimized.kind == ekInt
    check optimized.iValue == 20

  test "Unary Negation Folding":
    var l = newLexer("-4")
    let tokens = tokenizeExpression(l)
    var ast = parse(tokens)
    var opt = newOptimizer()
    let optimized = optimize(opt, ast)
    check optimized.kind == ekInt
    check optimized.iValue == -4

  test "Constant Propagation in Assignments":
    # The code "a = 5\n a + 3" should be optimized to 8
    var l = newLexer("{a = 5\n a + 3}")
    let tokens = tokenizeExpression(l)
    var blockAst = parse(tokens)
    var opt = newOptimizer()
    let optimizedBlock = optimize(opt, blockAst)
    # In a block optimized completely, the final expression is the result.
    check optimizedBlock.kind == ekInt
    check optimizedBlock.iValue == 8

  test "Optimizing If Expression with Constant Condition":
    var l = newLexer("if (5 > 3) 100 else 50 endif")
    let tokens = tokenizeExpression(l)
    var ast = parse(tokens)
    var opt = newOptimizer()
    let optimized = optimize(opt, ast)
    check optimized.kind == ekInt
    check optimized.iValue == 100

  test "Division by Zero Generates Error Expression":
    var l = newLexer("10 / 0")
    let tokens = tokenizeExpression(l)
    var ast = parse(tokens)
    var opt = newOptimizer()
    let optimized = optimize(opt, ast)
    check optimized.kind == ekError
    check optimized.message.contains("Division by zero")

  test "Boolean Operation Folding":
    var l = newLexer("true & false")
    let tokens = tokenizeExpression(l)
    var ast = parse(tokens)
    var opt = newOptimizer()
    let optimized = optimize(opt, ast)
    check optimized.kind == ekFalse

  test "Vector Literal Optimization":
    var l = newLexer("[1 * 2, 2 * 3, 3 * 4]")
    let tokens = tokenizeExpression(l)
    var ast = parse(tokens)
    var opt = newOptimizer()
    let optimized = optimize(opt, ast)
    check optimized.kind == ekVector
    check optimized.values.len == 3
    check optimized.values[0].kind == ekInt
    check optimized.values[0].iValue == 2
    check optimized.values[1].iValue == 6
    check optimized.values[2].iValue == 12
