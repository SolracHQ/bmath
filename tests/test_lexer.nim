import ../src/pipeline/lexer
import ../src/types/[token, errors]
import unittest

suite "Lexer tests":
  test "Tokenizing numbers":
    var l = newLexer("123 45.67 8e9")
    var tokens: seq[Token]
    while not l.atEnd:
      tokens.add l.next()

    check tokens[0].iValue == 123
    check tokens[1].fValue == 45.67
    check tokens[2].fValue == 8e9

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
      tkInt,
      tkNewline, # tmp^2
      tkRCurly,
      tkEoe, # }
      tkIdent,
      tkLpar,
      tkInt,
      tkComma,
      tkInt,
      tkRpar, # myFunc(1, 2)
    ]
    for i in 0 ..< expected.len:
      let next = l.next()
      check next.kind == expected[i]

  test "Tokenizing vector literal":
    var l = newLexer("v = [1, 2, 3]\n")
    let expected = [
      tkIdent, tkAssign, tkLSquare, tkInt, tkComma, tkInt, tkComma, tkInt, tkRSquare,
      tkEoe,
    ]
    for i in 0 ..< expected.len:
      let tok = l.next()
      check tok.kind == expected[i]

  test "Tokenizing vec function call":
    var l = newLexer("v2 = vec(3, 4)")
    let expected =
      [tkIdent, tkAssign, tkIdent, tkLpar, tkInt, tkComma, tkInt, tkRpar, tkEoe]
    for i in 0 ..< expected.len:
      let tok = l.next()
      check tok.kind == expected[i]

  test "Tokenizing if and booleans":
    var l = newLexer("if true else false elif endif")
    let expected = [tkIf, tkTrue, tkElse, tkFalse, tkElif, tkEndIf, tkEoe]
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

  test "malformed if expression missing endif throws exception":
    let src = "if(a > b) 100 else 200"
    var lexer = newLexer(src)
    expect(IncompleteInputError):
      discard tokenizeExpression(lexer)
