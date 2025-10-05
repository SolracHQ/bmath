## language_knowledge.nim - Load centralized language knowledge from JSON
##
## This module provides utilities to load language elements (keywords, types,
## operators) and their documentation from the language_knowledge.json file,
## which serves as the single source of truth for all language knowledge.
##
## The JSON file is embedded at compile time for zero runtime overhead.

import std/json

type
  KeywordInfo* = object
    name*: string
    category*: string
    description*: string
    syntax*: string
    examples*: seq[string]

  TypeInfo* = object
    name*: string
    category*: string
    description*: string
    examples*: seq[string]

  OperatorInfo* = object
    name*: string
    category*: string
    description*: string
    syntax*: string
    precedence*: int
    examples*: seq[string]

  LanguageKnowledge* = object
    version*: string
    keywords*: seq[KeywordInfo]
    types*: seq[TypeInfo]
    operators*: seq[OperatorInfo]

# Load JSON at compile time
const languageKnowledgeJson = staticRead("../../data/language_knowledge.json")

proc parseKeywordInfo(node: JsonNode): KeywordInfo =
  result.name = node["name"].getStr()
  result.category = node["category"].getStr()
  result.description = node["description"].getStr()
  result.syntax = node["syntax"].getStr()
  result.examples = @[]
  if node.hasKey("examples"):
    for ex in node["examples"]:
      result.examples.add(ex.getStr())

proc parseTypeInfo(node: JsonNode): TypeInfo =
  result.name = node["name"].getStr()
  result.category = node["category"].getStr()
  result.description = node["description"].getStr()
  result.examples = @[]
  if node.hasKey("examples"):
    for ex in node["examples"]:
      result.examples.add(ex.getStr())

proc parseOperatorInfo(node: JsonNode): OperatorInfo =
  result.name = node["name"].getStr()
  result.category = node["category"].getStr()
  result.description = node["description"].getStr()
  result.syntax = node["syntax"].getStr()
  result.precedence = if node.hasKey("precedence"): node["precedence"].getInt() else: 0
  result.examples = @[]
  if node.hasKey("examples"):
    for ex in node["examples"]:
      result.examples.add(ex.getStr())

proc loadLanguageKnowledge(): LanguageKnowledge =
  ## Load language knowledge from embedded JSON
  let rootNode = parseJson(languageKnowledgeJson)
  
  result.version = rootNode["version"].getStr()
  result.keywords = @[]
  result.types = @[]
  result.operators = @[]
  
  # Load keywords
  if rootNode.hasKey("keywords"):
    for kw in rootNode["keywords"]:
      result.keywords.add(parseKeywordInfo(kw))
  
  # Load types
  if rootNode.hasKey("types"):
    for t in rootNode["types"]:
      result.types.add(parseTypeInfo(t))
  
  # Load operators
  if rootNode.hasKey("operators"):
    for op in rootNode["operators"]:
      result.operators.add(parseOperatorInfo(op))

# Cache loaded knowledge (initialized once at runtime)
var knowledgeCache {.global.}: LanguageKnowledge
var cacheInitialized {.global.} = false

proc initLanguageKnowledge*() =
  ## Initialize the language knowledge cache from embedded JSON
  if not cacheInitialized:
    knowledgeCache = loadLanguageKnowledge()
    cacheInitialized = true

proc getKeywords*(): seq[KeywordInfo] =
  ## Get all keyword information
  if not cacheInitialized:
    initLanguageKnowledge()
  return knowledgeCache.keywords

proc getTypes*(): seq[TypeInfo] =
  ## Get all type information
  if not cacheInitialized:
    initLanguageKnowledge()
  return knowledgeCache.types

proc getOperators*(): seq[OperatorInfo] =
  ## Get all operator information
  if not cacheInitialized:
    initLanguageKnowledge()
  return knowledgeCache.operators

proc getKeywordNames*(): seq[string] =
  ## Get list of all keyword names
  if not cacheInitialized:
    initLanguageKnowledge()
  result = @[]
  for kw in knowledgeCache.keywords:
    result.add(kw.name)

proc getTypeNames*(): seq[string] =
  ## Get list of all type names
  if not cacheInitialized:
    initLanguageKnowledge()
  result = @[]
  for t in knowledgeCache.types:
    result.add(t.name)

proc getOperatorSymbols*(): seq[string] =
  ## Get list of all operator symbols
  if not cacheInitialized:
    initLanguageKnowledge()
  result = @[]
  for op in knowledgeCache.operators:
    result.add(op.name)

proc getDocumentation*(symbol: string): string =
  ## Get documentation for any BMath symbol
  ##
  ## Parameters:
  ## - symbol: The symbol to get documentation for
  ##
  ## Returns:
  ## - Documentation string if found, empty string otherwise
  if not cacheInitialized:
    initLanguageKnowledge()
  
  # Check keywords
  for kw in knowledgeCache.keywords:
    if kw.name == symbol:
      return kw.description
  
  # Check types
  for t in knowledgeCache.types:
    if t.name == symbol:
      return t.description
  
  # Check operators
  for op in knowledgeCache.operators:
    if op.name == symbol:
      return op.description
  
  return ""

proc isKeyword*(symbol: string): bool =
  ## Check if symbol is a keyword
  if not cacheInitialized:
    initLanguageKnowledge()
  for kw in knowledgeCache.keywords:
    if kw.name == symbol:
      return true
  return false

proc isType*(symbol: string): bool =
  ## Check if symbol is a type
  if not cacheInitialized:
    initLanguageKnowledge()
  for t in knowledgeCache.types:
    if t.name == symbol:
      return true
  return false

proc isOperator*(symbol: string): bool =
  ## Check if symbol is an operator
  if not cacheInitialized:
    initLanguageKnowledge()
  for op in knowledgeCache.operators:
    if op.name == symbol:
      return true
  return false
