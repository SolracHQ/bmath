import unittest, math, complex
import ../src/pipeline/interpreter/interpreter
import ../src/pipeline/parser/parser
import ../src/pipeline/lexer
import ../src/types/value
import ../src/types/errors

proc evalString(s: string): Value =
  var interpreter = newInterpreter()
  var lexer = newLexer(s)
  while not lexer.atEnd:
    let tokens = lexer.tokenizeExpression()
    if tokens.len == 0:
      continue
    let ast = parse(tokens)
    result = interpreter.eval(ast).value

suite "Interpreter tests":
  test "Type promotion edge cases":
    check evalString("2 + 3.0").nValue.fValue == 5.0
    check evalString("5 / 2").nValue.fValue == 2.5
    check evalString("2 ^ 0.5").nValue.fValue == sqrt(2.0)

  test "Weird but valid expressions":
    check evalString("---5").nValue.iValue == -5
    check evalString("3 * -(-4)").nValue.iValue == 12
    check evalString("2^3^2").nValue.iValue == 64 # Left associative

  test "Function call evaluation":
    check evalString("pow(2, 3+1)").nValue.iValue == 16
    check evalString("floor(3.9 + ceil(2.1))").nValue.iValue == 6

  test "Division and modulo edge cases":
    ## Division by zero should raise an error.
    ## Negative modulo should return a negative result.
    expect BMathError:
      discard evalString("5 / 0")
    check evalString("5 % 0.999").nValue.fValue == 0.0050000000000000044
    check evalString("-7 % 3").nValue.iValue == -1

  test "Chained and simple assignments":
    ## Evaluate two assignments and an arithmetic operation.
    ## Example: x = y = 5; x + y ==> 10
    let res = evalString("x = y = 5\nx + y")
    check res.nValue.iValue == 10

  test "Lambda function evaluation":
    ## Define a lambda that squares the sum of two arguments.
    ## Syntax: squares_sum = |x, y| (x + y)^2; squares_sum(2, 3)
    let res = evalString("squares_sum = |x, y| (x + y)^2\nsquares_sum(2, 3)")
    check res.nValue.iValue == 25

  test "Block function evaluation":
    ## Define a function with a multi-line block body.
    ## Syntax: fn = || { a = 2; b = 3; a * b; } ; fn()
    let res = evalString("fn = || { \n  a = 2\n  b = 3\n  a * b\n}\nfn()")
    check res.nValue.iValue == 6

  test "Higher-order function evaluation":
    ## Define a function that takes another function as argument.
    ## Syntax: apply = |fn, a, b| fn(a + b); apply(|x| x*10, 3, 4)
    let res = evalString("apply = |fn, a, b| fn(a + b)\napply(|x| x * 10, 3, 4)")
    check res.nValue.iValue == 70

  test "Vector operations":
    ## Test element-wise addition between two vectors.
    ## Syntax example: [1,2,3] + [4,5,6] equals [5,7,9]
    let res = evalString("[1, 2, 3] + [4, 5, 6]")
    check res.values[0].nValue.iValue == 5
    check res.values[1].nValue.iValue == 7
    check res.values[2].nValue.iValue == 9

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
    check res.nValue.iValue == 10

  test "If expression evaluation with elif and error on missing else branch":
    ## A proper if-elif-else expression.
    let res = evalString(
      """a = 10
         if (a == 10) 1 elif (a == 5) 2 else 3"""
    )
    check res.nValue.iValue == 1
    ## If condition fails and no else branch is provided, an error is expected.
    expect BMathError:
      discard evalString("""if (2 > 3) 100""")

  test "Complex if-else with nested local scopes":
    ## Combines if-elif structure with a nested block that uses local variables.
    ## Outer 'a' is set to 20; inner block computes a temp value without modifying 'a'.
    let res = evalString(
      """a = 20
        if (a > 15) {
          local temp = a
          temp = temp - 5
          temp  # returns 15 from inner block
        } elif (a == 10) 10 else 0"""
    )
    check res.nValue.iValue == 15

  test "Comparison and boolean operations expanded":
    ## Combining comparisons with boolean logic.
    let res = evalString("""(5 == 5) & ((3 < 4) | (2 > 10))""")
    check res.bValue
    let res2 = evalString("""(5 != 5) | ((10 > 2) & (1 == 1))""")

  test "Complex literal evaluation":
    ## Evaluates a pure imaginary literal.
    let res1 = evalString("3i")
    check res1.nValue.cValue == complex(0.0, 3.0)
    ## Evaluates a mixed real and complex addition, with promotion.
    let res2 = evalString("2 + 3i")
    check res2.nValue.cValue == complex(2.0, 3.0)

  test "Complex arithmetic operations":
    ## Addition and subtraction among pure imaginary numbers.
    let resAdd = evalString("3i + 4i")
    check resAdd.nValue.cValue == complex(0.0, 7.0)
    let resSub = evalString("3i - 5i")
    check resSub.nValue.cValue == complex(0.0, -2.0)
    ## Multiplication resulting in a purely real number.
    let resMul = evalString("3i * 3i")
    check resMul.nValue.fValue == -9.0
    ## Mixed arithmetic with real numbers.
    let resMixed = evalString("1 + 2i + 3 + 4i")
    check resMixed.nValue.cValue == complex(4.0, 6.0)

  test "Complex division and exponentiation":
    ## Division between a real and a complex number
    ## 4 divided by (2i) equals -2i.
    let resDiv = evalString("4 / 2i")
    check resDiv.nValue.cValue == complex(0.0, -2.0)
    ## Exponentiation: (3i)^2 equals -9.
    let resPow = evalString("3i ^ 2")
    check resPow.nValue.fValue == -9.0

  test "Block expression in arithmetic operations":
    ## Test that blocks can be used as expressions.
    ## Evaluates { sin(3.14) } + cos(3.14) as an expression.
    let resultVal = evalString("{ sin(3.14) } + cos(3.14)").nValue.fValue
    let expected = sin(3.14) + cos(3.14)
    check abs(resultVal - expected) < 1e-6

  test "Exception handling for type mismatches":
    ## Using arithmetic with non-numeric values
    expect BMathError:
      discard evalString("5 + true")

    expect BMathError:
      discard evalString("[1, 2] - 3")

    ## Using logical operators with non-boolean values
    expect BMathError:
      discard evalString("5 & 10")

    ## Comparison with complex numbers
    expect BMathError:
      discard evalString("3i > 2")

  test "Exception handling for invalid operations":
    ## Modulo with complex numbers
    expect BMathError:
      discard evalString("5i % 2")

  test "Exception handling for function calls":
    ## Calling a function with wrong number of arguments
    expect BMathError:
      discard evalString("pow(2)")

    ## Calling a non-existent function
    expect BMathError:
      discard evalString("nonExistentFunction(5)")

    ## Calling a non-function value
    expect BMathError:
      discard evalString("x = 5\nx(10)")

  test "Exception handling for vector operations":
    ## Vector operations with mismatched sizes
    expect BMathError:
      discard evalString("[1, 2] + [3, 4, 5]")

    ## Access out of bounds
    expect BMathError:
      discard evalString("nth([1, 2, 3], 5)")

    ## Empty vector access
    expect BMathError:
      discard evalString("first([])")

  test "Exception handling for scope and variable issues":
    ## Local variable shadowing test
    let scopeResult = evalString(
      """
      x = 10
      {
        local x = 20
        x = x + 5
      } 
      x
    """
    )
    check scopeResult.nValue.iValue == 10

    ## Using an undefined variable
    expect BMathError:
      echo evalString("y = z + 5")
