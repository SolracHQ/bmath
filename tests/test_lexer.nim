import ../src/pipeline/lexer/[lexer, errors]
import ../src/types/[token, number]
import unittest

suite "Lexer tests":
  test "Tokenizing numbers":
    var l = newLexer("123 45.67 8e9")
    var tokens: seq[Token]
    while not l.atEnd:
      tokens.add l.next()

    check tokens[0].nValue.integer == 123
    check tokens[1].nValue.real == 45.67
    check tokens[2].nValue.real == 8e9

  test "Tokenizing operators":
    var l = newLexer("+-*/^%")
    let expected = [tkAdd, tkSub, tkMul, tkDiv, tkPow, tkMod]
    for i in 0 .. 5:
      check l.next().kind == expected[i]

  test "Tokenizing identifiers":
    var l = newLexer("x sqrt")
    check l.next().name == "x"
    check l.next().name == "sqrt"

  test "Tokenize function components":
    var l = newLexer("myFunc = |a, b| {\ntmp = a+b\ntmp^2\n}\nmyFunc(1, 2)")
    let expected = [
      tkIdent,
      tkAssign,
      tkLine,
      tkIdent,
      tkComma,
      tkIdent,
      tkLine,
      tkLCurly,
      tkNewline, # myFunc = |a, b| {
      tkIdent,
      tkAssign,
      tkIdent,
      tkAdd,
      tkIdent,
      tkNewline, # tmp = a+b
      tkIdent,
      tkPow,
      tkNumber,
      tkNewline, # tmp^2
      tkRCurly,
      tkEoe, # }
      tkIdent,
      tkLpar,
      tkNumber,
      tkComma,
      tkNumber,
      tkRpar, # myFunc(1, 2)
    ]
    for i in 0 ..< expected.len:
      let next = l.next()
      check next.kind == expected[i]

  test "Tokenizing vector literal":
    var l = newLexer("v = [1, 2, 3]\n")
    let expected = [
      tkIdent, tkAssign, tkLSquare, tkNumber, tkComma, tkNumber, tkComma, tkNumber,
      tkRSquare, tkEoe,
    ]
    for i in 0 ..< expected.len:
      let tok = l.next()
      check tok.kind == expected[i]

  test "Tokenizing vec function call":
    var l = newLexer("v2 = vec(3, 4)")
    let expected =
      [tkIdent, tkAssign, tkIdent, tkLpar, tkNumber, tkComma, tkNumber, tkRpar, tkEoe]
    for i in 0 ..< expected.len:
      let tok = l.next()
      check tok.kind == expected[i]

  test "Tokenizing if and booleans":
    var l = newLexer("if true else false elif")
    let expected = [tkIf, tkTrue, tkElse, tkFalse, tkElif, tkEoe]
    for i in 0 ..< expected.len:
      let tok = l.next()
      check tok.kind == expected[i]
    # Additionally, verify the boolean values.
    # Reset lexer to check boolean literal values.
    l = newLexer("true false")
    let tTrue = l.next()
    let tFalse = l.next()
    check tTrue.kind == tkTrue
    check tFalse.kind == tkFalse

  test "Tokenizing comparison operators":
    var l = newLexer("a==b a!=c a<d a<=e a>d a>=f")
    let expectedKinds = [
      tkIdent,
      tkEq,
      tkIdent, # a==b
      tkIdent,
      tkNe,
      tkIdent, # a!=c
      tkIdent,
      tkLt,
      tkIdent, # a<d
      tkIdent,
      tkLe,
      tkIdent, # a<=e
      tkIdent,
      tkGt,
      tkIdent, # a>d
      tkIdent,
      tkGe,
      tkIdent, # a>=f
      tkEoe,
    ]
    for i in 0 ..< expectedKinds.len:
      let tok = l.next()
      check tok.kind == expectedKinds[i]

  test "Tokenizing boolean operations":
    var l = newLexer("x & y")
    let expected = [tkIdent, tkAnd, tkIdent, tkEoe]
    for i in 0 ..< expected.len:
      let tok = l.next()
      check tok.kind == expected[i]

  test "Tokenizing complex numbers":
    var l = newLexer("3i 4+3i 4+3i*2")
    # Tokenize "3i"
    let tok1 = l.next()
    check tok1.kind == tkNumber
    check $tok1.nValue == "3.0i"
    # Tokenize "4+3i" into 3 tokens: number "4", '+' operator, number "3i"
    let tok2 = l.next() # number "4"
    check tok2.kind == tkNumber
    check $tok2.nValue == "4"
    let tok3 = l.next() # '+' operator
    check tok3.kind == tkAdd
    let tok4 = l.next() # number "3i"
    check tok4.kind == tkNumber
    check $tok4.nValue == "3.0i"
    # Tokenize "4+3i*2" into 5 tokens: number "4", '+' operator, number "3i", '*' operator, number "2"
    let tok5 = l.next() # number "4"
    check tok5.kind == tkNumber
    check $tok5.nValue == "4"
    let tok6 = l.next() # '+' operator
    check tok6.kind == tkAdd
    let tok7 = l.next() # number "3i"
    check tok7.kind == tkNumber
    check $tok7.nValue == "3.0i"
    let tok8 = l.next() # '*' operator
    check tok8.kind == tkMul
    let tok9 = l.next() # number "2"
    check tok9.kind == tkNumber

  test "Tokenizing additional operators":
    var l = newLexer("a^2 5%3")
    let t1 = l.next() # identifier "a"
    check t1.kind == tkIdent
    let t2 = l.next() # exponentiation operator
    check t2.kind == tkPow
    let t3 = l.next() # number 2
    check t3.kind == tkNumber
    let t4 = l.next() # number 5
    check t4.kind == tkNumber
    let t5 = l.next() # modulo operator
    check t5.kind == tkMod
    let t6 = l.next() # number 3
    check t6.kind == tkNumber

  test "Incomplete curly brace":
    expect IncompleteInputError:
      var lex = newLexer("{")
      discard tokenizeExpression(lex)

  test "Incomplete parenthesis":
    expect IncompleteInputError:
      var lex = newLexer("(")
      discard tokenizeExpression(lex)

  test "Incomplete square bracket":
    expect IncompleteInputError:
      var lex = newLexer("[")
      discard tokenizeExpression(lex)

  test "Incomplete if block":
    expect IncompleteInputError:
      var lex = newLexer("if x")
      discard tokenizeExpression(lex)

  test "Malformed number: incomplete exponent":
    expect InvalidNumberFormatError:
      var lex = newLexer("1e")
      discard lex.next() # parse number
