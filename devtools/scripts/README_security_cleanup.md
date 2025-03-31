# Security Module Cleanup Tool

This Go tool helps migrate dependencies from legacy security modules to the new consolidated architecture modules in UmbraCore.

## Features

- Type-safe code that ensures consistent migrations
- Concurrent processing for faster operations on large codebases
- Dry-run mode to preview changes before applying them
- Detailed output with color-coded status messages

## Usage

```bash
# Build the tool
go build -o security_module_cleanup security_module_cleanup.go

# Run with dry-run mode (default)
./security_module_cleanup -security-utils

# Run multiple migrations
./security_module_cleanup -security-utils -security-interfaces-protocols

# Apply actual changes (disable dry-run)
./security_module_cleanup -security-utils -dry-run=false

# Specify source directory (if running from different location)
./security_module_cleanup -security-utils -source-dir=/path/to/UmbraCore/Sources
```

## Available Migration Flags

| Flag | Description |
|------|-------------|
| `-security-utils` | Migrate from SecurityUtils to SecurityBridge |
| `-security-interfaces-protocols` | Migrate from SecurityInterfacesProtocols to SecurityProtocolsCore |
| `-security-interfaces-foundation-bridge` | Migrate from SecurityInterfacesFoundationBridge to SecurityBridge |
| `-security-provider-bridge` | Migrate from SecurityProviderBridge to SecurityBridge |

## Best Practices

1. Always run with `-dry-run=true` first (default) to review changes
2. Run migrations one module at a time
3. Build and test after each migration
4. Only remove module directories after verifying everything works

## After Migration

After successfully migrating all references:

1. Build the project to verify no compilation errors
2. Run tests to ensure functionality is preserved
3. Remove the obsolete module directories
4. Update documentation to reflect the new architecture
