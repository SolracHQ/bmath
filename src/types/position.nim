from core import Position
export Position

proc pos*(line, column: int, filePath: string = "<expression>"): Position =
  ## Creates a new source position with optional file path
  result.line = line
  result.column = column
  result.filePath = filePath

proc `$`*(pos: Position): string =
  ## Returns human-readable string representation of source position
  if pos.filePath != "":
    pos.filePath & ":" & $pos.line & ":" & $pos.column
  else:
    $pos.line & ":" & $pos.column

template `==`*(a, b: Position): bool =
  ## Compares two source positions for equality
  a.line == b.line and a.column == b.column
