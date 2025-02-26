import unittest, math
import ../src/pipeline/interpreter/interpreter
import ../src/pipeline/parser/parser
import ../src/pipeline/lexer
import ../src/types/value
import ../src/types/errors

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

  test "Local keyword isolation in nested scopes":
    ## Outer assignment and inner block with a local copy.
    ## The inner 'local a' should not affect the outer 'a'.
    let res = evalString(
      """a = 10
                                  {
                                    local a = a
                                    a = a + 5
                                    a  # inner block returns 15, but outer 'a' remains 10
                                  }
                                  a"""
    )
    check res.iValue == 10

  test "If expression evaluation with elif and error on missing else branch":
    ## A proper if-elif-else expression.
    let res = evalString(
      """a = 10
                                  if (a == 10) 1 elif (a == 5) 2 else 3 endif"""
    )
    check res.iValue == 1
    ## If condition fails and no else branch is provided, an error is expected.
    expect BMathError:
      discard evalString("""if (2 > 3) 100 endif""")

  test "Complex if-else with nested local scopes":
    ## Combines if-elif structure with a nested block that uses local variables.
    ## Outer 'a' is set to 20; inner block computes a temp value without modifying 'a'.
    let res = evalString(
      """a = 20
                                  if (a > 15) {
                                    local temp = a
                                    temp = temp - 5
                                    temp  # returns 15 from inner block
                                  } elif (a == 10) 10 else 0 endif"""
    )
    check res.iValue == 15

  test "Comparison and boolean operations expanded":
    ## Combining comparisons with boolean logic.
    let res = evalString("""(5 == 5) & ((3 < 4) | (2 > 10))""")
    check res.bValue
    let res2 = evalString("""(5 != 5) | ((10 > 2) & (1 == 1))""")
    check res2.bValue
