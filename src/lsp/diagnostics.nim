## diagnostics.nim - LSP Diagnostics Integration
##
## Provides integration between BMath's static analysis system and LSP diagnostics.
## Converts BMath diagnostics to LSP format and manages diagnostic publishing.

import std/[strformat, sequtils, json]
import types
import protocol
import ../types/[position]
import ../pipeline/diagnostics as bmathDiag

# Conversion utilities
proc toLSPPosition*(pos: Position): LSPPosition =
  ## Convert BMath Position to LSP Position (0-based)
  LSPPosition(line: pos.line - 1, character: pos.column - 1)

proc toLSPRange*(pos: Position): LSPRange =
  ## Convert single BMath Position to LSP Range
  let lspPos = pos.toLSPPosition()
  LSPRange(start: lspPos, `end`: lspPos)

proc toLSPRange*(start: Position, `end`: Position): LSPRange =
  ## Convert BMath Position range to LSP Range
  LSPRange(start: start.toLSPPosition(), `end`: `end`.toLSPPosition())

proc severityToLSP*(severity: bmathDiag.DiagnosticSeverity): int =
  ## Convert BMath diagnostic severity to LSP severity
  case severity
  of bmathDiag.dsError:
    1
  # LSP Error
  of bmathDiag.dsWarning:
    2
  # LSP Warning
  of bmathDiag.dsInfo:
    3 # LSP Information

proc convertDiagnostic*(diagnostic: bmathDiag.Diagnostic): LSPDiagnostic =
  ## Convert BMath Diagnostic to LSP Diagnostic
  LSPDiagnostic(
    range: diagnostic.position.toLSPRange(),
    severity: diagnostic.severity.severityToLSP(),
    message: diagnostic.message,
    source: "BMath",
  )

# Diagnostic publishing
proc publishDiagnostics*(uri: string, diagnostics: seq[LSPDiagnostic]) =
  ## Publish diagnostics to LSP client
  let diagnosticsJson = diagnostics.mapIt(it.toJson())
  let params = %*{"uri": uri, "diagnostics": diagnosticsJson}
  sendNotification("textDocument/publishDiagnostics", params)

proc analyzeBMathText*(uri: string, text: string) =
  ## Analyze BMath text and publish diagnostics
  writeLog(&"Analyzing document: {uri}")

  try:
    # Use the BMath diagnostics system to analyze the file
    let filePath = extractFilePath(uri)
    let diagnostics = bmathDiag.analyzeFile(filePath, text)
    let lspDiagnostics = diagnostics.map(convertDiagnostic)

    publishDiagnostics(uri, lspDiagnostics)
    writeLog(&"Published {lspDiagnostics.len} diagnostics for {uri}")
  except Exception as e:
    writeLog(&"Error analyzing {uri}: {e.msg}")
    # Publish a single diagnostic about the analysis error
    let errorDiag = LSPDiagnostic(
      range: LSPRange(
        start: LSPPosition(line: 0, character: 0),
        `end`: LSPPosition(line: 0, character: 0),
      ),
      severity: 1, # Error
      message: "Analysis error: " & e.msg,
      source: "BMath",
    )
    publishDiagnostics(uri, @[errorDiag])

proc getDiagnosticsForFile*(uri: string, text: string): seq[LSPDiagnostic] =
  ## Get diagnostics for a file without publishing them
  try:
    let filePath = extractFilePath(uri)
    let diagnostics = bmathDiag.analyzeFile(filePath, text)
    return diagnostics.map(convertDiagnostic)
  except Exception as e:
    writeLog(&"Error getting diagnostics for {uri}: {e.msg}")
    # Return a single error diagnostic
    return
      @[
        LSPDiagnostic(
          range: LSPRange(
            start: LSPPosition(line: 0, character: 0),
            `end`: LSPPosition(line: 0, character: 0),
          ),
          severity: 1, # Error
          message: "Analysis error: " & e.msg,
          source: "BMath",
        )
      ]
