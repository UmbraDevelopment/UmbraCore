# BackupServices Module Refactoring Plan

This document outlines the step-by-step approach for refactoring the BackupServices module to comply with the Alpha Dot Five architecture. The plan emphasises comprehensive documentation and client code updates to ensure a smooth transition.

## Table of Contents

1. [Current Structure Analysis](#current-structure-analysis)
2. [Interface Refactoring](#interface-refactoring)
3. [Implementation Refactoring](#implementation-refactoring)
4. [Documentation Enhancements](#documentation-enhancements)
5. [Client Code Migration](#client-code-migration)
6. [BUILD File Updates](#build-file-updates)
7. [Implementation Checklist](#implementation-checklist)

## Current Structure Analysis

Before beginning refactoring, analyse the current structure of the BackupServices module:

```bash
# List all files in BackupServices module
find /Users/mpy/CascadeProjects/UmbraCore/packages/UmbraImplementations/Sources/BackupServices -type f -name "*.swift" | sort
```

### Key Components to Identify

1. **Public Interfaces**: Which protocols are exposed to clients?
2. **State Management**: What mutable state needs actor protection?
3. **Error Handling**: How are errors currently handled?
4. **Logging Patterns**: How is the current logging implemented?
5. **Client Dependencies**: Which modules depend on BackupServices?

### Dependency Analysis

```bash
# Find all modules that depend on BackupServices
bazelisk query "rdeps(//packages/..., //packages/UmbraImplementations/Sources/BackupServices:BackupServices)"
```

## Interface Refactoring

### 1. Update BackupInterfaces Protocol Definitions

Start by refactoring the protocol definitions in the BackupInterfaces module:

- Add proper documentation comments that use British spelling
- Update method signatures to use async/await
- Change thrown errors to Result types
- Ensure all types are Sendable where appropriate

**Example: BackupServiceProtocol**

```swift
/// Protocol defining the service interface for backup operations
///
/// This protocol follows the Alpha Dot Five architecture and provides
/// operations for creating, managing, and restoring backups with proper
/// concurrency safety and privacy controls.
public protocol BackupServiceProtocol: Sendable {
    /// Creates a new snapshot with the specified sources and exclusions
    ///
    /// This operation captures a point-in-time backup of the specified sources,
    /// excluding any paths in the exclusions list. The operation is performed
    /// asynchronously and reports progress through the optional progress handler.
    ///
    /// - Parameters:
    ///   - sources: The list of source URLs to include in the snapshot
    ///   - excludes: Optional list of URLs to exclude from the snapshot
    ///   - tags: Optional list of tags to associate with the snapshot
    /// - Returns: A Result containing either the snapshot information or an error
    func createSnapshot(
        withSources sources: [URL],
        excludes: [URL]?,
        tags: [String]?
    ) async -> Result<SnapshotInfo, BackupOperationError>
    
    // Additional methods...
}
```

### 2. Define Proper Error Types

Create a dedicated error enum for backup operations:

```swift
/// Errors that can occur during backup operations
///
/// This enum defines the comprehensive set of errors that can occur
/// during backup operations, providing specific details about each failure mode.
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
    
    /// Resource limits were exceeded
    case resourceLimitExceeded(String)
    
    /// An unexpected error occurred
    case unexpected(String)
    
    // Include catch-all for future compatibility
    @unknown default case unknown(String)
}
```

### 3. Define Logging Context Types

Ensure logging context types correctly implement the LogContextDTO protocol:

```swift
/// Logging context for backup operations
///
/// This context type provides structured, privacy-aware logging for backup operations
/// following the Alpha Dot Five architecture principles.
public struct BackupLogContext: LogContextDTO, Sendable, Equatable {
    /// The source identifier for this log context
    private let source: String = "BackupServices"
    
    /// The operation being performed
    private let operation: String
    
    /// Metadata collection with privacy annotations
    private let metadata: LogMetadataDTOCollection
    
    /// Create a new backup log context
    /// - Parameters:
    ///   - operation: The operation being performed
    ///   - additionalContext: Optional additional context information
    public init(
        operation: String,
        additionalContext: [String: String]? = nil
    ) {
        self.operation = operation
        
        // Initialise metadata collection
        self.metadata = LogMetadataDTOCollection()
        
        // Add standard fields
        self.metadata.add(key: "operation", value: operation, privacy: .public)
        
        // Add any additional context if provided
        additionalContext?.forEach { key, value in
            self.metadata.add(key: key, value: value, privacy: .public)
        }
    }
    
    /// Get the source identifier for this log context
    public func getSource() -> String {
        return source
    }
    
    /// Get metadata for this log context
    public func getMetadata() -> LogMetadata {
        return metadata.buildMetadata()
    }
    
    // Additional helper methods...
}
```

## Implementation Refactoring

### 1. Create BackupServicesActor

Create an actor implementation of the BackupServiceProtocol:

```swift
/// Actor-based implementation of the BackupServiceProtocol
///
/// This actor provides thread-safe backup operations following the
/// Alpha Dot Five architecture, ensuring proper state isolation and
/// concurrency safety while providing a clean interface for clients.
public actor BackupServicesActor: BackupServiceProtocol {
    // MARK: - Properties
    
    /// The repository used for backup operations
    private let repository: RepositoryProtocol
    
    /// The file system service for file operations
    private let fileSystem: FileSystemServiceProtocol
    
    /// The logger for backup operations
    private let logger: LoggingProtocol
    
    /// The domain-specific backup logger
    private let backupLogger: BackupLogger
    
    /// Active backup sessions
    private var activeSessions: [String: BackupSession] = [:]
    
    // MARK: - Initialisation
    
    /// Initialises a new BackupServicesActor with the required dependencies
    ///
    /// - Parameters:
    ///   - repository: The repository to use for backup operations
    ///   - fileSystem: The file system service for file operations
    ///   - logger: The logger for recording operations
    public init(
        repository: RepositoryProtocol,
        fileSystem: FileSystemServiceProtocol,
        logger: LoggingProtocol
    ) {
        self.repository = repository
        self.fileSystem = fileSystem
        self.logger = logger
        self.backupLogger = BackupLogger(logger: logger)
    }
    
    // MARK: - BackupServiceProtocol Implementation
    
    /// Create a new snapshot with the specified sources and exclusions
    ///
    /// - Parameters:
    ///   - sources: The source URLs to include
    ///   - excludes: Optional URLs to exclude
    ///   - tags: Optional tags to associate with the snapshot
    /// - Returns: A Result containing either the snapshot info or an error
    public func createSnapshot(
        withSources sources: [URL],
        excludes: [URL]? = nil,
        tags: [String]? = nil
    ) async -> Result<SnapshotInfo, BackupOperationError> {
        // Implementation details...
    }
    
    // Additional methods...
}
```

### 2. Implement Domain-Specific Logger

Create a BackupLogger class to handle backup-specific logging:

```swift
/// A logger specialised for backup operations
///
/// This logger provides domain-specific logging for backup operations
/// with appropriate privacy controls and structured logging.
public struct BackupLogger {
    /// The base domain logger
    private let domainLogger: DomainLogger
    
    /// Create a new backup logger
    /// - Parameter logger: The underlying logging protocol
    public init(logger: LoggingProtocol) {
        self.domainLogger = BaseDomainLogger(logger: logger)
    }
    
    /// Log a backup operation start
    /// - Parameters:
    ///   - operation: The operation being performed
    ///   - additionalContext: Additional context information
    ///   - message: Optional custom message
    public func logOperationStart(
        operation: String,
        additionalContext: [String: String]? = nil,
        message: String? = nil
    ) async {
        let context = BackupLogContext(
            operation: operation,
            additionalContext: additionalContext
        )
        
        let defaultMessage = "Starting backup \(operation) operation"
        await domainLogger.logOperationStart(
            context: context, 
            message: message ?? defaultMessage
        )
    }
    
    // Additional logging methods...
}
```

## Documentation Enhancements

### 1. Create Module Documentation

Create a comprehensive module documentation file:

```swift
/**
 # BackupServices
 
 The BackupServices module provides a thread-safe, actor-based implementation
 of backup operations following the Alpha Dot Five architecture.
 
 ## Key Components
 
 - `BackupServicesActor`: The primary actor implementation of BackupServiceProtocol
 - `BackupLogger`: Domain-specific logger for backup operations
 - `SnapshotLogContextAdapter`: Adapter for snapshot-specific logging
 
 ## Usage
 
 ```swift
 // Create the actor
 let backupActor = BackupServicesActor(
     repository: myRepository,
     fileSystem: myFileSystem,
     logger: myLogger
 )
 
 // Create a snapshot
 let result = await backupActor.createSnapshot(
     withSources: [myURL],
     excludes: nil,
     tags: ["weekly", "important"]
 )
 
 // Handle the result
 switch result {
 case .success(let snapshotInfo):
     print("Created snapshot: \(snapshotInfo.id)")
 case .failure(let error):
     print("Failed to create snapshot: \(error)")
 }
 ```
 
 ## Concurrency
 
 All operations are performed asynchronously using Swift actors to ensure
 thread safety. When using this module, always access methods using `await`
 and handle Result types appropriately.
 
 ## Error Handling
 
 Errors are returned as part of Result types rather than thrown exceptions.
 Specific error cases are defined in `BackupOperationError`.
 
 ## Privacy Controls
 
 All logging is privacy-aware, with appropriate redaction for sensitive
 information like file paths and content.
 
 ## BUILD Dependencies
 
 This module requires the following dependencies:
 - BackupInterfaces
 - LoggingInterfaces
 - RepositoryInterfaces
 - FileSystemInterfaces
 */
```

### 2. Add Method Documentation

Ensure all public methods have comprehensive documentation:

```swift
/**
 Retrieves information about a snapshot.
 
 This method fetches detailed information about a snapshot with the
 specified identifier, including its metadata, tags, creation time,
 and size statistics.
 
 - Parameter id: The unique identifier of the snapshot to retrieve
 - Returns: A Result containing either the snapshot information or an error
 
 ## Example
 
 ```swift
 let result = await backupActor.getSnapshotInfo(id: "snapshot-123")
 switch result {
 case .success(let info):
     // Use snapshot info
 case .failure(let error):
     // Handle error
 }
 ```
 
 ## Error Cases
 
 - `.snapshotNotFound`: If the snapshot with the given ID doesn't exist
 - `.repositoryError`: If an error occurs at the repository level
 - `.accessDenied`: If the repository is not accessible
 */
public func getSnapshotInfo(id: String) async -> Result<SnapshotInfo, BackupOperationError> {
    // Implementation
}
```

### 3. Document State Management

Clearly document how state is managed within the actor:

```swift
/**
 Active backup sessions, keyed by session ID.
 
 This dictionary maintains the state of all active backup operations,
 including their progress, cancellation tokens, and configuration.
 
 Access to this state is protected by the actor's isolation system,
 ensuring thread safety without explicit locks.
 
 ## State Management
 
 - Sessions are added when operations begin
 - Sessions are removed when operations complete or are cancelled
 - Clients cannot directly access this state
 */
private var activeSessions: [String: BackupSession] = [:]
```

## Client Code Migration

### 1. Identify Client Usage Patterns

Provide documentation on how to migrate from existing patterns:

```swift
/**
 # Client Migration Guide
 
 ## Before (Pre-Alpha Dot Five)
 
 ```swift
 let backupService = serviceContainer.backupService
 
 do {
     // Synchronous call with thrown error
     let snapshot = try backupService.createSnapshot(sources: sources)
     // Use snapshot
 } catch {
     // Handle error
 }
 ```
 
 ## After (Alpha Dot Five)
 
 ```swift
 let backupActor = serviceContainer.backupActor
 
 // Async call with Result return
 let result = await backupActor.createSnapshot(
     withSources: sources,
     excludes: nil,
     tags: nil
 )
 
 switch result {
 case .success(let snapshot):
     // Use snapshot
 case .failure(let error):
     // Handle specific error cases
     switch error {
     case .invalidInput(let message):
         // Handle invalid input
     case .repositoryError(let repoError):
         // Handle repository error
     // Handle other cases
     }
 }
 ```
 
 ## Parameter Changes
 
 - `createSnapshot(sources:)` → `createSnapshot(withSources:excludes:tags:)`
 - `restoreSnapshot(id:target:)` → `restoreSnapshot(withID:toTarget:options:)`
 
 ## Error Handling Changes
 
 - Replace `do/catch` with `switch result`
 - Use pattern matching on specific error cases
 - Consider using Result methods like `map`, `flatMap`, etc.
 */
```

### 2. Create Migration Examples

Provide specific examples for common use cases:

```swift
/**
 # Migration Examples
 
 ## Example 1: Creating a Backup
 
 ### Before:
 
 ```swift
 func performBackup() {
     DispatchQueue.global().async {
         do {
             let snapshot = try self.backupService.createSnapshot(sources: self.sources)
             DispatchQueue.main.async {
                 self.updateUI(with: snapshot)
             }
         } catch {
             DispatchQueue.main.async {
                 self.showError(error)
             }
         }
     }
 }
 ```
 
 ### After:
 
 ```swift
 func performBackup() async {
     let result = await backupActor.createSnapshot(
         withSources: sources,
         excludes: nil,
         tags: nil
     )
     
     // Switch on main thread for UI updates
     await MainActor.run {
         switch result {
         case .success(let snapshot):
             updateUI(with: snapshot)
         case .failure(let error):
             showError(error)
         }
     }
 }
 ```
 
 ## Example 2: Listing Snapshots with Filtering
 
 ### Before:
 
 ```swift
 func loadSnapshots(completion: @escaping ([SnapshotInfo]) -> Void) {
     DispatchQueue.global().async {
         do {
             let snapshots = try self.backupService.listSnapshots()
             let filtered = snapshots.filter { $0.tags.contains("important") }
             DispatchQueue.main.async {
                 completion(filtered)
             }
         } catch {
             DispatchQueue.main.async {
                 completion([])
             }
         }
     }
 }
 ```
 
 ### After:
 
 ```swift
 func loadSnapshots() async -> [SnapshotInfo] {
     let result = await backupActor.listSnapshots(
         withTags: ["important"]
     )
     
     switch result {
     case .success(let snapshots):
         return snapshots
     case .failure:
         return []
     }
 }
 ```
 */
```

## BUILD File Updates

### 1. Update BackupInterfaces BUILD File

Document the required changes to BUILD files:

```python
# BackupInterfaces BUILD File Updates

# Before
swift_library(
    name = "BackupInterfaces",
    srcs = glob(["**/*.swift"]),
    deps = [
        "//packages/UmbraCoreTypes/Sources/UmbraErrors:UmbraErrors",
        "//packages/UmbraInterfaces/Sources/CoreInterfaces:CoreInterfaces",
    ],
    visibility = ["//visibility:public"],
)

# After
swift_library(
    name = "BackupInterfaces",
    srcs = glob(["**/*.swift"]),
    deps = [
        "//packages/UmbraCoreTypes/Sources/LoggingTypes:LoggingTypes",
        "//packages/UmbraCoreTypes/Sources/UmbraErrors:UmbraErrors",
        "//packages/UmbraInterfaces/Sources/CoreInterfaces:CoreInterfaces",
        "//packages/UmbraInterfaces/Sources/RepositoryInterfaces:RepositoryInterfaces",
    ],
    visibility = ["//visibility:public"],
)
```

### 2. Update BackupServices BUILD File

```python
# BackupServices BUILD File Updates

# Before
swift_library(
    name = "BackupServices",
    srcs = glob(["**/*.swift"]),
    deps = [
        "//packages/UmbraCoreTypes/Sources/UmbraErrors:UmbraErrors",
        "//packages/UmbraInterfaces/Sources/BackupInterfaces:BackupInterfaces",
        "//packages/UmbraInterfaces/Sources/RepositoryInterfaces:RepositoryInterfaces",
        "//packages/UmbraImplementations/Sources/CoreServices:CoreServices",
    ],
    visibility = ["//visibility:public"],
)

# After
swift_library(
    name = "BackupServices",
    srcs = glob(["**/*.swift"]),
    deps = [
        "//packages/UmbraCoreTypes/Sources/LoggingTypes:LoggingTypes",
        "//packages/UmbraCoreTypes/Sources/UmbraErrors:UmbraErrors",
        "//packages/UmbraInterfaces/Sources/BackupInterfaces:BackupInterfaces",
        "//packages/UmbraInterfaces/Sources/FileSystemInterfaces:FileSystemInterfaces",
        "//packages/UmbraInterfaces/Sources/LoggingInterfaces:LoggingInterfaces",
        "//packages/UmbraInterfaces/Sources/RepositoryInterfaces:RepositoryInterfaces",
        "//packages/UmbraImplementations/Sources/LoggingServices:LoggingServices",
    ],
    visibility = ["//visibility:public"],
)
```

### 3. Client Module BUILD Updates

```python
# Client Module BUILD File Updates

# Any module that depends on BackupServices needs to update its dependencies
# to include both BackupInterfaces and BackupServices

# Example: Update BackupCoordinator BUILD file
swift_library(
    name = "BackupCoordinator",
    srcs = glob(["**/*.swift"]),
    deps = [
        "//packages/UmbraInterfaces/Sources/BackupInterfaces:BackupInterfaces",  # Add interface dependency
        "//packages/UmbraImplementations/Sources/BackupServices:BackupServices",
        # Other dependencies...
    ],
    visibility = ["//visibility:public"],
)
```

## Implementation Checklist

Use this checklist to track progress on the BackupServices refactoring:

- [ ] **Interface Updates**
  - [ ] Update BackupServiceProtocol with async methods
  - [ ] Create BackupOperationError enum
  - [ ] Update SnapshotInfo and related DTOs to be Sendable
  - [ ] Create BackupLogContext

- [ ] **Core Implementation**
  - [ ] Create BackupServicesActor
  - [ ] Implement BackupLogger
  - [ ] Update error handling to use Result types
  - [ ] Ensure proper state isolation with actor properties

- [ ] **Documentation**
  - [ ] Add comprehensive module documentation
  - [ ] Document all public methods
  - [ ] Create migration guide for clients
  - [ ] Document BUILD file changes

- [ ] **Client Code Update Examples**
  - [ ] Create example for creating snapshots
  - [ ] Create example for restoring snapshots
  - [ ] Create example for listing and filtering snapshots
  - [ ] Create example for error handling

- [ ] **BUILD File Updates**
  - [ ] Update BackupInterfaces BUILD file
  - [ ] Update BackupServices BUILD file
  - [ ] Update client module BUILD files
  - [ ] Verify dependencies are correct

- [ ] **Migration Validation**
  - [ ] Compile BackupInterfaces
  - [ ] Compile BackupServices
  - [ ] Compile dependent modules
  - [ ] Verify no regressions in functionality
