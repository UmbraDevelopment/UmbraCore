# ResticInterfaces

This module defines the core interfaces and data types for interacting with the Restic backup system as part of the Alpha Dot Five architecture.

## Overview

ResticInterfaces provides a protocol-based abstraction layer for Restic operations, separating the interface definitions from their implementations. This module serves as the foundation for Restic integration throughout the UmbraCore project.

## Key Components

### Service Protocol

- `ResticServiceProtocol`: The main service protocol defining all operations for Restic interaction
- `ResticServiceFactory`: Factory protocol for creating service instances with different configurations

### Command Types

- `ResticCommand`: Base protocol for all Restic commands
- Specific command protocols for different Restic operations:
  - `ResticInitCommand`: Repository initialisation
  - `ResticBackupCommand`: File backup operations
  - `ResticRestoreCommand`: Data restoration
  - `ResticSnapshotsCommand`: Snapshot listing and management
  - `ResticMaintenanceCommand`: Repository maintenance
  - `ResticCheckCommand`: Repository checking and verification

### Data Models

- `ResticCommandResult`: Representation of command execution results
- `ResticProgressTracking`: Models for tracking backup and restore progress
- `ResticCommonOptions`: Shared options for Restic commands
- `ResticMaintenanceType`: Enumeration of maintenance operation types

### Error Handling

- `ResticError`: Comprehensive error type for Restic operations with localised descriptions and recovery suggestions

## Usage

This module provides interfaces only and should be paired with a concrete implementation module (`ResticServices`) for actual functionality.

```swift
// Example implementation usage:
let resticService = ResticServiceFactory.createResticService(
    executablePath: "/usr/local/bin/restic",
    defaultRepository: "/path/to/repo",
    defaultPassword: "password",
    progressDelegate: progressReporter
)

// Perform operations
try await resticService.backup(
    paths: ["/Users/Documents"],
    tag: "daily",
    excludes: ["*.tmp"]
)
```

## Migration Notes

This module is part of the Alpha Dot Five architecture migration, replacing the older direct integration in the following modules:

- `Sources/ResticTypes`
- `Sources/ResticCLIHelper`
- `Sources/ResticCLIHelperModels`

The interface-based approach provides:

1. Clearer separation of concerns
2. Better testability through protocol-based design
3. Proper actor-based concurrency safety
4. Comprehensive error handling
5. Foundation-independent data types where appropriate

## Next Steps

The complete migration requires implementing these interfaces in the `ResticServices` module with proper actor-based concurrency.
