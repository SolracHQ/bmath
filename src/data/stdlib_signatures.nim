## stdlib_signatures.nim - Load standard library signatures from JSON at compile time
##
## This module provides utilities to load function signatures from the
## stdlib_signatures.json file, which serves as a single source of truth
## for type information used by the type checker, LSP, and documentation.
##
## The JSON file is embedded at compile time for zero runtime overhead.

import std/json
import std/tables
import std/sets
import ../types/[core, bm_types]

type
  LoadedFunctionData* = object
    ## Temporary type for loading function data from JSON
    metadata*: FunctionMetadata
    signatures*: seq[Signature]

# Load JSON at compile time
const stdlibSignaturesJson = staticRead("../../data/stdlib_signatures.json")

proc parseTypeString(typeStr: string): BMathType =
  ## Parse a type string from JSON into a BMathType
  case typeStr
  of "Int":
    newType(stInteger)
  of "Real":
    newType(stReal)
  of "Complex":
    newType(stComplex)
  of "Number":
    NumberType
  of "Bool":
    newType(stBoolean)
  of "String":
    newType(stString)
  of "Vec":
    newType(stVector)
  of "Seq":
    newType(stSequence)
  of "Function":
    newType(stFunction)
  of "Type":
    newType(stType)
  of "Error":
    newType(stError)
  of "Module":
    newType(stModule)
  of "Any":
    AnyType
  else:
    AnyType

proc parseType(typeNode: JsonNode): BMathType =
  ## Parse a type from JSON - can be a string or array of strings (sum type)
  if typeNode.kind == JString:
    return parseTypeString(typeNode.getStr())
  elif typeNode.kind == JArray:
    var simpleTypes: seq[BMathSimpleType] = @[]
    for typeStr in typeNode:
      let bmType = parseTypeString(typeStr.getStr())
      if bmType.kind == tkSimple:
        simpleTypes.add(bmType.simpleType)
      elif bmType.kind == tkSum:
        # If it's already a sum type (like Number), add all its types
        for t in bmType.types:
          simpleTypes.add(t)
    if simpleTypes.len == 1:
      return newType(simpleTypes[0])
    else:
      return newType(simpleTypes)
  else:
    return AnyType

proc loadSignatureFromJson(sigNode: JsonNode): Signature =
  ## Load a single signature from a JSON node
  result = Signature()
  
  if sigNode.hasKey("params"):
    for paramNode in sigNode["params"]:
      let paramName = paramNode["name"].getStr()
      let paramType = parseType(paramNode["type"])
      let isOptional = if paramNode.hasKey("optional"): paramNode["optional"].getBool() else: false
      let isVariadic = if paramNode.hasKey("variadic"): paramNode["variadic"].getBool() else: false
      let description = if paramNode.hasKey("description"): paramNode["description"].getStr() else: ""
      
      result.params.add(Parameter(
        name: paramName,
        bmath_type: paramType,
        isOptional: isOptional,
        isVariadic: isVariadic,
        description: description
      ))
  
  if sigNode.hasKey("returns"):
    result.returnType = parseType(sigNode["returns"])
  else:
    result.returnType = AnyType

proc loadStdlibSignatures(): Table[string, LoadedFunctionData] =
  ## Load all stdlib signatures from the embedded JSON
  ##
  ## Returns:
  ## - A table mapping function names to their function data
  result = initTable[string, LoadedFunctionData]()
  
  let rootNode = parseJson(stdlibSignaturesJson)
  
  if not rootNode.hasKey("functions"):
    return
  
  let functionsNode = rootNode["functions"]
  for funcName, funcData in functionsNode.pairs:
    var funcInfo = LoadedFunctionData()
    
    if funcData.hasKey("description"):
      funcInfo.metadata.description = funcData["description"].getStr()
    
    if funcData.hasKey("examples"):
      for example in funcData["examples"]:
        funcInfo.metadata.examples.add(example.getStr())
    
    if funcData.hasKey("signatures"):
      for sigNode in funcData["signatures"]:
        funcInfo.signatures.add(loadSignatureFromJson(sigNode))
    
    result[funcName] = funcInfo

# Cache loaded signatures (initialized once at runtime)
var signaturesCache {.global.}: Table[string, LoadedFunctionData]
var cacheInitialized {.global.} = false

proc initSignaturesCache*() =
  ## Initialize the signatures cache from embedded JSON
  if not cacheInitialized:
    signaturesCache = loadStdlibSignatures()
    cacheInitialized = true

proc getSignaturesFor*(funcName: string): seq[Signature] =
  ## Get signatures for a given function name
  ##
  ## Parameters:
  ## - funcName: Name of the function
  ##
  ## Returns:
  ## - Sequence of signatures for the function, or empty if not found
  if not cacheInitialized:
    initSignaturesCache()
  
  if signaturesCache.hasKey(funcName):
    return signaturesCache[funcName].signatures
  else:
    return @[]

proc getMetadataFor*(funcName: string): FunctionMetadata =
  ## Get metadata for a given function name
  ##
  ## Parameters:
  ## - funcName: Name of the function
  ##
  ## Returns:
  ## - Function metadata, or empty if not found
  if not cacheInitialized:
    initSignaturesCache()
  
  if signaturesCache.hasKey(funcName):
    return signaturesCache[funcName].metadata
  else:
    return FunctionMetadata()

proc getDescriptionFor*(funcName: string): string =
  ## Get description for a given function name
  ##
  ## Parameters:
  ## - funcName: Name of the function
  ##
  ## Returns:
  ## - Description string, or empty if not found
  if not cacheInitialized:
    initSignaturesCache()
  
  if signaturesCache.hasKey(funcName):
    return signaturesCache[funcName].metadata.description
  else:
    return ""

proc getAllFunctionNames*(): seq[string] =
  ## Get all function names that have signatures defined
  ##
  ## Returns:
  ## - Sequence of all function names
  if not cacheInitialized:
    initSignaturesCache()
  
  result = @[]
  for name in signaturesCache.keys:
    result.add(name)
