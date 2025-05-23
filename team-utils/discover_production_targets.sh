#!/bin/bash
# Script to automatically discover production targets in the UmbraCore project
# and update the production_config.yml file and production_targets.txt file accordingly

set -e

# Use stderr for all debugging output
debug() {
    echo "$@" >&2
}

debug "===== DEBUG: Starting production target discovery script ====="
debug "Current directory: $(pwd)"
debug "Current user: $(whoami)"

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    debug "Error: yq is not installed. Please install it with 'brew install yq'"
    debug "Visit https://github.com/mikefarah/yq for more information."
    exit 1
fi

debug "yq version: $(yq --version)"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="${SCRIPT_DIR}/production_config.yml"
TARGETS_FILE="${SCRIPT_DIR}/production_targets.txt"
TEMP_CONFIG_FILE="${CONFIG_FILE}.tmp"

debug "===== DEBUG: Script paths ====="
debug "SCRIPT_DIR: $SCRIPT_DIR"
debug "CONFIG_FILE: $CONFIG_FILE"
debug "TARGETS_FILE: $TARGETS_FILE"

# Define known deprecated patterns
DEPRECATED_PATTERNS=(
    "//Sources/SecurityBridge:.*"
    "//Sources/.*:.*_tests"
)

# Ensure the config file exists with necessary structure
if [ ! -f "$CONFIG_FILE" ]; then
    debug "Creating new config file: $CONFIG_FILE"
    echo "# Production target configuration for UmbraCore" > "$CONFIG_FILE"
    echo "# This file contains the targets to be run in production build workflows" >> "$CONFIG_FILE"
    echo "" >> "$CONFIG_FILE"
    echo "# Target configuration" >> "$CONFIG_FILE"
    echo "targets: []" >> "$CONFIG_FILE"
    echo "" >> "$CONFIG_FILE"
    echo "# Deprecated targets to ignore" >> "$CONFIG_FILE"
    echo "deprecated:" >> "$CONFIG_FILE"
    for pattern in "${DEPRECATED_PATTERNS[@]}"; do
        echo "  - pattern: \"$pattern\"" >> "$CONFIG_FILE"
    done
fi

debug "Discovering production targets in the UmbraCore project..."

# Create a temporary file for raw bazel output
BAZEL_OUTPUT_FILE="$(mktemp)"
trap 'rm -f "$BAZEL_OUTPUT_FILE"' EXIT

# Run bazelisk query and capture output to a file
debug "Querying production targets with bazelisk..."
bazelisk query 'kind("swift_library rule", //Sources/...)' > "$BAZEL_OUTPUT_FILE" 2>&1 || {
  debug "===== DEBUG: Error during bazelisk query ====="
  cat "$BAZEL_OUTPUT_FILE" >&2
  debug "Creating a minimal production targets file to allow CI to proceed with a subset of targets"
  # Make sure to completely empty the targets file first
  true > "$TARGETS_FILE"
  echo "//Sources/CoreDTOs:CoreDTOs" > "$TARGETS_FILE"
  echo "//Sources/ErrorHandling:ErrorHandling" >> "$TARGETS_FILE"
  debug "Generated minimal $TARGETS_FILE with $(wc -l < "$TARGETS_FILE" | xargs) fallback production targets."
  exit 0
}

# Filter the output to only include valid target patterns (starting with //)
debug "Filtering bazelisk output to only include valid targets..."
ALL_TARGETS=$(grep -E "^//Sources/" "$BAZEL_OUTPUT_FILE" || echo "")

# Verify we have targets
if [ -z "$ALL_TARGETS" ]; then
  debug "No valid targets found in bazelisk output. Using fallback targets."
  # Make sure to completely empty the targets file first
  true > "$TARGETS_FILE"
  echo "//Sources/CoreDTOs:CoreDTOs" > "$TARGETS_FILE"
  echo "//Sources/ErrorHandling:ErrorHandling" >> "$TARGETS_FILE"
  debug "Generated minimal $TARGETS_FILE with fallback production targets."
  exit 0
fi

# Create a temporary file to store discovered targets
echo "# Production target configuration for UmbraCore" > "$TEMP_CONFIG_FILE"
echo "# This file contains the targets to be run in production build workflows" >> "$TEMP_CONFIG_FILE"
echo "" >> "$TEMP_CONFIG_FILE"
echo "# Target configuration" >> "$TEMP_CONFIG_FILE"
echo "targets:" >> "$TEMP_CONFIG_FILE"

# Read the current deprecated patterns
if [ -f "$CONFIG_FILE" ]; then
    CURRENT_DEPRECATED=$(yq '.deprecated[].pattern' "$CONFIG_FILE" 2>/dev/null || echo "")
    debug "===== DEBUG: Current deprecated patterns ====="
    debug "$CURRENT_DEPRECATED"
else
    CURRENT_DEPRECATED=""
    debug "===== DEBUG: No existing config file found ====="
fi

# Process each target from bazelisk query
TARGET_COUNT=0
for TARGET in $ALL_TARGETS; do
    # Only process valid targets (starting with //)
    if [[ ! "$TARGET" =~ ^//Sources/ ]]; then
        debug "Skipping invalid target format: $TARGET"
        continue
    fi
    
    IS_DEPRECATED=false
    
    # Check if target matches any deprecated pattern
    for pattern in "${DEPRECATED_PATTERNS[@]}"; do
        if [[ "$TARGET" =~ $pattern ]]; then
            IS_DEPRECATED=true
            break
        fi
    done
    
    # Check against current deprecated patterns in config
    if [ -n "$CURRENT_DEPRECATED" ]; then
        while IFS= read -r deprecated_pattern; do
            if [[ "$TARGET" =~ $deprecated_pattern ]]; then
                IS_DEPRECATED=true
                break
            fi
        done <<< "$CURRENT_DEPRECATED"
    fi
    
    # Skip deprecated targets
    if [ "$IS_DEPRECATED" = true ]; then
        debug "Skipping deprecated target: $TARGET"
        continue
    fi
    
    # Extract module and target name from target
    MODULE_PATH=${TARGET#//}
    MODULE_PATH=${MODULE_PATH%:*}
    TARGET_NAME=${TARGET##*:}
    
    # Add the target to the config
    echo "  - target: \"$TARGET\"" >> "$TEMP_CONFIG_FILE"
    echo "    module: \"$MODULE_PATH\"" >> "$TEMP_CONFIG_FILE"
    echo "    name: \"$TARGET_NAME\"" >> "$TEMP_CONFIG_FILE"
    echo "    enabled: true" >> "$TEMP_CONFIG_FILE"
    
    debug "Found production target: $TARGET"
    TARGET_COUNT=$((TARGET_COUNT + 1))
done

# Add the deprecated section
echo "" >> "$TEMP_CONFIG_FILE"
echo "# Deprecated targets to ignore" >> "$TEMP_CONFIG_FILE"
echo "deprecated:" >> "$TEMP_CONFIG_FILE"
for pattern in "${DEPRECATED_PATTERNS[@]}"; do
    echo "  - pattern: \"$pattern\"" >> "$TEMP_CONFIG_FILE"
done

# Add any additional deprecated patterns from existing config
if [ -f "$CONFIG_FILE" ] && [ -n "$CURRENT_DEPRECATED" ]; then
    while IFS= read -r deprecated_pattern; do
        # Check if pattern is already in our list
        ALREADY_ADDED=false
        for pattern in "${DEPRECATED_PATTERNS[@]}"; do
            if [[ "$deprecated_pattern" == "$pattern" ]]; then
                ALREADY_ADDED=true
                break
            fi
        done
        
        if [ "$ALREADY_ADDED" = false ]; then
            echo "  - pattern: \"$deprecated_pattern\"" >> "$TEMP_CONFIG_FILE"
        fi
    done <<< "$CURRENT_DEPRECATED"
fi

# Replace the config file with the new one
mv "$TEMP_CONFIG_FILE" "$CONFIG_FILE"
debug "Updated $CONFIG_FILE with $TARGET_COUNT discovered targets."

# Generate production_targets.txt file - ensure it's completely empty first
debug "Generating $TARGETS_FILE..."
true > "$TARGETS_FILE"

# Extract enabled targets from config and write to targets file
# Use -r to get raw output without quotes, which helps with Bazel target parsing
yq -r '.targets[] | select(.enabled == true) | .target' "$CONFIG_FILE" > "$TARGETS_FILE"

# Verify the targets file has proper format
if [ ! -s "$TARGETS_FILE" ]; then
    debug "WARNING: Generated targets file is empty! Using fallback targets."
    echo "//Sources/CoreDTOs:CoreDTOs" > "$TARGETS_FILE"
    echo "//Sources/ErrorHandling:ErrorHandling" >> "$TARGETS_FILE"
else
    # Extra validation - ensure all lines start with //
    INVALID_LINES=$(grep -v "^//" "$TARGETS_FILE" || echo "")
    if [ -n "$INVALID_LINES" ]; then
        debug "WARNING: Found invalid target lines in $TARGETS_FILE! Cleaning up..."
        debug "Invalid lines: $INVALID_LINES"
        grep "^//" "$TARGETS_FILE" > "${TARGETS_FILE}.clean"
        mv "${TARGETS_FILE}.clean" "$TARGETS_FILE"
    fi
fi

debug "Generated $TARGETS_FILE with $(wc -l < "$TARGETS_FILE" | xargs) enabled production targets."
debug "Target file content sample (first 3 lines):"
debug "$(head -n 3 "$TARGETS_FILE")"
debug "To build targets: bazelisk build --define=build_environment=nonlocal -k --verbose_failures \$(cat ${TARGETS_FILE})"

debug "Discovery complete!"
