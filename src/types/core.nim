import std/complex # Required by Number
import std/sets # For HashSet in Type
import std/tables

template ANY(): untyped =
  BMathType(
    kind: tkSum,
    types: toHashSet(
      [
        stInteger, stReal, stComplex, stBoolean, stVector, stSequence, stFunction,
        stType,
      ]
    ),
  )

type
  Position* = object ## Source code location information
    line*: int ## 1-based line number in source
    column*: int ## 1-based column number in source
    filePath*: string ## Source file path, or "<expression>" for direct evaluation

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

  VectorObj* = object
    ## Represents a vector object fixed size array of elements of type T.
    p*: ptr UncheckedArray[Value]
    len*: int

  Vector* = ref VectorObj
    ## Reference to a vector object, providing dynamic memory management.

  BMathTypeKind* = enum
    ## Represents the kind of type in the BMath type system.
    tkSimple
    tkSum

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
    stModule

  BMathType* = object ## Represents a type in the BMath type system.
    case kind*: BMathTypeKind
    of tkSimple:
      simpleType*: BMathSimpleType
    of tkSum:
      types*: HashSet[BMathSimpleType]

  ValueMetadata* = object
    ## Metadata associated with runtime values for tracking mutability and other properties
    isMutable*: bool ## Whether the value can be modified after creation

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
    vkModule ## Module value

  FunctionMetadata* = object
    ## Metadata for functions including documentation
    description*: string = "" ## Function description
    examples*: seq[string] = @[] ## Usage examples

  Signature* = object
    ## Represents a function signature with parameter types.
    ##
    ## Contains the parameter names and their types.
    params*: seq[Parameter] ## Parameter names and types
    returnType*: BMathType = ANY() ## Return type of the function

  Function* = ref object ## User-defined function data
    body*: Expression ## Function body
    env*: Environment ## Environment for variable bindings
    signature*: Signature ## Function signature for type checking
    metadata*: FunctionMetadata ## Function metadata including description

  Sequence* = ref object ## Lazily evaluated sequence
    generator*: Generator ## Function to generate sequence values
    transformers*: seq[Transformer] ## Functions to transform sequence values

  Value* = object
    ## Variant type representing runtime values with mutability and type tracking.
    metadata*: ValueMetadata ## Metadata for mutability and other properties
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
      vector*: Vector ## Vector storage when kind is `vkVector`
    of vkSeq:
      sequence*: Sequence ## Sequence storage when kind is `vkSeq`
    of vkType:
      bmath_type*: BMathType ## Type storage when kind is `vkType`
    of vkString:
      content*: string ## String storage when kind is `vkString`
    of vkError:
      errKind*: string ## Error kind when kind is `vkError`
      error*: string ## Error message when kind is `vkError`
    of vkModule:
      environment*: Environment ## Module environment when kind is `vkModule`

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
    metadata*: FunctionMetadata ## Function metadata including description

  EnvironmentKind* = enum
    ## Represents the kind of environment/scope for proper scoping rules
    ekModule ## Module scope - isolated, accessible via this::
    ekFunction ## Function scope - creates capture boundary
    ekBlock ## Block scope - transparent for capture, creates local bindings

  Environment* = ref object
    ## Environment for storing variable bindings and parent scopes with context information.
    kind*: EnvironmentKind ## The kind of scope this environment represents
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
    tkImmutableDecl ## Immutable declaration operator ':='
    tkMutableDecl ## Mutable declaration operator ';='
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
    tkAs ## As keyword for aliasing
    tkThis ## This keyword for module scope reference

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

    # Module system
    tkModule ## Module definition keyword
    tkUse ## Module import keyword
    tkDoubleColon ## Module member access operator '::'

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
    ## Abstract Syntax Tree (AST) node categories.
    ## The order follows operator/construct precedence from highest (primaries)
    ## to lowest (control flow / assignment) to make the language grammar
    ## precedence easier to reason about when reading the source.

    # Primary expressions (highest precedence)
    ekValue ## Value literal (number, string, boolean, type)
    ekGroup ## Grouping expression to preserve parentheses
    ekVector ## Vector literal
    ekIdent ## Identifier reference
    ekThis ## This reference (module scope)
    ekFuncDef ## Function (lambda) literal
    ekModule ## Module definition expression
    ekUse ## Module import expression
    ekBlock ## Block expression (sequence of statements)

    # Postfix / call-like expressions
    ekFuncCall ## Function invocation (high precedence, postfix)
    ekModAccess ## Module member access expression (postfix)
    ekVecIndex ## Vector indexing expression (postfix)

    # Unary operations
    ekNeg ## Unary negation operation (-operand)
    ekNot ## Logical NOT operation (!operand)

    # Exponentiation (right-associative)
    ekPow ## Exponentiation operation (left ^ right)

    # Multiplicative level
    ekMul ## Multiplication operation (left * right)
    ekDiv ## Division operation (left / right)
    ekMod ## Modulus operation (left % right)

    # Additive level
    ekAdd ## Addition operation (left + right)
    ekSub ## Subtraction operation (left - right)

    # Relational comparisons
    ekLt ## Less-than comparison (left < right)
    ekLe ## Less-than-or-equal comparison (left <= right)
    ekGt ## Greater-than comparison (left > right)
    ekGe ## Greater-than-or-equal comparison (left >= right)

    # Equality
    ekEq ## Equality comparison (left == right)
    ekNe ## Inequality comparison (left != right)

    # Logical operators
    ekAnd ## Logical AND operation (left & right)
    ekOr ## Logical OR operation (left | right)

    # Assignment and control (lowest precedence)
    ekAssign ## Variable assignment (ident = expr)
    ekImmutableDecl ## Immutable declaration (ident := expr)
    ekMutableDecl ## Mutable declaration (ident ;= expr)
    ekIf ## If-else conditional expression

  Parameter* = object
    ## Represents a function parameter.
    ##
    ## Contains the parameter name, its type, and documentation.
    name*: string
    bmath_type*: BMathType = ANY()
    isVariadic*: bool = false
    isOptional*: bool = false
    description*: string = "" ## Parameter description for documentation

  # New specialized types for each expression variant
  UnaryOp* = object
    operand*: Expression ## Operand for unary operation

  BinaryOp* = object
    left*: Expression ## Left operand of binary operation
    right*: Expression ## Right operand of binary operation

  Identifier* = object
    ident*: string ## Identifier name

  Assign* = object
    lvalue*: Expression ## Left-hand side expression
    expr*: Expression ## Assigned expression

  FunctionCall* = object
    function*: Expression ## Expression that evaluates to a function
    params*: seq[Expression] ## params for the invocation

  Block* = object
    expressions*: seq[Expression] ## Sequence of statements in the block

  FunctionDef* = object
    body*: Expression ## Function body expression
    signature*: Signature ## Function signature for parameters and return type

  Branch* = object
    ## Represents a condition in an if-elif expression.
    ##
    ## Contains the condition expression and the corresponding branch expression.
    condition*: Expression
    then*: Expression

  IfExpr* = object
    branches*: seq[Branch]
    elseBranch*: Expression ## Else branch expression

  ModuleDef* = object
    content*: seq[Expression] ## Expressions contained in the module

  UseModule* = object
    path*: string ## Simple module path - only the root module to load

  ModuleAccess* = object
    target*: Expression ## Expression evaluating to a module or vector
    member*: string ## Member name being accessed

  VectorIndex* = object
    vector*: Expression ## Expression evaluating to a vector
    index*: Expression ## Expression evaluating to the index

  ImmutableDecl* = object ## Immutable variable declaration (identifier := value)
    lvalue*: Expression ## Left-hand side (identifier)
    expr*: Expression ## Right-hand side expression
    bmath_type*: BMathType ## Optional type annotation

  MutableDecl* = object ## Mutable variable declaration (identifier ;= value)
    lvalue*: Expression ## Left-hand side (identifier)
    expr*: Expression ## Right-hand side expression
    bmath_type*: BMathType ## Optional type annotation

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
      vector*: seq[Expression]
    of ekNeg, ekNot:
      unaryOp*: UnaryOp
    of ekAdd, ekSub, ekMul, ekDiv, ekMod, ekPow, ekEq, ekNe, ekLt, ekLe, ekGt, ekGe,
        ekAnd, ekOr:
      binaryOp*: BinaryOp
    of ekIdent:
      identifier*: Identifier
    of ekThis:
      discard # Returns the current module
    of ekAssign:
      assign*: Assign
    of ekImmutableDecl:
      immutableDecl*: ImmutableDecl
    of ekMutableDecl:
      mutableDecl*: MutableDecl
    of ekFuncCall:
      functionCall*: FunctionCall
    of ekBlock:
      blockExpr*: Block
    of ekFuncDef:
      functionDef*: FunctionDef
    of ekIf:
      ifExpr*: IfExpr
    of ekModule:
      moduleDef*: ModuleDef
    of ekUse:
      useModule*: UseModule
    of ekModAccess:
      moduleAccess*: ModuleAccess
    of ekVecIndex:
      vectorIndex*: VectorIndex

# Required due nim GC
proc `=destroy`*(v: VectorObj) =
  ## Frees the memory allocated for the vector when it goes out of scope.
  ##
  ## Params:
  ##   v: VectorObj - the vector object being destroyed.
  if v.p != nil:
    dealloc(v.p)

proc `=trace`*(v: var VectorObj, env: pointer) =
  ## Traces the vector's elements for garbage collection.
  ##
  ## Params:
  ##   v: var VectorObj - the vector being traced.
  ##   env: pointer - environment pointer for the GC.
  if v.p != nil:
    for i in 0 ..< v.len:
      `=trace`(v.p[i], env)
