# Bazel Build Analyser

A tool for analysing Bazel build outputs, categorising issues, and generating reports with recommendations for resolving common problems.

## Overview

This tool runs a Bazel build command, captures all output, and processes it to:

1. Categorise issues as warnings, errors, or failed targets
2. Generate a comprehensive JSON output file
3. Create a detailed Markdown report with analysis and recommendations
4. Provide module-level summaries of build issues

## Usage

Run the script with the following command:

```bash
python3 bazel_build_analyzer.py [OPTIONS]
```

### Options

- `--targets TARGETS`: Bazel targets to build (default: "//packages/...")
- `--output OUTPUT`: Output JSON file path (default: "build_output.json")
- `--report REPORT`: Output report file path (default: "build_report.md")
- `--keep`, `-k`: Keep going after errors (default: True)
- `--verbose`, `-v`: Show verbose failures (default: True)

### Example

```bash
# Run with default settings
python3 bazel_build_analyzer.py

# Specify custom targets and output files
python3 bazel_build_analyzer.py --targets "//packages/UmbraImplementations/..." --output "umbra_build.json" --report "umbra_report.md"
```

## Features

- **Build Execution**: Runs Bazel build commands with configurable options
- **Output Categorisation**: Sorts build messages into errors, warnings, and target statuses
- **Module Analysis**: Groups issues by module to identify problematic areas
- **Recommendation Engine**: Provides specific recommendations for common issues
- **Comprehensive Reporting**: Generates detailed Markdown reports with actionable insights

## Sample Report Structure

- **Build Summary**: Overall build status and counts
- **Module Summary**: Table of issues by module
- **Errors**: Detailed error listings with recommendations
- **Warnings**: Warning listings with recommendations
- **Failed Targets**: List of targets that failed to build
- **General Recommendations**: Common patterns and suggested fixes

## Requirements

- Python 3.6+
- Bazelisk installed and available in PATH
- Access to the UmbraCore build environment
