# Binary Tools

This directory contains compiled binary tools for the UmbraCore project.

## Contents

- `dependency_analyzer` - Analyses dependency relationships in the UmbraCore codebase
- `migration_helper` - Assists with the Alpha Dot Five migration process

## Usage

These binaries are pre-compiled and can be executed directly. For example:

```bash
./dependency_analyzer --help
./migration_helper --help
```

## Adding New Binaries

When adding new binaries to this directory:

1. Ensure they have appropriate execute permissions
2. Update this README with information about the tool
3. Consider including source code or build instructions in the relevant tool directory
4. Test the binary on all supported platforms
