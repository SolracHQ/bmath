import unittest, ../src/[interpreter, lexer, parser, types], math

proc evalString(s: string): Value =
  var interp = newInterpreter()
  var lexer = newLexer(s)
  while not lexer.atEnd:
    let tokens = lexer.tokenizeExpression()
    let ast = parse(tokens)
    result = interp.eval(ast).value

suite "Interpreter tests":
  test "Type promotion edge cases":
    check evalString("2 + 3.0").fValue == 5.0
    check evalString("5 / 2").fValue == 2.5
    check evalString("2 ^ 0.5").fValue == sqrt(2.0)

  test "Weird but valid expressions":
    check evalString("---5").iValue == -5
    check evalString("3 * -(-4)").iValue == 12
    check evalString("2^3^2").iValue == 64 # Left associative

  test "Function call evaluation":
    check evalString("pow(2, 3+1)").iValue == 16
    check evalString("floor(3.9 + ceil(2.1))").iValue == 6

  test "Division and modulo edge cases":
    ## Division by zero should raise an error.
    ## Modulo rounds so 0.999 converts to 1.
    ## Negative modulo should return a negative result.
    expect BMathError:
      discard evalString("5 / 0")
    check evalString("5 % 0.999").iValue == 0
    check evalString("-7 % 3").iValue == -1

  test "Chained and simple assignments":
    ## Evaluate two assignments and an arithmetic operation.
    ## Example: x = y = 5; x + y ==> 10
    let res = evalString("x = y = 5\nx + y")
    check res.iValue == 10

  test "Lambda function evaluation":
    ## Define a lambda that squares the sum of two arguments.
    ## Syntax: squares_sum = |x, y| (x + y)^2; squares_sum(2, 3)
    let res = evalString("squares_sum = |x, y| (x + y)^2\nsquares_sum(2, 3)")
    check res.iValue == 25

  test "Block function evaluation":
    ## Define a function with a multi-line block body.
    ## Syntax: fn = || { a = 2; b = 3; a * b; } ; fn()
    let res = evalString("fn = || { \n  a = 2\n  b = 3\n  a * b\n}\nfn()")
    check res.iValue == 6

  test "Higher-order function evaluation":
    ## Define a function that takes another function as argument.
    ## Syntax: apply = |fn, a, b| fn(a + b); apply(|x| x*10, 3, 4)
    let res = evalString("apply = |fn, a, b| fn(a + b)\napply(|x| x * 10, 3, 4)")
    check res.iValue == 70

  test "Vector operations":
    ## Test element-wise addition between two vectors.
    ## Syntax example: [1,2,3] + [4,5,6] equals [5,7,9]
    let res = evalString("[1, 2, 3] + [4, 5, 6]")
    check res.values[0].iValue == 5
    check res.values[1].iValue == 7
    check res.values[2].iValue == 9

  test "Error on undefined variable":
    ## Calling an undefined variable should raise an error.
    expect BMathError:
      discard evalString("undefinedVar + 10")
