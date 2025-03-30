# Error Logging System Documentation

The UmbraCore Error Logging System provides a standardised, privacy-aware approach to error logging throughout the application. This documentation outlines the key components, usage patterns, and best practises for effective error logging.

## Core Components

### ErrorLoggingProtocol

The central interface that defines all error logging operations:

```swift
public protocol ErrorLoggingProtocol: Sendable {
    func logWithContext(_ error: Error, context: ErrorContext, level: ErrorLoggingLevel, 
                       file: String, function: String, line: Int) async
    
    func log(_ error: Error, level: ErrorLoggingLevel?, 
            file: String, function: String, line: Int) async
    
    // Domain filter management methods...
}
```

### ErrorLoggerActor

The primary implementation of `ErrorLoggingProtocol`, providing:

- Thread-safe error logging through Swift concurrency
- Privacy controls for sensitive error data
- Domain-specific filtering
- Integration with the OSLog system
- Contextual error information management

### ErrorLoggerFactory

A factory providing standardised methods for creating error loggers:

```swift
// Create a default error logger
let errorLogger = await ErrorLoggerFactory.createDefaultErrorLogger()

// Create an OSLog-based error logger
let osLogger = await ErrorLoggerFactory.createOSLogErrorLogger(
    subsystem: "com.umbraapp.myapp",
    category: "MyComponent"
)
```

## Error Severity Levels

The system defines five error severity levels, each corresponding to a specific usage scenario:

1. **Debug**: Low-level information only needed for debugging
2. **Info**: General information about error events, not requiring immediate action
3. **Warning**: Indicates potential issues that might need attention
4. **Error**: Serious problems that affect functionality but allow continued operation
5. **Critical**: Severe issues that might cause the application to fail

## Usage Guidelines

### Basic Error Logging

To log a simple error:

```swift
// Create an error
let error = NSError(domain: "MyDomain", code: 100, 
                   userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])

// Log it with the default severity level
await errorLogger.log(error)
```

### Logging with Context

For richer error information, provide explicit context:

```swift
// Create context
let context = ErrorContext(
    operation: "file_upload",
    metadata: [
        "file_id": "12345",
        "file_size": "2.5MB"
    ]
)

// Log with explicit context
await errorLogger.logWithContext(
    error,
    context: context,
    level: .error
)
```

### Using UmbraError

For maximum control, use the `UmbraError` type:

```swift
let umbraError = UmbraError(
    domain: "NetworkService",
    code: "CONNECTION_TIMEOUT",
    message: "Failed to connect to server",
    severity: .error,
    context: context
)

await errorLogger.log(umbraError)
```

## Privacy Considerations

The error logging system respects privacy by:

1. Using the `LogPrivacy` settings for controlling what appears in logs
2. Applying privacy controls to error metadata
3. Allowing domain-specific filtering to minimise unnecessary logs

To configure privacy settings:

```swift
let config = ErrorLoggerConfiguration(
    includeMetadata: true,
    metadataPrivacyLevel: .private
)

let privacyLogger = await ErrorLoggerFactory.createErrorLogger(
    configuration: config
)
```

## Domain-Specific Filtering

Control which errors are logged based on their domain and severity:

```swift
// Only log errors and above from NetworkService
await errorLogger.addDomainFilter(domain: "NetworkService", level: .error)

// Only log warnings and above from UIService
await errorLogger.addDomainFilter(domain: "UIService", level: .warning)
```

## Integration with OSLog

For improved system integration on Apple platforms, use OSLog:

```swift
let osLogErrorLogger = await ErrorLoggerFactory.createOSLogErrorLogger(
    subsystem: "com.umbraapp.myapp",
    category: "MyComponent"
)
```

## Best Practises

1. **Be Contextual**: Always include relevant context information with errors
2. **Respect Privacy**: Mark sensitive information with appropriate privacy levels
3. **Use Domain Filtering**: Configure domain-specific filters to reduce noise
4. **Categorise Properly**: Choose the appropriate severity level for each error
5. **Provide Actionable Information**: Include enough information to understand and address issues
6. **Avoid Sensitive Data**: Never log credentials or personal information unprotected

## Advanced Configuration

For comprehensive logging setup with multiple destinations:

```swift
let advancedLogger = await ErrorLoggerFactory.createComprehensiveErrorLogger(
    fileURL: fileURL,
    osLogSubsystem: "com.umbraapp.myapp",
    osLogCategory: "ErrorLogging",
    configuration: customConfig
)
```

## Troubleshooting

Common issues and solutions:

1. **Missing Logs**: Check minimum log levels and domain filters
2. **Performance Issues**: Reduce log verbosity or disable stack traces
3. **Privacy Leaks**: Review metadata privacy settings
4. **Integration Problems**: Ensure proper initialisation of underlying logging service

## Migration Guidelines

When migrating from the legacy error logging system:

1. Replace `ErrorLogger.shared` with an instance created via `ErrorLoggerFactory`
2. Update error creation to use `UmbraError` instead of legacy error types
3. Replace direct logger calls with async await pattern
4. Review domain and severity mappings for consistency
