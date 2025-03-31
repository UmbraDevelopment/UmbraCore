# Actor-Based Logging System

## Overview

The actor-based logging system provides a thread-safe, privacy-aware logging infrastructure for the Alpha Dot Five architecture. By leveraging Swift's actor model and concurrency features, the system ensures log messages are processed safely across multiple threads without race conditions or data corruption.

This document provides guidance on how to use the system effectively, with examples and best practices.

## Key Components

### Core Types

- **LogLevel**: Defines the severity of log messages (debug, info, warning, error, critical)
- **LogPrivacyLevel**: Controls how sensitive data is handled (public, private, sensitive, hash, auto)
- **LogTimestamp**: Provides precise timing information for log entries
- **LogEntry**: Represents a complete log message with metadata
- **PrivacyMetadata**: Container for key-value data with privacy annotations

### Interfaces

- **LoggingProtocol**: Primary interface for application code to interact with the logging system
- **ActorLogDestination**: Thread-safe destination for log entries
- **LoggingActor**: Central actor that manages the flow of log messages

### Services

- **ActorLogger**: Concrete implementation of LoggingProtocol
- **ConsoleLogDestination**: Writes formatted log entries to the console
- **PrivacyFilteredConsoleDestination**: Applies privacy filtering to log output
- **FileLogDestination**: Writes log entries to a file
- **LoggerFactory**: Creates configured logger instances

## Usage Patterns

### Basic Logging

The most straightforward way to use the system is through the LoggerFactory:

```swift
// Create a standard console logger
let logger = await LoggerFactory.createConsoleLogger(source: "MyAppModule")

// Log messages at different levels
await logger.debug("Initialising module...")
await logger.info("Module ready")
await logger.warning("Resource running low")
await logger.error("Failed to connect to service")
```

### Privacy-Aware Logging

To handle sensitive information properly:

```swift
// Create a privacy-aware logger
let logger = await LoggerFactory.createPrivacyAwareLogger(
    source: "AuthenticationModule",
    minimumLogLevel: .info
)

// Log with privacy annotations
let username = "john.smith@example.com"
let password = "SecretPassword123"

// Public information (visible in logs)
await logger.info("User login attempt: \(username, privacy: .public)")

// Private information (redacted in production)
await logger.debug("Authentication details: \(password, privacy: .sensitive)")

// Using metadata
var metadata = PrivacyMetadata()
metadata["user"] = PrivacyMetadataValue(value: username, privacy: .public)
metadata["sessionID"] = PrivacyMetadataValue(value: UUID().uuidString, privacy: .private)

await logger.info("Session established", metadata: metadata)
```

### File Logging

For persistent logs:

```swift
// Create a file logger that also outputs to console
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let logFileURL = documentsPath.appendingPathComponent("app.log")

let logger = await LoggerFactory.createFileLogger(
    fileURL: logFileURL,
    source: "AppCore",
    includeConsole: true
)

await logger.info("Application started")
```

### Contextual Logging

Create loggers with specific contexts:

```swift
// Create a base logger
let baseLogger = await LoggerFactory.createConsoleLogger()

// Create contextualised loggers for different components
let networkLogger = baseLogger.withSource("Network")
let databaseLogger = baseLogger.withSource("Database")
let uiLogger = baseLogger.withSource("UserInterface")

// Use each logger in its respective component
await networkLogger.info("Connection established")
await databaseLogger.debug("Query executed in 42ms")
await uiLogger.warning("UI element not responding")
```

## Advanced Usage

### Custom Log Destinations

You can create custom log destinations by implementing the ActorLogDestination protocol:

```swift
public actor DatabaseLogDestination: ActorLogDestination {
    public let identifier: String
    public let minimumLogLevel: LogLevel?
    
    private let database: Database
    
    public init(database: Database, identifier: String = "database", minimumLogLevel: LogLevel? = nil) {
        self.database = database
        self.identifier = identifier
        self.minimumLogLevel = minimumLogLevel
    }
    
    public func write(_ entry: LogEntry) async {
        // Store log entry in database
        let record = LogRecord(
            timestamp: entry.timestamp.secondsSinceEpoch,
            level: entry.level.rawValue,
            message: entry.message,
            source: entry.source
        )
        
        do {
            try await database.insert(record, into: "logs")
        } catch {
            print("Failed to write log to database: \(error.localizedDescription)")
        }
    }
}
```

### Combining Multiple Destinations

For complex logging needs, combine multiple destinations:

```swift
// Create individual destinations
let consoleDestination = ConsoleLogDestination(identifier: "console")
let fileDestination = FileLogDestination(fileURL: logFileURL)
let analyticsDestination = AnalyticsLogDestination(analyticsService: analytics)

// Combine them in a logger
var destinations: [any ActorLogDestination] = [
    consoleDestination,
    fileDestination,
    analyticsDestination
]

let loggingActor = LoggingActor(
    destinations: destinations,
    minimumLogLevel: .info
)

let logger = ActorLogger(loggingActor: loggingActor, defaultSource: "AppWithAnalytics")
```

## Performance Considerations

### Asynchronous Logging

Because the logging system is actor-based, all logging calls are asynchronous. This provides thread safety but requires the use of `await`:

```swift
// This requires an async context
await logger.info("This is an async log call")

// In synchronous contexts, you can use Task:
Task {
    await logger.info("Logging from a synchronous context")
}
```

### Log Levels

Set appropriate minimum log levels to avoid performance impacts:

```swift
// In development
let devLogger = await LoggerFactory.createConsoleLogger(minimumLogLevel: .debug)

// In production
let prodLogger = await LoggerFactory.createConsoleLogger(minimumLogLevel: .warning)
```

## Privacy and Compliance

The logging system is designed with privacy regulations (like GDPR and CCPA) in mind:

- Use appropriate privacy levels for all personal or sensitive data
- In production builds, sensitive information is automatically redacted
- The hash privacy level allows for correlation without exposing actual values
- File logs should be properly managed with retention policies

## Best Practices

1. **Contextualise logs** by using appropriate source identifiers
2. **Add metadata** to provide additional context for debugging
3. **Use privacy annotations** for all personal or sensitive information
4. **Set appropriate log levels** for different environments
5. **Handle errors** from the logging system gracefully
6. **Include correlation IDs** to track related operations
7. **Use structured logging** with metadata rather than complex string formatting
8. **Document logging conventions** for your team

## Troubleshooting

### Common Issues

1. **"Failed to write log to file"**: Check file permissions and disk space
2. **Missing await**: Ensure all logging calls are properly awaited
3. **Memory usage**: If logging large amounts of data, consider increasing buffer sizes
4. **Performance slowdown**: Review minimum log levels and destination configurations

## Future Enhancements

1. **Remote logging** to centralized log management systems
2. **Binary log formats** for improved performance and reduced storage
3. **Log rotation** and management policies
4. **Structured query language** for searching logs
5. **Real-time log streaming** for monitoring applications

---

## Appendix: Full API Reference

For complete API documentation, refer to the inline documentation in the source code:

- `LoggingTypes.swift`
- `LoggingProtocol.swift`
- `LoggingActor.swift`
- Various log destination implementations
