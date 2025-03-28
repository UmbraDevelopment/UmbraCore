# ResticServices

This module provides a complete implementation of the ResticInterfaces protocols for interacting with the Restic backup system as part of the Alpha Dot Five architecture.

## Overview

ResticServices implements a thread-safe, actor-based service for Restic operations, following the Alpha Dot Five architectural patterns. The implementation provides proper concurrency control, comprehensive error handling, and progress tracking for long-running operations.

## Key Components

### Service Implementation

- `ResticServiceImpl`: Actor-based implementation of the ResticServiceProtocol
- Thread-safe for concurrent operations through Swift actor isolation
- Comprehensive error handling with contextual error messages

### Command Implementations

- Type-safe implementations of all standard Restic commands:
  - `ResticInitCommandImpl`: Repository initialisation
  - `ResticBackupCommandImpl`: File backup operations
  - `ResticRestoreCommandImpl`: Data restoration
  - `ResticSnapshotsCommandImpl`: Snapshot listing and management
  - `ResticMaintenanceCommandImpl`: Repository maintenance
  - `ResticCheckCommandImpl`: Repository checking and verification

### Helper Components

- `ResticProgressParser`: Parses and forwards progress information
- `ResticServiceFactoryImpl`: Factory for creating service instances

## Usage Example

```swift
// Get the factory
let factory = ResticServiceFactoryImpl(logger: logger)

// Create a service instance
let resticService = try await factory.createResticService(
    executablePath: "/usr/local/bin/restic",
    defaultRepository: "/path/to/repo",
    defaultPassword: "password",
    progressDelegate: progressReporter
)

// Perform operations
let result = try await resticService.backup(
    paths: ["/Users/Documents"],
    tag: "daily",
    excludes: ["*.tmp"]
)

// Process the result
print("Backup completed in \(result.duration) seconds")
```

## Alpha Dot Five Compliance

This implementation adheres to the Alpha Dot Five architecture principles:

1. **Actor-based Concurrency**: All mutable state is protected using Swift actors
2. **Interface Separation**: Clear separation between interfaces and implementation
3. **Error Handling**: Domain-specific error types with helpful messages
4. **British English Documentation**: All documentation uses British English spelling
5. **Factory Pattern**: Services are created through factories for proper dependency injection

## Migration Notes

This module replaces the older direct integration in:
- `Sources/ResticTypes`
- `Sources/ResticCLIHelper`
- `Sources/ResticCLIHelperModels`

The implementation maintains full compatibility with existing code while providing improved thread safety and error handling.

## Dependencies

- **ResticInterfaces**: Core protocols and data types for Restic operations
- **LoggingInterfaces**: Logging support for operation tracking

## Future Enhancements

1. Add support for additional Restic commands (stats, diff, find, etc.)
2. Enhance progress reporting with more detailed statistics
3. Implement intelligent retry mechanisms for transient errors
4. Add support for cloud storage backends with proper authentication
