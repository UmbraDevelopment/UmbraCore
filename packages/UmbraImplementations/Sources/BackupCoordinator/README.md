# BackupCoordinator

The BackupCoordinator module provides a unified interface for managing backup operations within the UmbraCore system. It serves as a central coordination point that brings together various backup-related services to deliver a cohesive experience for backup creation, restoration, and management.

## Architecture

This module follows the Alpha Dot Five architecture, with clear separation between interfaces and implementations:

- **Interfaces**: Defined in the `BackupInterfaces` module as protocols
- **Implementations**: Provided in this module as concrete actor-based classes
- **Dependency Injection**: Services are injected via initializers to facilitate testing and flexibility

## Components

### BackupCoordinatorProtocol

The main protocol that defines the public interface for backup coordination, including:

- Creating and restoring backups
- Managing snapshots and their metadata
- Finding files within snapshots
- Verifying snapshot integrity
- Performing maintenance operations

### BackupCoordinatorImpl

A thread-safe, actor-based implementation of the `BackupCoordinatorProtocol` that:

- Coordinates between backup and snapshot services
- Provides comprehensive logging
- Handles error translation
- Manages repository information

## Usage

### Creating a Coordinator

```swift
// Create a coordinator using the factory approach
let coordinator = try await BackupCoordinatorImpl.create(
    factory: BackupServiceFactory(),
    resticServiceFactory: ResticServiceFactory(),
    logger: LoggingSystem.shared.logger,
    repositoryPath: "/path/to/repository",
    repositoryPassword: "optional-password"
)
```

### Creating a Backup

```swift
// Create a backup of specific directories
let result = try await coordinator.createBackup(
    sources: [homeURL.appendingPathComponent("Documents")],
    excludePaths: [homeURL.appendingPathComponent("Documents/temp")],
    tags: ["documents", "weekly"],
    options: BackupOptions(compressionLevel: .maximum)
)

print("Backup created with ID: \(result.snapshotID)")
```

### Restoring a Backup

```swift
// Restore a specific snapshot to a target location
let result = try await coordinator.restoreBackup(
    snapshotID: "snapshot123",
    targetPath: URL(fileURLWithPath: "/path/to/restore"),
    includePaths: nil,
    excludePaths: nil,
    options: RestoreOptions(overwriteFiles: true)
)

print("Restored \(result.fileCount) files")
```

### Managing Snapshots

```swift
// List available snapshots
let snapshots = try await coordinator.listSnapshots(
    tags: ["important"],
    before: nil,
    after: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
    options: nil
)

// Update snapshot tags
let updatedSnapshot = try await coordinator.updateSnapshotTags(
    snapshotID: "snapshot123",
    addTags: ["archived"],
    removeTags: ["current"]
)
```

## Error Handling

The coordinator translates low-level errors from the underlying services into domain-specific `BackupError` types, providing clear context for error situations:

```swift
do {
    let result = try await coordinator.createBackup(
        sources: [directoryURL],
        excludePaths: nil,
        tags: nil,
        options: nil
    )
} catch let error as BackupError {
    switch error {
    case .repositoryAccessFailure(let path, let reason):
        print("Cannot access repository at \(path): \(reason)")
    case .invalidConfiguration(let details):
        print("Configuration error: \(details)")
    case .snapshotFailure(let id, let reason):
        print("Snapshot operation failed for \(id ?? "unknown"): \(reason)")
    default:
        print("Backup error: \(error.localizedDescription)")
    }
} catch {
    print("Unexpected error: \(error.localizedDescription)")
}
```

## Thread Safety

The BackupCoordinator implementation uses Swift's actor model to ensure thread safety:

- All mutable state is contained within the actor
- External operations are asynchronous using Swift's structured concurrency
- Service calls are properly awaited to maintain execution order

## Best Practices

When using the BackupCoordinator:

1. Always handle errors appropriately using the domain-specific error types
2. Consider using sensible defaults for optional parameters
3. Provide proper progress reporting for long-running operations
4. Use meaningful tags to organize your snapshots
5. Implement a regular maintenance schedule using the maintenance functions

## Planned Enhancements

Future versions of the BackupCoordinator will include:

- Progress reporting with cancellation support
- More sophisticated scheduling for automated backups
- Advanced snapshot retention policies
- Cloud storage support
- Enhanced security options
