import ../src/lexer, ../src/types
import unittest

test "Tokenizing numbers":
  var l = newLexer("123 45.67 8e9")
  var tokens: seq[Token]
  while not l.atEnd:
    tokens.add l.next()

  check tokens[0].value.iValue == 123
  check tokens[1].value.fValue == 45.67
  check tokens[2].value.fValue == 8e9

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
    tkIdent, tkAssign, tkLine, tkIdent, tkComma, tkIdent, tkLine, tkLcur, tkNewline, # myFunc = |a, b| {
    tkIdent, tkAssign, tkIdent, tkAdd, tkIdent, tkNewline, # tmp = a+b
    tkIdent, tkPow, tkNum, tkNewline, # tmp^2
    tkRcur, tkEoe, # }
    tkIdent, tkLpar, tkNum, tkComma, tkNum, tkRpar # myFunc(1, 2)
  ]
  for i in 0 ..< expected.len:
    let next = l.next()
    check next.kind == expected[i]