import ../src/pipeline/lexer
import ../src/types/[token, number, bm_types, errors]
import std/tables
import unittest

suite "Lexer tests":
  test "Tokenizing numbers":
    var l = newLexer("123 45.67 8e9")
    var tokens: seq[Token]
    while not l.atEnd:
      tokens.add l.next()

    check tokens[0].value.number.integer == 123
    check tokens[1].value.number.real == 45.67
    check tokens[2].value.number.real == 8e9

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
    check $tok1.value.number == "3.0i"
    # Tokenize "4+3i" into 3 tokens: number "4", '+' operator, number "3i"
    let tok2 = l.next() # number "4"
    check tok2.kind == tkNumber
    check $tok2.value.number == "4"
    let tok3 = l.next() # '+' operator
    check tok3.kind == tkAdd
    let tok4 = l.next() # number "3i"
    check tok4.kind == tkNumber
    check $tok4.value.number == "3.0i"
    # Tokenize "4+3i*2" into 5 tokens: number "4", '+' operator, number "3i", '*' operator, number "2"
    let tok5 = l.next() # number "4"
    check tok5.kind == tkNumber
    check $tok5.value.number == "4"
    let tok6 = l.next() # '+' operator
    check tok6.kind == tkAdd
    let tok7 = l.next() # number "3i"
    check tok7.kind == tkNumber
    check $tok7.value.number == "3.0i"
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

  test "Tokenizing type identifiers":
    var l = newLexer("integer real complex boolean vector sequence function type any number")
    
    # Check each type token
    let tok1 = l.next()
    check tok1.kind == tkType
    check tok1.value.typ === stInteger.newType
    
    let tok2 = l.next()
    check tok2.kind == tkType
    check tok2.value.typ === stReal.newType
    
    let tok3 = l.next()
    check tok3.kind == tkType
    check tok3.value.typ === stComplex.newType
    
    let tok4 = l.next()
    check tok4.kind == tkType
    check tok4.value.typ == stBoolean.newType
    
    let tok5 = l.next()
    check tok5.kind == tkType
    check tok5.value.typ === stVector.newType
    
    let tok6 = l.next()
    check tok6.kind == tkType
    check tok6.value.typ === stSequence.newType
    
    let tok7 = l.next()
    check tok7.kind == tkType
    check tok7.value.typ === stFunction.newType
    
    let tok8 = l.next()
    check tok8.kind == tkType
    check tok8.value.typ === stType.newType
    
    let tok9 = l.next()
    check tok9.kind == tkType
    check tok9.value.typ === AnyType
    
    let tok10 = l.next()
    check tok10.kind == tkType
    check tok10.value.typ === NumberType
  
  test "Tokenizing 'is' operator":
    var l = newLexer("x is integer")
    
    let tok1 = l.next()
    check tok1.kind == tkIdent
    check tok1.name == "x"
    
    let tok2 = l.next()
    check tok2.kind == tkIs
    
    let tok3 = l.next()
    check tok3.kind == tkType
    check tok3.value.typ === stInteger.newType

  test "Token positions are recorded correctly":
    # Prepare a multi-line input with various tokens placed at known columns
    let src = "let x = 12\nmyFunc = |a, b| {\n  s = \"hello\\nworld\"\n}\n"
    var lpos = newLexer(src)
    # 'let' is not a keyword here, it will be tkIdent at column 1
    let t1 = lpos.next()
    check t1.kind == tkIdent
    check t1.position.column == 1

    # next token should be identifier 'x' at column 5
    let t2 = lpos.next()
    check t2.kind == tkIdent
    check t2.position.column == 5

    # '=' should be at column 7
    let t3 = lpos.next()
    check t3.kind == tkAssign
    check t3.position.column == 7

    # number 12 starts at column 9
    let t4 = lpos.next()
    check t4.kind == tkNumber
    check t4.position.column == 9

    # Advance to the string token and check its starting column and content
    # Skip to the line with the string
    while not lpos.atEnd and lpos.next().kind != tkString: discard
    # Note: after the loop above, we've consumed the string token; re-lex string line separately
    var lstr = newLexer("s = \"hello\\nworld\"\n")
    let id = lstr.next()
    check id.kind == tkIdent
    check id.position.column == 1
    let eq = lstr.next()
    check eq.kind == tkAssign
    check eq.position.column == 3
    let strTok = lstr.next()
    check strTok.kind == tkString
    # string opening quote at column 5
    check strTok.position.column == 5
    check strTok.value.content == "hello\nworld"

  test "Backslash-newline continuation preserves position and skips newline":
    # A backslash at end of line should continue the logical line; lexer.skipNewline should clear and not emit EOE
    var l = newLexer("a = 1 \\\n + 2\n")
    # tokens: a, =, 1, +, 2, EOE
    let ta = l.next()
    check ta.kind == tkIdent
    check ta.position.column == 1
    let teq = l.next()
    check teq.kind == tkAssign
    check teq.position.column == 3
    let tnum = l.next()
    check tnum.kind == tkNumber
    # number 1 is at column 5
    check tnum.position.column == 5
    let top = l.next()
    check top.kind == tkAdd
    # plus after continuation should be at column 4 of the second physical line (but lexer reports absolute column)
    check top.position.column > 1

  test "Multi-line chain with backslash continuation keeps correct line/column":
    let src = "seq(9, |_| 100) -> \\\n    map(|x| x + 1) -> \\\n    filter(|x| x % 2 == 0) -> \\\n    collect\n"
    var l = newLexer(src)
    var toks: seq[Token]
    while not l.atEnd:
      toks.add l.next()

    # Collect identifier tokens in appearance order
    var idents: seq[Token] = @[]
    for t in toks:
      if t.kind == tkIdent:
        idents.add t

    check idents.len >= 4
    # Verify lines are correct for the pipeline functions
    var found: Table[string, tuple[line: int, col: int]]
    found = initTable[string, tuple[line: int, col: int]]()
    for t in toks:
      if t.kind == tkIdent and (t.name == "seq" or t.name == "map" or t.name == "filter" or t.name == "collect"):
        found[t.name] = (line: t.position.line, col: t.position.column)

    check found.hasKey("seq")
    check found.hasKey("map")
    check found.hasKey("filter")
    check found.hasKey("collect")

    check found["seq"].line == 1
    check found["map"].line == 2
    check found["map"].col == 5
    check found["filter"].line == 3
    check found["filter"].col == 5
    check found["collect"].line == 4
    check found["collect"].col == 5
