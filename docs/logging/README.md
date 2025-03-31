# UmbraCore Logging System

## Overview

The UmbraCore Logging System follows the Alpha Dot Five architecture, providing a thread-safe, actor-based logging solution with comprehensive error handling and proper separation of concerns. This document outlines the architecture, components, and usage of the logging system.

## Architecture

The logging system is split into three main components:

1. **LoggingTypes** - Core type definitions with no dependencies
2. **LoggingInterfaces** - Protocol definitions defining the API surface
3. **LoggingServices** - Concrete implementations of the logging services

This separation allows for a clean architecture with minimal dependencies and maximum flexibility.

### Key Features

- **Actor-based concurrency** - Thread-safe logging operations
- **Multiple log destinations** - Console, file, and custom destinations
- **Flexible formatting** - Customisable log formatting
- **Comprehensive error handling** - Domain-specific error types
- **Log rotation** - Automatic file rotation for file-based logging
- **Metadata support** - Attach structured data to log entries
- **Source tracking** - Identify the component that generated each log

## Components

### Core Types

- **LogEntry** - Represents a log message with metadata
- **LogMetadata** - Key-value pairs of additional information
- **UmbraLogLevel** - Severity levels (verbose, debug, info, warning, error, critical)
- **LogDestination** - Protocol for log output targets
- **TimePointAdapter** - Foundation-free timestamp representation

### Interfaces

- **LoggingProtocol** - Basic logging interface
- **LoggingServiceProtocol** - Enhanced logging service with destination management
- **LogFormatterProtocol** - Interface for formatting log entries

### Implementations

- **LoggingServiceActor** - Primary actor-based logging implementation
- **ConsoleLogDestination** - Logs to standard output
- **FileLogDestination** - Logs to files with rotation
- **DefaultLogFormatter** - Standard log formatting
- **LoggingServiceFactory** - Factory methods for creating logging services

## Usage Examples

### Basic Logging

```swift
// Create a standard logger
let logger = LoggingServiceFactory.createStandardLogger()

// Log at different levels
await logger.debug("Debug message")
await logger.info("Info message")
await logger.warning("Warning message", metadata: LogMetadata(["key": "value"]))
await logger.error("Error message", source: "MyComponent")
```

### Custom Configuration

```swift
// Create a development logger with debug level
let devLogger = LoggingServiceFactory.createDevelopmentLogger()

// Create a production logger with file output
let prodLogger = LoggingServiceFactory.createProductionLogger(
    logDirectoryPath: "/var/log/umbra",
    logFileName: "application.log",
    minimumLevel: .info,
    maxFileSizeMB: 20,
    maxBackupCount: 5
)
```

### Managing Log Destinations

```swift
// Create a custom logger
let logger = LoggingServiceFactory.createStandardLogger()

// Add a file destination
let fileDestination = FileLogDestination(
    identifier: "custom-file",
    filePath: "/path/to/logs/custom.log"
)
try await logger.addDestination(fileDestination)

// Remove a destination
_ = await logger.removeDestination(withIdentifier: "console")
```

### Using Metadata

```swift
// Create metadata
let metadata = LogMetadata([
    "user": "johndoe",
    "requestId": "abc-123",
    "component": "authentication"
])

// Log with metadata
await logger.info("User authenticated", metadata: metadata)
```

## Best Practices

1. **Use the appropriate log level** - Reserve error and critical for actual errors
2. **Add relevant metadata** - Include context with structured data
3. **Specify source components** - Help identify where logs originated
4. **Consider log volume** - Use verbose and debug sparingly in production
5. **Handle async properly** - Remember that logging operations are async

## Error Handling

The logging system uses domain-specific error types defined in `LoggingError`:

- **initialisationFailed** - Failed to initialise logging system
- **writeFailed** - Failed to write log
- **destinationWriteFailed** - Failed to write to specific destination
- **filteredByLevel** - Message filtered due to log level
- **invalidConfiguration** - Invalid configuration provided
- **operationNotSupported** - Operation not supported by logger
- **destinationNotFound** - Specified destination not found
- **duplicateDestination** - Duplicate destination identifier

## Thread Safety

All logging operations are thread-safe through the use of Swift actors. The `LoggingServiceActor` ensures proper isolation and serialised access to log destinations.

## Performance Considerations

- File logging performs automatic rotation to prevent excessive file sizes
- Log filtering happens early to avoid unnecessary formatting
- Consider using a custom formatter for high-performance needs

## Future Enhancements

- Network log destinations
- Structured logging output formats (JSON, etc.)
- Log aggregation and analysis tools
- Performance metrics for logging operations
