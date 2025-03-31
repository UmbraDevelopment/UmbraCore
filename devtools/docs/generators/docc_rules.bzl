"""
Rules for generating and serving DocC documentation.
"""

load(":build_settings.bzl", "BuildEnvironmentInfo")

def _docc_documentation_impl(ctx):
    """Implementation of docc_documentation rule."""

    # Get build environment info from the build_environment target
    build_env = ctx.attr._build_environment[BuildEnvironmentInfo]
    is_local_build = build_env.is_local

    # Check for build_environment flag to override is_local determination
    build_env_flag = ctx.var.get("define", "")
    if "build_environment=nonlocal" in build_env_flag:
        is_local_build = False

    print("DEBUG: Is local build: %s" % is_local_build)

    if ctx.attr.localonly and not is_local_build:
        # If localonly is True and we're not in a local development environment, skip generating documentation
        print("Skipping DocC documentation for %s (non-local build)" % ctx.attr.module_name)
        return [DefaultInfo(files = depset([]))]

    print("Building DocC documentation for %s (local build or non-localonly target)" % ctx.attr.module_name)

    # Create output directory for DocC archive
    docc_archive = ctx.actions.declare_directory(ctx.label.name + ".doccarchive")

    # Create a temporary directory for DocC inputs
    temp_dir = ctx.actions.declare_directory(ctx.label.name + "_temp")

    # Get all source files
    srcs = ctx.files.srcs

    # Find docc_gen tool
    docc_gen = ctx.executable._docc_gen

    # Find DocC tool
    docc_tool = "/usr/bin/xcrun docc"  # Direct path to DocC tool

    # Build arguments for docc_gen
    args = ctx.actions.args()

    # Add temp_dir argument
    args.add("--temp_dir", temp_dir.path)

    # Add output directory argument
    args.add("--output", docc_archive.path)

    # Add module name
    args.add("--module_name", ctx.attr.module_name)

    # Add DocC tool path
    args.add("--docc_tool", docc_tool)

    # Add symbol graph directory argument if provided
    if ctx.attr.symbol_graph_dir:
        args.add("--symbol_graph_dir", ctx.file.symbol_graph_dir.path)

    # Add additional source directories if provided
    if ctx.attr.additional_source_directories:
        for dir in ctx.files.additional_source_directories:
            args.add("--additional_source_dir", dir.path)

    # Add source files
    for src in srcs:
        args.add("--source", src.path)

    # Add copy flag if requested
    if ctx.attr.copy_sources:
        args.add("--copy")

    # Run docc_gen tool to generate DocC archive
    ctx.actions.run(
        executable = docc_gen,
        arguments = [args],
        inputs = srcs + (ctx.files.additional_source_directories if ctx.attr.additional_source_directories else []) + ([ctx.file.symbol_graph_dir] if ctx.attr.symbol_graph_dir else []),
        outputs = [temp_dir, docc_archive],
        progress_message = "Generating DocC documentation for %s" % ctx.attr.module_name,
    )

    return [DefaultInfo(files = depset([docc_archive]))]

docc_documentation = rule(
    implementation = _docc_documentation_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, doc = "Source files for documentation"),
        "module_name": attr.string(mandatory = True, doc = "Name of the module to document"),
        "symbol_graph_dir": attr.label(allow_single_file = True, doc = "Directory containing symbol graph files"),
        "additional_source_directories": attr.label_list(allow_files = True, doc = "Additional source directories to include"),
        "localonly": attr.bool(default = False, doc = "If True, documentation will only be built in local development environments"),
        "copy_sources": attr.bool(default = True, doc = "Whether to copy source files to temp directory"),
        "_docc_gen": attr.label(
            default = Label("//tools/swift:docc_gen"),
            executable = True,
            cfg = "exec",
        ),
        "_build_environment": attr.label(
            default = Label("//tools/swift:local_environment"),
            providers = [BuildEnvironmentInfo],
        ),
    },
)

def _docc_preview_impl(ctx):
    """Implementation of docc_preview rule."""
    docc_archive = ctx.file.docc_archive

    script = ctx.actions.declare_file(ctx.label.name + ".sh")

    # Create a script to preview the DocC documentation
    script_content = """#!/bin/bash
    # Get the absolute path to the DocC archive
    WORKSPACE_ROOT="$(pwd)"
    DOCC_ARCHIVE_PATH="{docc_archive}"
    
    # If the path is not absolute, make it absolute
    if [[ "$DOCC_ARCHIVE_PATH" != /* ]]; then
        DOCC_ARCHIVE_PATH="$WORKSPACE_ROOT/$DOCC_ARCHIVE_PATH"
    fi
    
    # Source the preview_docc script
    source "{preview_script}" "$DOCC_ARCHIVE_PATH"
    """.format(
        preview_script = ctx.executable._preview_script.path,
        docc_archive = docc_archive.path,
    )

    ctx.actions.write(
        output = script,
        content = script_content,
        is_executable = True,
    )

    # Return runfiles for the script
    runfiles = ctx.runfiles(files = [
        ctx.executable._preview_script,
        docc_archive,
    ])

    return [DefaultInfo(
        executable = script,
        runfiles = runfiles,
    )]

docc_preview = rule(
    implementation = _docc_preview_impl,
    attrs = {
        "docc_archive": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "DocC archive to preview",
        ),
        "_preview_script": attr.label(
            default = Label("//tools/swift:preview_docc.sh"),
            executable = True,
            cfg = "host",
            allow_files = True,
        ),
    },
    executable = True,
    doc = "Create a runnable target that previews DocC documentation",
)

def _docc_serve_impl(ctx):
    """Implementation of docc_serve rule."""
    docc_archive = ctx.file.docc_archive

    script = ctx.actions.declare_file(ctx.label.name + ".sh")

    # Create a script to serve the DocC documentation
    script_content = """#!/bin/bash
    # Get the absolute path to the DocC archive
    WORKSPACE_ROOT="$(pwd)"
    DOCC_ARCHIVE_PATH="{docc_archive}"
    
    # If the path is not absolute, make it absolute
    if [[ "$DOCC_ARCHIVE_PATH" != /* ]]; then
        DOCC_ARCHIVE_PATH="$WORKSPACE_ROOT/$DOCC_ARCHIVE_PATH"
    fi
    
    # Source the serve_docc script
    source "{serve_script}" "$DOCC_ARCHIVE_PATH"
    """.format(
        serve_script = ctx.executable._serve_script.path,
        docc_archive = docc_archive.path,
    )

    ctx.actions.write(
        output = script,
        content = script_content,
        is_executable = True,
    )

    # Return runfiles for the script
    runfiles = ctx.runfiles(files = [
        ctx.executable._serve_script,
        docc_archive,
    ])

    return [DefaultInfo(
        executable = script,
        runfiles = runfiles,
    )]

docc_serve = rule(
    implementation = _docc_serve_impl,
    attrs = {
        "docc_archive": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "DocC archive to serve",
        ),
        "_serve_script": attr.label(
            default = Label("//tools/swift:serve_docc.sh"),
            executable = True,
            cfg = "host",
            allow_files = True,
        ),
    },
    executable = True,
    doc = "Create a runnable target that serves DocC documentation over HTTP",
)

def _docc_gen_impl(ctx):
    """Implementation for the docc_gen executable rule."""
    script = ctx.actions.declare_file(ctx.label.name + ".sh")

    script_content = """#!/bin/bash
    set -e
    
    # Parse arguments
    TEMP_DIR=""
    OUTPUT=""
    MODULE_NAME=""
    DOCC_TOOL=""
    SOURCES=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --copy)
                # --copy flag is just a marker for copy operation, no value needed
                shift
                ;;
            --temp_dir)
                TEMP_DIR="$2"
                shift 2
                ;;
            --output)
                OUTPUT="$2"
                shift 2
                ;;
            --module_name)
                MODULE_NAME="$2"
                shift 2
                ;;
            --docc_tool)
                DOCC_TOOL="$2"
                shift 2
                ;;
            --source)
                SOURCES+=("$2")
                shift 2
                ;;
            *)
                echo "Unknown argument: $1"
                exit 1
                ;;
        esac
    done
    
    # Check required arguments
    if [ -z "$TEMP_DIR" ]; then
        echo "Error: --temp_dir is required"
        exit 1
    fi
    
    if [ -z "$OUTPUT" ]; then
        echo "Error: --output is required"
        exit 1
    fi
    
    if [ -z "$MODULE_NAME" ]; then
        echo "Error: --module_name is required"
        exit 1
    fi
    
    if [ -z "$DOCC_TOOL" ]; then
        echo "Error: --docc_tool is required"
        exit 1
    fi
    
    # Create temporary directory structure
    mkdir -p "$TEMP_DIR/Documentation.docc"
    mkdir -p "$TEMP_DIR/Sources"
    
    # Default documentation catalog if none provided
    if [ ! -f "$TEMP_DIR/Documentation.docc/Info.plist" ]; then
        cat > "$TEMP_DIR/Documentation.docc/Info.plist" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>$MODULE_NAME</string>
    <key>CFBundleName</key>
    <string>$MODULE_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CDDefaultCodeListingLanguage</key>
    <string>swift</string>
</dict>
</plist>
EOL
    fi
    
    # Create default module documentation file
    if [ ! -f "$TEMP_DIR/Documentation.docc/$MODULE_NAME.md" ]; then
        cat > "$TEMP_DIR/Documentation.docc/$MODULE_NAME.md" << EOL
# ``$MODULE_NAME``

Documentation for the $MODULE_NAME module.

## Overview

This is the documentation for the $MODULE_NAME module. This documentation was generated using Apple's DocC and Bazel.

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
EOL
    fi
    
    # Copy source files to temp directory
    echo "Copying source files to temporary directory..."
    for src in "${SOURCES[@]}"; do
        # Skip non-Swift files in source directories
        if [[ "$src" == *"/Sources/"* && ! "$src" == *.swift ]]; then
            continue
        fi
        
        # Determine the destination based on the source path
        if [[ "$src" == *"/Documentation.docc/"* ]]; then
            # Extract the part after Documentation.docc/
            rel_path=$(echo "$src" | awk -F "/Documentation.docc/" '{print $2}')
            dst="$TEMP_DIR/Documentation.docc/$rel_path"
        elif [[ "$src" == *"/Sources/"* ]]; then
            # Extract the part after /Sources/
            rel_path=$(echo "$src" | awk -F "/Sources/" '{print $2}')
            dst="$TEMP_DIR/Sources/$rel_path"
        else
            # For other files, place them at the root of temp dir
            dst="$TEMP_DIR/$(basename "$src")"
        fi
        
        # Create directory if needed
        mkdir -p "$(dirname "$dst")"
        
        # Copy the file
        cp "$src" "$dst"
    done
    
    # Show what we've got
    echo "Contents of temporary directory:"
    find "$TEMP_DIR" -type f | sort
    
    # Check if we have source files
    if [ -d "$TEMP_DIR/Sources" ] && [ "$(find "$TEMP_DIR/Sources" -name "*.swift" | wc -l)" -gt 0 ]; then
        echo "Found source files in $TEMP_DIR/Sources"
    else
        echo "Warning: No Swift source files found in $TEMP_DIR/Sources"
    fi
    
    # Generate documentation
    echo "Approach 1: Using DocC convert directly..."
    if "$DOCC_TOOL" convert "$TEMP_DIR/Documentation.docc" \\
        --output-path "$OUTPUT" \\
        --fallback-display-name "$MODULE_NAME" \\
        --fallback-bundle-identifier "com.umbreproject.$MODULE_NAME" \\
        --fallback-bundle-version "1.0.0" \\
        --additional-symbol-graph-dir "$TEMP_DIR/Sources" \\
        --transform-for-static-hosting; then
        
        echo "DocC conversion succeeded!"
        
        # Process archive for static hosting
        echo "Processing archive for static hosting..."
        # Ensure index.html is present for static hosting
        if [ ! -f "$OUTPUT/index.html" ]; then
            cat > "$OUTPUT/index.html" << EOL
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="refresh" content="0;URL='documentation/index.html'" />
</head>
<body>
    <p>Redirecting to documentation...</p>
</body>
</html>
EOL
        fi
        
        echo "Successfully processed archive, copying back to output directory"
        
    else
        echo "DocC conversion failed with approach 1, trying alternative approach..."
        # Alternative approach using old-style arguments
        "$DOCC_TOOL" \\
            --output-path "$OUTPUT" \\
            --bundle-identifier "com.umbreproject.$MODULE_NAME" \\
            --fallback-display-name "$MODULE_NAME" \\
            --fallback-bundle-version "1.0.0" \\
            --additional-symbol-graph-dir "$TEMP_DIR/Sources" \\
            --transform-for-static-hosting \\
            "$TEMP_DIR/Documentation.docc"
            
        if [ $? -eq 0 ]; then
            echo "Alternative DocC conversion succeeded!"
        else
            echo "All DocC conversion approaches failed"
            exit 1
        fi
    fi
    """

    ctx.actions.write(
        output = script,
        content = script_content,
        is_executable = True,
    )

    return [DefaultInfo(
        executable = script,
        files = depset([script]),
    )]

docc_gen = rule(
    implementation = _docc_gen_impl,
    executable = True,
    doc = "Create an executable that generates DocC documentation",
)
