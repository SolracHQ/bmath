## types.nim - LSP Protocol Types and Constants
##
## Defines all LSP protocol types, enums, and constants used throughout
## the BMath Language Server implementation.

import std/json

# LSP Constants
const
  LSP_VERSION* = "3.17.0"
  SERVER_NAME* = "BMath Language Server"
  SERVER_VERSION* = "0.12.0"
  BMATH_VERSION* = "0.12.0"

# LSP Protocol Types
type
  LSPPosition* = object
    line*: int # 0-based
    character*: int # 0-based

  LSPRange* = object
    start*: LSPPosition
    `end`*: LSPPosition

  LSPDiagnostic* = object
    range*: LSPRange
    severity*: int # 1=Error, 2=Warning, 3=Information, 4=Hint
    message*: string
    source*: string

  CompletionItemKind* = enum
    ckText = 1
    ckMethod = 2
    ckFunction = 3
    ckConstructor = 4
    ckField = 5
    ckVariable = 6
    ckClass = 7
    ckInterface = 8
    ckModule = 9
    ckProperty = 10
    ckUnit = 11
    ckValue = 12
    ckEnum = 13
    ckKeyword = 14
    ckSnippet = 15
    ckColor = 16
    ckFile = 17
    ckReference = 18
    ckFolder = 19
    ckEnumMember = 20
    ckConstant = 21
    ckStruct = 22
    ckEvent = 23
    ckOperator = 24
    ckTypeParameter = 25

  CompletionItem* = object
    label*: string
    kind*: CompletionItemKind
    detail*: string
    documentation*: string
    insertText*: string

  # Internal types for request handling
  RequestKind* = enum
    rkRequest ## Request requiring a response
    rkNotification ## Notification (no response)

  LSPRequest* = object
    case kind*: RequestKind
    of rkRequest:
      id*: JsonNode
    of rkNotification:
      discard
    `method`*: string
    params*: JsonNode

# Utility procs for JSON serialization
proc toJson*(pos: LSPPosition): JsonNode =
  %*{"line": pos.line, "character": pos.character}

proc toJson*(range: LSPRange): JsonNode =
  %*{"start": range.start.toJson(), "end": range.`end`.toJson()}

proc toJson*(diagnostic: LSPDiagnostic): JsonNode =
  %*{
    "range": diagnostic.range.toJson(),
    "severity": diagnostic.severity,
    "message": diagnostic.message,
    "source": diagnostic.source,
  }

proc toJson*(item: CompletionItem): JsonNode =
  result =
    %*{
      "label": item.label,
      "kind": item.kind.ord,
      "detail": item.detail,
      "documentation": item.documentation,
    }
  if item.insertText.len > 0:
    result["insertText"] = %item.insertText
