# Deprecation Remover

A tool to analyse, report on, and remove/comment out deprecated items in the UmbraCore codebase.

## Usage

```
./deprecation_remover -module=ModuleName -inventory=/path/to/deprecated_inventory.md [flags]
```

### Flags

- `-module`: The module to process (required)
- `-inventory`: Path to the deprecated inventory file (required)
- `-dry-run`: Run without making changes to files
- `-verbose`: Enable verbose logging
- `-report`: Generate a detailed report at the specified path
- `-file`: Target a specific file (base name only)

### Examples

Process all files in the XPCProtocolsCore module:
```
./deprecation_remover -module=XPCProtocolsCore -inventory=/path/to/deprecated_inventory.md
```

Dry-run on a specific module without making changes:
```
./deprecation_remover -module=SecurityBridge -inventory=/path/to/deprecated_inventory.md -dry-run
```

Process a specific file in a module:
```
./deprecation_remover -module=SecurityInterfaces -file=SecurityProviderBridge.swift -inventory=/path/to/deprecated_inventory.md
```

Generate a detailed report:
```
./deprecation_remover -module=XPCProtocolsCore -inventory=/path/to/deprecated_inventory.md -report=report.md
```

## Features

The tool:

1. Parses a deprecated inventory file to identify deprecated items
2. Locates the files containing these items, even in nested directory structures
3. Finds references to deprecated items across the codebase
4. Comments out deprecated item declarations (adding a "DEPRECATED:" prefix)
5. Replaces uses of deprecated items with their recommended replacements, if available
6. Generates a detailed report of what it found and what actions it took

## Enhanced File Path Handling

The tool has robust file path handling that can find files in various directory structures:
- Standard path (Sources/ModuleName/File.swift)
- Nested paths (Sources/ModuleName/Subdirectory/File.swift)
- Test files (Tests/ModuleName/File.swift)
- Adapter paths (Sources/ModuleName/Adapters/File.swift)

If a file cannot be found at the expected path, the tool will use the `find` command to locate it anywhere in the module directory.

## Report Generation

When using the `-report` flag, the tool generates a comprehensive report including:
- A list of all deprecated items identified in the module, with their types and impact levels
- If running without the dry-run flag, a list of files that were modified
- Information about any replacements that were made

## Error Handling

The tool provides detailed error messages and robust error handling, especially for:
- Files that cannot be found
- Parsing errors in the inventory file
- Problems updating references to deprecated items

## Helper Script

A helper script `run_deprecation_removal.sh` is provided in the project root to simplify running the tool:

```
./run_deprecation_removal.sh <module_name> [dry-run]
```

This script:
1. Builds the latest version of the tool
2. Creates a reports directory
3. Runs the tool with appropriate flags
4. For non-dry-run mode, asks for confirmation before proceeding
