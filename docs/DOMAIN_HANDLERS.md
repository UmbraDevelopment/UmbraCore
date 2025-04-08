# Domain Handlers Documentation

## Overview

Domain handlers are a core component of the Alpha Dot Five architecture in UmbraCore. They process API operations within specific domains, providing a consistent interface while optimising performance through caching and batch processing.

## Table of Contents

1. [Architecture](#architecture)
2. [Base Implementation](#base-implementation)
3. [Protocol Definition](#protocol-definition)
4. [Available Handlers](#available-handlers)
5. [Performance Optimisations](#performance-optimisations)
6. [Usage Examples](#usage-examples)
7. [Best Practices](#best-practices)

## Architecture

Domain handlers follow a consistent architecture:

1. **Actor-Based Implementation**: All handlers are implemented as actors to ensure thread safety and memory isolation.
2. **Common Base Functionality**: The `BaseDomainHandler` provides shared functionality for all handlers.
3. **Protocol Conformance**: All handlers implement the `DomainHandlerProtocol` for consistency.
4. **Service Dependencies**: Handlers depend on domain-specific services for actual implementation.
5. **Privacy-Aware Logging**: All operations are logged with appropriate privacy classifications.

## Base Implementation

The `BaseDomainHandler` provides common functionality for all domain handlers:

```swift
public actor BaseDomainHandler {
    /// The domain name for this handler
    public nonisolated let domain: String
    
    /// Logger with privacy controls
    private let logger: (any LoggingProtocol)?
    
    // Logging helper methods
    public func createBaseMetadata(operation: String, event: String) -> LogMetadataDTOCollection
    public func logOperationStart(operationName: String, source: String) async
    public func logOperationSuccess(operationName: String, source: String) async
    public func logOperationFailure(operationName: String, error: Error, source: String) async
    public func logCriticalError(message: String, operationName: String, source: String) async
    public func logDebug(message: String, operationName: String, source: String, additionalMetadata: LogMetadataDTOCollection?) async
    
    // Error handling
    public func mapToAPIError(_ error: Error) -> APIError
}
```

### Key Features

- **Optimised Metadata Creation**: Creates metadata only when logging is enabled.
- **Standardised Logging**: Consistent logging format across all handlers.
- **Error Mapping**: Common error mapping functionality.

## Protocol Definition

The `DomainHandlerProtocol` ensures consistent implementation across all domain handlers:

```swift
public protocol DomainHandlerProtocol: Sendable {
    /// The domain name for this handler
    var domain: String { get }
    
    /// Handles an API operation and returns its result
    func handleOperation<T: APIOperation>(operation: T) async throws -> Any
    
    /// Determines if this handler supports the given operation
    func supports(_ operation: some APIOperation) -> Bool
    
    /// Executes a batch of operations more efficiently than individual execution
    func executeBatch(_ operations: [any APIOperation]) async throws -> [String: Any]
    
    /// Clears any cached data held by the handler
    func clearCache() async
}
```

### Default Implementations

The protocol provides default implementations for some methods:

- **executeBatch**: Processes operations individually if no optimised batch processing is available.
- **clearCache**: Does nothing by default, to be overridden by handlers that implement caching.

## Available Handlers

UmbraCore provides the following domain handlers:

### SecurityDomainHandler

Handles security-related operations such as encryption, decryption, hashing, and key management.

```swift
public actor SecurityDomainHandler: DomainHandlerProtocol {
    private let securityService: SecurityServiceProtocol
    private var keyMetadataCache: [String: KeyMetadata] = [:]
    
    // Operation handling
    public func handleOperation<T: APIOperation>(operation: T) async throws -> Any
    
    // Batch processing
    public func executeBatch(_ operations: [any APIOperation]) async throws -> [String: Any]
    private func batchHashData(_ operations: [HashData]) async throws -> [String: HashResult]
    private func batchEncryptData(_ operations: [EncryptData]) async throws -> [String: EncryptionResult]
    
    // Cache management
    public func clearCache()
}
```

### BackupDomainHandler

Handles backup-related operations such as creating snapshots, restoring data, and managing backup configurations.

```swift
public actor BackupDomainHandler: DomainHandlerProtocol {
    private let backupService: BackupServiceProtocol
    private var snapshotCache: [String: (SnapshotInfo, Date)] = [:]
    
    // Operation handling
    public func handleOperation<T: APIOperation>(operation: T) async throws -> Any
    
    // Batch processing
    public func executeBatch(_ operations: [any APIOperation]) async throws -> [String: Any]
    private func batchCreateSnapshots(_ operations: [CreateSnapshotOperation]) async throws -> [String: SnapshotInfo]
    
    // Cache management
    public func clearCache()
}
```

### RepositoryDomainHandler

Handles repository-related operations such as creating, retrieving, updating, and deleting repositories.

```swift
public actor RepositoryDomainHandler: DomainHandlerProtocol {
    private let repositoryService: RepositoryServiceProtocol
    private var repositoryCache: [String: (RepositoryInfo, Date)] = [:]
    
    // Operation handling
    public func handleOperation<T: APIOperation>(operation: T) async throws -> Any
    
    // Batch processing
    public func executeBatch(_ operations: [any APIOperation]) async throws -> [String: Any]
    private func batchListRepositories(_ operations: [ListRepositoriesOperation]) async throws -> [String: [RepositoryInfo]]
    
    // Cache management
    public func clearCache()
}
```

## Performance Optimisations

Domain handlers implement several performance optimisations:

### Caching

Handlers cache frequently accessed resources to improve performance of repeated requests:

```swift
// Get a repository from the cache
private func getCachedRepository(id: String) -> RepositoryInfo? {
    if let (info, timestamp) = repositoryCache[id],
       Date().timeIntervalSince(timestamp) < cacheTTL {
        return info
    }
    return nil
}

// Cache a repository
private func cacheRepository(id: String, info: RepositoryInfo) {
    repositoryCache[id] = (info, Date())
}
```

### Batch Processing

Handlers optimise the processing of multiple operations of the same type:

```swift
// Process multiple hash operations in a batch
private func batchHashData(_ operations: [HashData]) async throws -> [String: HashResult] {
    // Group operations by algorithm to minimize configuration changes
    let groupedByAlgorithm = Dictionary(grouping: operations) { $0.algorithm ?? "SHA-256" }
    
    // Process each algorithm group
    for (algorithm, algorithmOperations) in groupedByAlgorithm {
        // Configure the security service once per algorithm
        let securityConfig = SecurityConfigDTO(
            operation: .hash,
            algorithm: algorithm,
            options: SecurityConfigOptions()
        )
        
        // Process each operation with the same algorithm
        for operation in algorithmOperations {
            // Implementation details...
        }
    }
    
    return results
}
```

### Conditional Logging

Handlers optimise logging by only creating metadata when logging is enabled:

```swift
public func logOperationStart(operationName: String, source: String) async {
    // Only create metadata if logging is enabled
    if await logger?.isEnabled(for: .info) == true {
        let metadata = createBaseMetadata(operation: operationName, event: "start")
        
        await logger?.info(
            "Starting \(domain) operation: \(operationName)",
            context: CoreLogContext(
                source: source,
                metadata: metadata
            )
        )
    }
}
```

## Usage Examples

### Basic Operation Handling

```swift
// Create a domain handler
let securityHandler = try await DomainHandlerFactory.shared.createHandler(for: .security)

// Create an operation
let encryptOperation = EncryptData(
    data: "Hello, world!".data(using: .utf8)!,
    keyIdentifier: "my-key",
    algorithm: "AES-256-GCM"
)

// Execute the operation
let result = try await securityHandler.handleOperation(operation: encryptOperation)
let encryptionResult = result as! EncryptionResult

print("Encrypted data: \(encryptionResult.ciphertext)")
```

### Batch Processing

```swift
// Create multiple operations
let hashOperations: [any APIOperation] = [
    HashData(data: "Hello".data(using: .utf8)!, algorithm: "SHA-256"),
    HashData(data: "World".data(using: .utf8)!, algorithm: "SHA-256"),
    HashData(data: "!".data(using: .utf8)!, algorithm: "SHA-512")
]

// Execute batch operation
let results = try await securityHandler.executeBatch(hashOperations)

// Process results
for (id, result) in results {
    if let hashResult = result as? HashResult {
        print("Hash for operation \(id): \(hashResult.hash)")
    }
}
```

## Best Practices

When working with domain handlers, follow these best practices:

1. **Use the Factory**: Always create handlers through the `DomainHandlerFactory` to ensure proper configuration.

2. **Batch Similar Operations**: When processing multiple operations of the same type, use `executeBatch` instead of calling `handleOperation` multiple times.

3. **Handle Errors Appropriately**: Domain handlers throw `APIError` instances that provide clear error information.

4. **Respect Privacy Classifications**: When logging, use appropriate privacy classifications for sensitive data.

5. **Clear Caches When Needed**: Call `clearCache()` when cached data might be stale.

6. **Implement New Handlers Consistently**: When creating new domain handlers, follow the established patterns and extend the base implementation.

7. **Make Methods Nonisolated When Possible**: Methods that don't access actor state should be marked as `nonisolated` for better performance.

8. **Use Strongly Typed Operations**: Create specific operation types rather than using generic dictionaries or strings.

9. **Document Domain-Specific Behaviour**: Each domain handler may have unique behaviour that should be documented.

10. **Test Thoroughly**: Write unit tests for all handlers, especially focusing on caching and batch processing.
