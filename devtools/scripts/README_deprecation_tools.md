# UmbraCore Deprecation Tools

This document describes the tools available for identifying and removing deprecated items in the UmbraCore project.

## Available Tools

### 1. Deprecation Analyzer

Located in `tools/go/cmd/deprecation_analyzer`, this tool scans the codebase for deprecated items and generates an inventory file.

#### Usage:

```bash
cd tools/go/cmd/deprecation_analyzer
go run main.go [options]
```

Options:
- `-output`: Path to output file (default: deprecated_inventory.md in the project root)
- `-module`: Filter results to a specific module
- `-impact`: Filter results by impact level (High, Medium, Low)
- `-type`: Filter results by type (Protocol, Module, Method, etc.)

### 2. Deprecation Remover

Located in `tools/go/cmd/deprecation_remover`, this tool processes deprecated items found by the analyzer.

#### Usage:

```bash
cd tools/go/cmd/deprecation_remover
go run main.go [options]
```

Options:
- `-module`: Module to process (required)
- `-inventory`: Path to deprecated inventory file (default: deprecated_inventory.md)
- `-file`: Target specific file (base name only)
- `-dry-run`: Run without making changes
- `-verbose`: Enable detailed logging
- `-report`: Path to write report

### 3. Deprecation Removal Script

Located in `tools/scripts/run_deprecation_removal.sh`, this script helps process modules with nested directory structures.

#### Usage:

```bash
cd tools/scripts
chmod +x run_deprecation_removal.sh
./run_deprecation_removal.sh
```

The script will:
1. Find all Swift files in the SecurityBridge, SecurityInterfaces, and XPCProtocolsCore modules
2. Process each file individually using the deprecation_remover tool
3. Generate separate reports for each file in the deprecation_reports directory

## Workflow

The recommended workflow for handling deprecated items is:

1. Run the deprecation_analyzer to generate a fresh inventory:
   ```bash
   cd tools/go/cmd/deprecation_analyzer
   go run main.go
   ```

2. Review the generated inventory file to understand the scope of deprecation.

3. Run the deprecation removal script to process specified modules:
   ```bash
   cd tools/scripts
   ./run_deprecation_removal.sh
   ```

4. Review the generated reports in the deprecation_reports directory.

5. Verify changes with unit tests and integration tests before committing.

## Customising the Process

To process different modules or customise the behaviour:

1. Edit the `MODULES` array in run_deprecation_removal.sh to include different modules.
2. Modify the script to use different flags for the deprecation_remover tool.

## Troubleshooting

If you encounter issues:

1. Run the tools with the `-verbose` flag for more detailed logging.
2. Verify that the paths in the inventory file match the actual file structure.
3. For specific files that fail processing, try running the deprecation_remover tool directly with the `-file` flag.
