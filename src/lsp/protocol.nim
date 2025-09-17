## protocol.nim - LSP Protocol Communication
##
## Handles low-level LSP protocol communication including:
## - Reading framed messages from stdin
## - Sending responses and notifications to stdout
## - Message parsing and error handling
## - Logging utilities

import std/[json, strutils, strformat, times]
import types
export json

# Logging utility
proc writeLog*(msg: string) =
  ## Write timestamped log message to stderr
  let timestamp = now().format("yyyy-MM-dd HH:mm:ss")
  try:
    stderr.writeLine(&"[{timestamp}] BMath LSP: {msg}")
    stderr.flushFile()
  except:
    discard

# LSP Protocol Communication
proc readMessageRaw*(): string =
  ## Read LSP framed message from stdin and return the raw JSON body
  var contentLen = 0

  # Read headers
  while true:
    let line = stdin.readLine().strip()
    if line.len == 0:
      break

    if line.startsWith("Content-Length:"):
      let parts = line.split(":")
      if parts.len >= 2:
        try:
          contentLen = parseInt(parts[1].strip())
        except ValueError:
          writeLog("Invalid Content-Length format: " & line)
          return ""

  if contentLen <= 0:
    writeLog("Invalid content length: " & $contentLen)
    return ""

  # Read body
  var body = newString(contentLen)
  for i in 0 ..< contentLen:
    body[i] = stdin.readChar()

  return body

proc parseRequest*(rawMessage: string): LSPRequest =
  ## Parse raw LSP message into structured request
  try:
    let json = parseJson(rawMessage)

    if not json.hasKey("method"):
      raise newException(ValueError, "Missing method field")

    let `method` = json["method"].getStr()
    let params =
      if json.hasKey("params"):
        json["params"]
      else:
        newJNull()

    if json.hasKey("id") and json["id"] != newJNull():
      # It's a request (requires response)
      result =
        LSPRequest(kind: rkRequest, id: json["id"], `method`: `method`, params: params)
    else:
      # It's a notification (no response needed)
      result = LSPRequest(kind: rkNotification, `method`: `method`, params: params)
  except JsonParsingError as e:
    writeLog(&"JSON parsing error: {e.msg}")
    raise
  except ValueError as e:
    writeLog(&"Request parsing error: {e.msg}")
    raise

proc sendResponse*(response: JsonNode) =
  ## Send LSP response to client via stdout
  let content = $response
  let header = "Content-Length: " & $content.len & "\r\n\r\n"
  stdout.write(header & content)
  stdout.flushFile()

proc sendNotification*(`method`: string, params: JsonNode) =
  ## Send LSP notification to client
  let notification = %*{"jsonrpc": "2.0", "method": `method`, "params": params}
  sendResponse(notification)

proc sendError*(id: JsonNode, code: int, message: string) =
  ## Send LSP error response to client
  let error =
    %*{"jsonrpc": "2.0", "id": id, "error": {"code": code, "message": message}}
  sendResponse(error)

proc sendSuccess*(id: JsonNode, result: JsonNode) =
  ## Send successful LSP response to client
  let response = %*{"jsonrpc": "2.0", "id": id, "result": result}
  sendResponse(response)

proc sendSuccessNull*(id: JsonNode) =
  ## Send successful LSP response with null result
  sendSuccess(id, newJNull())

# URI utilities
proc extractFilePath*(uri: string): string =
  ## Extract file path from LSP URI
  result = uri
  if result.startsWith("file://"):
    result = result[7 ..^ 1]
    # Handle URL decoding if needed
    result = result.replace("%20", " ")
    result = result.replace("%3A", ":")

# LSP Error Codes (from LSP specification)
const
  LSP_PARSE_ERROR* = -32700
  LSP_INVALID_REQUEST* = -32600
  LSP_METHOD_NOT_FOUND* = -32601
  LSP_INVALID_PARAMS* = -32602
  LSP_INTERNAL_ERROR* = -32603
  LSP_SERVER_NOT_INITIALIZED* = -32002
  LSP_UNKNOWN_ERROR* = -32001
