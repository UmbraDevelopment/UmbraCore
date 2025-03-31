# Logging Module

The Logging module provides a unified logging interface for UmbraCore using SwiftyBeaver as the underlying logging implementation.

## Features

- Structured logging with metadata support
- Multiple log levels (trace, debug, info, notice, warning, error, critical)
- File and console output with customisable formatting
- Integration with Apple's OSLog API for improved system integration
- Thread-safe logging operations
- Proper sandbox compliance for file access

## Usage

```swift
import UmbraCore

// Get shared logging service
let logger = LoggingService.shared

// Initialize with log file path
try await logger.initialize(with: "/path/to/logfile.log")

// Log messages with different levels
try await logger.log(LogEntry(
    level: .info,
    message: "Application started",
    metadata: ["version": "1.0.0"]
))

// Log with source context
try await logger.log(LogEntry(
    level: .error,
    message: "Operation failed",
    metadata: ["error": "Permission denied"],
    file: #file,
    function: #function,
    line: #line
))
```

## Log Levels

- `trace`: Detailed information for debugging
- `debug`: Debugging information
- `info`: General information about program execution
- `notice`: Normal but significant events
- `warning`: Warning messages for potentially harmful situations
- `error`: Error events that might still allow the application to continue running
- `critical`: Critical events that may cause the application to terminate

## Implementation Details

The logging system is built on SwiftyBeaver and provides:

- Coloured console output in Xcode
- Integration with Console.app via OSLog
- JSON-formatted logging capability
- Custom log formatting
- Proper error handling and recovery
- Thread-safe operations

## Best Practices

1. Always provide relevant metadata with log entries
2. Use appropriate log levels
3. Include source context for error and warning levels
4. Handle logging errors appropriately
5. Clean up resources by calling stop() when done

## Error Handling

The logging system can throw the following errors:
- `LoggingError.notInitialized`: Logger hasn't been initialized
- `LoggingError.fileError`: File operations failed
