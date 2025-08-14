import value
import std/complex

import ../types

template newToken*(the_value: typed, pos: Position): Token =
  when the_value is SomeInteger:
    Token(kind: tkNumber, value: newValue(the_value), position: pos)
  elif the_value is SomeFloat:
    Token(kind: tkNumber, value: newValue(the_value), position: pos)
  elif the_value is Number:
    Token(kind: tkNumber, value: newValue(the_value), position: pos)
  elif the_value is Complex[float]:
    Token(kind: tkNumber, value: newValue(the_value), position: pos)
  elif the_value is string:
    Token(kind: tkString, value: newValue(the_value), position: pos)
  elif the_value is Type:
    Token(kind: tkType, value: newValue(the_value), position: pos)
  else:
    {.error: "Unsupported type for Token".}

# Helper for identifiers
template newIdentToken*(identname: string, pos: Position): Token =
  Token(kind: tkIdent, name: identname, position: pos)

proc `$`*(token: Token): string =
  ## Returns human-readable token representation
  case token.kind
  # Operators
  of tkAdd:
    "'+'"
  of tkSub:
    "'-'"
  of tkMul:
    "'*'"
  of tkDiv:
    "'/'"
  of tkPow:
    "'^'"
  of tkMod:
    "'%'"
  of tkAssign:
    "'='"
  of tkChain:
    "'->'"
  # Boolean operators
  of tkAnd:
    "'&'" ## Logical AND operator
  of tkNot:
    "'!'" ## Logical NOT operator
  # Comparison operators
  of tkEq:
    "'=='"
  of tkNe:
    "'!='"
  of tkLt:
    "'<'"
  of tkLe:
    "'<='"
  of tkGt:
    "'>'"
  of tkGe:
    "'>='"
  # Structural tokens
  of tkLPar:
    "'('"
  of tkRPar:
    "')'"
  of tkLCurly:
    "'{'"
  of tkRCurly:
    "'}'"
  of tkRSquare:
    "'['"
  of tkLSquare:
    "']'"
  of tkLine:
    "'|'"
  # Literals and identifiers
  of tkNumber:
    $token.value
  of tkTrue:
    "true"
  of tkFalse:
    "false"
  of tkIdent:
    "'" & token.name & "'"
  of tkString:
    $token.value
  # Keywords
  of tkIf:
    "if"
  of tkElse:
    "else"
  of tkElif:
    "elif"
  of tkLocal:
    "local"
  # Types
  of tkType:
    $token.value
  of tkIs:
    "'is'"
  of tkColon:
    "':'"
  # Control tokens
  of tkComma:
    "','"
  of tkNewline:
    "'\\n'"
  of tkEoe:
    "EOF"
