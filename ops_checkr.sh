#!/bin/bash
set -e

# Output files to accumulate the output (clean them first)
OUT_WITH="with_optimizations.txt"
OUT_WITHOUT="without_optimizations.txt"
DEFAULT_BINARY="bin/bm"
WITH_BINARY="bin/bm_with"
WITHOUT_BINARY="bin/bm_without"
rm -f "$OUT_WITH" "$OUT_WITHOUT" "$WITH_BINARY" "$WITHOUT_BINARY"

COMPILATION_FLAGS="-d:printAst -d:danger"

# Compiles with optimizations
nimble build $COMPILATION_FLAGS
mv "$DEFAULT_BINARY" "$WITH_BINARY"
# Compiles without optimizations
nimble build $COMPILATION_FLAGS -d:disableBMathOpt
mv "$DEFAULT_BINARY" "$WITHOUT_BINARY"

# Process every file in the examples folder
for SCRIPT in examples/*.bm; do
  SCRIPT_NAME=$(basename "$SCRIPT")
  # Write a header to both cumulative files
  echo "--- $SCRIPT_NAME ---" | tee -a "$OUT_WITH" "$OUT_WITHOUT"

  # Build and execute with optimizations
  echo "Output with optimizations for $SCRIPT_NAME:" | tee -a "$OUT_WITH"
  $WITH_BINARY -f:"$SCRIPT" >> "$OUT_WITH"

  # Build and execute without optimizations
  echo "Output without optimizations for $SCRIPT_NAME:" | tee -a "$OUT_WITHOUT"
  $WITHOUT_BINARY -f:"$SCRIPT" >> "$OUT_WITHOUT"

  # Benchmark the binaries using hyperfine
  echo "Benchmarking $SCRIPT_NAME with hyperfine:"
  hyperfine -w 3 --runs 10 "$WITH_BINARY -f:$SCRIPT" "$WITHOUT_BINARY -f:$SCRIPT"

  echo "" >> "$OUT_WITH"
  echo "" >> "$OUT_WITHOUT"
done

read -p "Open diff view comparing outputs? (y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  # Open the diff view comparing the two files
  code --diff "$OUT_WITHOUT" "$OUT_WITH"
  sleep 5
fi

# Clean up
rm "$OUT_WITH" "$OUT_WITHOUT" "$WITH_BINARY" "$WITHOUT_BINARY"
