# UmbraCore Development Tools

This directory contains various development tools used in the UmbraCore project. These tools are organised into logical categories to make them easier to find and use.

## Directory Structure

- `build/` - Tools related to the build system
  - `analyzers/` - Tools for analysing build outputs and identifying issues
  - `fixers/` - Tools for fixing build problems
  - `generators/` - Tools for generating build files

- `code/` - Tools for code manipulation
  - `formatters/` - Code formatting tools
  - `migrators/` - Tools for migrating code between architectures
  - `analyzers/` - Code analysis tools

- `infra/` - Infrastructure-related tools
  - `ci/` - Continuous Integration tooling
  - `workflow/` - GitHub workflow management

- `migration/` - Alpha Dot Five migration tools
  - `error_handling/` - Error handling migration tools
  - `protocols/` - Protocol migration tools
  - `xpc/` - XPC migration tools

- `scripts/` - Simple utility scripts
- `docs/` - Documentation tools

## Usage

Most tools can be run directly from this directory structure. For specific usage instructions, refer to the README.md files in each subdirectory or comments within the scripts themselves.

## Contributing

When adding new tools, please place them in the appropriate category directory. If none of the existing categories fit, consult with the team before creating a new category.
