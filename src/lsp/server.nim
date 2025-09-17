## server.nim - Main LSP Server Orchestration
##
## Main entry point for the BMath Language Server.
## Coordinates between protocol handling, request processing, and language features.

import std/[json, strformat]
import types
import protocol
import handlers

proc processMessage(rawMessage: string) =
  ## Process a single LSP message
  try:
    if rawMessage.len == 0:
      return

    let request = parseRequest(rawMessage)
    let response = handleRequest(request)

    # Send response if it's a request (not notification)
    if request.kind == rkRequest and response != newJNull():
      sendResponse(response)
  except JsonParsingError as e:
    writeLog(&"JSON parsing error: {e.msg}")
  except ValueError as e:
    writeLog(&"Request parsing error: {e.msg}")
  except Exception as e:
    writeLog(&"Unexpected error processing message: {e.msg}")

proc runServer*() =
  ## Main server loop
  writeLog("BMath Language Server starting...")
  writeLog(&"Server: {SERVER_NAME} v{SERVER_VERSION}")
  writeLog(&"LSP Version: {LSP_VERSION}")

  try:
    while true:
      let rawMessage = readMessageRaw()
      if rawMessage.len > 0:
        processMessage(rawMessage)
      else:
        # Empty message usually means client disconnected
        writeLog("Received empty message, client may have disconnected")
        break
  except Exception as e:
    writeLog(&"Fatal error in main server loop: {e.msg}")
    quit(1)

  writeLog("Server shutting down")

# Entry point when called as main module
when isMainModule:
  runServer()
