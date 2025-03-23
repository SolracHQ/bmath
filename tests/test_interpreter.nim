import unittest, math, complex
import ../src/pipeline/interpreter/[interpreter, errors]
import ../src/pipeline/parser/[parser]
import ../src/pipeline/lexer/[lexer, errors]
import ../src/types/value

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
    check evalString("2 + 3.0").number.fValue == 5.0
    check evalString("5 / 2").number.fValue == 2.5
    check evalString("2 ^ 0.5").number.fValue == sqrt(2.0)

  test "Weird but valid expressions":
    check evalString("---5").number.iValue == -5
    check evalString("3 * -(-4)").number.iValue == 12
    check evalString("2^3^2").number.iValue == 64 # Left associative

  test "Function call evaluation":
    check evalString("pow(2, 3+1)").number.iValue == 16
    check evalString("floor(3.9 + ceil(2.1))").number.iValue == 6

  test "Division and modulo edge cases":
    ## Division by zero should raise an error.
    ## Negative modulo should return a negative result.
    expect DivideByZeroError:
      discard evalString("5 / 0")
    check evalString("5 % 0.999").number.fValue == 0.0050000000000000044
    check evalString("-7 % 3").number.iValue == -1

  test "Chained and simple assignments":
    ## Evaluate two assignments and an arithmetic operation.
    ## Example: x = y = 5; x + y ==> 10
    let res = evalString("x = y = 5\nx + y")
    check res.number.iValue == 10

  test "Lambda function evaluation":
    ## Define a lambda that squares the sum of two arguments.
    ## Syntax: squares_sum = |x, y| (x + y)^2; squares_sum(2, 3)
    let res = evalString("squares_sum = |x, y| (x + y)^2\nsquares_sum(2, 3)")
    check res.number.iValue == 25

  test "Block function evaluation":
    ## Define a function with a multi-line block body.
    ## Syntax: fn = || { a = 2; b = 3; a * b; } ; fn()
    let res = evalString("fn = || { \n  a = 2\n  b = 3\n  a * b\n}\nfn()")
    check res.number.iValue == 6

  test "Higher-order function evaluation":
    ## Define a function that takes another function as argument.
    ## Syntax: apply = |fn, a, b| fn(a + b); apply(|x| x*10, 3, 4)
    let res = evalString("apply = |fn, a, b| fn(a + b)\napply(|x| x * 10, 3, 4)")
    check res.number.iValue == 70

  test "Vector operations":
    ## Test element-wise addition between two vectors.
    ## Syntax example: [1,2,3] + [4,5,6] equals [5,7,9]
    let res = evalString("[1, 2, 3] + [4, 5, 6]")
    check res.vector[0].number.iValue == 5
    check res.vector[1].number.iValue == 7
    check res.vector[2].number.iValue == 9

  test "Error on undefined variable":
    ## Calling an undefined variable should raise an error.
    expect UndefinedVariableError:
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
    check res.number.iValue == 10

  test "If expression evaluation with elif and error on missing else branch":
    ## A proper if-elif-else expression.
    let res = evalString(
      """a = 10
         if (a == 10) 1 elif (a == 5) 2 else 3"""
    )
    check res.number.iValue == 1
    ## If condition fails and no else branch is provided, an error is expected.
    expect IncompleteInputError:
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
    check res.number.iValue == 15

  test "Comparison and boolean operations expanded":
    ## Combining comparisons with boolean logic.
    let res = evalString("""(5 == 5) & ((3 < 4) | (2 > 10))""")
    check res.boolean
    let res2 = evalString("""(5 != 5) | ((10 > 2) & (1 == 1))""")

  test "Complex literal evaluation":
    ## Evaluates a pure imaginary literal.
    let res1 = evalString("3i")
    check res1.number.cValue == complex(0.0, 3.0)
    ## Evaluates a mixed real and complex addition, with promotion.
    let res2 = evalString("2 + 3i")
    check res2.number.cValue == complex(2.0, 3.0)

  test "Complex arithmetic operations":
    ## Addition and subtraction among pure imaginary numbers.
    let resAdd = evalString("3i + 4i")
    check resAdd.number.cValue == complex(0.0, 7.0)
    let resSub = evalString("3i - 5i")
    check resSub.number.cValue == complex(0.0, -2.0)
    ## Multiplication resulting in a purely real number.
    let resMul = evalString("3i * 3i")
    check resMul.number.fValue == -9.0
    ## Mixed arithmetic with real numbers.
    let resMixed = evalString("1 + 2i + 3 + 4i")
    check resMixed.number.cValue == complex(4.0, 6.0)

  test "Complex division and exponentiation":
    ## Division between a real and a complex number
    ## 4 divided by (2i) equals -2i.
    let resDiv = evalString("4 / 2i")
    check resDiv.number.cValue == complex(0.0, -2.0)
    ## Exponentiation: (3i)^2 equals -9.
    let resPow = evalString("3i ^ 2")
    check resPow.number.fValue == -9.0

  test "Block expression in arithmetic operations":
    ## Test that blocks can be used as expressions.
    ## Evaluates { sin(3.14) } + cos(3.14) as an expression.
    let resultVal = evalString("{ sin(3.14) } + cos(3.14)").number.fValue
    let expected = sin(3.14) + cos(3.14)
    check abs(resultVal - expected) < 1e-6

  test "Exception handling for type mismatches":
    ## Using arithmetic with non-numeric vector
    expect TypeError:
      discard evalString("5 + true")

    expect TypeError:
      discard evalString("[1, 2] - 3")

    ## Using logical operators with non-boolean vector
    expect TypeError:
      discard evalString("5 & 10")

    ## Comparison with complex numbers
    expect TypeError:
      discard evalString("3i > 2")

  test "Exception handling for invalid operations":
    ## Modulo with complex numbers
    expect TypeError:
      discard evalString("5i % 2")

  test "Exception handling for function calls":
    ## Calling a function with wrong number of arguments
    expect InvalidArgumentError:
      discard evalString("pow(2)")

    ## Calling a non-existent function
    expect UndefinedVariableError:
      discard evalString("nonExistentFunction(5)")

    ## Calling a non-function value
    expect TypeError:
      discard evalString("x = 5\nx(10)")

  test "Exception handling for vector operations":
    ## Vector operations with mismatched sizes
    expect InvalidArgumentError:
      discard evalString("[1, 2] + [3, 4, 5]")

    ## Access out of bounds
    expect InvalidArgumentError:
      discard evalString("nth([1, 2, 3], 5)")

    ## Empty vector access
    expect InvalidArgumentError:
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
    check scopeResult.number.iValue == 10

    ## Using an undefined variable
    expect UndefinedVariableError:
      discard evalString("y = z + 5")

  test "Trigonometric function edge cases":
    ## Test special vector
    let sinZero = evalString("sin(0)").number.fValue
    check abs(sinZero) < 1e-10

    let cosZero = evalString("cos(0)").number.fValue
    check abs(cosZero - 1.0) < 1e-10

    let sinPiHalf = evalString("sin(pi/2)").number.fValue
    check abs(sinPiHalf - 1.0) < 1e-10

    let cosPiHalf = evalString("cos(pi/2)").number.fValue
    check abs(cosPiHalf) < 1e-10

    let logOneBase2 = evalString("log(1, 2)").number.fValue
    check abs(logOneBase2) < 1e-10

    ## Test exp(0) = 1
    let expZero = evalString("exp(0)").number.fValue
    check abs(expZero - 1.0) < 1e-10
