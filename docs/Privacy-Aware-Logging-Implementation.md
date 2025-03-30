# Privacy-Aware Logging Implementation in UmbraCore

This document outlines the privacy-enhanced logging system implemented for the Alpha Dot Five architecture within UmbraCore. The implementation focuses on data protection while maintaining robust logging capabilities.

## Architecture Overview

The privacy-aware logging implementation follows a hierarchical approach:

```
┌─────────────────────────┐
│  LoggingProtocol        │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Domain-Specific        │
│  Log Contexts           │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Domain-Specific        │
│  Loggers                │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Service Implementations │
└─────────────────────────┘
```

## Core Components

### Log Metadata DTOs

At the foundation of the privacy-aware logging system are the Data Transfer Objects (DTOs) that carry structured log information with privacy annotations:

1. **LogMetadataDTO**: Represents a single metadata entry with a key, value, and privacy level.
   ```swift
   public struct LogMetadataDTO: Sendable, Hashable, Equatable {
       public let key: String
       public let value: String
       public let privacy: LogPrivacyLevel
   }
   ```

2. **LogMetadataDTOCollection**: A collection of metadata entries that can be converted to a PrivacyMetadata instance.
   ```swift
   public struct LogMetadataDTOCollection: Sendable, Equatable {
       // Methods for adding metadata with different privacy levels
       public mutating func addPublic(key: String, value: String)
       public mutating func addPrivate(key: String, value: String)
       public mutating func addSensitive(key: String, value: String)
       
       // Convert to PrivacyMetadata
       public func toPrivacyMetadata() -> PrivacyMetadata
   }
   ```

### Domain-Specific Log Contexts

Log contexts encapsulate domain-specific metadata with privacy controls:

1. **LogContextDTO**: Base protocol for all domain-specific contexts
   ```swift
   public protocol LogContextDTO {
       func toPrivacyMetadata() -> PrivacyMetadata
       func getSource() -> String
   }
   ```

2. **Implemented Contexts**:
   - `SnapshotLogContext`: For snapshot and backup operations
   - `KeyManagementLogContext`: For key management operations
   - `KeychainLogContext`: For keychain operations
   - `CryptoLogContext`: For cryptographic operations
   - `ErrorLogContext`: For structured error logging
   - `FileSystemLogContext`: For file system operations with path privacy

### Domain-Specific Loggers

Specialised loggers that handle domain-specific log entries and privacy concerns:

1. **DomainLogger Protocol**: Common interface for domain-specific loggers
   ```swift
   public protocol DomainLogger {
       func logOperationStart<T: LogContextDTO>(context: T, message: String?) async
       func logOperationSuccess<T: LogContextDTO, R: Sendable>(context: T, result: R?, message: String?) async
       func logOperationError<T: LogContextDTO>(context: T, error: Error, message: String?) async
   }
   ```

2. **Implemented Loggers**:
   - `SnapshotLogger`: For snapshot and backup operations
   - `KeyManagementLogger`: For key management operations
   - `KeychainLogger`: For keychain operations
   - `CryptoLogger`: For cryptographic operations
   - `ErrorLogger`: For structured error logging
   - `FileSystemLogger`: For file system operations

## Privacy Levels

The system supports several privacy levels for data classification:

1. **Public**: Information that can be logged without redaction
2. **Private**: Information that should be redacted in logs but may be visible in debug builds
3. **Sensitive**: Information that requires special handling and should always be redacted
4. **Hash**: Information that should be hashed before logging
5. **Auto**: Automatically determined privacy level based on content analysis

## Factory Pattern

A factory pattern is used to create domain-specific loggers with the right configuration:

```swift
public enum PrivacyAwareLoggingFactory {
    // Core logger creation
    public static func createLogger(...) -> any PrivacyAwareLoggingProtocol
    
    // Domain-specific logger creation
    public static func createKeyManagementLogger(...) -> KeyManagementLogger
    public static func createKeychainLogger(...) -> KeychainLogger
    public static func createCryptoLogger(...) -> CryptoLogger
    public static func createErrorLogger(...) -> ErrorLogger
    public static func createFileSystemLogger(...) -> FileSystemLogger
    public static func createSnapshotLogger(...) -> SnapshotLogger
}
```

## Implementation Status

The privacy-aware logging system has been implemented in several critical components:

1. **Completed**:
   - Core DTOs and interfaces (`LogMetadataDTO`, `LogContextDTO`, etc.)
   - Domain-specific contexts for all major subsystems
   - Domain-specific loggers for all major subsystems
   - Factory methods for creating loggers
   - Enhanced logging in `KeyManagementActor`, `KeychainSecurityActor`, and `CryptoServiceActor`
   - Privacy-aware error logging in `DefaultErrorHandler`
   - Integration with `ModernSnapshotServiceImpl` using component-based architecture
   - Implementation of domain-specific `SnapshotLogContextAdapter` for privacy-aware logging
   - Creation of `SnapshotOperationDTO` parameter objects with privacy annotations
   - Centralised error handling with privacy context

2. **In Progress**:
   - Integration with other service implementations
   - Resolving protocol conformance issues

## Integration Strategy

To fully integrate the privacy-aware logging system across UmbraCore without disrupting existing functionality, we recommend a phased approach:

1. **Phase 1**: Create adapter classes to bridge between new domain-specific loggers and existing logging code
2. **Phase 2**: Update service implementations one by one to use the appropriate domain loggers
3. **Phase 3**: Refine protocol hierarchies and consolidate any adapter code
4. **Phase 4**: Implement consistent dependency injection for all loggers

## Recent Implementations

### Backup Services Module

The Backup Services module has been fully refactored to follow the Alpha Dot Five architecture with privacy-aware logging:

1. **Component-Based Architecture**:
   - Specialised services for different operation types
   - Clear separation of concerns following single responsibility principle
   - Actor-based implementation for thread safety

2. **Privacy-Aware Logging**:
   - Consistent use of `SnapshotLogContextAdapter` for structured logging
   - Privacy annotations for all parameters and metadata
   - Centralised error handling with appropriate privacy controls

3. **Type-Safe DTOs**:
   - Operation-specific parameter objects with validation
   - Privacy annotations integrated directly into DTOs
   - Strongly-typed interfaces that make illegal states unrepresentable

For detailed information on the Backup Services implementation, see the [BackupServices-AlphaDotFive-Architecture.md](./BackupServices-AlphaDotFive-Architecture.md) document.

## Examples

### Logging Key Management Operations

```swift
// Initialize the logger
let logger = PrivacyAwareLoggingFactory.createKeyManagementLogger(
    logger: baseLogger
)

// Log a key operation with privacy-aware metadata
let context = KeyManagementLogContext(
    keyIdentifier: "key-123", 
    operation: "encrypt"
)
await logger.logOperationStart(context: context)

// When operation completes successfully
await logger.logOperationSuccess(context: context)

// If an error occurs
await logger.logOperationError(context: context, error: someError)
```

### Logging File System Operations with Path Privacy

```swift
// Initialize the logger
let logger = PrivacyAwareLoggingFactory.createFileSystemLogger(
    logger: baseLogger
)

// Log file operation with private path
await logger.logPath(
    "/Users/username/Documents/sensitive-file.txt",
    operation: "read",
    level: .info
)
```

## Best Practices

1. **Always classify data properly**: Use the right privacy level for each piece of data
2. **Use domain-specific loggers**: Choose the appropriate logger for the context
3. **Include relevant context**: Add operation type, identifiers, and status information
4. **Be consistent**: Use the same logging patterns across similar operations
5. **Prefer structured logging**: Use the DTO-based approach rather than string manipulation
