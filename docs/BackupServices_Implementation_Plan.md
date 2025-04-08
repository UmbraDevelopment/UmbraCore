# BackupServices Implementation Plan

This document provides a step-by-step implementation plan for refactoring the BackupServices module to fully align with the Alpha Dot Five architecture. The implementation focuses on introducing actor-based concurrency, type safety, and privacy-by-design while maintaining British spelling in documentation.

## 1. Interface Refactoring (BackupInterfaces)

### 1.1 Update `BackupServiceProtocol`

Replace the existing protocol with a Result-based version:

```swift
/// Protocol defining the requirements for a backup service
public protocol BackupServiceProtocol: Sendable {
    /// Creates a new backup
    /// - Parameters:
    ///   - sources: Source paths to back up
    ///   - excludePaths: Optional paths to exclude
    ///   - tags: Optional tags to associate with the backup
    ///   - options: Optional backup options
    /// - Returns: A Result containing either the backup result and progress stream, or an error
    func createBackup(
        sources: [URL],
        excludePaths: [URL]?,
        tags: [String]?,
        options: BackupOptions?
    ) async -> Result<(BackupResult, AsyncStream<BackupProgress>), BackupOperationError>

    /// Restores a backup
    /// - Parameters:
    ///   - snapshotID: ID of the snapshot to restore
    ///   - targetPath: Path to restore to
    ///   - includePaths: Optional paths to include
    ///   - excludePaths: Optional paths to exclude
    ///   - options: Optional restore options
    /// - Returns: A Result containing either the restore result and progress stream, or an error
    func restoreBackup(
        snapshotID: String,
        targetPath: URL,
        includePaths: [URL]?,
        excludePaths: [URL]?,
        options: RestoreOptions?
    ) async -> Result<(RestoreResult, AsyncStream<BackupProgress>), BackupOperationError>

    // Other methods converted to similar Result pattern...
}
```

### 1.2 Define `BackupOperationError`

Create a comprehensive error type to replace thrown errors:

```swift
/// Errors that can occur during backup operations
public enum BackupOperationError: Error, Sendable, Equatable {
    /// Invalid input was provided
    case invalidInput(String)
    
    /// Access was denied to a required resource
    case accessDenied(String)
    
    /// The requested snapshot was not found
    case snapshotNotFound(String)
    
    /// The operation was cancelled
    case operationCancelled(String)
    
    /// A repository-level error occurred
    case repositoryError(RepositoryError)
    
    /// The operation timed out
    case timeout(String)
    
    /// A system-level error occurred
    case systemError(String)
    
    /// An unexpected error occurred
    case unexpected(String)
    
    // Include catch-all for future compatibility
    @unknown default case unknown(String)
}
```

### 1.3 Create Generic `BackupOperationResult`

Implement a generic result type to standardise the return type pattern:

```swift
/// Result of a backup operation with generically-typed success value
public struct BackupOperationResult<Success>: Sendable, Equatable where Success: Sendable, Success: Equatable {
    /// The operation-specific result
    public let value: Success
    
    /// Optional progress reporting stream
    public let progressStream: AsyncStream<BackupProgress>?
    
    /// Metadata about the operation
    public let metadata: BackupOperationMetadata
    
    /// Creates a new operation result
    /// - Parameters:
    ///   - value: The operation-specific result
    ///   - progressStream: Optional progress reporting stream
    ///   - metadata: Metadata about the operation
    public init(
        value: Success,
        progressStream: AsyncStream<BackupProgress>? = nil,
        metadata: BackupOperationMetadata
    ) {
        self.value = value
        self.progressStream = progressStream
        self.metadata = metadata
    }
}

/// Metadata about a backup operation
public struct BackupOperationMetadata: Sendable, Equatable {
    /// The time the operation started
    public let startTime: Date
    
    /// The time the operation completed
    public let endTime: Date
    
    /// The duration of the operation in seconds
    public let duration: TimeInterval
    
    /// Creates new operation metadata
    /// - Parameters:
    ///   - startTime: The time the operation started
    ///   - endTime: The time the operation completed
    public init(startTime: Date, endTime: Date) {
        self.startTime = startTime
        self.endTime = endTime
        self.duration = endTime.timeIntervalSince(startTime)
    }
}
```

## 2. Actor Implementation (BackupServices)

### 2.1 Update `BackupServicesActor`

Refactor the existing implementation to use Result types:

```swift
/**
 # Backup Services Actor
 
 This actor provides thread-safe backup operations following the
 Alpha Dot Five architecture, ensuring proper state isolation and
 concurrency safety while providing a clean interface for clients.
 
 ## Usage
 
 ```swift
 let actor = BackupServicesActor(repository: myRepo, logger: myLogger)
 
 let result = await actor.createBackup(
     sources: [myURL],
     excludePaths: nil,
     tags: ["weekly"]
 )
 
 switch result {
 case .success(let result):
     // Use result.value and result.progressStream
 case .failure(let error):
     // Handle error
 }
 ```
 */
public actor BackupServicesActor: BackupServiceProtocol {
    // MARK: - Properties
    
    /// The operations service
    private let operationsService: BackupOperationsService
    
    /// The operation executor
    private let operationExecutor: BackupOperationExecutor
    
    /// The backup logger
    private let backupLogger: BackupLogger
    
    /// Active operation tokens
    private var activeOperations: [String: CancellationToken] = [:]
    
    // MARK: - Initialisation
    
    /**
     * Initialises a new backup services actor
     *
     * - Parameters:
     *   - resticService: Restic service for backend operations
     *   - logger: Logger for operation tracking
     *   - repositoryInfo: Repository connection details
     */
    public init(
        resticService: ResticServiceProtocol,
        logger: any LoggingProtocol,
        repositoryInfo: RepositoryInfo
    ) {
        // Create components
        let commandFactory = BackupCommandFactory()
        let resultParser = BackupResultParser()
        
        // Initialize component services
        operationsService = BackupOperationsService(
            resticService: resticService,
            repositoryInfo: repositoryInfo,
            commandFactory: commandFactory,
            resultParser: resultParser
        )
        
        // Create the backup logger
        backupLogger = BackupLogger(logger: logger)
        
        // Create needed components
        let errorLogContextMapper = ErrorLogContextMapper()
        let errorMapper = BackupErrorMapper()
        let metricsCollector = BackupMetricsCollector()
        let cancellationHandler = ModernCancellationHandler()
        
        // Initialize operation executor
        operationExecutor = BackupOperationExecutor(
            logger: logger,
            cancellationHandler: cancellationHandler,
            metricsCollector: metricsCollector,
            errorLogContextMapper: errorLogContextMapper,
            errorMapper: errorMapper
        )
    }

    // MARK: - BackupServiceProtocol Implementation
    
    /**
     * Creates a backup from the provided sources
     *
     * - Parameters:
     *   - sources: Paths to include in the backup
     *   - excludePaths: Optional paths to exclude
     *   - tags: Optional tags to apply to the backup
     *   - options: Optional backup configuration options
     * - Returns: A Result containing either the operation result or an error
     */
    public func createBackup(
        sources: [URL],
        excludePaths: [URL]? = nil,
        tags: [String]? = nil,
        options: BackupOptions? = nil
    ) async -> Result<(BackupResult, AsyncStream<BackupProgress>), BackupOperationError> {
        // Create a log context
        let logContext = BackupLogContext(operation: "createBackup")
        
        // Log operation start
        await backupLogger.logOperationStart(context: logContext)
        
        // Input validation
        guard !sources.isEmpty else {
            let error = BackupOperationError.invalidInput("Sources cannot be empty")
            await backupLogger.logOperationError(context: logContext, error: error)
            return .failure(error)
        }
        
        // Create parameters
        let parameters = BackupCreateParameters(
            sources: sources,
            excludePaths: excludePaths,
            tags: tags,
            options: options
        )
        
        // Generate a token for this operation
        let token = CancellationToken(id: UUID().uuidString)
        let operationID = token.id
        activeOperations[operationID] = token

        do {
            // Create progress reporter
            let progressReporter = AsyncProgressReporter<BackupProgress>()
            
            // Execute the operation
            let result = try await operationExecutor.execute(
                parameters: parameters,
                operation: { params, progress, token in
                    return try await operationsService.createBackup(
                        parameters: params as! BackupCreateParameters,
                        progressReporter: progress,
                        cancellationToken: token
                    )
                },
                progressReporter: progressReporter,
                cancellationToken: token
            )
            
            // Log success
            await backupLogger.logOperationSuccess(context: logContext)
            
            // Remove token and return result
            activeOperations[operationID] = nil
            return .success((result, progressReporter.stream))
        } catch {
            // Map error to BackupOperationError
            let backupError = mapToBackupOperationError(error)
            
            // Log error
            await backupLogger.logOperationError(
                context: logContext,
                error: backupError
            )
            
            // Remove token and return error
            activeOperations[operationID] = nil
            return .failure(backupError)
        }
    }
    
    // Additional methods would follow the same pattern...
    
    // MARK: - Helper Methods
    
    /**
     * Maps any error to a BackupOperationError
     *
     * - Parameter error: The error to map
     * - Returns: A BackupOperationError
     */
    private func mapToBackupOperationError(_ error: Error) -> BackupOperationError {
        if let backupError = error as? BackupOperationError {
            return backupError
        } else if let cancellationError = error as? CancellationError {
            return .operationCancelled("Operation was cancelled")
        } else {
            return .unexpected("Unexpected error: \(error.localizedDescription)")
        }
    }
}
```

### 2.2 Implement `BackupLogger`

Create a dedicated domain-specific logger:

```swift
/**
 * A domain-specific logger for backup operations
 *
 * This logger provides structured, privacy-aware logging specifically for
 * backup operations, following the Alpha Dot Five architecture principles.
 */
public struct BackupLogger {
    /// The base domain logger
    private let domainLogger: DomainLogger
    
    /**
     * Initialises a new backup logger
     *
     * - Parameter logger: The underlying logging protocol
     */
    public init(logger: LoggingProtocol) {
        self.domainLogger = BaseDomainLogger(logger: logger)
    }
    
    /**
     * Logs the start of a backup operation
     *
     * - Parameters:
     *   - context: The log context
     *   - message: Optional custom message
     */
    public func logOperationStart(
        context: LogContextDTO,
        message: String? = nil
    ) async {
        let defaultMessage = "Starting backup operation"
        await domainLogger.logOperationStart(
            context: context, 
            message: message ?? defaultMessage
        )
    }
    
    /**
     * Logs the successful completion of a backup operation
     *
     * - Parameters:
     *   - context: The log context
     *   - result: Optional operation result
     *   - message: Optional custom message
     */
    public func logOperationSuccess<R: Sendable>(
        context: LogContextDTO,
        result: R? = nil,
        message: String? = nil
    ) async {
        let defaultMessage = "Backup operation completed successfully"
        await domainLogger.logOperationSuccess(
            context: context, 
            result: result, 
            message: message ?? defaultMessage
        )
    }
    
    /**
     * Logs an error that occurred during a backup operation
     *
     * - Parameters:
     *   - context: The log context
     *   - error: The error that occurred
     *   - message: Optional custom message
     */
    public func logOperationError(
        context: LogContextDTO,
        error: Error,
        message: String? = nil
    ) async {
        let errorMessage = message ?? "Backup operation failed: \(error.localizedDescription)"
        await domainLogger.logOperationError(
            context: context,
            error: error,
            message: errorMessage
        )
    }
}
```

### 2.3 Implement `BackupLogContext`

Create a standardised log context:

```swift
/**
 * A log context for backup operations
 *
 * This context provides structured, privacy-aware logging context for backup
 * operations, ensuring sensitive information is properly protected.
 */
public struct BackupLogContext: LogContextDTO, Sendable, Equatable {
    /// The source identifier for this log context
    private let source: String = "BackupServices"
    
    /// The operation being performed
    private let operation: String
    
    /// Metadata collection with privacy annotations
    private let metadata: LogMetadataDTOCollection
    
    /**
     * Initialises a new backup log context
     *
     * - Parameters:
     *   - operation: The operation being performed
     *   - additionalContext: Optional additional context information
     */
    public init(
        operation: String,
        additionalContext: [String: String]? = nil
    ) {
        self.operation = operation
        
        // Initialise metadata collection
        self.metadata = LogMetadataDTOCollection()
            .with(key: "operation", value: operation, privacyLevel: .public)
        
        // Add any additional context if provided
        additionalContext?.forEach { key, value in
            self.metadata = self.metadata.with(key: key, value: value, privacyLevel: .public)
        }
    }
    
    /**
     * Get the source identifier for this log context
     *
     * - Returns: The source identifier
     */
    public func getSource() -> String {
        return source
    }
    
    /**
     * Get metadata for this log context
     *
     * - Returns: The context metadata
     */
    public func getMetadata() -> LogMetadata {
        return metadata.buildMetadata()
    }
    
    /**
     * Create a new context with an additional key-value pair
     *
     * - Parameters:
     *   - key: The key for the value
     *   - value: The value to add
     *   - privacyLevel: The privacy level
     * - Returns: A new context with the additional value
     */
    public func with(
        key: String,
        value: String,
        privacyLevel: LogPrivacyLevel
    ) -> BackupLogContext {
        let newMetadata = self.metadata.with(key: key, value: value, privacyLevel: privacyLevel)
        var newContext = self
        newContext.metadata = newMetadata
        return newContext
    }
}
```

## 3. Client Code Migration Examples

### 3.1 BackupCoordinator Migration

```swift
// Before
func startBackup() async {
    do {
        let (result, progress) = try await backupService.createBackup(
            sources: selectedSources,
            excludePaths: excludedPaths,
            tags: selectedTags
        )
        
        // Process result and set up progress tracking
        self.currentBackupId = result.backupId
        self.trackProgress(progress)
    } catch {
        // Handle error
        handleBackupError(error)
    }
}

// After
func startBackup() async {
    let result = await backupActor.createBackup(
        sources: selectedSources,
        excludePaths: excludedPaths,
        tags: selectedTags
    )
    
    switch result {
    case .success(let (backupResult, progress)):
        // Process result and set up progress tracking
        self.currentBackupId = backupResult.backupId
        self.trackProgress(progress)
    
    case .failure(let error):
        // Handle specific error types
        switch error {
        case .invalidInput(let message):
            handleInputError(message)
        case .accessDenied(let message):
            handleAccessError(message)
        case .operationCancelled:
            handleCancellation()
        default:
            handleGenericError(error)
        }
    }
}
```

### 3.2 Progress Tracking Migration

```swift
// Before
func trackProgress(_ progress: AsyncStream<BackupProgress>) {
    Task {
        for await update in progress {
            await MainActor.run {
                // Update UI with progress
                self.updateProgressUI(update)
            }
        }
        
        await MainActor.run {
            // Progress complete
            self.finishProgressUI()
        }
    }
}

// After - No changes needed for the progress tracking function!
// The AsyncStream approach is compatible with Alpha Dot Five
func trackProgress(_ progress: AsyncStream<BackupProgress>) {
    Task {
        for await update in progress {
            await MainActor.run {
                // Update UI with progress
                self.updateProgressUI(update)
            }
        }
        
        await MainActor.run {
            // Progress complete
            self.finishProgressUI()
        }
    }
}
```

## 4. BUILD File Updates

### 4.1 BackupInterfaces BUILD File

```python
swift_library(
    name = "BackupInterfaces",
    srcs = glob(["**/*.swift"]),
    deps = [
        "//packages/UmbraCoreTypes/Sources/LoggingTypes:LoggingTypes",
        "//packages/UmbraCoreTypes/Sources/UmbraErrors:UmbraErrors",
        "//packages/UmbraInterfaces/Sources/CoreInterfaces:CoreInterfaces",
        "//packages/UmbraInterfaces/Sources/FileSystemInterfaces:FileSystemInterfaces",
        "//packages/UmbraInterfaces/Sources/RepositoryInterfaces:RepositoryInterfaces",
    ],
    visibility = ["//visibility:public"],
)
```

### 4.2 BackupServices BUILD File

```python
swift_library(
    name = "BackupServices",
    srcs = glob(["**/*.swift"]),
    deps = [
        "//packages/UmbraCoreTypes/Sources/LoggingTypes:LoggingTypes",
        "//packages/UmbraCoreTypes/Sources/UmbraErrors:UmbraErrors",
        "//packages/UmbraInterfaces/Sources/BackupInterfaces:BackupInterfaces",
        "//packages/UmbraInterfaces/Sources/FileSystemInterfaces:FileSystemInterfaces",
        "//packages/UmbraInterfaces/Sources/LoggingInterfaces:LoggingInterfaces",
        "//packages/UmbraInterfaces/Sources/ResticInterfaces:ResticInterfaces",
        "//packages/UmbraInterfaces/Sources/RepositoryInterfaces:RepositoryInterfaces",
        "//packages/UmbraImplementations/Sources/LoggingServices:LoggingServices",
        "//packages/UmbraImplementations/Sources/ResticServices:ResticServices",
    ],
    visibility = ["//visibility:public"],
)
```

## 5. Implementation Sequence

1. Start with interface changes in BackupInterfaces
   - Update BackupServiceProtocol
   - Create BackupOperationError
   - Create BackupOperationResult

2. Create core logging components in BackupServices
   - Implement BackupLogContext
   - Implement BackupLogger

3. Refactor core implementation classes
   - Update BackupOperationExecutor to use Result
   - Create BackupServicesActor
   - Update/rename ModernBackupServiceImpl

4. Update client code
   - Modify BackupCoordinator to use new interfaces
   - Update UI components for progress handling

5. Update BUILD files
   - Update BackupInterfaces dependencies
   - Update BackupServices dependencies
   - Check client module dependencies

## 6. Documentation Priorities

Include comprehensive documentation for:

1. Public interfaces and expected usage patterns
2. Error cases and how to handle them
3. Actor isolation guarantees
4. Privacy constraints on logged data
5. Migration examples for existing client code

All documentation should use British English spelling (e.g., "initialise" not "initialize") while maintaining American spelling in code identifiers.
