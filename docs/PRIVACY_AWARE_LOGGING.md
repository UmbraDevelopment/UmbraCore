# Privacy-Aware Logging Documentation

## Overview

The privacy-aware logging system in UmbraCore ensures sensitive data is properly protected whilst providing comprehensive logging capabilities. This system is a core component of the Alpha Dot Five architecture, implementing the "Privacy-By-Design" principle.

## Table of Contents

1. [Architecture](#architecture)
2. [Privacy Classifications](#privacy-classifications)
3. [Key Components](#key-components)
4. [Usage Examples](#usage-examples)
5. [Best Practices](#best-practices)
6. [Environment-Based Behaviour](#environment-based-behaviour)
7. [Automatic Pattern Detection](#automatic-pattern-detection)

## Architecture

The privacy-aware logging system follows a layered architecture:

1. **Interface Layer**: Protocols defining the logging capabilities.
2. **Implementation Layer**: Concrete implementations of the logging protocols.
3. **Formatter Layer**: Formatters that apply privacy controls to log messages.
4. **Destination Layer**: Destinations where log messages are sent.

## Privacy Classifications

The system supports different privacy classifications for data:

### Public

Public data is displayed normally in all environments.

```swift
metadata = metadata.withPublic(key: "operation", value: "encryptData")
```

### Private

Private data is redacted in production environments but displayed in development.

```swift
metadata = metadata.withPrivate(key: "userId", value: "12345")
```

### Sensitive

Sensitive data is always redacted unless explicitly authorised.

```swift
metadata = metadata.withSensitive(key: "apiKey", value: "sk_live_1234567890")
```

### Hash

Data is replaced with a hash of the original value.

```swift
metadata = metadata.with(key: "password", value: "secret123", privacyLevel: .hash)
```

### Auto

The system attempts to automatically detect sensitive patterns.

```swift
metadata = metadata.with(key: "data", value: userInput, privacyLevel: .auto)
```

## Key Components

### LogMetadataDTO

Represents a single metadata entry with privacy classification.

```swift
public struct LogMetadataDTO: Sendable, Equatable, Hashable {
    public let key: String
    public let value: String
    public let privacyLevel: PrivacyClassification
}
```

### LogMetadataDTOCollection

Builder for a collection of metadata entries with privacy annotations.

```swift
public struct LogMetadataDTOCollection: Sendable, Equatable {
    public private(set) var entries: [LogMetadataDTO]
    
    public func withPublic(key: String, value: String) -> LogMetadataDTOCollection
    public func withPrivate(key: String, value: String) -> LogMetadataDTOCollection
    public func withSensitive(key: String, value: String) -> LogMetadataDTOCollection
    public func with(key: String, value: String, privacyLevel: PrivacyClassification) -> LogMetadataDTOCollection
    public func merging(with other: LogMetadataDTOCollection) -> LogMetadataDTOCollection
}
```

### PrivacyAwareLogFormatter

Formats log messages with privacy controls based on privacy classifications.

```swift
public class PrivacyAwareLogFormatter: LogFormatterProtocol {
    private let environment: DeploymentEnvironment
    private let includePrivateDetails: Bool
    private let includeSensitiveDetails: Bool
    
    public func format(
        level: UmbraLogLevel,
        message: String,
        metadata: [String: Any]?,
        source: String?,
        file: String,
        function: String,
        line: UInt,
        timestamp: Date
    ) -> String
}
```

### PrivacyAwareLoggingActor

Actor that implements the `PrivacyAwareLoggingProtocol`.

```swift
public actor PrivacyAwareLoggingActor: PrivacyAwareLoggingProtocol {
    private let loggingService: LoggingServiceActor
    private let environment: DeploymentEnvironment
    private var includeSensitiveDetails: Bool
    
    // LoggingProtocol methods
    public func log(_ level: UmbraLogLevel, _ message: String) async
    public func debug(_ message: String) async
    public func info(_ message: String) async
    public func notice(_ message: String) async
    public func warning(_ message: String) async
    public func error(_ message: String) async
    public func critical(_ message: String) async
    public func isEnabled(for level: UmbraLogLevel) async -> Bool
    
    // Context-based logging
    public func debug(_ message: String, context: LogContextDTO) async
    public func info(_ message: String, context: LogContextDTO) async
    public func notice(_ message: String, context: LogContextDTO) async
    public func warning(_ message: String, context: LogContextDTO) async
    public func error(_ message: String, context: LogContextDTO) async
    public func critical(_ message: String, context: LogContextDTO) async
    
    // PrivacyAwareLoggingProtocol methods
    public func log(_ level: UmbraLogLevel, _ message: PrivacyString, context: LogContextDTO) async
    public func logSensitive(_ level: UmbraLogLevel, _ message: String, sensitiveValues: LogMetadata, context: LogContextDTO) async
    public func logError(_ error: Error, privacyLevel: LogPrivacyLevel, context: LogContextDTO) async
    
    // Authorisation
    public func authorizeSensitiveAccess(authToken: String) -> Bool
    public func revokeSensitiveAccess()
}
```

### LoggingServiceFactory

Factory for creating and configuring logging services.

```swift
public enum LoggingServiceFactory {
    public static func createPrivacyAwareLogger(
        minimumLevel: LoggingTypes.UmbraLogLevel = .info,
        environment: DeploymentEnvironment = .development,
        formatter: LoggingInterfaces.LogFormatterProtocol? = nil
    ) -> PrivacyAwareLoggingActor
    
    public static func createComprehensivePrivacyAwareLogger(
        subsystem: String,
        category: String,
        logDirectoryPath: String,
        environment: DeploymentEnvironment = .development,
        minimumLevel: LoggingTypes.UmbraLogLevel = .info,
        fileMinimumLevel: LoggingTypes.UmbraLogLevel = .warning,
        osLogMinimumLevel: LoggingTypes.UmbraLogLevel = .info,
        consoleMinimumLevel: LoggingTypes.UmbraLogLevel = .info
    ) -> PrivacyAwareLoggingActor
    
    public static func createProductionPrivacyAwareLogger(
        logDirectoryPath: String,
        logFileName: String = "umbra-privacy.log",
        environment: DeploymentEnvironment = .production,
        minimumLevel: LoggingTypes.UmbraLogLevel = .info
    ) -> PrivacyAwareLoggingActor
}
```

## Usage Examples

### Basic Logging

```swift
// Create a privacy-aware logger
let logger = LoggingServiceFactory.createPrivacyAwareLogger(
    minimumLevel: .debug,
    environment: .development
)

// Log a simple message
await logger.info("Application started")
```

### Context-Based Logging

```swift
// Create metadata with privacy classifications
let metadata = LogMetadataDTOCollection()
    .withPublic(key: "operation", value: "encryptData")
    .withPublic(key: "algorithm", value: "AES-256-GCM")
    .withPrivate(key: "userId", value: "12345")
    .withSensitive(key: "apiKey", value: "sk_live_1234567890")

// Log with context
await logger.info(
    "Processing encryption request",
    context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: metadata
    )
)
```

### Sensitive Value Logging

```swift
// Create base metadata
let metadata = LogMetadataDTOCollection()
    .withPublic(key: "operation", value: "userLogin")

// Create sensitive values
let sensitiveValues: [String: Any] = [
    "password": "secret123",
    "mfaToken": "123456"
]

// Log with sensitive values
await logger.logSensitive(
    .info,
    "User login attempt",
    sensitiveValues: sensitiveValues,
    context: CoreLogContext(
        source: "AuthenticationService",
        metadata: metadata
    )
)
```

### Error Logging

```swift
do {
    // Attempt an operation
    try performOperation()
} catch {
    // Log the error with privacy controls
    await logger.logError(
        error,
        privacyLevel: .private,
        context: CoreLogContext(
            source: "OperationService",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "operation", value: "performOperation")
        )
    )
}
```

## Best Practices

When working with the privacy-aware logging system, follow these best practices:

1. **Use Appropriate Privacy Classifications**: Always use the most restrictive privacy classification that is appropriate for the data.

2. **Create Context-Rich Logs**: Include relevant context information in logs to aid debugging and monitoring.

3. **Be Consistent with Sources**: Use consistent source names to make log filtering and analysis easier.

4. **Log at Appropriate Levels**: Use the appropriate log level for each message (debug, info, warning, error, critical).

5. **Don't Log Sensitive Data at Public Level**: Never log sensitive data with a public privacy classification.

6. **Use Structured Logging**: Use structured logging with metadata rather than embedding sensitive data in log messages.

7. **Consider Environment**: Remember that logs behave differently in different environments.

8. **Authorise Sensitive Access Carefully**: Only authorise access to sensitive data when absolutely necessary.

9. **Revoke Access When Done**: Always revoke access to sensitive data when it's no longer needed.

10. **Test Logging in Different Environments**: Verify that privacy controls work correctly in all environments.

## Environment-Based Behaviour

The privacy-aware logging system behaves differently based on the deployment environment:

### Development Environment

- Public data is displayed normally.
- Private data is displayed normally.
- Sensitive data is redacted unless explicitly authorised.
- Hashed data is replaced with a hash.

### Staging Environment

- Public data is displayed normally.
- Private data is displayed normally.
- Sensitive data is redacted unless explicitly authorised.
- Hashed data is replaced with a hash.

### Production Environment

- Public data is displayed normally.
- Private data is redacted.
- Sensitive data is redacted.
- Hashed data is replaced with a hash.

### Testing Environment

- Public data is displayed normally.
- Private data is displayed normally.
- Sensitive data is displayed normally (for testing purposes).
- Hashed data is replaced with a hash.

## Automatic Pattern Detection

The privacy-aware logging system can automatically detect sensitive patterns in data with the `.auto` privacy classification. The following patterns are detected:

### Credit Card Numbers

Credit card numbers are automatically detected and redacted.

```
4111 1111 1111 1111 -> [REDACTED:AUTO]
```

### Email Addresses

Email addresses are automatically detected and redacted.

```
user@example.com -> [REDACTED:AUTO]
```

### API Keys

Common API key formats are automatically detected and redacted.

```
sk_live_1234567890abcdef -> [REDACTED:AUTO]
```

### JWT Tokens

JWT tokens are automatically detected and redacted.

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U -> [REDACTED:AUTO]
```

### Custom Patterns

You can add custom patterns to detect specific sensitive data formats in your application.
