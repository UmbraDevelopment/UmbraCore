# UmbraCore Logging System Documentation

## Overview

The UmbraCore Logging System provides a comprehensive, thread-safe logging solution following the Alpha Dot Five architecture principles. The system includes:

- Multiple log destinations including console, file, and OSLog (Apple platforms)
- Privacy-aware logging with fine-grained control
- Thread-safe implementation using Swift concurrency (actors)
- British English documentation standard

## Core Components

### LoggingServiceProtocol

Defines the standard interface for logging operations, including:

- Level-specific logging methods (`verbose`, `debug`, `info`, etc.)
- Destination management
- Log level configuration
- Flush operations

### LoggingServiceActor

The primary implementation of `LoggingServiceProtocol`, providing:

- Thread-safe logging through Swift actors
- Support for multiple concurrent writers
- Management of multiple destinations
- Privacy-aware logging extensions

### Log Destinations

#### ConsoleLogDestination

Logs messages to the standard output:

- Thread-safe implementation
- Configurable formatting
- Customisable minimum log level

#### FileLogDestination

Writes logs to a file with advanced features:

- File rotation when size limits are reached
- Configurable backup count
- Asynchronous writing for performance
- Path management

#### OSLogDestination

Integration with Apple's OSLog system:

- Privacy-aware logging with fine-grained control
- Console.app integration
- High-performance system logging
- Compliant with Apple's privacy guidelines

## Privacy-Aware Logging

The logging system supports privacy controls through the following components:

### LogPrivacy

An enumeration defining privacy levels:

```swift
public enum LogPrivacy: String, CaseIterable, Equatable {
    case `public`   // Information safe for general viewing
    case `private`  // Potentially sensitive information
    case sensitive  // Highly sensitive information
}
```

### PrivacyAnnotatedString

A structure that pairs a string with its privacy level:

```swift
public struct PrivacyAnnotatedString: Sendable, Equatable {
    public let content: String
    public let privacy: LogPrivacy
    
    public init(_ content: String, privacy: LogPrivacy = .private) {
        self.content = content
        self.privacy = privacy
    }
}
```

### Privacy Metadata

The system uses metadata to carry privacy annotations:

```swift
// Create a privacy-enhanced metadata
var privacyMetadata = metadata ?? LogMetadata()
privacyMetadata["__privacy_message"] = message.privacy.description
privacyMetadata["__privacy_metadata"] = metadataPrivacy.description
```

## Privacy-Enhanced Logging

The Alpha Dot Five architecture includes a comprehensive privacy-enhanced logging system that prioritises data protection whilst maintaining robust logging capabilities.

### Core Types

The foundation of the privacy-enhanced logging system includes:

#### LogPrivacyLevel

```swift
public enum LogPrivacyLevel: Sendable, Equatable {
    /// Public information that can be logged without redaction
    case `public`
    
    /// Private information that should be redacted in logs
    /// but may be visible in debug builds
    case `private`
    
    /// Sensitive information that requires special handling
    /// and should always be redacted or processed before logging
    case sensitive
    
    /// Information that should be hashed before logging
    /// to allow correlation without revealing the actual value
    case hash
    
    /// Auto-redacted content based on type analysis
    /// This is the default for unannotated values
    case auto
}
```

#### PrivacyString

A string interpolation type that supports privacy annotations for interpolated values:

```swift
// Basic usage
let message: PrivacyString = "Processing payment for user \(private: userId) with amount \(public: amount)"

// Converting to a log-safe string
let processedMessage = message.processForLogging()
```

#### LogContext

Provides rich contextual information about log events with privacy annotations:

```swift
public struct LogContext: Sendable, Equatable {
    /// Component that generated the log
    public let source: String
    
    /// Additional structured data with privacy annotations
    public let metadata: LogMetadata?
    
    /// For tracking related logs across components
    public let correlationId: String
    
    /// When the log was created
    public let timestamp: LogTimestamp
}
```

### Protocol Hierarchy

The privacy-enhanced logging system uses a hierarchical protocol design:

#### CoreLoggingProtocol

The base protocol that all logging protocols extend from:

```swift
public protocol CoreLoggingProtocol: Sendable {
    /// Log a message with the specified level and context
    func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async
}
```

#### LoggingProtocol

Standard logging protocol with convenience methods:

```swift
public protocol LoggingProtocol: CoreLoggingProtocol {
    func trace(_ message: String, metadata: LogMetadata?, source: String) async
    func debug(_ message: String, metadata: LogMetadata?, source: String) async
    func info(_ message: String, metadata: LogMetadata?, source: String) async
    func warning(_ message: String, metadata: LogMetadata?, source: String) async
    func error(_ message: String, metadata: LogMetadata?, source: String) async
    func critical(_ message: String, metadata: LogMetadata?, source: String) async
}
```

#### PrivacyAwareLoggingProtocol

Enhanced logging protocol with privacy controls:

```swift
public protocol PrivacyAwareLoggingProtocol: LoggingProtocol {
    /// Log a message with explicit privacy controls
    func log(
        _ level: LogLevel,
        _ message: PrivacyString,
        metadata: LogMetadata?,
        source: String
    ) async
    
    /// Log sensitive information with appropriate redaction
    func logSensitive(
        _ level: LogLevel,
        _ message: String,
        sensitiveValues: [String: Any],
        source: String
    ) async
    
    /// Log an error with privacy controls
    func logError(
        _ error: Error,
        privacyLevel: LogPrivacyLevel,
        metadata: LogMetadata?,
        source: String
    ) async
}
```

### Implementations

#### PrivacyAwareLogger

An actor that implements the PrivacyAwareLoggingProtocol:

```swift
public actor PrivacyAwareLogger: PrivacyAwareLoggingProtocol {
    // Implementation of the privacy-aware logging protocol
}
```

#### OSLogPrivacyBackend

A backend that uses Apple's OSLog system with privacy annotations:

```swift
public struct OSLogPrivacyBackend: LoggingBackend {
    // Implementation that maps LogPrivacyLevel to OSLog privacy qualifiers
}
```

#### Factory Pattern

```swift
public enum PrivacyAwareLoggingFactory {
    /// Create a logger with privacy features
    public static func createLogger(
        minimumLevel: LogLevel = .info,
        identifier: String,
        backend: LoggingBackend? = nil,
        privacyLevel: LogPrivacyLevel = .auto
    ) -> any PrivacyAwareLoggingProtocol {
        // Creates the appropriate logger instance
    }
}
```

### Usage Examples

#### Basic Privacy-Aware Logging

```swift
// Create a privacy-aware logger
let logger = PrivacyAwareLoggingFactory.createLogger(
    identifier: "com.umbraapp.example"
)

// Log with explicit privacy annotations
await logger.log(
    .info,
    "Processing payment for user \(private: userId) with amount \(public: amount)",
    metadata: [
        "transactionId": (value: transactionId, privacy: .public),
        "cardInfo": (value: cardLastFour, privacy: .private)
    ],
    source: "PaymentProcessor"
)
```

#### Sensitive Data Handling

```swift
// Simplified logging of sensitive data
await logger.logSensitive(
    .debug,
    "Authentication attempt",
    sensitiveValues: [
        "username": username,
        "ipAddress": ipAddress
    ],
    source: "AuthenticationService"
)
```

#### Error Logging with Privacy

```swift
do {
    // Operation code
} catch {
    await logger.logError(
        error,
        privacyLevel: .private,
        metadata: [
            "errorCode": (value: (error as? AppError)?.code ?? -1, privacy: .public),
            "timestamp": (value: Date(), privacy: .public)
        ],
        source: "OperationManager"
    )
}
```

### MVVM Integration

The privacy-enhanced logging system integrates cleanly with the MVVM architecture:

```swift
public class KeychainSecurityViewModel {
    private let logger: PrivacyAwareLoggingProtocol
    private let keychainService: KeychainSecurityProtocol
    
    @Published private(set) var status: KeychainOperationStatus = .idle
    
    public func storeSecret(_ secret: String, forAccount account: String) async {
        // Update status for UI binding
        status = .processing
        
        await logger.log(
            .info,
            "Processing secret storage for \(private: account)",
            metadata: [
                "secretLength": (value: secret.count, privacy: .public)
            ],
            source: "KeychainSecurityViewModel"
        )
        
        do {
            try await keychainService.storeSecret(secret, forAccount: account)
            
            // Update status for UI binding
            status = .completed
            
            await logger.info(
                "Secret stored successfully",
                metadata: nil,
                source: "KeychainSecurityViewModel"
            )
        } catch {
            // Update status for UI binding
            status = .failed(error)
            
            await logger.logError(
                error,
                privacyLevel: .private,
                metadata: nil,
                source: "KeychainSecurityViewModel"
            )
        }
    }
}
```

### Benefits

1. **Privacy by Design**: Data privacy is a first-class concern in the logging architecture
2. **Regulatory Compliance**: Helps meet GDPR, CCPA, and other privacy regulations
3. **Development-friendly**: More verbose in development, appropriately redacted in production
4. **Type Safety**: Strong typing for privacy annotations
5. **Contextual Richness**: Preserves important context whilst protecting sensitive data
6. **MVVM Compatibility**: Seamlessly integrates with the MVVM architecture
7. **Extensibility**: Easy to adapt for different logging backends

### Implementation Guidelines

1. Always use the appropriate privacy level for personal or sensitive data
2. Prefer explicit privacy annotations over relying on automatic redaction
3. Keep public metadata separate from private metadata
4. Use correlation IDs to trace related log events across components
5. Configure minimum log levels appropriately for each environment

### Migration Guide

When migrating from the existing adapter-based logging system:

1. Replace `LoggingAdapter` instances with direct `PrivacyAwareLogger` instances
2. Update logging calls to use the privacy-enhanced methods
3. Add appropriate privacy annotations to sensitive data
4. Update dependencies to inject the new logger types

## Usage Examples

### Basic Logging

```swift
// Create a logging service
let logger = LoggingServiceFactory.createDefaultLogger(
    minimumLevel: .info,
    identifier: "AppLogger"
)

// Log messages at different levels
await logger.info("Application started")
await logger.warning("Resource running low")
await logger.error("Failed to connect to server")
```

### Privacy-Aware Logging

```swift
// Create a privacy-annotated string
let username = PrivacyAnnotatedString("john.doe@example.com", privacy: .private)
let userID = PrivacyAnnotatedString("12345", privacy: .public)
let password = PrivacyAnnotatedString("Secret123!", privacy: .sensitive)

// Log with privacy annotations
await logger.log(level: .info, message: username)
await logger.log(level: .debug, message: userID)

// Log with privacy annotations and metadata
var metadata = LogMetadata()
metadata["action"] = "login_attempt"
await logger.log(level: .info, message: username, metadata: metadata, metadataPrivacy: .public)
```

### OSLog Integration

```swift
// Create an OSLog destination
let osLogger = LoggingServiceFactory.createOSLogger(
    subsystem: "com.umbraapp.example",
    category: "Authentication",
    minimumLevel: .info
)

// Log with privacy considerations
let creditCard = PrivacyAnnotatedString("1234-5678-9012-3456", privacy: .sensitive)
await osLogger.log(level: .info, message: creditCard)
```

## Best Practices

1. **Use Privacy Annotations**:
   Always annotate personal or sensitive information with appropriate privacy levels.

2. **Consistent Log Levels**:
   Follow the convention of using the appropriate log level for different types of information.

3. **Meaningful Metadata**:
   Include relevant context in metadata to make logs more useful for debugging.

4. **British English in Documentation**:
   Maintain British English spelling in documentation and user-facing elements.

5. **Efficient Log Levels**:
   Configure minimum log levels appropriately to avoid excessive logging in production.

## Error Handling

The logging system uses a dedicated error type to handle various failure scenarios:

- `LoggingError.destinationAlreadyExists`: Attempt to add a destination with an existing identifier
- `LoggingError.flushFailed`: Failure when flushing a specific destination
- `LoggingError.multipleFlushFailures`: Multiple destinations failed to flush
- `LoggingError.destinationCreationFailed`: Unable to create a log destination
- `LoggingError.writeError`: Failed to write to a log destination

## Thread Safety Considerations

The logging system is designed to be thread-safe through the use of Swift actors. When using the system across multiple threads, be aware that:

1. All logging operations are asynchronous and must be awaited
2. File operations are isolated within the actor to prevent race conditions
3. Destinations manage their own thread safety

## Extension Points

The logging system is designed to be extensible through:

1. **Custom Destinations**: Create new destinations by conforming to `LogDestination`
2. **Custom Formatters**: Create new formatters by conforming to `LogFormatterProtocol`
3. **Additional Privacy Controls**: Extend the `LogPrivacy` enum with more granular options
