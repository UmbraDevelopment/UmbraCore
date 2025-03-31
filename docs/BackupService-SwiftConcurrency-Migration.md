# Swift Concurrency Migration Guide for Backup Services

This document outlines how to migrate from the legacy backup service protocols to the modernised Swift Concurrency implementation in UmbraCore.

## Overview of Changes

The backup services have been modernised to:

1. Remove unused parameters (`progressReporter` and `cancellationToken`)
2. Add Swift Concurrency support using Swift's native async/await
3. Implement more composable progress reporting with `AsyncStream<BackupProgress>`
4. Integrate with the privacy-enhanced logging system

## Migration Steps

### Step 1: Update Method Signatures

Update method signatures to remove the unused parameters and add return tuples with progress streams:

**Before:**
```swift
func createBackup(
    sources: [URL],
    excludePaths: [URL]?,
    tags: [String]?,
    options: BackupOptions?,
    progressReporter: BackupProgressReporter?,
    cancellationToken: CancellationToken?
) async throws -> BackupResult
```

**After:**
```swift
func createBackup(
    sources: [URL],
    excludePaths: [URL]?,
    tags: [String]?,
    options: BackupOptions?
) async throws -> (BackupResult, AsyncStream<BackupProgress>)
```

### Step 2: Replace Cancellation Tokens with Swift's Task Cancellation

Use Swift's built-in task cancellation system:

```swift
// Check for cancellation
try Task.checkCancellation()

// Handle cancellation errors
catch is CancellationError {
    // Handle cancellation by logging and throwing appropriate error
}
```

### Step 3: Replace Progress Reporting with AsyncStream

Two approaches are available:

1. **Direct Stream Creation:**
```swift
let (stream, updateProgress, completeProgress) = BackupProgress.createProgressStream()

// Report progress
updateProgress(.initialising(description: "Starting..."))
updateProgress(.processing(phase: "Processing files", percentComplete: 0.5))
updateProgress(.completed)
completeProgress()

return (result, stream)
```

2. **AsyncProgressReporter Actor:**
```swift
let operation = BackupOperation.createBackup
let progressStream = progressReporter.progressStream(for: operation)

// Report progress
progressReporter.reportProgress(.initialising, for: operation)
progressReporter.reportProgress(.processing(phase: "Working", percentComplete: 0.3), for: operation)
progressReporter.reportProgress(.completed, for: operation)
progressReporter.completeOperation(operation)

return (result, progressStream)
```

### Step 4: Update Calling Code

For client code that consumes the service:

```swift
// Call the service
let (result, progress) = try await backupService.createBackup(
    sources: sources,
    excludePaths: excludePaths,
    tags: tags,
    options: options
)

// Process the result immediately
processBackupResult(result)

// Monitor progress separately
Task {
    for await progressUpdate in progress {
        switch progressUpdate {
        case .initialising(let description):
            // Handle initialisation
        case .processing(let phase, let percentComplete):
            // Update UI with progress information
        case .completed:
            // Handle completion
        case .cancelled:
            // Handle cancellation
        case .failed(let error):
            // Handle failure
        }
    }
}
```

### Step 5: Integrate with Privacy-Aware Logging

Use the structured logging context:

```swift
// Create log context
let logContext = BackupLogContext()
    .with(sources: sources.map(\.path), privacy: .public)
    .with(operation: "createBackup")

// Log operation start
await backupLogging.logOperationStart(logContext: logContext)

// Log progress updates
await backupLogging.logProgressUpdate(progress, for: operation, logContext: logContext)

// Log operation completion
await backupLogging.logOperationSuccess(logContext: resultContext)
```

## Key Components

The modernisation includes these new components:

1. **AsyncBackupProgress.swift**: Defines the async sequence infrastructure for progress reporting.
2. **BackupLogContext.swift**: Structured context for privacy-aware logging.
3. **BackupLoggingAdapter.swift**: Connects progress reporting with the privacy-enhanced logging system.
4. **ModernBackupServiceImpl.swift**: Reference implementation of the modern protocol.
5. **ModernSnapshotServiceImpl.swift**: Reference implementation for snapshots.

## Benefits

This modernisation brings several benefits:

1. **More Swift-Native**: Uses Swift's built-in concurrency model.
2. **Simpler Interfaces**: Method signatures are cleaner and more focused.
3. **Better Composability**: Progress can be observed using Swift's async/await syntax.
4. **Improved Error Handling**: Integrates with Swift's task cancellation system.
5. **Enhanced Privacy**: Integrates with the privacy-enhanced logging system.

## Example Usage

```swift
// Create a task that can be cancelled
let backupTask = Task {
    do {
        // Start the backup
        let (result, progressStream) = try await backupService.createBackup(
            sources: [documentsURL],
            excludePaths: [cacheURL],
            tags: ["automatic", "documents"],
            options: BackupOptions(compressionLevel: 6, verifyAfterBackup: true)
        )
        
        // Process the result
        await processBackupResult(result)
        
    } catch is CancellationError {
        // Handle cancellation gracefully
        await handleBackupCancelled()
    } catch {
        // Handle other errors
        await handleBackupError(error)
    }
}

// Progress monitoring in a separate task
let progressTask = Task {
    // Get the progress stream from the previous call
    let (_, progressStream) = try await backupService.createBackup(/* ... */)
    
    for await progress in progressStream {
        switch progress {
        case .initialising:
            await updateStatus("Starting backup...")
        case .processing(let phase, let percent):
            await updateProgressBar(percent)
            await updateStatus(phase)
        case .completed:
            await updateStatus("Backup completed")
        case .cancelled:
            await updateStatus("Backup cancelled")
        case .failed(let error):
            await showError(error)
        }
    }
}

// Cancel the backup if needed
backupTask.cancel()
```
