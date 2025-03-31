# BackupCoordinator

The BackupCoordinator module provides high-level backup orchestration for UmbraCore applications.

## Overview

BackupCoordinator offers a comprehensive solution for coordinating backup operations, including scheduling, progress tracking, error handling, and reporting. It serves as the central conductor for backup processes in applications built with UmbraCore.

## Features

- Backup task scheduling and coordination
- Progress monitoring and reporting
- Resource management during backups
- Error handling and recovery
- Backup policy enforcement
- Backup verification

## Architecture

BackupCoordinator uses a task-based architecture:

1. **BackupSession**: Represents a complete backup operation
2. **BackupTask**: Individual unit of work within a backup session
3. **BackupPolicy**: Rules governing backup behaviour
4. **ProgressTracker**: Monitors and reports on backup progress
5. **BackupResult**: Structured outcome of a backup operation

## Usage

```swift
import BackupCoordinator

// Create a backup coordinator
let coordinator = BackupCoordinator(
    repositoryManager: repoManager,
    securityService: securityService
)

// Configure backup policy
let policy = BackupPolicy(
    schedule: .daily,
    retention: .keepLastN(7),
    compressionLevel: 6,
    bandwidth: .limited(100_000_000) // 100 MB/s
)

// Start a backup session
let session = try await coordinator.startBackupSession(
    paths: ["/Users/Documents", "/Users/Pictures"],
    repository: "main-backup",
    policy: policy
)

// Monitor progress
session.progressHandler = { progress in
    print("Progress: \(progress.percentComplete)%")
    print("Files processed: \(progress.filesProcessed)")
    print("Bytes processed: \(progress.bytesProcessed)")
}

// Wait for completion
let result = try await session.result
switch result {
case .success(let backupInfo):
    print("Backup successful: \(backupInfo.snapshotId)")
case .failure(let error):
    print("Backup failed: \(error.localizedDescription)")
}
```

## Integration

BackupCoordinator integrates with multiple UmbraCore components, including RepositoryManager, SecurityService, and Configuration, to provide a complete backup solution.
