## bmath_knowledge.nim - BMath Language Knowledge Base
##
## Now uses centralized language knowledge from data/language_knowledge.json
## via the data/language_knowledge module. This ensures consistency across
## the LSP, interpreter, and documentation.

import ../data/language_knowledge
import ../data/stdlib_signatures

# Initialize language knowledge on module load
static:
  echo "Loading language knowledge from centralized JSON..."
  echo "Loading stdlib data from centralized JSON..."

# BMath Language Elements - loaded from centralized source
proc BMATH_KEYWORDS*(): seq[string] =
  getKeywordNames()

proc BMATH_TYPES*(): seq[string] =
  getTypeNames()

proc BMATH_OPERATORS*(): seq[string] =
  getOperatorSymbols()

# Load stdlib functions and constants from centralized JSON
proc BMATH_STDLIB_FUNCTIONS*(): seq[string] =
  ## Get all stdlib function names from centralized JSON
  getAllFunctionNames()

proc BMATH_STDLIB_CONSTANTS*(): seq[string] =
  ## Get all stdlib constant names from centralized JSON
  getAllConstantNames()

# Note: All documentation is now loaded from centralized JSON files:
# - language_knowledge.json for keywords, types, and operators
# - stdlib.json for functions and constants

# Function to get documentation for any BMath symbol
proc getDocumentation*(symbol: string): string =
  ## Get documentation for a BMath symbol (keyword, type, constant, or function)
  ## All documentation is loaded from centralized JSON files
  
  # 1. Check centralized language knowledge (keywords, types, operators)
  let centralizedDoc = language_knowledge.getDocumentation(symbol)
  if centralizedDoc != "":
    return centralizedDoc
  
  # 2. Check stdlib constants from stdlib.json
  let constantDoc = getConstantDescription(symbol)
  if constantDoc != "":
    return constantDoc
  
  # 3. Check stdlib functions from stdlib.json
  let functionDoc = getDescriptionFor(symbol)
  if functionDoc != "":
    return functionDoc
  
  # No documentation found
  return ""

# Function to check symbol category
proc isKeyword*(symbol: string): bool =
  language_knowledge.isKeyword(symbol)

proc isType*(symbol: string): bool =
  language_knowledge.isType(symbol)

proc isStdlibConstant*(symbol: string): bool =
  isConstant(symbol)

proc isStdlibFunction*(symbol: string): bool =
  let funcs = BMATH_STDLIB_FUNCTIONS()
  symbol in funcs

proc isOperator*(symbol: string): bool =
  language_knowledge.isOperator(symbol)

# Function to categorize functions for completion
proc getFunctionCategory*(funcName: string): string =
  ## Get the category of a function for better completion organization
  ## Now loads from centralized stdlib.json
  
  # Check if it's a constant first
  if isStdlibConstant(funcName):
    return "Constants"
  
  # Get category from stdlib.json
  let category = getCategoryFor(funcName)
  
  # Map internal categories to display names
  case category
  of "core": return "Core Functions"
  of "arithmetic": return "Arithmetic"
  of "trigonometric": return "Mathematical"
  of "vector": return "Vector Operations"
  of "sequence": return "Sequence Operations"
  of "functional": return "Collection"
  of "comparison": return "Comparison"
  of "assertions": return "Assertions"
  of "type-system": return "Type System"
  else: return "Other"
