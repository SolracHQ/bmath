import value
import std/complex

import position
import number
from core import Token, TokenKind
export Token, TokenKind

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
  elif the_value is BMathType:
    Token(kind: tkType, value: newValue(the_value), position: pos)
  else:
    {.error: "Unsupported type for Token".}

# Helper for identifiers
template newIdentToken*(identname: string, pos: Position): Token =
  Token(kind: tkIdent, name: identname, position: pos)

# Helper for comments
template newCommentToken*(commentText: string, pos: Position): Token =
  Token(kind: tkComment, comment: commentText, position: pos)

proc `$`*(token: Token): string =
  ## Returns human-readable token representation
  case token.kind
  # Operators
  of tkAdd:
    return "'+'"
  of tkSub:
    return "'-'"
  of tkMul:
    return "'*'"
  of tkDiv:
    return "'/'"
  of tkPow:
    return "'^'"
  of tkMod:
    return "'%'"
  of tkAssign:
    return "'='"
  of tkChain:
    return "'->'"
  # Boolean operators
  of tkAnd:
    return "'&'" ## Logical AND operator
  of tkNot:
    return "'!'" ## Logical NOT operator
  # Comparison operators
  of tkEq:
    return "'=='"
  of tkNe:
    return "'!='"
  of tkLt:
    return "'<'"
  of tkLe:
    return "'<='"
  of tkGt:
    return "'>'"
  of tkGe:
    return "'>='"
  # Structural tokens
  of tkLPar:
    return "'('"
  of tkRPar:
    return "')'"
  of tkLCurly:
    return "'{'"
  of tkRCurly:
    return "'}'"
  of tkRSquare:
    return "'['"
  of tkLSquare:
    return "']'"
  of tkLine:
    return "'|'"
  of tkFatArrow:
    return "'=>'"
  # Literals and identifiers
  of tkNumber:
    return $token.value
  of tkTrue:
    return "true"
  of tkFalse:
    return "false"
  of tkIdent:
    return "'" & token.name & "'"
  of tkString:
    return $token.value
  # Keywords
  of tkIf:
    return "if"
  of tkElse:
    return "else"
  of tkElif:
    return "elif"
  of tkLocal:
    return "local"
  # Types
  of tkType:
    return $token.value
  of tkIs:
    return "'is'"
  of tkColon:
    return "':'"
  # Control tokens
  of tkComma:
    return "','"
  of tkNewline:
    return "'\\n'"
  of tkComment:
    return "'#" & token.comment & "'"
  of tkEoe:
    return "EOF"
