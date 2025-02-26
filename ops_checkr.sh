#!/bin/bash
set -ex

# Output files to accumulate the output (clean them first)
OUT_WITH="with_optimizations.txt"
OUT_WITHOUT="without_optimizations.txt"
OUT_AST_WITH="with_optimizations_ast.txt"
OUT_AST_WITHOUT="without_optimizations_ast.txt"
DEFAULT_BINARY="bin/bm"
WITH_BINARY="bin/bm_with"
WITHOUT_BINARY="bin/bm_without"
rm -f "$OUT_WITH" "$OUT_WITHOUT" "$OUT_AST_WITH" "$OUT_AST_WITHOUT" "$WITH_BINARY" "$WITHOUT_BINARY"

# Compiles with optimizations
nimble build -d:release -d:printAst
mv "$DEFAULT_BINARY" "$WITH_BINARY"
# Compiles without optimizations
nimble build -d:release -d:disableBMathOpt -d:printAst
mv "$DEFAULT_BINARY" "$WITHOUT_BINARY"

# Process every file in the examples folder
for SCRIPT in examples/*.bm; do
  SCRIPT_NAME=$(basename "$SCRIPT")
  # Write a header to both cumulative files
  echo "--- $SCRIPT_NAME ---" | tee -a "$OUT_WITH" "$OUT_WITHOUT"

  # Build and execute with optimizations
  echo "Output with optimizations for $SCRIPT_NAME:" | tee -a "$OUT_WITH" "$OUT_AST_WITH"
  $WITH_BINARY -f:"$SCRIPT" >> "$OUT_WITH" 2>> "$OUT_AST_WITH"

  # Build and execute without optimizations
  echo "Output without optimizations for $SCRIPT_NAME:" | tee -a "$OUT_WITHOUT" "$OUT_AST_WITHOUT"
  $WITHOUT_BINARY -f:"$SCRIPT" >> "$OUT_WITHOUT" 2>> "$OUT_AST_WITHOUT"

  echo "" >> "$OUT_WITH"
  echo "" >> "$OUT_WITHOUT"
done

# Open the diff view comparing the two files
code --diff "$OUT_WITHOUT" "$OUT_WITH"
code --diff "$OUT_AST_WITHOUT" "$OUT_AST_WITH"
sleep 5

# Clean up
rm "$OUT_WITH" "$OUT_WITHOUT" "$WITH_BINARY" "$WITHOUT_BINARY" "$OUT_AST_WITH" "$OUT_AST_WITHOUT"