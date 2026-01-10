#!/bin/bash
# Smart "read before edit" check with time-based caching
#
# This hook tracks which files have been read recently and only warns
# if the file hasn't been read in the last N tool calls or M seconds.

CACHE_DIR="${HOME}/.claude/cache/read-files"
CACHE_TTL_SECONDS=300  # 5 minutes
MAX_CACHED_FILES=50

# Create cache directory if needed
mkdir -p "$CACHE_DIR"

# Get file path from tool input
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .filePath // empty')

# If no file path, allow the edit
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Normalize path
FILE_PATH=$(realpath "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")

# Skip check for test files - lower risk, caught by test runs
if [[ "$FILE_PATH" == *"_test.dart" ]] || [[ "$FILE_PATH" == */test/* ]]; then
    exit 0
fi

# Create a safe filename for the cache
CACHE_KEY=$(echo "$FILE_PATH" | md5 | cut -c1-16)
CACHE_FILE="$CACHE_DIR/$CACHE_KEY"

# Check if file was read recently
if [[ -f "$CACHE_FILE" ]]; then
    CACHED_PATH=$(cat "$CACHE_FILE" 2>/dev/null | head -1)
    CACHED_TIME=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
    CURRENT_TIME=$(date +%s)
    AGE=$((CURRENT_TIME - CACHED_TIME))

    if [[ "$CACHED_PATH" == "$FILE_PATH" ]] && [[ $AGE -lt $CACHE_TTL_SECONDS ]]; then
        # File was read recently, allow edit silently
        exit 0
    fi
fi

# File not in cache or cache expired - remind to read first
echo "⚠️ File not read recently: $(basename "$FILE_PATH")"
echo "Consider reading it first to verify context (cache TTL: ${CACHE_TTL_SECONDS}s)"

# Don't block, just warn
exit 0
