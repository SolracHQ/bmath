type Position* = object ## Source code location information
  line*: int ## 1-based line number in source
  column*: int ## 1-based column number in source

proc newPosition*(line, column: int): Position =
  ## Creates a new source position
  result.line = line
  result.column = column

proc `$`*(pos: Position): string =
  ## Returns human-readable string representation of source position
  $pos.line & ":" & $pos.column
