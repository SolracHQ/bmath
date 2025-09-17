## lsp.nim - BMath Language Server Protocol Implementation
##
## Modular BMath LSP server with clean separation of concerns:
## - Protocol communication in lsp/protocol.nim
## - Type definitions in lsp/types.nim  
## - Language knowledge in lsp/bmath_knowledge.nim
## - Diagnostics integration in lsp/diagnostics.nim
## - Hover provider in lsp/hover.nim
## - Completion provider in lsp/completions.nim
## - Request handlers in lsp/handlers.nim
## - Main server loop in lsp/server.nim
##
## This file serves as the main entry point and delegates to the server module.

# Re-export the main entry point from the server module
import lsp/server
export server

# Main entry point when this file is executed directly
when isMainModule:
  runServer()
