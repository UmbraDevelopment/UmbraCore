# BackupInterfaces

## Overview

The BackupInterfaces module defines the core protocols and data types required for backup operations in the UmbraCore system. This module follows the Alpha Dot Five architecture, providing clear boundaries between interfaces and implementations.

## Key Components

### Protocols

- **BackupServiceProtocol**: Core protocol for managing backup operations, including creation, restoration, and maintenance
- **SnapshotServiceProtocol**: Focused protocol for snapshot management, providing detailed snapshot operations

### Data Types

- **BackupSnapshot**: Comprehensive model for backup snapshots with detailed metadata
- **BackupError**: Well-structured error type with localised descriptions and recovery suggestions
- **BackupOptions/RestoreOptions**: Configuration options for backup and restore operations
- **BackupResult/RestoreResult**: Result types for backup operations with detailed metrics
- **SnapshotFile**: Representation of files within snapshots
- **SnapshotDifference**: Comparison between two snapshots showing changes

## Usage Examples

### Creating a Backup

```swift
let backupService: BackupServiceProtocol = ...

// Configure backup options
let options = BackupOptions(
    compressionLevel: 6,
    verifyAfterBackup: true,
    useParallelisation: true,
    priority: .normal
)

// Create backup
do {
    let result = try await backupService.createBackup(
        sources: [homeDirectoryURL, documentsURL],
        excludePaths: [cacheDirectoryURL],
        tags: ["weekly", "documents"],
        options: options
    )
    
    print("Backup created with ID: \(result.snapshotID)")
    print("Total size: \(result.totalSize) bytes")
    print("Files backed up: \(result.fileCount)")
    print("Duration: \(result.duration) seconds")
} catch let error as BackupError {
    print("Backup failed: \(error.localizedDescription)")
    
    if let recoverySuggestion = error.recoverySuggestion {
        print("Suggested recovery: \(recoverySuggestion)")
    }
}
```

### Managing Snapshots

```swift
let snapshotService: SnapshotServiceProtocol = ...

// List recent snapshots
let recentSnapshots = try await snapshotService.listSnapshots(
    repositoryID: nil,
    tags: ["weekly"],
    before: nil,
    after: Date().addingTimeInterval(-7 * 24 * 60 * 60), // One week ago
    path: nil,
    limit: 5
)

// Compare two snapshots
if recentSnapshots.count >= 2 {
    let diff = try await snapshotService.compareSnapshots(
        snapshotID1: recentSnapshots[0].id,
        snapshotID2: recentSnapshots[1].id,
        path: nil
    )
    
    print("Files added: \(diff.addedCount)")
    print("Files removed: \(diff.removedCount)")
    print("Files modified: \(diff.modifiedCount)")
}
```

## Architecture Compliance

This module follows the Alpha Dot Five architecture:

- **Interface Separation**: Clear protocol boundaries with well-defined responsibilities
- **Sendable Conformance**: All types conform to `Sendable` for thread safety
- **British Spelling**: Documentation uses British English spelling conventions
- **Error Handling**: Comprehensive error types with recovery suggestions
- **Structured Documentation**: Clear and consistent documentation style

## Dependencies

- **UmbraErrors**: For error handling base types

## Implementation Notes

The BackupInterfaces module only defines interfaces and data types. Concrete implementations are provided by the BackupServices module, which uses actor-based concurrency for thread safety.
