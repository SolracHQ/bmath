import unittest, math
import ../src/pipeline/lexer/lexer
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
    check optimized.kind == ekNumber
    check optimized.nValue.iValue == 5

  test "Constant Folding Multiplication":
    var l = newLexer("4 * 5")
    let tokens = tokenizeExpression(l)
    var ast = parse(tokens)
    var opt = newOptimizer()
    let optimized = optimize(opt, ast)
    check optimized.kind == ekNumber
    check optimized.nValue.iValue == 20

  test "Unary Negation Folding":
    var l = newLexer("-4")
    let tokens = tokenizeExpression(l)
    var ast = parse(tokens)
    var opt = newOptimizer()
    let optimized = optimize(opt, ast)
    check optimized.kind == ekNumber
    check optimized.nValue.iValue == -4

  test "Constant Propagation in Assignments":
    # The code "a = 5\n a + 3" should be optimized to 8
    var l = newLexer("{a = 5\n a + 3}")
    let tokens = tokenizeExpression(l)
    var blockAst = parse(tokens)
    var opt = newOptimizer()
    let optimizedBlock = optimize(opt, blockAst)
    # In a block optimized completely, the final expression is the result.
    check optimizedBlock.kind == ekNumber
    check optimizedBlock.nValue.iValue == 8

  test "Optimizing If Expression with Constant Condition":
    var l = newLexer("if (5 > 3) 100 else 50")
    let tokens = tokenizeExpression(l)
    var ast = parse(tokens)
    var opt = newOptimizer()
    let optimized = optimize(opt, ast)
    check optimized.kind == ekNumber
    check optimized.nValue.iValue == 100

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
    check optimized.values[0].kind == ekNumber
    check optimized.values[0].nValue.iValue == 2
    check optimized.values[1].nValue.iValue == 6
    check optimized.values[2].nValue.iValue == 12
