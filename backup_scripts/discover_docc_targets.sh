#!/bin/bash
# Script to automatically discover DocC targets in the UmbraCore project
# and update the docc_config.yml file accordingly

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "Error: yq is not installed. Please install it with 'brew install yq'"
    echo "Visit https://github.com/mikefarah/yq for more information."
    exit 1
fi

CONFIG_FILE="docc_config.yml"
TEMP_CONFIG_FILE="${CONFIG_FILE}.tmp"

# Ensure the config file exists with necessary structure
if [ ! -f "$CONFIG_FILE" ]; then
    echo "# DocC documentation configuration for UmbraCore" > "$CONFIG_FILE"
    echo "# This file contains the targets to build for DocC documentation" >> "$CONFIG_FILE"
    echo "" >> "$CONFIG_FILE"
    echo "targets: []" >> "$CONFIG_FILE"
    echo "" >> "$CONFIG_FILE"
    echo "# Configuration settings" >> "$CONFIG_FILE"
    echo "settings:" >> "$CONFIG_FILE"
    echo "  output_dir: docs/api" >> "$CONFIG_FILE"
    echo "  build_environment: local" >> "$CONFIG_FILE"
fi

echo "Discovering DocC targets in the UmbraCore project..."

# Create a temporary file to store discovered targets
echo "# DocC documentation configuration for UmbraCore" > "$TEMP_CONFIG_FILE"
echo "# This file contains the targets to build for DocC documentation" >> "$TEMP_CONFIG_FILE"
echo "" >> "$TEMP_CONFIG_FILE"
echo "targets:" >> "$TEMP_CONFIG_FILE"

# Find all BUILD.bazel files that contain DocC targets using a safer approach
# Use find with -exec to avoid issues with filenames containing spaces or special characters
find Sources -name "BUILD.bazel" -o -name "BUILD" -type f -exec grep -l "docc_documentation" {} \; | while IFS= read -r build_file; do
    # Extract module directory from the build file path
    module_dir=$(dirname "$build_file")
    module_name=$(basename "$module_dir")
    
    # Handle the case where DocC might be in a subdirectory called Documentation.docc
    if [[ "$module_name" == "Documentation.docc" ]]; then
        parent_dir=$(dirname "$module_dir")
        module_name=$(basename "$parent_dir")
        # Adjust target path for this special case
        target_path="//$module_dir:${module_name}DocC"
        output_path="$module_dir/${module_name}DocC.doccarchive"
    else
        # Regular case
        target_path="//$module_dir:${module_name}DocC"
        output_path="$module_dir/${module_name}DocC.doccarchive"
    fi
    
    # Check for duplicates - only add if not already in the file
    if ! grep -q "$target_path" "$TEMP_CONFIG_FILE"; then
        echo "  - target: $target_path" >> "$TEMP_CONFIG_FILE"
        echo "    output: $output_path" >> "$TEMP_CONFIG_FILE"
        echo "    module: $module_name" >> "$TEMP_CONFIG_FILE"
        
        echo "Discovered target: $target_path"
    else
        echo "Skipping duplicate target: $target_path"
    fi
done

# Add the settings section
echo "" >> "$TEMP_CONFIG_FILE"
echo "# Configuration settings" >> "$TEMP_CONFIG_FILE"
echo "settings:" >> "$TEMP_CONFIG_FILE"
echo "  output_dir: docs/api" >> "$TEMP_CONFIG_FILE"
echo "  build_environment: local" >> "$TEMP_CONFIG_FILE"

# Replace the config file with the new one if targets were found
if grep -q "target:" "$TEMP_CONFIG_FILE"; then
    mv "$TEMP_CONFIG_FILE" "$CONFIG_FILE"
    echo "Updated $CONFIG_FILE with discovered targets."
else
    echo "No DocC targets found. Keeping existing configuration."
    rm "$TEMP_CONFIG_FILE"
fi

echo "Discovery complete!"
