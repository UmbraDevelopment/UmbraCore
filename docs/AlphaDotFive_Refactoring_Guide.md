# Alpha Dot Five Architecture Refactoring Guide

This guide provides comprehensive instructions for refactoring UmbraCore modules to comply with the Alpha Dot Five architecture requirements. It details specific patterns, code organisation principles, and concrete examples to ensure consistency across the codebase.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Actor-Based Concurrency](#actor-based-concurrency)
3. [Type Safety Enhancements](#type-safety-enhancements)
4. [Privacy-By-Design Implementation](#privacy-by-design-implementation)
5. [Module Organisation](#module-organisation)
6. [Step-by-Step Refactoring Process](#step-by-step-refactoring-process)
7. [Example Implementations](#example-implementations)
8. [Testing Refactored Code](#testing-refactored-code)
9. [Common Pitfalls and Solutions](#common-pitfalls-and-solutions)
10. [Appendix: British English Usage](#appendix-british-english-usage)

## Architecture Overview

The Alpha Dot Five architecture is built upon three core principles:

1. **Actor-Based Concurrency**: Using Swift actors for thread safety and structured concurrency
2. **Type Safety**: Creating strongly-typed interfaces that make illegal states unrepresentable
3. **Privacy-By-Design**: Enhancing error handling with proper domain-specific errors and privacy-aware logging

This architecture enables more maintainable, secure code with clear thread safety guarantees and improved data protection.

## Actor-Based Concurrency

### Core Principles

- Isolate mutable state within actors
- Use async/await for all operations that access actor state
- Maintain thread safety through actor isolation
- Provide clear interface boundaries

### Implementation Guidelines

#### Actor Declaration

```swift
public actor ServiceNameActor: ServiceProtocol {
    // Private state
    private let dependencies: Dependencies
    private let logger: LoggingProtocol
    private let domainLogger: DomainSpecificLogger
    
    // State that needs thread safety
    private var cache: [String: CachedItem] = [:]
    
    // Initialisation
    public init(dependencies: Dependencies, logger: LoggingProtocol) {
        self.dependencies = dependencies
        self.logger = logger
        self.domainLogger = DomainSpecificLogger(logger: logger)
    }
    
    // Public methods with Result return types
    public func performOperation() async -> Result<OutputType, DomainError> {
        // Implementation
    }
}
```

#### Actor Method Patterns

- Use `async` methods for all actor operations
- Return `Result<Success, Error>` types rather than throwing errors
- Log operation start, success, and failure states consistently
- Validate input parameters before performing operations

#### Example: Before and After

Before:
```swift
public class BackupService: BackupServiceProtocol {
    private let repository: RepositoryProtocol
    
    public func createSnapshot(sources: [URL]) throws -> SnapshotInfo {
        guard !sources.isEmpty else {
            throw BackupError.invalidInput("Sources cannot be empty")
        }
        return try repository.createSnapshot(sources: sources)
    }
}
```

After:
```swift
public actor BackupServicesActor: BackupServiceProtocol {
    private let repository: RepositoryProtocol
    private let logger: LoggingProtocol
    private let backupLogger: BackupLogger
    
    public init(repository: RepositoryProtocol, logger: LoggingProtocol) {
        self.repository = repository
        self.logger = logger
        self.backupLogger = BackupLogger(logger: logger)
    }
    
    public func createSnapshot(sources: [URL]) async -> Result<SnapshotInfo, BackupOperationError> {
        await backupLogger.logOperationStart(
            operation: "createSnapshot",
            additionalContext: LogMetadataDTOCollection()
        )
        
        guard !sources.isEmpty else {
            let error = BackupOperationError.invalidInput("Sources cannot be empty")
            await backupLogger.logOperationError(
                operation: "createSnapshot",
                error: error
            )
            return .failure(error)
        }
        
        let result = await repository.createSnapshot(sources: sources)
        
        switch result {
        case .success(let info):
            await backupLogger.logOperationSuccess(
                operation: "createSnapshot",
                result: info
            )
            return .success(info)
        case .failure(let error):
            await backupLogger.logOperationError(
                operation: "createSnapshot",
                error: error
            )
            return .failure(.repositoryError(error))
        }
    }
}
```

## Type Safety Enhancements

### Core Principles

- Make illegal states unrepresentable
- Use descriptive, strongly-typed enums for error states
- Leverage generic constraints appropriately
- Ensure all types crossing actor boundaries conform to `Sendable`

### Implementation Guidelines

#### Error Type Definitions

```swift
public enum DomainSpecificError: Error, Sendable, Equatable {
    case invalidInput(String)
    case operationFailed(String)
    case resourceNotFound(String)
    case unauthorisedAccess(String)
    case systemError(String)
    
    // Include a catch-all case for future extensibility
    @unknown default case unknown(String)
}
```

#### Sendable Conformance

All types that cross actor boundaries must conform to `Sendable`:

```swift
public struct ConfigurationOptions: Sendable {
    public let timeout: TimeInterval
    public let retryCount: Int
    public let priority: OperationPriority
    
    public init(timeout: TimeInterval, retryCount: Int, priority: OperationPriority) {
        self.timeout = timeout
        self.retryCount = retryCount
        self.priority = priority
    }
}
```

#### Removing Type Aliases

Replace type aliases with direct type references:

Before:
```swift
public typealias BackupResult = Result<SnapshotInfo, BackupError>
public typealias BackupCallback = (BackupResult) -> Void
```

After:
```swift
// No typealias - use the actual types directly in method signatures
public func performBackup() async -> Result<SnapshotInfo, BackupOperationError>
```

## Privacy-By-Design Implementation

### Core Principles

- Implement privacy-level annotations for all logged data
- Create domain-specific logging contexts
- Use structured, explicit privacy controls
- Prevent accidental leakage of sensitive information

### Implementation Guidelines

#### Privacy-Aware Log Context

```swift
public struct DomainLogContext: LogContextDTO, Sendable {
    private let source: String
    private let operation: String
    private let metadata: LogMetadataDTOCollection
    
    public init(operation: String, additionalContext: [String: String]? = nil) {
        self.source = "Domain.Service"
        self.operation = operation
        
        self.metadata = LogMetadataDTOCollection()
            .with(key: "operation", value: operation, privacyLevel: .public)
        
        additionalContext?.forEach { key, value in
            self.metadata = self.metadata.with(key: key, value: value, privacyLevel: .public)
        }
    }
    
    public func getSource() -> String {
        return source
    }
    
    public func getMetadata() -> LogMetadata {
        return metadata.buildMetadata()
    }
}
```

#### Domain-Specific Logger

```swift
public struct DomainLogger {
    private let logger: LoggingProtocol
    
    public init(logger: LoggingProtocol) {
        self.logger = logger
    }
    
    public func logOperationStart(
        context: LogContextDTO,
        message: String
    ) async {
        await logger.log(
            level: .info,
            message: message,
            context: context
        )
    }
    
    public func logOperationSuccess<R: Sendable>(
        context: LogContextDTO,
        result: R? = nil,
        message: String
    ) async {
        await logger.log(
            level: .info,
            message: message,
            context: context
        )
    }
    
    public func logOperationError(
        context: LogContextDTO,
        error: Error,
        message: String? = nil
    ) async {
        let errorMessage = message ?? "Operation failed: \(error.localizedDescription)"
        await logger.log(
            level: .error,
            message: errorMessage,
            context: context
        )
    }
}
```

#### Privacy-Level Annotations

Always use explicit privacy levels when logging data:

```swift
let metadata = LogMetadataDTOCollection()
    .with(key: "userId", value: userId, privacyLevel: .hash)
    .with(key: "operation", value: "login", privacyLevel: .public)
    .with(key: "ipAddress", value: ipAddress, privacyLevel: .private)
```

## Module Organisation

### Interface and Implementation Separation

Proper separation between interfaces and implementations:

1. **Interfaces Module Structure**
   - Define protocols in interface modules
   - Include DTOs and type definitions
   - Error type declarations
   - No concrete implementations

2. **Implementation Module Structure**
   - Actor implementations of protocols
   - Domain-specific loggers
   - Adapters and converters
   - Concrete implementations of protocols

### File Naming Conventions

- `SomethingProtocol.swift` - Protocol definitions
- `SomethingActor.swift` - Actor implementations
- `SomethingLogger.swift` - Domain-specific loggers
- `SomethingContext.swift` - Logging contexts
- `SomethingError.swift` - Error definitions

## Step-by-Step Refactoring Process

### 1. Analysis Phase

1. Identify all mutable state that requires thread safety
2. Document all public interfaces and their usages
3. Catalogue current error handling approaches
4. Identify privacy concerns in logging and data handling

### 2. Interface Definition

1. Create or update protocol definitions with async methods
2. Update return types to use `Result<Success, Error>` instead of throws
3. Define proper DTOs that conform to `Sendable`
4. Define domain-specific error types

### 3. Actor Implementation

1. Create an actor that implements the protocol
2. Move all mutable state inside the actor
3. Implement methods using async/await
4. Add proper error handling with Result types
5. Implement privacy-aware logging

### 4. Logging Enhancement

1. Create domain-specific log context types
2. Implement specialised logger for the domain
3. Update all logging to use privacy annotations
4. Ensure consistent operation lifecycle logging (start/success/error)

### 5. Client Migration

1. Update all clients to use async/await with the new actor
2. Replace direct property access with method calls
3. Handle Result types appropriately
4. Ensure proper error propagation

### 6. Testing

1. Create unit tests for the refactored actor
2. Test concurrency behaviour
3. Verify privacy controls
4. Test error handling cases

## Example Implementations

### Example: BackupServicesActor

```swift
public actor BackupServicesActor: BackupServiceProtocol {
    // MARK: - Properties
    
    private let repository: RepositoryProtocol
    private let fileSystem: FileSystemServiceProtocol
    private let logger: LoggingProtocol
    private let backupLogger: BackupLogger
    
    // Actor-isolated state
    private var activeSessions: [String: BackupSession] = [:]
    private var progressTrackers: [String: ProgressTracker] = [:]
    
    // MARK: - Initialisation
    
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
    
    // MARK: - Public Methods
    
    public func createSnapshot(
        withSources sources: [URL],
        excludes: [URL]? = nil,
        tags: [String]? = nil
    ) async -> Result<SnapshotInfo, BackupOperationError> {
        let logContext = SnapshotLogContext(
            operation: "createSnapshot",
            additionalContext: ["sourceCount": "\(sources.count)"]
        )
        
        await backupLogger.logOperationStart(context: logContext)
        
        // Input validation
        guard !sources.isEmpty else {
            let error = BackupOperationError.invalidInput("Sources cannot be empty")
            await backupLogger.logOperationError(context: logContext, error: error)
            return .failure(error)
        }
        
        // Check file permissions
        for source in sources {
            let accessResult = await fileSystem.checkAccess(to: source, mode: .read)
            if case .failure(let error) = accessResult {
                let backupError = BackupOperationError.accessDenied(
                    "Cannot access source: \(source.path), reason: \(error.localizedDescription)"
                )
                await backupLogger.logOperationError(context: logContext, error: backupError)
                return .failure(backupError)
            }
        }
        
        // Create a session ID and track progress
        let sessionId = UUID().uuidString
        let progressTracker = ProgressTracker(totalItems: sources.count)
        progressTrackers[sessionId] = progressTracker
        
        // Perform the backup
        let result = await repository.createSnapshot(
            sources: sources,
            excludes: excludes ?? [],
            tags: tags ?? []
        )
        
        // Clean up regardless of result
        progressTrackers[sessionId] = nil
        
        // Handle result
        switch result {
        case .success(let snapshotInfo):
            let updatedContext = logContext.with(
                key: "snapshotId", 
                value: snapshotInfo.id,
                privacyLevel: .public
            )
            
            await backupLogger.logOperationSuccess(
                context: updatedContext,
                result: snapshotInfo
            )
            return .success(snapshotInfo)
            
        case .failure(let error):
            let backupError = BackupOperationError.repositoryError(error)
            await backupLogger.logOperationError(
                context: logContext,
                error: backupError
            )
            return .failure(backupError)
        }
    }
    
    // Additional methods...
}
```

### Example: Domain-Specific Error Type

```swift
public enum BackupOperationError: Error, Sendable, Equatable {
    case invalidInput(String)
    case accessDenied(String)
    case repositoryError(RepositoryError)
    case snapshotNotFound(String)
    case operationCancelled(String)
    case resourceLimitExceeded(String)
    
    // Catch-all case for unexpected errors
    case other(String)
    
    // Extensions for error categorisation, localisation, etc.
}
```

## Testing Refactored Code

### Unit Testing Actors

```swift
func testCreateSnapshot() async {
    // Setup
    let mockRepository = MockRepositoryProtocol()
    let mockFileSystem = MockFileSystemServiceProtocol()
    let mockLogger = MockLoggingProtocol()
    
    let actor = BackupServicesActor(
        repository: mockRepository,
        fileSystem: mockFileSystem,
        logger: mockLogger
    )
    
    let sources = [URL(fileURLWithPath: "/test/path")]
    let expectedSnapshot = SnapshotInfo(id: "test-id", timestamp: Date(), size: 1000)
    
    // Configure mocks
    mockFileSystem.checkAccessHandler = { _, _ in .success(()) }
    mockRepository.createSnapshotHandler = { _, _, _ in .success(expectedSnapshot) }
    
    // Execute
    let result = await actor.createSnapshot(withSources: sources)
    
    // Verify
    XCTAssertEqual(result, .success(expectedSnapshot))
    XCTAssertEqual(mockRepository.createSnapshotCallCount, 1)
    XCTAssertEqual(mockLogger.logCallCount, 2) // Start and success log
}
```

### Testing Concurrency

```swift
func testConcurrentOperations() async {
    // Setup actor with mocks
    let actor = BackupServicesActor(/*...*/)
    
    // Execute multiple operations concurrently
    async let result1 = actor.createSnapshot(withSources: [url1])
    async let result2 = actor.listSnapshots()
    async let result3 = actor.deleteSnapshot(id: "test-id")
    
    // Wait for all operations to complete
    let (snapshot, list, deleteResult) = await (result1, result2, result3)
    
    // Verify results
    XCTAssertNotNil(snapshot)
    XCTAssertFalse(list.isEmpty)
    XCTAssertTrue(deleteResult.isSuccess)
}
```

## Common Pitfalls and Solutions

### Pitfall: Protocol Conformance

**Problem**: Actor methods are implicitly async, which can cause protocol conformance issues.

**Solution**: Ensure protocols explicitly declare methods as async:

```swift
public protocol ServiceProtocol {
    func performOperation() async -> Result<OutputType, ServiceError>
}

public actor ServiceActor: ServiceProtocol {
    public func performOperation() async -> Result<OutputType, ServiceError> {
        // Implementation
    }
}
```

### Pitfall: Non-Sendable Types

**Problem**: Passing non-Sendable types across actor boundaries.

**Solution**: Make types Sendable or use value types:

```swift
// Before
public class Configuration { // Classes aren't automatically Sendable
    var settings: [String: Any] // Dictionary with Any isn't Sendable
}

// After
public struct Configuration: Sendable {
    var settings: [String: SendableValue] // Use a Sendable-compatible value type
}
```

### Pitfall: Over-Isolation

**Problem**: Creating too many fine-grained actors can lead to performance issues.

**Solution**: Group related functionality into cohesive actors:

```swift
// Too granular
public actor UserReader { /* Read operations */ }
public actor UserWriter { /* Write operations */ }
public actor UserValidator { /* Validation operations */ }

// Better approach
public actor UserManager {
    // Contains read, write, and validation operations in one actor
}
```

### Pitfall: Non-Isolated State

**Problem**: Accessing actor state from non-isolated contexts.

**Solution**: Use proper async access patterns:

```swift
// Incorrect
public actor DataManager {
    private var cache: [String: Data] = [:]
    
    public var cacheSize: Int {
        return cache.count // Direct access from property, not isolated
    }
}

// Correct
public actor DataManager {
    private var cache: [String: Data] = [:]
    
    public func getCacheSize() async -> Int {
        return cache.count // Properly isolated access
    }
}
```

## Appendix: British English Usage

This project uses British English spelling in documentation, error messages, and user-facing text. American English should be used for code identifiers (classes, methods, variables) to maintain consistency with the Swift standard library.

### British Spelling in Documentation

- Use `-ise` instead of `-ize` (e.g., "initialise" not "initialize")
- Use `-re` instead of `-er` (e.g., "centre" not "center")
- Use `-our` instead of `-or` (e.g., "colour" not "color")
- Use `-yse` instead of `-yze` (e.g., "analyse" not "analyze")
- Use `-ogue` instead of `-og` (e.g., "catalogue" not "catalog")

### Examples of Proper Usage

```swift
/**
 Initialises the controller with the specified parameters.
 
 This method organises resources and centralises configuration for the service.
 The colour settings will be applied to the interface, and the behaviour can be
 customised through the options parameter.
 */
public func initialize(options: Options) // Method name uses American spelling
```

### Error Messages

```swift
// Correct
throw ServiceError.invalidInput("The colour value is not recognised")

// Incorrect
throw ServiceError.invalidInput("The color value is not recognized")
```
