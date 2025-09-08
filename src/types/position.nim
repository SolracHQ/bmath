from core import Position
export Position

proc pos*(line, column: int): Position =
  ## Creates a new source position
  result.line = line
  result.column = column

proc `$`*(pos: Position): string =
  ## Returns human-readable string representation of source position
  $pos.line & ":" & $pos.column

template `==`*(a, b: Position): bool =
  ## Compares two source positions for equality
  a.line == b.line and a.column == b.column
