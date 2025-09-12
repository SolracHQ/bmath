## test_parser.nim - Parser tests using S-expressions for better readability
import unittest, strutils
import ../src/pipeline/parser
import ../src/pipeline/lexer
import ../src/pipeline/optimization
import ../src/types/expression

proc parseAndSexp(code: string, level: OptimizationLevel = olFull): string =
  ## Helper to parse code and return S-expression with specified optimization level
  var lexer = newLexer(code)
  let tokens = tokenizeExpression(lexer)
  let ast = parse(tokens, level)
  return ast.asSexp()

suite "Parser tests with S-expressions":
  test "basic arithmetic operations":
    check parseAndSexp("a + b") == "(+ a b)"
    check parseAndSexp("x - y") == "(- x y)"
    check parseAndSexp("m * n") == "(* m n)"
    check parseAndSexp("p / q") == "(/ p q)"
    check parseAndSexp("r ^ s") == "(^ r s)"
    check parseAndSexp("a % b") == "(% a b)"

  test "operator precedence":
    check parseAndSexp("a + b * c") == "(+ a (* b c))"
    check parseAndSexp("(a + b) * c") == "(* (+ a b) c)"
    check parseAndSexp("a ^ b ^ c") == "(^ a (^ b c))"  # Right associative
    check parseAndSexp("a + b - c") == "(- (+ a b) c)"  # Left associative
    check parseAndSexp("a * b / c") == "(/ (* a b) c)"  # Left associative

  test "unary operations with different optimization levels":
    # With full optimization - constants are folded
    check parseAndSexp("-4", olFull) == "-4"
    check parseAndSexp("!true", olFull) == "false"
    
    # Without optimization - keeps AST structure
    check parseAndSexp("-4", olNone) == "(neg 4)"
    check parseAndSexp("!true", olNone) == "(not true)"
    
    # Variables never get optimized
    check parseAndSexp("-a", olFull) == "(neg a)"
    check parseAndSexp("-a", olNone) == "(neg a)"
    check parseAndSexp("!flag", olFull) == "(not flag)"
    check parseAndSexp("!flag", olNone) == "(not flag)"

  test "arithmetic with different optimization levels":
    # With full optimization - constant expressions are folded
    check parseAndSexp("2 + 3", olFull) == "5"
    check parseAndSexp("10 - 4", olFull) == "6"
    check parseAndSexp("3 * 4", olFull) == "12"
    check parseAndSexp("8 / 2", olFull) == "4.0"  # Division results in float
    check parseAndSexp("2 ^ 3", olFull) == "8"
    
    # Without optimization - keeps AST structure
    check parseAndSexp("2 + 3", olNone) == "(+ 2 3)"
    check parseAndSexp("10 - 4", olNone) == "(- 10 4)"
    check parseAndSexp("3 * 4", olNone) == "(* 3 4)"
    check parseAndSexp("8 / 2", olNone) == "(/ 8 2)"
    check parseAndSexp("2 ^ 3", olNone) == "(^ 2 3)"
    
    # Mixed variables and constants - only partial optimization
    check parseAndSexp("a + 3", olFull) == "(+ a 3)"
    check parseAndSexp("a + 3", olNone) == "(+ a 3)"

  test "comparison and boolean operations":
    check parseAndSexp("a == b") == "(== a b)"
    check parseAndSexp("a != b") == "(!= a b)"
    check parseAndSexp("a < b") == "(< a b)"
    check parseAndSexp("a <= b") == "(<= a b)"
    check parseAndSexp("a > b") == "(> a b)"
    check parseAndSexp("a >= b") == "(>= a b)"
    check parseAndSexp("a & b") == "(& a b)"
    check parseAndSexp("a | b") == "(| a b)"
    
    # Boolean constant folding
    check parseAndSexp("true & false", olFull) == "false"
    check parseAndSexp("true | false", olFull) == "true"
    check parseAndSexp("true & false", olNone) == "(& true false)"
    check parseAndSexp("true | false", olNone) == "(| true false)"

  test "comparison constant folding":
    # Numeric comparisons with constants get folded
    check parseAndSexp("5 == 5", olFull) == "true"
    check parseAndSexp("5 != 3", olFull) == "true"
    check parseAndSexp("3 < 5", olFull) == "true"
    check parseAndSexp("5 <= 5", olFull) == "true"
    check parseAndSexp("7 > 3", olFull) == "true"
    check parseAndSexp("5 >= 5", olFull) == "true"
    
    # Without optimization
    check parseAndSexp("5 == 5", olNone) == "(== 5 5)"
    check parseAndSexp("3 < 5", olNone) == "(< 3 5)"

  test "function calls":
    check parseAndSexp("f()") == "(call f )"
    check parseAndSexp("f(x)") == "(call f x)"
    check parseAndSexp("f(x, y)") == "(call f x y)"
    check parseAndSexp("g(f(x))") == "(call g (call f x))"
    check parseAndSexp("main()") == "(call main )"

  test "function definitions":
    check parseAndSexp("|x| x + 1") == "(lambda (x) (+ x 1))"
    check parseAndSexp("|x, y| x * y") == "(lambda (x y) (* x y))"
    check parseAndSexp("|| 42") == "(lambda () 42)"
    
    # Lambda with block
    check parseAndSexp("|| { a = 5\n b = 10\n (a + b) * 2 }")
      .contains("(lambda () (block")

  test "assignments":
    check parseAndSexp("x = 5") == "(= x 5)"
    check parseAndSexp("local y = 10") == "(= local y 10)"
    
    # Chained assignments
    check parseAndSexp("x = y = 5") == "(= x (= y 5))"

  test "vectors":
    check parseAndSexp("[1, 2, 3]") == "(vector 1 2 3)"
    check parseAndSexp("[a, b + c]") == "(vector a (+ b c))"
    check parseAndSexp("v = [1, 2, 3]") == "(= v (vector 1 2 3))"

  test "if expressions with optimization":
    # Regular if expressions
    check parseAndSexp("if(x > 0) 1 else -1") == "(cond (if (> x 0) 1) (else -1))"
    check parseAndSexp("if(a) 1 elif(b) 2 else 3") == "(cond (if a 1) (if b 2) (else 3))"
    
    # Constant condition optimization
    check parseAndSexp("if(true) 1 else 2", olFull) == "1"
    check parseAndSexp("if(false) 1 else 2", olFull) == "2"
    check parseAndSexp("if(true) 1 else 2", olNone) == "(cond (if true 1) (else 2))"

  test "arrow operator (function chaining)":
    check parseAndSexp("x->f") == "(call f x)"
    check parseAndSexp("x->f(y)") == "(call f x y)"
    check parseAndSexp("x->f->g") == "(call g (call f x))"
    check parseAndSexp("a->f->g(x)") == "(call g (call f a) x)"
    
    # Arrow with arithmetic
    check parseAndSexp("4->double + 4->double") == "(+ (call double 4) (call double 4))"

  test "complex nested expressions":
    check parseAndSexp("5->double->increment->square") == "(call square (call increment (call double 5)))"
    
    # Function definition with complex body
    check parseAndSexp("|x| if(x > 10) 1 elif(x > 5) 2 else 3") == "(lambda (x) (cond (if (> x 10) 1) (if (> x 5) 2) (else 3)))"

  test "blocks":
    # Simple block
    check parseAndSexp("{ a = 5\n a + 10 }") == "(block (= a 5) (+ a 10))"
    
    # Block with function definition and call
    let blockResult = parseAndSexp("{ a = |x| if(x == 2) 2 else x\n a(x) }")
    check blockResult.startsWith("(block")
    check blockResult.contains("(= a (lambda")
    check blockResult.contains("(call a x)")

  test "type checking with is operator":
    check parseAndSexp("x is complex") == "(== (call type x) complex)"
    check parseAndSexp("|x| if(x is complex) 1 else 2") == "(lambda (x) (cond (if (== (call type x) complex) 1) (else 2)))"

  test "optimization level comparison":
    # Same expression with different optimization levels
    let expr = "2 + 3 * 4 - 1"
    
    # Full optimization: 2 + 12 - 1 = 13
    check parseAndSexp(expr, olFull) == "13"
    
    # No optimization: keeps full AST structure
    check parseAndSexp(expr, olNone) == "(- (+ 2 (* 3 4)) 1)"
    
    # Basic optimization: only constant folding
    check parseAndSexp(expr, olBasic) == "13"

  test "mixed constant and variable expressions":
    # These should have consistent behavior regardless of optimization level
    # since they involve variables
    check parseAndSexp("a + 2 * 3", olFull) == "(+ a 6)"
    check parseAndSexp("a + 2 * 3", olNone) == "(+ a (* 2 3))"
    check parseAndSexp("a + 2 * 3", olBasic) == "(+ a 6)"

  test "grouping with parentheses":
    check parseAndSexp("(5.8)") == "5.8"  # Groups just return inner expression
    check parseAndSexp("(a + b)") == "(+ a b)"
    check parseAndSexp("(a + b) * c") == "(* (+ a b) c)"

  test "complex real-world expressions":
    # Factorial-like function
    let factorialLike = parseAndSexp("|n| if(n <= 1) 1 else n * factorial(n - 1)")
    check factorialLike.startsWith("(lambda (n) (cond (if (<= n 1) 1) (else (* n (call factorial (- n 1))))))")
    
    # Quadratic formula-like expression (simplified)
    check parseAndSexp("(-b + sqrt(delta)) / (2*a)") == "(/ (+ (neg b) (call sqrt delta)) (* 2 a))"
    
    # Complex chained operations
    check parseAndSexp("data->filter(|x| x > 0)->map(|x| x * 2)->sum") == "(call sum (call map (call filter data (lambda (x) (> x 0))) (lambda (x) (* x 2))))"