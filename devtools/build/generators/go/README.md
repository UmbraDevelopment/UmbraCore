# UmbraCore Go Tools

This directory contains Go-based tools for UmbraCore development processes.

## Available Tools

### DocC Documentation Generator

The DocC documentation generator (`docc`) creates DocC documentation archives from Swift modules with DocC markup.

#### Usage

```bash
# Build the tool
go build -o bin/docc cmd/docc/main.go

# Generate documentation for a specific module
./bin/docc --module SecurityInterfaces

# Generate documentation with custom output path
./bin/docc --module SecurityInterfaces --output path/to/output.doccarchive

# Skip symbol graph generation (use existing ones)
./bin/docc --module SecurityInterfaces --skip-symbol-graph

# Use verbose output
./bin/docc --module SecurityInterfaces --verbose
```

#### Options

- `--module`: The Swift module to generate documentation for (required)
- `--output`: Custom output path for the DocC archive
- `--skip-symbol-graph`: Skip symbol graph generation step
- `--verbose`: Enable verbose output
- `--sdk`: SDK to use for symbol graph generation (default: macosx)
- `--target`: Target to use for symbol graph generation

### Typealias Analyser

The typealias analyser (`typealias`) scans the codebase for typealiases and generates a comprehensive analysis report.

#### Usage

```bash
# Build the tool
go build -o bin/typealias cmd/typealias/main.go

# Run the typealias analyser
./bin/typealias

# Run with a custom output path
./bin/typealias --output custom_report.md

# Run with verbose output
./bin/typealias --verbose
```

#### Report Format

The typealias analyser generates a Markdown report containing:

1. List of all typealiases in the codebase
2. Categorisation of typealiases
3. Recommendations for each typealias (Keep, Refactor, Deprecate)
4. Module-specific analysis
5. Statistical breakdowns

## Building

A simple Makefile is available for building all tools:

```bash
# Build all tools
make build

# Clean build artifacts
make clean
```

## CI/CD Integration

These tools are integrated into the UmbraCore CI/CD pipeline via the workflows defined in `.github/workflows/docc-documentation.yml`.

When changes are pushed to main branches or documentation files are modified in pull requests, the DocC documentation is automatically rebuilt and deployed.
