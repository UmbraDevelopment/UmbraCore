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
