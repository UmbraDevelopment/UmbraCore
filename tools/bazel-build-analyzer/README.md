# Bazel Build Analyser

A Go tool for analysing Bazel build status across multiple targets in the UmbraCore project.

## Features

- Queries all Bazel targets in the repository
- Builds each target with `--verbose_failures` flag
- Captures build outputs and parses for errors and warnings
- Groups similar errors to identify common issues
- Generates a comprehensive Markdown report

## Installation

The tool is written in Go and can be built with:

```bash
cd ~/CascadeProjects/UmbraCore/tools/bazel-build-analyzer
go build
```

## Usage

Run the tool with default settings:

```bash
# From the tool directory
./bazel-build-analyzer --workspace ~/CascadeProjects/UmbraCore

# Or from anywhere with full paths
~/CascadeProjects/UmbraCore/tools/bazel-build-analyzer/bazel-build-analyzer --workspace ~/CascadeProjects/UmbraCore
```

### Command-Line Options

- `--workspace` - Path to Bazel workspace directory (default: current directory)
- `--query` - Bazel query expression to find targets (default: "//...")
- `--query-output` - Path to save query results as JSON (default: "bazel_targets.json")
- `--build-output` - Path to save build results as JSON (default: "bazel_build_results.json")
- `--report` - Path to save markdown report (default: "bazel_build_report.md")
- `--skip-query` - Skip query phase and use existing query results file
- `--skip-build` - Skip build phase and use existing build results file

### Example: Only Analyse a Subset of Targets

```bash
./bazel-build-analyzer --workspace ~/CascadeProjects/UmbraCore --query "//packages/..."
```

### Example: Resume a Previous Analysis

If a build was interrupted, you can resume from where you left off:

```bash
./bazel-build-analyzer --workspace ~/CascadeProjects/UmbraCore --skip-query
```

## Output

The tool generates three output files:

1. `bazel_targets.json` - All Bazel targets found by the query
2. `bazel_build_results.json` - Detailed build results for each target
3. `bazel_build_report.md` - A comprehensive Markdown report with build status and error analysis

## Sample Report Format

The Markdown report includes:

- Overall build statistics
- Status table for all targets
- Categorised error groups with examples
- Lists of targets affected by each error category
