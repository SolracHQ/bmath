import unittest, ../src/[interpreter, lexer, parser, types], math

proc evalString(s: string): Value =
  var interp = newInterpreter()
  var lexer = newLexer(s)
  let tokens = lexer.tokenizeExpression()
  echo tokens
  let ast = parse(tokens)
  interp.eval(ast).value

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
  expect BMathError:
    discard evalString("5 / 0")
  check evalString("5 % 0.999").iValue == 0
  check evalString("-7 % 3").iValue == -1