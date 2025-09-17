## span.nim - Enhanced position tracking with character length
##
## Provides precise token boundaries for better error highlighting
## and LSP support.

import position

type Span* = object
  ## Represents a span of text in source code with start position and length
  start*: Position ## Starting position of the span
  length*: int ## Character length of the span

proc newSpan*(start: Position, length: int): Span {.inline.} =
  ## Creates a new span
  Span(start: start, length: length)

proc newSpan*(
    line, column, length: int, filePath: string = "<expression>"
): Span {.inline.} =
  ## Creates a new span with line/column position and optional file path
  Span(start: Position(line: line, column: column, filePath: filePath), length: length)

proc endPosition*(span: Span): Position =
  ## Returns the end position of the span
  Position(line: span.start.line, column: span.start.column + span.length)

proc contains*(span: Span, pos: Position): bool =
  ## Checks if a position is within this span
  if pos.line != span.start.line:
    return false
  pos.column >= span.start.column and pos.column < span.start.column + span.length

proc `$`*(span: Span): string =
  ## String representation of span
  $span.start & ":" & $span.length
