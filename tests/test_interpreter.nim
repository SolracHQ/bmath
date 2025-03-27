import unittest, math, complex
import ../src/pipeline/interpreter/[interpreter, errors]
import ../src/pipeline/parser/[parser]
import ../src/pipeline/lexer/[lexer, errors]
import ../src/types/[value, vector]

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

  test "Function defined and called within a block":
    ## This tests defining and calling a function inside a block
    let res = evalString("""
      {
        a = |x| if(x == 2) 2 else x
        a(3)
      }
    """)
    check res.number.iValue == 3
    
    let res2 = evalString("""
      {
        a = |x| if(x == 2) 2 else x
        a(2)
      }
    """)
    check res2.number.iValue == 2

  test "Arrow operator chaining with addition":
    ## Tests arrow operator usage with literals and combining multiple arrow operations
    let res = evalString("""
      double = |x| x + x
      4->double + 4->double
    """)
    check res.number.iValue == 16  # (4+4) + (4+4)
    
    let res2 = evalString("""
      double = |x| x * 2
      increment = |x| x + 1
      5->double->increment  # Should be (5*2)+1 = 11
    """)
    check res2.number.iValue == 11

  test "Nested functions with closures":
    ## Tests defining functions that return other functions, with closure capturing
    let res = evalString("""
      makeAdder = |x| |y| x + y
      add5 = makeAdder(5)
      add5(10)
    """)
    check res.number.iValue == 15
    
    let res2 = evalString("""
      counter = || {
        count = 0
        || {
          count = count + 1
          count
        }
      }
      c = counter()
      local first = c()
      second = c()
      second
    """)
    check res2.number.iValue == 2

  test "Complex arrow chaining with multiple transformations":
    ## Tests elaborate arrow chaining with multiple functions
    let res = evalString("""
      double = |x| x * 2
      increment = |x| x + 1
      square = |x| x * x
      5->double->increment->square  # (5*2+1)² = 11² = 121
    """)
    check res.number.iValue == 121

  test "Arrow operator with vector operations":
    ## Tests arrow operator with vector transformations
    let res = evalString("""
      [1, 2, 3, 4]->map(|x| x * 2)->filter(|x| x > 4)
    """)
    check res.vector.size == 2
    check res.vector[0].number.iValue == 6
    check res.vector[1].number.iValue == 8

  test "Nested conditionals with arrows and vectors":
    ## Tests combining conditionals, arrows and vector operations
    let res = evalString("""
      classifier = |x| if(x > 10) 1 elif(x > 5) 2 else 3
      result = 15->classifier
      result
    """)
    check res.number.iValue == 1
    
    let res2 = evalString("""
      process = |x| if(x > 5) x * 2 else x
      [3, 6, 9]->map(process)  # [3, 12, 18]
    """)
    check res2.vector.size == 3
    check res2.vector[0].number.iValue == 3
    check res2.vector[1].number.iValue == 12
    check res2.vector[2].number.iValue == 18

  test "Arrow operator with block expressions":
    ## Tests using block expressions with arrow operators
    let res = evalString("""
      double = |x| x * 2
      {5 + 5}->double  # (5+5)*2 = 20
    """)
    check res.number.iValue == 20

  test "Complex multi-line expressions with nested transformations":
    ## Tests complex multi-line expressions with nested transformations
    let res = evalString("""
      result = {
        transformer = |x| {
          doubled = x * 2
          squared = doubled * doubled
          if(squared > 100) squared else doubled
        }
        [3, 7, 11]->map(transformer)
      }
      result->nth(2)  # For 11: doubled=22, squared=484, returns 484
    """)
    check res.number.iValue == 484

  test "Sequence creation and access":
    ## Tests creating sequences and accessing elements
    let res = evalString("""
      finiteSeq = seq(5, |i| i * 2)
      finiteSeq->nth(3)  # Should be 6
    """)
    check res.number.iValue == 6
    
    let vecRes = evalString("""
      vectorSeq = seq([1, 2, 3, 4, 5])
      vectorSeq->nth(2)  # Should be 3
    """)
    check vecRes.number.iValue == 3

  test "Sequence transformations":
    ## Tests sequence mapping and filtering
    let mapRes = evalString("""
      numbers = seq(5, |i| i + 1)  # [1, 2, 3, 4, 5]
      doubled = numbers->map(|x| x * 2)->collect
      doubled->nth(3)  # Should be 8
    """)
    check mapRes.number.iValue == 8
    
    let filterRes = evalString("""
      numbers = seq(8, |i| i)  # [0, 1, 2, 3, 4, 5, 6, 7]
      evens = numbers->filter(|x| x % 2 == 0)->collect
      evens->len
    """)
    check filterRes.number.iValue == 4

  test "Sequence reductions":
    ## Tests sequence reduction operations
    let sumRes = evalString("""
      seq(5, |i| i + 1)->sum  # 1+2+3+4+5 = 15
    """)
    check sumRes.number.iValue == 15
    
    let productRes = evalString("""
      seq(5, |i| i + 1)->reduce(1, |acc, x| acc * x)  # 5! = 120
    """)
    check productRes.number.iValue == 120

  test "Complex sequence operations":
    ## Tests chaining multiple sequence operations
    let complexRes = evalString("""
      processedSeq = seq(|i| i) ->\  # Infinite sequence of natural numbers
                    map(|x| x * x) ->\  # Square the numbers
                    filter(|x| x % 2 == 0) ->\  # Keep only even squares
                    map(|x| x / 2) ->\  # Divide by 2
                    take(5) ->\  # Take first 5 elements
                    collect    # Convert to vector
      processedSeq->nth(4)  # Should be 32
    """)
    check complexRes.number.fvalue == 32
    
    let zipRes = evalString("""
      zipped = seq(3, |i| i)->zip(seq(3, |i| i * 10))->collect
      zipped->nth(1)->nth(1)  # Should be 10
    """)
    check zipRes.number.iValue == 10

  test "Custom sequence operations":
    ## Tests custom sequence transformation functions
    let runningAvgRes = evalString("""
      runningAvg = |numbers| {
        _sum = 0
        seq(len(numbers), |i| {
          _sum = _sum + nth(numbers, i)
          _sum / (i + 1)
        })->collect
      }
      avgResult = runningAvg([2, 4, 6, 8, 10])
      avgResult->nth(4)  # Should be 6.0
    """)
    check runningAvgRes.number.fValue == 6.0

  test "Sequence error handling":
    ## Tests error cases for sequences
    expect InvalidArgumentError:
      discard evalString("seq(5, |i| i)->nth(10)")  # Out of bounds access
