import position

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
    tkInt ## Integer literal
    tkFloat ## Floating-point literal
    tkTrue ## Boolean true literal
    tkFalse ## Boolean false literal
    tkIdent ## Identifier (variable/function name)

    # Keywords
    tkIf ## If keyword
    tkElse ## Else keyword
    tkElif ## Elif keyword
    tkEndIf ## EndIf keyword
    tkReturn ## Return keyword
    tkLocal ## Local keyword

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
    of tkInt:
      iValue*: int ## Integer value for tkInt tokens
    of tkFloat:
      fValue*: float ## Floating-point value for tkFloat tokens
    of tkIdent:
      name*: string ## Identifier name for tkIdent tokens
    else:
      discard

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
  of tkInt:
    $token.iValue
  of tkFloat:
    $token.fValue
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
  of tkEndIf:
    "endif"
  of tkReturn:
    "return"
  of tkLocal:
    "local"
  # Control tokens
  of tkComma:
    "','"
  of tkNewline:
    "'\\n'"
  of tkEoe:
    "EOF"
