# Alpha Dot Five Architecture for Backup Services

This document outlines the implementation of the Alpha Dot Five architecture in the UmbraCore Backup Services module, focusing on component-based design, privacy-aware logging, and structured error handling.

## Core Architecture Principles

The Alpha Dot Five architecture for Backup Services is built on these foundational principles:

1. **Actor-Based Concurrency**: Utilising Swift actors for thread safety and structured concurrency
2. **Component-Based Design**: Breaking down services into focused, single-responsibility components
3. **Privacy-By-Design**: Enhanced privacy-aware error handling and logging
4. **Type Safety**: Using strongly-typed DTO interfaces that make illegal states unrepresentable
5. **Metrics Collection**: Built-in performance tracking and telemetry

## Key Components

### Service Components

The snapshot service has been refactored into specialized components:

1. **SnapshotOperationsService**: Core query operations like listing, retrieving, and comparing snapshots
2. **SnapshotManagementService**: Management operations like updating tags, descriptions, and deleting snapshots
3. **SnapshotRestoreService**: Specialised service for restore operations with safety validation

### Support Components

Supporting infrastructure for consistent operation handling:

1. **SnapshotOperationExecutor**: Central executor ensuring consistent error handling and logging
2. **CancellationHandler**: Thread-safe management of cancellation state
3. **SnapshotMetricsCollector**: Collection of performance metrics and success rates
4. **ErrorMapper & ErrorLogContextMapper**: Privacy-aware error handling and context creation

### Data Transfer Objects

Type-safe parameter objects for operations:

1. **SnapshotOperationDTO**: Base protocol for all operation parameters
2. **SnapshotListParameters**: Parameters for listing operations
3. **SnapshotRestoreParameters**: Parameters for restore operations
4. **Various other operation-specific parameter types**

## Implementation Details

### Component Registration and Dependency Injection

The ModernSnapshotServiceImpl initialises and connects components:

```swift
// Initialize support components
self.cancellationHandler = CancellationHandler()
self.metricsCollector = SnapshotMetricsCollector()
self.errorLogContextMapper = ErrorLogContextMapper()

// Initialize operation executor
self.operationExecutor = SnapshotOperationExecutor(
    logger: logger,
    cancellationHandler: cancellationHandler,
    metricsCollector: metricsCollector,
    errorLogContextMapper: errorLogContextMapper,
    errorMapper: errorMapper
)

// Initialize service components in dependency order
self.operationsService = SnapshotOperationsService(
    resticService: resticService,
    operationExecutor: operationExecutor
)

self.managementService = SnapshotManagementService(
    resticService: resticService,
    operationExecutor: operationExecutor,
    operationsService: operationsService
)

self.restoreService = SnapshotRestoreService(
    resticService: resticService,
    operationExecutor: operationExecutor
)
```

### Privacy-Aware Logging Integration

Operations are logged with structured, privacy-aware contexts:

```swift
// Create parameters with privacy annotations
let parameters = SnapshotListParameters(
    repositoryID: repositoryID,
    tags: tags,
    before: before,
    after: after,
    path: path,
    limit: limit
)

// The operation executor handles consistent logging
return try await operationsService.listSnapshots(
    parameters: parameters,
    progressReporter: progressReporter,
    cancellationToken: cancellationToken
)
```

### Cancellation Support

Two cancellation approaches are supported:

1. **Task-Based Cancellation**: Using Swift's native task cancellation system
   ```swift
   try Task.checkCancellation()
   ```

2. **Token-Based Cancellation**: For legacy compatibility
   ```swift
   try await cancellationHandler.checkCancellation(token: cancellationToken)
   ```

### Progress Reporting

Two progress reporting approaches are available:

1. **AsyncStream-Based Progress**:
   ```swift
   let progressStream = progressReporter.createProgressStream()
   let progressAdapter = ProgressReporterAdapter(reporter: progressReporter)
   
   // Execute operation with progress reporting
   let snapshots = try await operationsService.listSnapshots(
       parameters: parameters,
       progressReporter: progressAdapter,
       cancellationToken: nil
   )
   
   return (snapshots, progressStream)
   ```

2. **Legacy Callback-Based Progress**:
   ```swift
   try await operationsService.listSnapshots(
       parameters: parameters,
       progressReporter: progressReporter,
       cancellationToken: cancellationToken
   )
   ```

## Error Handling

Errors are handled in a structured, privacy-aware manner:

```swift
do {
    // Execute operation
    return try await executeOperation(...)
} catch is CancellationError {
    // Map cancellation errors
    throw BackupError.operationCancelled(
        "Operation was cancelled",
        context: errorMapper.createCancellationContext(operation: "listSnapshots")
    )
} catch {
    // Map other errors with privacy-aware context
    let mappedError = errorMapper.mapError(
        error, 
        context: errorLogContextMapper.createContext(parameters)
    )
    throw mappedError
}
```

## Metrics Collection

Operations automatically collect performance metrics:

```swift
// Start timing
let startTime = Date()

// Execute operation
let result = try await executeOperation(...)

// Record metrics
await metricsCollector.recordOperationCompleted(
    operation: "listSnapshots",
    duration: Date().timeIntervalSince(startTime),
    success: true
)

return result
```

These metrics can be retrieved for monitoring and diagnostics:

```swift
let metrics = await snapshotService.getMetrics()
let successRates = await snapshotService.getSuccessRates()
```

## Migration Guide

### Migrating from Legacy SnapshotServiceImpl

When migrating from the legacy implementation to the Alpha Dot Five architecture:

1. **Update Factory Usage**:
   ```swift
   // Legacy code
   let snapshotService = BackupServiceFactory().createSnapshotService(
       resticService: resticService,
       logger: logger
   )
   
   // Already updated to return ModernSnapshotServiceImpl
   ```

2. **Use AsyncStream Progress API** (recommended):
   ```swift
   // Get progress stream along with operation result
   let (snapshots, progressStream) = try await snapshotService.listSnapshots(
       repositoryID: repoId,
       tags: ["important"],
       before: nil,
       after: nil,
       path: nil,
       limit: nil
   )
   
   // Process progress updates
   Task {
       for await progress in progressStream {
           // Update UI with progress information
           updateProgressUI(progress.progress, message: progress.message)
           
           if let error = progress.error {
               // Handle error
               showError(error)
           }
       }
   }
   ```

3. **Continue Using Legacy API** (for backwards compatibility):
   ```swift
   // Legacy API with progress reporter and cancellation token
   let snapshots = try await snapshotService.listSnapshots(
       repositoryID: repoId,
       tags: ["important"],
       before: nil,
       after: nil,
       path: nil,
       limit: nil,
       progressReporter: myProgressReporter,
       cancellationToken: myCancellationToken
   )
   ```

## Benefits of Alpha Dot Five Architecture

The refactored implementation provides several key benefits:

1. **Better Separation of Concerns**
   - Each service component has a clear, focused responsibility
   - Improved testability and maintainability

2. **Enhanced Privacy Controls**
   - Consistently applied privacy-aware logging throughout
   - Proper structured error handling with privacy annotations

3. **Improved Performance Monitoring**
   - Comprehensive metrics collection for all operations
   - Operation timing and success rate tracking

4. **Type Safety**
   - Parameter objects prevent invalid parameter combinations
   - Improved compile-time safety with dedicated DTOs

5. **Backward Compatibility**
   - Support for both modern and legacy APIs
   - Gradual migration path for existing code

## Example Usage

```swift
// Modern API with AsyncStream
do {
    // Start the operation
    let (snapshots, progressStream) = try await snapshotService.listSnapshots(
        repositoryID: repoId,
        tags: ["important"],
        before: nil,
        after: nil,
        path: nil,
        limit: 10
    )
    
    // Process the result
    await processSnapshots(snapshots)
    
    // Monitor progress in a separate task
    Task {
        for await progress in progressStream {
            await updateUI(progress: progress.progress, message: progress.message)
            
            if let error = progress.error {
                await showError(error)
            }
        }
    }
    
} catch {
    // Handle operation errors
    await handleError(error)
}
```

## Future Enhancements

Planned enhancements to the Alpha Dot Five architecture include:

1. Extending component-based architecture to BackupServiceImpl
2. Adding specialized metrics dashboards and monitoring
3. Further privacy enhancements with improved data classification
4. Extended validation for parameter objects
5. Integration with domain-specific logger factories
