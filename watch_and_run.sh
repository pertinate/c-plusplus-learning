#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 path/to/main.cpp"
  exit 1
fi

SRC="$1"
SRC_DIR=$(dirname "$SRC")
BIN_NAME=$(basename "$SRC_DIR")

BUILD_DIR="$SRC_DIR/build"
mkdir -p "$BUILD_DIR"

LAST_BUILD_TIMESTAMP="$BUILD_DIR/.last_build"

while true; do
  # Wait for file change event from entr on .cpp/.h/.hpp files
  find "$SRC_DIR" -type f \( -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) | entr -d -n -s '
    # Get newest modification time of all source files
    NEWEST_SRC=$(find "'"$SRC_DIR"'" -type f \( -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) -printf "%T@\n" | sort -nr | head -1)
    
    # Read last build time or zero if none
    LAST_BUILD=0
    if [ -f "'"$LAST_BUILD_TIMESTAMP"'" ]; then
      LAST_BUILD=$(cat "'"$LAST_BUILD_TIMESTAMP"'")
    fi

    # Compare times, recompile only if sources are newer
    if (( $(echo "$NEWEST_SRC > $LAST_BUILD" | bc -l) )); then
      clear
      echo "Compiling '"$SRC"'..."
      g++ "'"$SRC"'" -o "'"$BUILD_DIR/$BIN_NAME"'"
      if [ $? -eq 0 ]; then
        echo "Running '"$BIN_NAME"':"
        "'"$BUILD_DIR/$BIN_NAME"'"
        # Update last build timestamp
        date +%s > "'"$LAST_BUILD_TIMESTAMP"'"
      else
        echo "Compilation failed"
      fi
      echo
      echo "Watching for changes. Press Ctrl+C to stop."
    else
      echo "No source changes detected; skipping build."
    fi
  '
done
