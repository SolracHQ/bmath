import std/complex # Required by Number
import std/sets # For HashSet in Type
import std/tables

type
  Position* = object ## Source code location information
    line*: int ## 1-based line number in source
    column*: int ## 1-based column number in source

  NumberKind* = enum
    nkInteger ## Integer number
    nkReal ## Floating-point number
    nkComplex ## Complex number

  Number* = object
    case kind*: NumberKind
    of nkInteger:
      integer*: int ## Integer value
    of nkReal:
      real*: float ## Floating-point value
    of nkComplex:
      complex*: Complex[float] ## Complex number value

  VectorObj*[T] = object
    ## Represents a vector object fixed size array of elements of type T.
    p*: ptr UncheckedArray[T]
    len*: int

  Vector*[T] = ref VectorObj[T]
    ## Reference to a vector object, providing dynamic memory management.

  BMathTypeKind* = enum
    ## Represents the kind of type in the BMath type system.
    tkSimple
    tkSum
    tkError

  BMathSimpleType* = enum
    ## Represents simple types in the BMath type system.
    stInteger
    stReal
    stComplex
    stBoolean
    stVector
    stSequence
    stFunction
    stType
    stString
    stError

  BMathType* = object ## Represents a type in the BMath type system.
    case kind*: BMathTypeKind
    of tkSimple:
      simpleType*: BMathSimpleType
    of tkSum:
      types*: HashSet[BMathSimpleType]
    of tkError:
      error*: cstring

  ValueKind* = enum
    ## Discriminator for runtime value types stored in `Value` objects.
    vkNumber ## Numeric value stored in `nValue` field
    vkBool ## Boolean value stored in `bValue` field
    vkNativeFunc ## Native function stored in `nativeFunc` field
    vkFunction ## User-defined function stored as reference
    vkVector ## Vector value
    vkSeq ## Sequence value, lazily evaluated and stored as reference
    vkType ## Type value
    vkString ## String value
    vkError ## Error value

  Signature* = object
    ## Represents a function signature with parameter types.
    ##
    ## Contains the parameter names and their types.
    params*: seq[Parameter] ## Parameter names and types
    returnType*: BMathType ## Return type of the function

  Function* = ref object ## User-defined function data
    body*: Expression ## Function body
    env*: Environment ## Environment for variable bindings
    params*: seq[Parameter] ## Parameter names for the function
    signature*: Signature ## Function signature for type checking

  Sequence* = ref object ## Lazily evaluated sequence
    generator*: Generator ## Function to generate sequence values
    transformers*: seq[Transformer] ## Functions to transform sequence values

  Value* = object
    ## Variant type representing runtime numeric values with type tracking.
    case kind*: ValueKind ## Type discriminator determining active field
    of vkNumber:
      number*: Number ## Numeric storage when kind is `vkNumber`
    of vkBool:
      boolean*: bool ## Boolean storage when kind is `vkBool`
    of vkNativeFunc:
      nativeFn*: NativeFn ## Native function storage when kind is `vkNativeFunc`
    of vkFunction:
      function*: Function ## User-defined function storage when kind is `vkFunction`
    of vkVector:
      vector*: Vector[Value] ## Vector storage when kind is `vkVector`
    of vkSeq:
      sequence*: Sequence ## Sequence storage when kind is `vkSeq`
    of vkType:
      typ*: BMathType ## Type storage when kind is `vkType`
    of vkString:
      content*: string ## String storage when kind is `vkString`
    of vkError:
      error*: string ## Error message when kind is `vkError`

  TransformerKind* = enum
    ## Discriminator for runtime transformer types stored in `Transformer` objects.
    tkMap ## Map transformer
    tkFilter ## Filter transformer

  Transformer* = object
    kind*: TransformerKind ## Type of transformer
    fun*: proc(x: Value): Value ## Function to transform each item in a sequence.

  Generator* = object
    atEnd*: proc(): bool ## Function to check if the sequence is exhausted.
    next*: proc(peek: bool = false): Value ## Function to generate sequence values.

  LabeledValue* = object
    label*: string
    value*: Value

  FnInvoker* = proc(function: Value, args: openArray[Value]): Value
    ## Function type for invoking functions in the runtime.

  NativeFn* = object ## Function in the host language callable from the interpreter.
    callable*: proc(args: openArray[Value], invoker: FnInvoker): Value
      ## Native function callable from the interpreter
    signatures*: seq[Signature] ## Signatures for type checking

  Environment* = ref object
    ## Environment for storing variable bindings and parent scopes.
    values*: Table[string, Value]
    parent*: Environment

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
    tkString ## String literal

    # Keywords
    tkIf ## If keyword
    tkElse ## Else keyword
    tkElif ## Elif keyword
    tkLocal ## Local keyword

    # Types
    tkType ## Type Value
    tkIs ## Type check operator 'is'
    tkColon ## Type separator ':'

    # Control tokens
    tkComma ## Argument separator ','
    tkFatArrow ## Return type arrow '=>'
    tkNewline # End of expression marker for parser (due multiline blocks support)
    tkComment ## Comment text starting with '#'
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
    of tkNumber, tkString, tkType:
      value*: Value
    of tkIdent:
      name*: string ## Identifier name for tkIdent tokens
    of tkComment:
      comment*: string ## Comment content for tkComment tokens
    else:
      discard

  ExpressionKind* = enum
    ## Abstract Syntax Tree (AST) node categories (now called Expressions).
    ## 
    ## Each variant corresponds to a different language construct with
    ## associated child nodes or values.

    # Literals
    ekValue ## Value literal (number or string or boolean or type)
    ekGroup ## Grouping expression to preserve parentheses
    ekVector ## Vector literal

    # Unary operations
    ekNeg ## Unary negation operation (-operand)

    # Binary operations
    ekAdd ## Addition operation (left + right)
    ekSub ## Subtraction operation (left - right)
    ekMul ## Multiplication operation (left * right)
    ekDiv ## Division operation (left / right)
    ekPow ## Exponentiation operation (left ^ right)
    ekMod ## Modulus operation (left % right)

    # Comparison operations
    ekEq ## Equality comparison (left == right)
    ekNe ## Inequality comparison (left != right)
    ekLt ## Less-than comparison (left < right)
    ekLe ## Less-than-or-equal comparison (left <= right)
    ekGt ## Greater-than comparison (left > right)
    ekGe ## Greater-than-or-equal comparison (left >= right)

    # Logical operations
    ekAnd ## Logical AND operation (left & right)
    ekOr ## Logical OR operation (left | right)
    ekNot ## Logical NOT operation (!operand)

    # Identifiers and assignments
    ekIdent ## Identifier reference
    ekAssign ## Variable assignment (ident = expr)

    # Function constructs
    ekFuncDef ## Function definition
    ekFuncCall ## Function invocation

    # Block expression
    ekBlock ## Block expression (sequence of statements)

    # Control flow
    ekIf ## If-else conditional expression

  Parameter* = object
    ## Represents a function parameter.
    ##
    ## Contains the parameter name and its type.
    name*: string
    typ*: BMathType = BMathType(
      kind: tkSum,
      types: toHashSet(
        [
          stInteger, stReal, stComplex, stBoolean, stVector, stSequence, stFunction,
          stType,
        ]
      ),
    )

  # New specialized types for each expression variant
  UnaryOp* = object
    operand*: Expression ## Operand for unary operation

  BinaryOp* = object
    left*: Expression ## Left operand of binary operation
    right*: Expression ## Right operand of binary operation

  Identifier* = object
    ident*: string ## Identifier name

  Assign* = object
    ident*: string ## Target identifier for assignment
    expr*: Expression ## Assigned expression
    isLocal*: bool ## Flag indicating if the assignment is to a local variable
    typ*: BMathType = BMathType(
      kind: tkSum,
      types: toHashSet(
        [
          stInteger, stReal, stComplex, stBoolean, stVector, stSequence, stFunction,
          stType,
        ]
      ),
    )

  FunctionCall* = object
    function*: Expression ## Expression that evaluates to a function
    params*: seq[Expression] ## params for the invocation

  Block* = object
    expressions*: seq[Expression] ## Sequence of statements in the block

  FunctionDef* = object
    body*: Expression ## Function body expression
    params*: seq[Parameter] ## Function parameter names
    returnType*: BMathType = BMathType(
      kind: tkSum,
      types: toHashSet(
        [
          stInteger, stReal, stComplex, stBoolean, stVector, stSequence, stFunction,
          stType,
        ]
      ),
    )

  Branch* = object
    ## Represents a condition in an if-elif expression.
    ##
    ## Contains the condition expression and the corresponding branch expression.
    condition*: Expression
    then*: Expression

  IfExpr* = object
    branches*: seq[Branch]
    elseBranch*: Expression ## Else branch expression

  Expression* = ref object
    ## Abstract Syntax Tree (AST) node (renamed to Expression).
    ##
    ## The active fields depend on the node kind specified in the discriminator.
    ## Each kind maps to a specialized type.
    position*: Position ## Original source location
    case kind*: ExpressionKind
    of ekValue:
      value*: Value
    of ekGroup:
      groupExpr*: Expression
    of ekVector:
      vector*: Vector[Expression]
    of ekNeg, ekNot:
      unaryOp*: UnaryOp
    of ekAdd, ekSub, ekMul, ekDiv, ekMod, ekPow, ekEq, ekNe, ekLt, ekLe, ekGt, ekGe,
        ekAnd, ekOr:
      binaryOp*: BinaryOp
    of ekIdent:
      identifier*: Identifier
    of ekAssign:
      assign*: Assign
    of ekFuncCall:
      functionCall*: FunctionCall
    of ekBlock:
      blockExpr*: Block
    of ekFuncDef:
      functionDef*: FunctionDef
    of ekIf:
      ifExpr*: IfExpr

# Required due nim GC
proc `=destroy`*[T](v: VectorObj[T]) =
  ## Frees the memory allocated for the vector when it goes out of scope.
  ##
  ## Params:
  ##   v: VectorObj[T] - the vector object being destroyed.
  if v.p != nil:
    dealloc(v.p)

proc `=trace`*[T](v: var VectorObj[T], env: pointer) =
  ## Traces the vector's elements for garbage collection.
  ##
  ## Params:
  ##   v: var VectorObj[T] - the vector being traced.
  ##   env: pointer - environment pointer for the GC.
  if v.p != nil:
    for i in 0 ..< v.len:
      `=trace`(v.p[i], env)

proc `=wasMoved`*[T](v: var VectorObj[T]) {.error.}
