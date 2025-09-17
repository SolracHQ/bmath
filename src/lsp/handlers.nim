## handlers.nim - LSP Request Handlers
##
## Contains all LSP request and notification handlers.
## Each handler is responsible for a specific LSP method.

import std/[json, os, strformat, sequtils]
import types
import protocol
import diagnostics
import hover
export protocol

# Server state
var serverInitialized* = false

# Initialization handlers
proc handleInitialize*(id: JsonNode, params: JsonNode): JsonNode =
  ## Handle initialize request
  writeLog("Handling initialize request")

  result =
    %*{
      "jsonrpc": "2.0",
      "id": id,
      "result": {
        "capabilities": {
          "textDocumentSync": {
            "openClose": true,
            "change": 2, # Incremental
            "save": true,
          },
          "hoverProvider": true,
          "diagnosticProvider": {
            "identifier": "bmath",
            "interFileDependencies": false,
            "workspaceDiagnostics": false,
          },
        },
        "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
      },
    }

proc handleInitialized*(params: JsonNode) =
  ## Handle initialized notification
  writeLog("Client initialized")
  serverInitialized = true

proc handleShutdown*(id: JsonNode): JsonNode =
  ## Handle shutdown request
  writeLog("Handling shutdown request")
  serverInitialized = false
  result = %*{"jsonrpc": "2.0", "id": id, "result": newJNull()}

proc handleExit*() =
  ## Handle exit notification
  writeLog("Server exiting")
  quit(0)

# Text document handlers
proc handleDidOpen*(params: JsonNode) =
  ## Handle textDocument/didOpen notification
  if not params.hasKey("textDocument"):
    writeLog("didOpen: Missing textDocument")
    return

  let doc = params["textDocument"]
  if not (doc.hasKey("uri") and doc.hasKey("text")):
    writeLog("didOpen: Missing uri or text")
    return

  let uri = doc["uri"].getStr()
  let text = doc["text"].getStr()

  writeLog(&"Document opened: {uri}")

  # Analyze and publish diagnostics
  analyzeBMathText(uri, text)

proc handleDidChange*(params: JsonNode) =
  ## Handle textDocument/didChange notification
  if not (params.hasKey("textDocument") and params.hasKey("contentChanges")):
    writeLog("didChange: Missing required parameters")
    return

  let doc = params["textDocument"]
  let changes = params["contentChanges"]

  if not doc.hasKey("uri") or changes.len == 0:
    writeLog("didChange: Missing uri or no changes")
    return

  # For incremental sync, we'd need to apply changes
  # For now, assume full document sync (the last change contains full text)
  let lastChange = changes[changes.len - 1]
  if not lastChange.hasKey("text"):
    writeLog("didChange: No full text in change")
    return

  let uri = doc["uri"].getStr()
  let text = lastChange["text"].getStr()

  writeLog(&"Document changed: {uri}")

  # Re-analyze and publish diagnostics
  analyzeBMathText(uri, text)

proc handleDidSave*(params: JsonNode) =
  ## Handle textDocument/didSave notification
  if not params.hasKey("textDocument"):
    return

  let doc = params["textDocument"]
  if not doc.hasKey("uri"):
    return

  let uri = doc["uri"].getStr()
  writeLog(&"Document saved: {uri}")

  # Re-analyze from file for saved version
  try:
    let filePath = extractFilePath(uri)
    if fileExists(filePath):
      let text = readFile(filePath)
      analyzeBMathText(uri, text)
  except Exception as e:
    writeLog(&"Error reading saved file {uri}: {e.msg}")

proc handleDidClose*(params: JsonNode) =
  ## Handle textDocument/didClose notification
  if not params.hasKey("textDocument"):
    return

  let doc = params["textDocument"]
  if not doc.hasKey("uri"):
    return

  let uri = doc["uri"].getStr()
  writeLog(&"Document closed: {uri}")

  # Clear diagnostics for closed document
  publishDiagnostics(uri, @[])

# Language feature handlers
proc handleHover*(id: JsonNode, params: JsonNode): JsonNode =
  ## Handle textDocument/hover request
  if not (params.hasKey("textDocument") and params.hasKey("position")):
    sendError(id, LSP_INVALID_PARAMS, "Invalid parameters")
    return %*{"jsonrpc": "2.0", "id": id, "result": newJNull()}

  let doc = params["textDocument"]
  let pos = params["position"]

  if not (doc.hasKey("uri") and pos.hasKey("line") and pos.hasKey("character")):
    return %*{"jsonrpc": "2.0", "id": id, "result": newJNull()}

  let uri = doc["uri"].getStr()
  let line = pos["line"].getInt()
  let character = pos["character"].getInt()

  try:
    let filePath = extractFilePath(uri)
    let text =
      if fileExists(filePath):
        readFile(filePath)
      else:
        ""

    let hoverText = provideHoverInfo(filePath, text, line, character)

    if hoverText.len > 0:
      result =
        %*{
          "jsonrpc": "2.0",
          "id": id,
          "result": {"contents": {"kind": "markdown", "value": hoverText}},
        }
    else:
      result = %*{"jsonrpc": "2.0", "id": id, "result": newJNull()}
  except Exception as e:
    writeLog(&"Error in handleHover: {e.msg}")
    result = %*{"jsonrpc": "2.0", "id": id, "result": newJNull()}

proc handleTextDocumentDiagnostic*(id: JsonNode, params: JsonNode): JsonNode =
  ## Handle textDocument/diagnostic request (LSP 3.17 pull-based diagnostics)
  if not params.hasKey("textDocument"):
    sendError(id, LSP_INVALID_PARAMS, "Invalid parameters")
    return %*{"jsonrpc": "2.0", "id": id, "result": newJNull()}

  let doc = params["textDocument"]
  if not doc.hasKey("uri"):
    return %*{"jsonrpc": "2.0", "id": id, "result": newJNull()}

  let uri = doc["uri"].getStr()

  try:
    let filePath = extractFilePath(uri)
    if not fileExists(filePath):
      return %*{"jsonrpc": "2.0", "id": id, "result": newJNull()}

    let text = readFile(filePath)
    let lspDiagnostics = getDiagnosticsForFile(uri, text)
    let diagnosticsJson = lspDiagnostics.mapIt(it.toJson())

    result =
      %*{
        "jsonrpc": "2.0", "id": id, "result": {"kind": "full", "items": diagnosticsJson}
      }
  except Exception as e:
    writeLog(&"Error in handleTextDocumentDiagnostic: {e.msg}")
    result = %*{"jsonrpc": "2.0", "id": id, "result": newJNull()}

# Workspace handlers
proc handleDidChangeConfiguration*(params: JsonNode) =
  ## Handle workspace/didChangeConfiguration notification
  writeLog("Configuration changed")
  # Future: read BMath-specific configuration settings

proc handleSetTrace*(params: JsonNode) =
  ## Handle $/setTrace notification  
  if params.hasKey("value"):
    let value = params["value"].getStr()
    writeLog(&"Trace level set to: {value}")
  else:
    writeLog("Trace level changed")

# Main request dispatcher
proc handleRequest*(request: LSPRequest): JsonNode =
  ## Main request handler dispatcher
  try:
    # Allow initialize, initialized, and exit even when not initialized
    if not serverInitialized and
        request.`method` notin ["initialize", "initialized", "exit"]:
      case request.kind
      of rkRequest:
        sendError(request.id, LSP_SERVER_NOT_INITIALIZED, "Server not initialized")
        return newJNull()
      of rkNotification:
        return newJNull()

    writeLog(&"Handling method: {request.`method`}")

    case request.`method`
    of "initialize":
      if request.kind == rkRequest:
        return handleInitialize(request.id, request.params)
    of "initialized":
      handleInitialized(request.params)
    of "shutdown":
      if request.kind == rkRequest:
        return handleShutdown(request.id)
    of "exit":
      handleExit()
    of "textDocument/didOpen":
      handleDidOpen(request.params)
    of "textDocument/didChange":
      handleDidChange(request.params)
    of "textDocument/didSave":
      handleDidSave(request.params)
    of "textDocument/didClose":
      handleDidClose(request.params)
    of "textDocument/hover":
      if request.kind == rkRequest:
        return handleHover(request.id, request.params)
    of "textDocument/diagnostic":
      if request.kind == rkRequest:
        return handleTextDocumentDiagnostic(request.id, request.params)
    of "workspace/didChangeConfiguration":
      handleDidChangeConfiguration(request.params)
    of "$/setTrace":
      handleSetTrace(request.params)
    else:
      writeLog(&"Unknown method: {request.`method`}")
      if request.kind == rkRequest:
        sendError(
          request.id, LSP_METHOD_NOT_FOUND, "Method not found: " & request.`method`
        )
  except Exception as e:
    writeLog(&"Error handling request: {e.msg}")
    if request.kind == rkRequest:
      sendError(request.id, LSP_INTERNAL_ERROR, "Internal error: " & e.msg)

  return newJNull()
