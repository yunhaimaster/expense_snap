#!/bin/bash
# Cache the fact that a file was read
#
# Called as a PostToolUse hook for the Read tool.
# Updates the read-files cache so that subsequent Edit calls
# know the file was recently read.

CACHE_DIR="${HOME}/.claude/cache/read-files"
MAX_CACHED_FILES=50

# Create cache directory if needed
mkdir -p "$CACHE_DIR"

# Get file path from tool input
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .filePath // empty')

# If no file path, exit
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Normalize path
FILE_PATH=$(realpath "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")

# Create a safe filename for the cache
CACHE_KEY=$(echo "$FILE_PATH" | md5 | cut -c1-16)
CACHE_FILE="$CACHE_DIR/$CACHE_KEY"

# Write the file path to cache
echo "$FILE_PATH" > "$CACHE_FILE"

# Cleanup old cache files (keep only the most recent MAX_CACHED_FILES)
cd "$CACHE_DIR" 2>/dev/null && ls -t | tail -n +$((MAX_CACHED_FILES + 1)) | xargs rm -f 2>/dev/null

exit 0
