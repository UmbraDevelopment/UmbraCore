#!/bin/bash
# Script to build DocC documentation for all modules in UmbraCore using yq
# Enhanced with multi-module documentation support

# Exit on error
set -e

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "Error: yq is not installed. Please install it with 'brew install yq'"
    echo "Visit https://github.com/mikefarah/yq for more information."
    exit 1
fi

CONFIG_FILE="docc_config.yml"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found."
    exit 1
fi

echo "Building DocC documentation for all modules with Bazelisk..."

# Get output directory from config
OUTPUT_DIR=$(yq '.settings.output_dir' "$CONFIG_FILE")
BUILD_ENV=$(yq '.settings.build_environment' "$CONFIG_FILE")
COMBINED_DIR="${OUTPUT_DIR}/combined"

# Print the targets we're going to build
echo "Building the following DocC targets:"
yq '.targets[].target' "$CONFIG_FILE"

# Build targets individually
echo "Building documentation with Bazelisk..."
TARGET_COUNT=$(yq '.targets | length' "$CONFIG_FILE")

for ((i=0; i<$TARGET_COUNT; i++)); do
    TARGET=$(yq ".targets[$i].target" "$CONFIG_FILE")
    
    # Build the target
    echo "Building target: $TARGET"
    bazelisk build --define=build_environment="$BUILD_ENV" --verbose_failures "$TARGET"
done

# Prepare the output directory
echo "Preparing output directory..."
mkdir -p "$OUTPUT_DIR"
mkdir -p "$COMBINED_DIR"

# Clean existing documentation files using find to avoid permission issues
if [ -d "$OUTPUT_DIR" ]; then
    echo "Cleaning existing documentation files..."
    find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -type d -not -name "combined" -delete 2>/dev/null || echo "Note: Some files could not be deleted, continuing anyway..."
fi

# Process and copy the documentation
echo "Processing documentation archives..."
MODULES_JSON="$COMBINED_DIR/modules.json"
echo "[" > "$MODULES_JSON"

for ((i=0; i<$TARGET_COUNT; i++)); do
    TARGET=$(yq ".targets[$i].target" "$CONFIG_FILE")
    BAZEL_PATH=$(yq ".targets[$i].output" "$CONFIG_FILE")
    MODULE_NAME=$(yq ".targets[$i].module" "$CONFIG_FILE")
    
    # Full path to the doccarchive in bazel-bin
    SOURCE_PATH="bazel-bin/$BAZEL_PATH"
    
    echo "Looking for documentation at: $SOURCE_PATH"
    if [ -d "$SOURCE_PATH" ]; then
        # Process the files with rsync which handles permissions better
        echo "Copying $SOURCE_PATH to $OUTPUT_DIR/${MODULE_NAME}.doccarchive"
        
        # Create the destination directory
        mkdir -p "$OUTPUT_DIR/${MODULE_NAME}.doccarchive"
        
        # Use rsync to copy files with proper permissions
        rsync -a "$SOURCE_PATH/" "$OUTPUT_DIR/${MODULE_NAME}.doccarchive/" || {
            echo "Error using rsync, falling back to cp..."
            cp -R "$SOURCE_PATH"/* "$OUTPUT_DIR/${MODULE_NAME}.doccarchive/" 2>/dev/null
        }
        
        # Add to modules.json
        if [ $i -gt 0 ]; then
            echo "," >> "$MODULES_JSON"
        fi
        
        echo "  {" >> "$MODULES_JSON"
        echo "    \"name\": \"${MODULE_NAME}\"," >> "$MODULES_JSON"
        echo "    \"path\": \"../${MODULE_NAME}.doccarchive\"" >> "$MODULES_JSON"
        echo "  }" >> "$MODULES_JSON"
        
        echo "✅ Copied documentation for $MODULE_NAME"
    else
        echo "⚠️ Warning: Documentation not found at $SOURCE_PATH"
        
        # List contents of bazel-bin to help troubleshoot
        echo "Contents of bazel-bin/$(dirname "$BAZEL_PATH"):"
        ls -la "bazel-bin/$(dirname "$BAZEL_PATH")" 2>/dev/null || echo "Directory not found"
    fi
done

# Close the modules.json file
echo "]" >> "$MODULES_JSON"

# Create a combined index.html file
cat > "$COMBINED_DIR/index.html" << EOF
<!DOCTYPE html>
<html lang="en-GB">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UmbraCore Documentation</title>
    <style>
        :root {
            --primary-color: #0055aa;
            --background-color: #f5f5f5;
            --text-color: #333333;
            --card-background: #ffffff;
            --accent-color: #0077cc;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen,
                Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            line-height: 1.6;
            color: var(--text-color);
            background-color: var(--background-color);
            margin: 0;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        header {
            text-align: center;
            margin-bottom: 40px;
        }
        
        h1 {
            color: var(--primary-color);
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        
        .subtitle {
            font-size: 1.2rem;
            color: #666;
            margin-bottom: 30px;
        }
        
        .modules-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
        }
        
        .module-card {
            background-color: var(--card-background);
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            padding: 20px;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .module-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
        }
        
        .module-name {
            font-size: 1.5rem;
            color: var(--accent-color);
            margin-top: 0;
            margin-bottom: 15px;
        }
        
        .module-link {
            display: inline-block;
            margin-top: 15px;
            padding: 8px 16px;
            background-color: var(--accent-color);
            color: white;
            text-decoration: none;
            border-radius: 4px;
            font-weight: 500;
            transition: background-color 0.3s ease;
        }
        
        .module-link:hover {
            background-color: var(--primary-color);
        }
        
        .combined-doc-section {
            margin-top: 50px;
            padding: 30px;
            background-color: var(--card-background);
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        footer {
            margin-top: 50px;
            text-align: center;
            color: #666;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>UmbraCore Documentation</h1>
            <p class="subtitle">Comprehensive documentation for the UmbraCore framework</p>
        </header>
        
        <div class="modules-grid" id="modules-grid">
            <!-- Module cards will be inserted here via JavaScript -->
        </div>
        
        <div class="combined-doc-section">
            <h2>Combined Documentation</h2>
            <p>View the combined documentation for all UmbraCore modules in a unified interface.</p>
            <a href="combined-docs/" class="module-link">View Combined Documentation</a>
        </div>
        
        <footer>
            <p> 2025 Umbra Development. All rights reserved.</p>
            <p>Generated on <span id="generation-date"></span></p>
        </footer>
    </div>
    
    <script>
        // Fetch and process the modules data
        fetch('modules.json')
            .then(response => response.json())
            .then(modules => {
                const modulesGrid = document.getElementById('modules-grid');
                
                modules.forEach(module => {
                    const card = document.createElement('div');
                    card.className = 'module-card';
                    
                    const moduleName = document.createElement('h3');
                    moduleName.className = 'module-name';
                    moduleName.textContent = module.name;
                    
                    const description = document.createElement('p');
                    description.textContent = "Documentation for the " + module.name + " module";
                    
                    const link = document.createElement('a');
                    link.className = 'module-link';
                    link.href = module.path;
                    link.textContent = 'View Documentation';
                    
                    card.appendChild(moduleName);
                    card.appendChild(description);
                    card.appendChild(link);
                    
                    modulesGrid.appendChild(card);
                });
            })
            .catch(error => {
                console.error('Error loading modules:', error);
                document.getElementById('modules-grid').innerHTML = '<p>Error loading module information. Please try again.</p>';
            });
        
        // Set the generation date
        document.getElementById('generation-date').textContent = new Date().toLocaleDateString('en-GB', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    </script>
</body>
</html>
EOF

# Generate the unified documentation
if command -v xcrun docc &> /dev/null; then
    echo "Creating combined documentation with DocC..."
    
    # Create a temporary directory for combined documentation
    TEMP_DIR=$(mktemp -d)
    
    # Create a unified DocC catalog
    mkdir -p "$TEMP_DIR/UmbraCore.docc"
    
    # Create Info.plist
    cat > "$TEMP_DIR/UmbraCore.docc/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.umbradevelopment.UmbraCore</string>
    <key>CFBundleName</key>
    <string>UmbraCore</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CDDefaultCodeListingLanguage</key>
    <string>swift</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en-GB</string>
</dict>
</plist>
EOF

    # Create README.md
    cat > "$TEMP_DIR/UmbraCore.docc/README.md" << EOF
# UmbraCore

The secure backup and recovery framework.

## Overview

UmbraCore provides a comprehensive set of tools and libraries for implementing secure backup and recovery solutions.

## Topics

### Essentials

- <doc:GettingStarted>

### Modules
EOF

    # Add modules to README.md
    for ((i=0; i<$TARGET_COUNT; i++)); do
        MODULE_NAME=$(yq ".targets[$i].module" "$CONFIG_FILE")
        echo "- ``$MODULE_NAME``" >> "$TEMP_DIR/UmbraCore.docc/README.md"
    done

    # Create GettingStarted.md
    cat > "$TEMP_DIR/UmbraCore.docc/GettingStarted.md" << EOF
# Getting Started with UmbraCore

Learn how to use the UmbraCore framework.

## Overview

UmbraCore is a framework designed for building secure backup and recovery solutions.

## Modules

UmbraCore consists of several modules, each focused on a specific aspect of backup and security:
EOF

    # Add modules to GettingStarted.md
    for ((i=0; i<$TARGET_COUNT; i++)); do
        MODULE_NAME=$(yq ".targets[$i].module" "$CONFIG_FILE")
        echo "- **$MODULE_NAME**: Import with \`import $MODULE_NAME\`" >> "$TEMP_DIR/UmbraCore.docc/GettingStarted.md"
    done

    # Create symbol graph directory
    mkdir -p "$TEMP_DIR/symbol-graphs"
    
    # Copy symbol graphs from individual documentation archives
    for ((i=0; i<$TARGET_COUNT; i++)); do
        MODULE_NAME=$(yq ".targets[$i].module" "$CONFIG_FILE")
        MODULE_PATH="$OUTPUT_DIR/${MODULE_NAME}.doccarchive"
        
        if [ -d "$MODULE_PATH/data/documentation/symbol-graphs" ]; then
            cp -R "$MODULE_PATH/data/documentation/symbol-graphs/"* "$TEMP_DIR/symbol-graphs/" 2>/dev/null || true
        fi
    done
    
    # Run docc to generate combined documentation
    COMBINED_OUTPUT="$COMBINED_DIR/combined-docs"
    mkdir -p "$COMBINED_OUTPUT"
    
    xcrun docc convert "$TEMP_DIR/UmbraCore.docc" \
        --additional-symbol-graph-dir "$TEMP_DIR/symbol-graphs" \
        --fallback-display-name "UmbraCore" \
        --fallback-bundle-identifier "com.umbradevelopment.UmbraCore" \
        --output-path "$COMBINED_OUTPUT" \
        --transform-for-static-hosting

    # Clean up
    rm -rf "$TEMP_DIR"
    
    echo "✅ Combined documentation generated successfully at $COMBINED_OUTPUT"
else
    echo "⚠️ Warning: DocC command not found. Skipping combined documentation generation."
fi

echo "DocC documentation build complete!"
echo "Individual documentation archives are available in $OUTPUT_DIR directory"
echo "Combined documentation is available at $COMBINED_DIR/combined-docs"
