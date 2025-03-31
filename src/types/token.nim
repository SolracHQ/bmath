import position
import number
import types
import std/complex

type
  TokenKind* = enum
    ## Lexical token categories produced by the lexer.
    ## 
    ## These represent fundamental syntactic elements including:
    ## - Operators (arithmetic, assignment)
    ## - Literal values
    ## - Structural characters
    ## - Identifiers

    # Operators
    tkAdd ## Addition operator '+'
    tkSub ## Subtraction operator '-'
    tkMul ## Multiplication operator '*'
    tkDiv ## Division operator '/'
    tkPow ## Exponentiation operator '^'
    tkMod ## Modulus operator '%'
    tkAssign ## Assignment operator '='
    tkChain ## Chained function call operator '->'

    # Boolean operators
    tkAnd ## Logical AND operator '&'
    # for tkOr we will reuse the tkLine '|' character
    tkNot ## Logical NOT operator '!'

    # Comparison operators
    tkEq ## Equality operator '=='
    tkNe ## Inequality operator '!='
    tkLt ## Less than operator '<'
    tkLe ## Less than or equal operator '<='
    tkGt ## Greater than operator '>'
    tkGe ## Greater than or equal operator '>='

    # Structural tokens
    tkLPar ## Left parenthesis '('
    tkRPar ## Right parenthesis ')'
    tkLCurly ## Left curly brace '{'
    tkRCurly ## Right curly brace '}'
    tkRSquare ## Square bracket '['
    tkLSquare ## Square bracket ']'
    tkLine ## Parameter delimiter '|'

    # Literals and identifiers
    tkNumber ## Numeric literal (integer or float)
    tkTrue ## Boolean true literal
    tkFalse ## Boolean false literal
    tkIdent ## Identifier (variable/function name)

    # Keywords
    tkIf ## If keyword
    tkElse ## Else keyword
    tkElif ## Elif keyword
    tkLocal ## Local keyword

    # Types
    tkType ## Type Value
    tkColon ## Type separator ':'

    # Control tokens
    tkComma ## Argument separator ','
    tkNewline # End of expression marker for parser (due multiline blocks support)
    tkEoe ## End of expression marker for lexer

  Token* = object
    ## Lexical token with source position and type-specific data.
    ## 
    ## The active field depends on the token kind:
    ## - `iValue` for integer literals (tkInt)
    ## - `fValue` for floating-point literals (tkFloat)
    ## - `name` for identifiers (tkIdent)
    position*: Position ## Source location of the token
    case kind*: TokenKind
    of tkNumber:
      nValue*: Number ## Numeric value for tkNumber tokens
    of tkIdent:
      name*: string ## Identifier name for tkIdent tokens
    of tkType:
      typ*: Type ## Type value for tkType tokens
    else:
      discard

template newToken*(value: typed, pos: Position): Token =
  when value is SomeInteger:
    Token(kind: tkNumber, nValue: newNumber(value), position: pos)
  elif value is SomeFloat:
    Token(kind: tkNumber, nValue: newNumber(value), position: pos)
  elif value is Number:
    Token(kind: tkNumber, nValue: value, position: pos)
  elif value is Complex[float]:
    Token(kind: tkNumber, nValue: newNumber(value), position: pos)
  elif value is SomeString:
    Token(kind: tkIdent, name: value, position: pos)
  else:
    {.error: "Unsupported type for Token".}

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
    $token.nValue
  of tkTrue:
    "true"
  of tkFalse:
    "false"
  of tkIdent:
    "'" & token.name & "'"
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
    $token.typ
  of tkColon:
    "':'"
  # Control tokens
  of tkComma:
    "','"
  of tkNewline:
    "'\\n'"
  of tkEoe:
    "EOF"
