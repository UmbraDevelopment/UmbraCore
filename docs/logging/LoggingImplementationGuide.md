# Logging Implementation Guide for UmbraCore

## Overview

UmbraCore employs a sophisticated, privacy-enhanced logging system based on the Alpha Dot Five architecture. This guide outlines the implementation requirements, best practices, and recent updates to ensure consistent logging throughout the codebase.

## Core Components

### LoggingActor

The `LoggingActor` component (defined in `LoggingInterfaces`) is the thread-safe coordinator for all logging operations:

```swift
public actor LoggingActor: Sendable {
    // Destinations for logs
    private var destinations: [any ActorLogDestination]
    
    // Initialisation requires at least empty destinations array
    public init(
        destinations: [any ActorLogDestination],
        minimumLogLevel: LogLevel = .info
    ) {
        self.destinations = destinations
        self.minimumLogLevel = minimumLogLevel
    }
    
    // Core logging method
    public func log(level: LogLevel, message: String, context: LogContext) async {
        // Implementation details...
    }
}
```

### LoggingProtocol Requirements

All logger implementations must conform to `LoggingProtocol` by implementing:

1. The `loggingActor` property
2. The core `logMessage` method
3. Convenience methods for different log levels

## Privacy-Enhanced Metadata

`PrivacyMetadata` is used to attach structured information to logs with appropriate privacy controls:

1. Each entry requires a `PrivacyMetadataValue` with an explicit privacy level
2. Never use raw string assignments to `PrivacyMetadata`
3. Privacy levels include:
   - `.public`: Non-sensitive information
   - `.private`: Information that should be redacted in production
   - `.sensitive`: Highly sensitive data requiring additional protection
   - `.hash`: Data that should be hashed before logging

Example:
```swift
var metadata = LoggingTypes.PrivacyMetadata()
metadata["dataSize"] = LoggingTypes.PrivacyMetadataValue(value: "\(data.count)", privacy: .public)
```

## Implementing Logger Classes

When implementing a custom logger, follow this pattern:

```swift
struct MyLogger: LoggingInterfaces.LoggingProtocol {
    // Required property - must use correct module reference
    var loggingActor: LoggingInterfaces.LoggingActor = LoggingInterfaces.LoggingActor(destinations: [])
    
    // Required core method
    func logMessage(_ level: LoggingTypes.LogLevel, _ message: String, context: LoggingTypes.LogContext) async {
        // Implementation details...
    }
    
    // Implement convenience methods if needed
}
```

## Source Parameter Requirement

All logging method calls require a `source` parameter to identify the component generating the log:

```swift
await logger.debug("Starting operation", metadata: metadata, source: "ComponentName")
```

## Swift 6 Compatibility

Recent updates include:
- Ensuring all logger implementations are Swift 6 compatible
- Addressing sendability warnings, especially with shared resources like FileManager
- Removing non-sendable method implementations in favour of Swift 6 compatible alternatives

## Domain-Specific Loggers

UmbraCore uses domain-specific loggers to provide contextual information:

1. **CryptoService**: Logs encryption/decryption operations with appropriate privacy controls
2. **FileSystemService**: Tracks file operations with source identification
3. **KeychainService**: Handles secure storage operations with enhanced privacy

## Best Practices

1. Always provide a `source` parameter
2. Use `PrivacyMetadataValue` with appropriate privacy levels
3. Keep logger implementations concise and focused
4. Ensure proper initialisation of `LoggingActor` with destinations
5. Consider domain-specific context information where appropriate

## Recent Changes

Recent updates to the logging system include:
1. Fixed references to `LoggingActor` using the correct module (`LoggingInterfaces`)
2. Updated all logger implementations to conform to the required protocols
3. Ensured proper initialisation of `LoggingActor` with empty destinations array when needed
4. Fixed type safety issues with `PrivacyMetadata` value assignments
5. Removed code with Swift 6 sendability warnings in `FileSystemServiceFactory`

For more detailed information on the privacy architecture of the logging system, refer to `/docs/logging/LoggingSystem-PrivacyEnhancements.md`.
