## bmath_knowledge.nim - BMath Language Knowledge Base
##
## Contains all BMath-specific language information including keywords,
## types, functions, operators, and their documentation.

import std/tables

# BMath Language Elements
const BMATH_KEYWORDS* =
  @["if", "else", "elif", "true", "false", "mod", "use", "this", "is"]

const BMATH_TYPES* =
  @[
    "Int", "Real", "Complex", "Bool", "Vec", "Seq", "Function", "Any", "Number", "Type",
    "String", "Module",
  ]

const BMATH_OPERATORS* =
  @[
    ":=", ";=", "=", "->", "::", "+", "-", "*", "/", "%", "^", "==", "!=", "<", "<=",
    ">", ">=", "&", "|", "!",
  ]

const BMATH_STDLIB_FUNCTIONS* =
  @[
    # Core functions
    "exit",
    "try_or",
    "try_catch",
    "print",
    "sqrt",
    "abs",
    "vec",
    "seq",
    "concat",

    # Constants
    "PI",
    "E",
    "I",
    "pi",
    "e",
    "i",

    # Arithmetic functions  
    "pow",
    "floor",
    "ceil",
    "round",
    "re",
    "im",

    # Trigonometry functions
    "sin",
    "cos",
    "tan",
    "cot",
    "sec",
    "csc",
    "log",
    "exp",

    # Vector functions
    "dot",
    "first",
    "last",
    "len",
    "merge",
    "slice",
    "set",

    # Sequence functions  
    "skip",
    "take",
    "has_next",
    "next",
    "collect",
    "zip",

    # Functional programming functions
    "map",
    "filter",
    "reduce",
    "sum",
    "any",
    "all",
    "nth",
    "at",

    # Comparison functions
    "min",
    "max",

    # Assertion functions
    "assert",
    "assert_eq",
    "assert_neq",
    "assert_lt",
    "assert_gt",
    "assert_type",
    "assert_error",

    # Type functions
    "type",
  ]

# Documentation for language elements
const KEYWORD_DOCS* = {
  "if": "**if** - Conditional statement\n\nSyntax: `if condition { ... }`",
  "else": "**else** - Alternative branch in conditional statement",
  "elif": "**elif** - Additional conditional branch\n\nSyntax: `elif condition { ... }`",
  "true": "**true** - Boolean literal representing logical truth",
  "false": "**false** - Boolean literal representing logical falsehood",
  "mod": "**mod** - Module definition\n\nSyntax: `mod name { ... }`",
  "use": "**use** - Import module or symbols\n\nSyntax: `use module_name`",
  "this": "**this** - Reference to current module context",
  "is": "**is** - Type checking operator\n\nSyntax: `value is Type`",
}.toTable

const TYPE_DOCS* = {
  "Int":
    "**Int** - Integer number type\n\nRepresents whole numbers without fractional components.",
  "Real":
    "**Real** - Real number type\n\nRepresents floating-point numbers with decimal precision.",
  "Complex":
    "**Complex** - Complex number type\n\nRepresents numbers with real and imaginary components.",
  "Bool": "**Bool** - Boolean type\n\nRepresents logical values: true or false.",
  "Vec":
    "**Vec** - Vector type\n\nRepresents collections of values with indexed access.",
  "Seq":
    "**Seq** - Sequence type\n\nRepresents lazy-evaluated collections for streaming operations.",
  "Function":
    "**Function** - Function type\n\nRepresents callable procedures and expressions.",
  "String": "**String** - Text string type\n\nRepresents sequences of characters.",
  "Module": "**Module** - Module type\n\nRepresents organizational units of code.",
  "Any": "**Any** - Universal type\n\nTop type that can represent any value.",
  "Number":
    "**Number** - Generic number type\n\nUnion type covering Int, Real, and Complex.",
  "Type": "**Type** - Type of types\n\nMeta-type representing type information.",
}.toTable

const FUNCTION_DOCS* = {
  # Core functions
  "exit": "**exit** - Terminate program execution\n\nSyntax: `exit(code: Int)`",
  "try_or":
    "**try_or** - Error handling with default value\n\nSyntax: `try_or(expr, default)`",
  "try_catch":
    "**try_catch** - Error handling with callback\n\nSyntax: `try_catch(expr, handler)`",
  "print": "**print** - Output values to console\n\nSyntax: `print(value, ...)`",
  "sqrt": "**sqrt** - Square root function\n\nSyntax: `sqrt(x: Number) -> Number`",
  "abs": "**abs** - Absolute value function\n\nSyntax: `abs(x: Number) -> Number`",
  "vec": "**vec** - Create vector from values\n\nSyntax: `vec(values...) -> Vec`",
  "seq":
    "**seq** - Create sequence from range or values\n\nSyntax: `seq(start, end) -> Seq`",
  "concat": "**concat** - Concatenate collections\n\nSyntax: `concat(a, b) -> Vec|Seq`",

  # Constants
  "PI": "**PI** - Mathematical constant π (3.14159...)",
  "E": "**E** - Mathematical constant e (2.71828...)",
  "I": "**I** - Imaginary unit (√-1)",
  "pi": "**pi** - Alias for PI",
  "e": "**e** - Alias for E",
  "i": "**i** - Alias for I",

  # Arithmetic functions
  "pow": "**pow** - Power function\n\nSyntax: `pow(base, exponent) -> Number`",
  "floor": "**floor** - Floor function (round down)\n\nSyntax: `floor(x: Real) -> Int`",
  "ceil": "**ceil** - Ceiling function (round up)\n\nSyntax: `ceil(x: Real) -> Int`",
  "round": "**round** - Round to nearest integer\n\nSyntax: `round(x: Real) -> Int`",
  "re": "**re** - Real part of complex number\n\nSyntax: `re(z: Complex) -> Real`",
  "im": "**im** - Imaginary part of complex number\n\nSyntax: `im(z: Complex) -> Real`",

  # Trigonometry
  "sin": "**sin** - Sine function\n\nSyntax: `sin(x: Number) -> Number`",
  "cos": "**cos** - Cosine function\n\nSyntax: `cos(x: Number) -> Number`",
  "tan": "**tan** - Tangent function\n\nSyntax: `tan(x: Number) -> Number`",
  "cot": "**cot** - Cotangent function\n\nSyntax: `cot(x: Number) -> Number`",
  "sec": "**sec** - Secant function\n\nSyntax: `sec(x: Number) -> Number`",
  "csc": "**csc** - Cosecant function\n\nSyntax: `csc(x: Number) -> Number`",
  "log": "**log** - Natural logarithm\n\nSyntax: `log(x: Number) -> Number`",
  "exp": "**exp** - Exponential function (e^x)\n\nSyntax: `exp(x: Number) -> Number`",

  # Vector functions
  "dot": "**dot** - Dot product of vectors\n\nSyntax: `dot(a: Vec, b: Vec) -> Number`",
  "first": "**first** - Get first element\n\nSyntax: `first(v: Vec|Seq) -> Any`",
  "last": "**last** - Get last element\n\nSyntax: `last(v: Vec) -> Any`",
  "len": "**len** - Get collection length\n\nSyntax: `len(v: Vec|Seq) -> Int`",
  "merge": "**merge** - Merge collections\n\nSyntax: `merge(a: Vec, b: Vec) -> Vec`",
  "slice":
    "**slice** - Extract slice from collection\n\nSyntax: `slice(v: Vec, start: Int, end: Int) -> Vec`",
  "set":
    "**set** - Set element at index\n\nSyntax: `set(v: Vec, index: Int, value: Any) -> Vec`",

  # Sequence functions
  "skip": "**skip** - Skip first n elements\n\nSyntax: `skip(s: Seq, n: Int) -> Seq`",
  "take": "**take** - Take first n elements\n\nSyntax: `take(s: Seq, n: Int) -> Seq`",
  "has_next":
    "**has_next** - Check if sequence has more elements\n\nSyntax: `has_next(s: Seq) -> Bool`",
  "next": "**next** - Get next element from sequence\n\nSyntax: `next(s: Seq) -> Any`",
  "collect":
    "**collect** - Collect sequence into vector\n\nSyntax: `collect(s: Seq) -> Vec`",
  "zip": "**zip** - Zip two sequences together\n\nSyntax: `zip(a: Seq, b: Seq) -> Seq`",

  # Functional programming
  "map":
    "**map** - Apply function to each element\n\nSyntax: `map(f: Function, collection) -> Vec|Seq`",
  "filter":
    "**filter** - Filter elements by predicate\n\nSyntax: `filter(f: Function, collection) -> Vec|Seq`",
  "reduce":
    "**reduce** - Reduce collection to single value\n\nSyntax: `reduce(f: Function, initial, collection) -> Any`",
  "sum": "**sum** - Sum all elements\n\nSyntax: `sum(collection) -> Number`",
  "any":
    "**any** - Check if any element satisfies predicate\n\nSyntax: `any(f: Function, collection) -> Bool`",
  "all":
    "**all** - Check if all elements satisfy predicate\n\nSyntax: `all(f: Function, collection) -> Bool`",
  "nth": "**nth** - Get nth element\n\nSyntax: `nth(collection, n: Int) -> Any`",
  "at": "**at** - Get element at index\n\nSyntax: `at(collection, index: Int) -> Any`",

  # Comparison
  "min": "**min** - Minimum of values\n\nSyntax: `min(values...) -> Number`",
  "max": "**max** - Maximum of values\n\nSyntax: `max(values...) -> Number`",

  # Assertions
  "assert":
    "**assert** - Assert condition is true\n\nSyntax: `assert(condition: Bool, message?: String)`",
  "assert_eq":
    "**assert_eq** - Assert values are equal\n\nSyntax: `assert_eq(actual, expected, message?)`",
  "assert_neq":
    "**assert_neq** - Assert values are not equal\n\nSyntax: `assert_neq(actual, unexpected, message?)`",
  "assert_lt":
    "**assert_lt** - Assert first value is less than second\n\nSyntax: `assert_lt(a, b, message?)`",
  "assert_gt":
    "**assert_gt** - Assert first value is greater than second\n\nSyntax: `assert_gt(a, b, message?)`",
  "assert_type":
    "**assert_type** - Assert value has expected type\n\nSyntax: `assert_type(value, expectedType, message?)`",
  "assert_error":
    "**assert_error** - Assert expression throws error\n\nSyntax: `assert_error(expr, message?)`",

  # Type functions
  "type": "**type** - Get type of value\n\nSyntax: `type(value) -> Type`",
}.toTable

# Function to get documentation for any BMath symbol
proc getDocumentation*(symbol: string): string =
  ## Get documentation for a BMath symbol (keyword, type, or function)
  if symbol in KEYWORD_DOCS:
    return KEYWORD_DOCS[symbol]
  elif symbol in TYPE_DOCS:
    return TYPE_DOCS[symbol]
  elif symbol in FUNCTION_DOCS:
    return FUNCTION_DOCS[symbol]
  else:
    return ""

# Function to check symbol category
proc isKeyword*(symbol: string): bool =
  symbol in BMATH_KEYWORDS

proc isType*(symbol: string): bool =
  symbol in BMATH_TYPES

proc isStdlibFunction*(symbol: string): bool =
  symbol in BMATH_STDLIB_FUNCTIONS

proc isOperator*(symbol: string): bool =
  symbol in BMATH_OPERATORS

# Function to categorize functions for completion
proc getFunctionCategory*(funcName: string): string =
  ## Get the category of a function for better completion organization
  if funcName in ["sin", "cos", "tan", "cot", "sec", "csc", "exp", "log"]:
    return "Mathematical"
  elif funcName in ["abs", "sqrt", "pow", "floor", "ceil", "round", "re", "im"]:
    return "Arithmetic"
  elif funcName in ["len", "sum", "map", "filter", "reduce", "any", "all"]:
    return "Collection"
  elif funcName in ["PI", "E", "I", "pi", "e", "i"]:
    return "Constants"
  elif funcName in [
    "assert", "assert_eq", "assert_neq", "assert_lt", "assert_gt", "assert_type",
    "assert_error",
  ]:
    return "Assertions"
  elif funcName in ["dot", "first", "last", "merge", "slice", "set"]:
    return "Vector Operations"
  elif funcName in ["skip", "take", "has_next", "next", "collect", "zip"]:
    return "Sequence Operations"
  elif funcName in ["try_or", "try_catch", "exit", "print"]:
    return "Core Functions"
  else:
    return "Other"
