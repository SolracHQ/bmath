# empty

import std/[json, strutils, os, times, tables]

import pipeline/lexer
import pipeline/parser
import types/errors
import types/position
import types/token
import types/core

# Per-document caches: tokens, ASTs and the latest text. Updated on didOpen / didChange
var docTokens*: Table[string, seq[Token]] = initTable[string, seq[Token]]()
var docASTs*: Table[string, seq[Expression]] = initTable[string, seq[Expression]]()
var docTexts*: Table[string, string] = initTable[string, string]()

## Minimal LSP server for BMath (stdio JSON-RPC)
## Supports: initialize, shutdown, exit, textDocument/didOpen, textDocument/didChange, textDocument/hover

proc readMessageRaw(): string =
  ## Read LSP framed message from stdin and return the raw JSON body.
  var contentLen = 0
  while true:
    var line = stdin.readLine()
    if line.len == 0:
      break
    let s = line.strip()
    if s.len == 0:
      break
    if s.startsWith("Content-Length:"):
      let parts = s.split(':')
      if parts.len >= 2:
        try:
          contentLen = parts[1].strip().parseInt()
        except:
          contentLen = 0
  if contentLen <= 0:
    return ""
  var buf = newString(contentLen)
  # fill string with characters read from stdin (portable)
  setLen(buf, contentLen)
  for i in 0 ..< contentLen:
    buf[i] = stdin.readChar()
  return buf

proc sendJson(node: JsonNode) =
  let txt = $node
  let header = "Content-Length: " & $txt.len & "\r\n\r\n"
  stdout.write(header & txt)
  # Ensure the response is flushed so the LSP client receives it promptly.
  flushFile(stdout)

proc posToRange(p: Position): JsonNode =
  ## Convert internal Position (1-based) to LSP range (0-based)
  result =
    %*{
      "start": {"line": p.line - 1, "character": max(0, p.column - 1)},
      "end": {"line": p.line - 1, "character": max(0, p.column)},
    }

proc publishDiagnostics(uri: string, diagnostics: seq[JsonNode]) =
  let notif =
    %*{
      "jsonrpc": "2.0",
      "method": "textDocument/publishDiagnostics",
      "params": {"uri": uri, "diagnostics": diagnostics},
    }
  sendJson(notif)

proc writeLog(msg: string) =
  ## Append a timestamped message to the fixed log file. Non-fatal on error.
  let t = now()
  let line = $(t) & " - " & msg & "\n"
  try:
    # Write diagnostics/logging to stderr so the client or wrapper can capture it.
    stderr.write(line)
    flushFile(stderr)
  except:
    discard

proc makeDiagnostic(msg: string, p: Position): JsonNode =
  result =
    %*{
      "range": {
        "start": {"line": p.line - 1, "character": max(0, p.column - 1)},
        "end": {"line": p.line - 1, "character": max(0, p.column)},
      },
      "severity": 1,
      "message": msg,
    }

proc analyzeText(uri: string, text: string) =
  ## Tokenize and parse the given text and publish diagnostics (empty if ok).
  var diagnostics: seq[JsonNode] = @[]
  writeLog("analyzeText: starting for " & uri & " (len=" & $text.len & ")")

  # Accumulate tokens and ASTs for caching and richer hover info
  var tokensAcc: seq[Token] = @[]
  var astAcc: seq[Expression] = @[]

  var lx = newLexer(text)
  # The lexer/tokenizer supports returning tokens for one expression at a time.
  # Loop until input exhausted so we capture diagnostics for each expression.
  while not lx.atEnd:
    try:
      let tokens = lx.tokenizeExpression()
      writeLog("tokenizeExpression returned " & $tokens.len & " tokens")
      if tokens.len == 0:
        continue
      # collect tokens for the whole document
      for t in tokens:
        tokensAcc.add(t)
      let ast = parse(tokens)
      # Use the expression position (if present) to optionally attach info-level diagnostics
      if ast != nil:
        let p = ast.position
        # For now we only log successful parse positions; no error diagnostic needed
        writeLog("parse succeeded at line=" & $p.line & " col=" & $p.column)
        astAcc.add(ast)
    except BMathError as be:
      var p = Position(line: 1, column: 1)
      if be.stack.len > 0:
        p = be.stack[0]
      writeLog("BMathError: " & be.msg & " at " & $p.line & ":" & $p.column)
      diagnostics.add(makeDiagnostic(be.msg, p))
    except Exception as e:
      writeLog("Exception: " & e.msg)
      diagnostics.add(makeDiagnostic(e.msg, Position(line: 1, column: 1)))

  # Cache results for this document so hover can use them without re-lexing/parsing
  docTokens[uri] = tokensAcc
  docASTs[uri] = astAcc
  docTexts[uri] = text

  # Publish accumulated diagnostics (empty seq means no diagnostics)
  writeLog("analyzeText: publishing " & $diagnostics.len & " diagnostics for " & uri)
  publishDiagnostics(uri, diagnostics)

proc findTokenHover(uri: string, text: string, line0: int, char0: int): string =
  ## Return a short description for the token at the given 0-based position.
  try:
    var allTokens: seq[Token] = @[]
    if docTokens.hasKey(uri):
      allTokens = docTokens[uri]
    else:
      # fallback: lex the provided text
      var lx = newLexer(text)
      while not lx.atEnd:
        let toks = lx.tokenizeExpression()
        if toks.len == 0:
          continue
        for t in toks:
          allTokens.add(t)

    writeLog(
      "findTokenHover: tokens=" & $allTokens.len & " at " & $line0 & "," & $char0
    )
    var bestIndex = -1
    for i in 0 ..< allTokens.len:
      let t = allTokens[i]
      if t.position.line - 1 == line0 and t.position.column - 1 <= char0:
        if bestIndex == -1 or t.position.column > allTokens[bestIndex].position.column:
          bestIndex = i
    if bestIndex == -1:
      return ""
    let best = allTokens[bestIndex]
    # Build richer description using cached ASTs when available
    case best.kind
    of tkIdent:
      var info = "identifier: " & best.name
      if docASTs.hasKey(uri):
        let asts = docASTs[uri]
        for a in asts:
          if a.position.line == best.position.line and
              a.position.column == best.position.column:
            info.add(" (AST: " & $(a.kind) & ")")
            break
      return info
    of tkNumber:
      if best.value.kind == vkNumber:
        case best.value.number.kind
        of nkInteger:
          return "integer literal: " & $best.value.number.integer
        of nkReal:
          return "real literal: " & $best.value.number.real
        of nkComplex:
          return "complex literal"
      else:
        return "number literal"
    of tkString:
      return "string literal: " & best.value.content
    else:
      return $best.kind
  except Exception:
    return ""

proc handleRequest(j: JsonNode) =
  if j.hasKey("method"):
    let m = j["method"].getStr()
    # Log incoming methods to help debugging from the fixed log file
    try:
      writeLog("handleRequest: method=" & m)
    except:
      discard
    if m == "initialize":
      let id = j["id"]
      # Log destination: stderr (writeLog writes to stderr)
      writeLog("Logging initialized to stderr")
      let resp =
        %*{
          "jsonrpc": "2.0",
          "id": id,
          "result": {"capabilities": {"textDocumentSync": 1, "hoverProvider": true}},
        }
      sendJson(resp)
    elif m == "textDocument/didOpen":
      let uri = j["params"]["textDocument"]["uri"].getStr()
      let txt = j["params"]["textDocument"]["text"].getStr()
      analyzeText(uri, txt)
    elif m == "textDocument/didChange":
      let uri = j["params"]["textDocument"]["uri"].getStr()
      let txt = j["params"]["contentChanges"][0]["text"].getStr()
      analyzeText(uri, txt)
    elif m == "shutdown":
      # respond with null result
      if j.hasKey("id"):
        let resp = %*{"jsonrpc": "2.0", "id": j["id"], "result": nil}
        sendJson(resp)

  # handle requests with response (hover)
  if j.hasKey("method") and j["method"].getStr() == "textDocument/hover":
    let id = j["id"]
    let uri = j["params"]["textDocument"]["uri"].getStr()
    let line = j["params"]["position"]["line"].getInt()
    let character = j["params"]["position"]["character"].getInt()
    # Need the text: do we have it? Prefer cached text, else try to read from workspace file
    var text = ""
    if docTexts.hasKey(uri):
      text = docTexts[uri]
    else:
      try:
        let path = uri.replace("file://", "")
        if fileExists(path):
          text = readFile(path)
      except:
        discard
    var contents = ""
    if text.len > 0:
      contents = findTokenHover(uri, text, line, character)
    if contents.len == 0:
      contents = "(no hover information)"
    let resp =
      %*{
        "jsonrpc": "2.0",
        "id": id,
        "result": {"contents": {"kind": "plaintext", "value": contents}},
      }
    sendJson(resp)

when isMainModule:
  # Main loop
  while true:
    writeLog("Waiting for LSP message...")
    let raw = readMessageRaw()
    writeLog("Received raw message: " & raw)
    if raw.len == 0:
      continue
    var ok = true
    var j: JsonNode
    try:
      j = parseJson(raw)
    except:
      continue
    handleRequest(j)
