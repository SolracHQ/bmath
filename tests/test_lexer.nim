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
  for i in 0..5:
    check l.next().kind == expected[i]

test "Tokenizing identifiers":
  var l = newLexer("x sqrt")
  check l.next().name == "x"
  check l.next().name == "sqrt"