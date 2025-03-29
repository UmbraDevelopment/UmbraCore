# UmbraCore Logging Implementation Guide

## Quick Start

This guide provides practical examples for implementing the Alpha Dot Five compliant logging system in your UmbraCore modules. All examples follow the proper architectural patterns and concurrency model.

## Basic Setup

### 1. Import Required Modules

```swift
import LoggingTypes
import LoggingInterfaces
import LoggingServices
```

### 2. Create a Logger Instance

```swift
// Standard logger (console output, info level)
let logger = LoggingServiceFactory.createStandardLogger()

// Development logger (console output, debug level)
let devLogger = LoggingServiceFactory.createDevelopmentLogger()

// Production logger (file and console output)
let prodLogger = LoggingServiceFactory.createProductionLogger(
    logDirectoryPath: "/Library/Logs/UmbraCore",
    logFileName: "umbra.log"
)
```

### 3. Inject the Logger into Your Components

```swift
public struct MyService {
    private let logger: LoggingServiceProtocol
    
    public init(logger: LoggingServiceProtocol) {
        self.logger = logger
    }
    
    // Service methods...
}

// Usage:
let service = MyService(logger: LoggingServiceFactory.createStandardLogger())
```

## Logging Best Practices

### Log Levels

Choose the appropriate log level for your messages:

```swift
// Detailed tracing information (disabled in production)
await logger.verbose("Detailed processing step", source: "DataProcessor")

// Debugging information
await logger.debug("User input validation started", source: "FormValidator")

// General information about application flow
await logger.info("User successfully logged in", source: "AuthService")

// Potential issues that don't prevent normal operation
await logger.warning("API response slow, took 3s", source: "NetworkClient")

// Errors that prevent a specific operation from completing
await logger.error("Failed to save user preferences", source: "PreferencesManager")

// Critical failures that require immediate attention
await logger.critical("Database connection lost", source: "StorageService")
```

### Use Structured Metadata

Add contextual information using structured metadata:

```swift
// Create metadata with relevant context
let metadata = LogMetadata([
    "userId": "12345",
    "deviceType": "iPhone",
    "operationId": UUID().uuidString,
    "requestPath": "/api/v1/users"
])

// Log with metadata
await logger.info("API request completed", metadata: metadata, source: "APIClient")
```

### Track Operation Context

Use consistent identifiers across related log entries:

```swift
func processRequest(requestId: String) async {
    let requestMetadata = LogMetadata([
        "requestId": requestId,
        "timestamp": TimePointAdapter.now().description
    ])
    
    await logger.info("Request processing started", metadata: requestMetadata, source: "RequestHandler")
    
    // Later in the operation
    await logger.info("Request validation completed", metadata: requestMetadata, source: "RequestHandler")
    
    // At the end
    await logger.info("Request processing completed", metadata: requestMetadata, source: "RequestHandler")
}
```

## Error Handling

### Log Errors with Context

```swift
do {
    try await performOperation()
} catch let error as NSError {
    await logger.error(
        "Operation failed",
        metadata: LogMetadata([
            "errorCode": String(error.code),
            "errorDomain": error.domain,
            "errorDescription": error.localizedDescription
        ]),
        source: "OperationProcessor"
    )
}
```

### Handle Logging Errors

```swift
do {
    try await logger.addDestination(customDestination)
} catch let error as LoggingError {
    switch error {
    case .duplicateDestination(let identifier):
        print("Destination with identifier \(identifier) already exists")
    case .invalidConfiguration(let description):
        print("Invalid configuration: \(description)")
    default:
        print("Unexpected logging error: \(error)")
    }
}
```

## Advanced Usage

### Custom Log Formatters

Create a custom formatter for specialised output:

```swift
struct JSONLogFormatter: LogFormatterProtocol {
    public func format(_ entry: LogEntry) -> String {
        var jsonDict: [String: Any] = [
            "timestamp": entry.timestamp.description,
            "level": String(describing: entry.level),
            "message": entry.message
        ]
        
        if let source = entry.source {
            jsonDict["source"] = source
        }
        
        if let metadata = entry.metadata?.asDictionary {
            jsonDict["metadata"] = metadata
        }
        
        // Convert to JSON string
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "Error formatting log entry as JSON"
        }
        
        return jsonString
    }
}

// Usage:
let formatter = JSONLogFormatter()
let logger = LoggingServiceFactory.createStandardLogger(formatter: formatter)
```

### Custom Log Destinations

Implement a custom log destination:

```swift
actor NetworkLogDestination: LogDestination {
    public let identifier: String
    public nonisolated(unsafe) var minimumLevel: UmbraLogLevel
    private let endpoint: URL
    private let networkClient: NetworkClientProtocol
    
    public init(identifier: String, endpoint: URL, minimumLevel: UmbraLogLevel = .info, 
                networkClient: NetworkClientProtocol) {
        self.identifier = identifier
        self.minimumLevel = minimumLevel
        self.endpoint = endpoint
        self.networkClient = networkClient
    }
    
    public func write(_ entry: LogEntry) async throws {
        guard entry.level.rawValue >= minimumLevel.rawValue else {
            return
        }
        
        // Convert entry to network payload
        let payload = createPayload(from: entry)
        
        // Send log to remote endpoint
        try await networkClient.sendData(payload, to: endpoint)
    }
    
    public func flush() async throws {
        // Implement if your network client supports batching
    }
    
    private func createPayload(from entry: LogEntry) -> Data {
        // Implementation details...
        return Data()
    }
}
```

## Integration with Other Systems

### SwiftUI Integration

```swift
struct ContentView: View {
    @State private var logger: LoggingServiceProtocol?
    
    var body: some View {
        VStack {
            Button("Log Action") {
                Task {
                    await logger?.info("Button tapped", source: "ContentView")
                }
            }
        }
        .onAppear {
            // Initialize logger
            logger = LoggingServiceFactory.createStandardLogger()
        }
    }
}
```

### Actor-Based Service Integration

```swift
actor UserService {
    private let logger: LoggingServiceProtocol
    
    init(logger: LoggingServiceProtocol) {
        self.logger = logger
    }
    
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        await logger.debug("Fetching user profile", 
                         metadata: LogMetadata(["userId": userId]),
                         source: "UserService")
                         
        // Fetch logic...
        
        await logger.info("User profile fetched successfully", 
                        metadata: LogMetadata(["userId": userId]),
                        source: "UserService")
                        
        return UserProfile(/* ... */)
    }
}
```

## Performance Optimisation

### Conditional Logging

Avoid unnecessary string formatting for logs that will be filtered:

```swift
// Inefficient approach
await logger.debug("Processed item \(complexCalculation()) with result \(anotherExpensiveCall())")

// Efficient approach
if logger.getMinimumLogLevel().rawValue <= UmbraLogLevel.debug.rawValue {
    let result = complexCalculation()
    let otherResult = anotherExpensiveCall()
    await logger.debug("Processed item \(result) with result \(otherResult)")
}
```

### Batch Processing Considerations

For high-volume logging in batch operations, consider periodic flushing:

```swift
func processBatch(items: [Item]) async {
    for (index, item) in items.enumerated() {
        // Process item
        await logger.debug("Processed item \(index)", source: "BatchProcessor")
        
        // Periodically flush logs
        if index % 100 == 0 {
            try? await logger.flushAllDestinations()
        }
    }
}
```

## Testing with Logging

### Creating a Test Logger

```swift
class TestLogDestination: LogDestination {
    let identifier = "test-destination"
    var minimumLevel: UmbraLogLevel = .debug
    private(set) var loggedEntries: [LogEntry] = []
    
    func write(_ entry: LogEntry) async throws {
        loggedEntries.append(entry)
    }
    
    func flush() async throws {
        // No-op for testing
    }
}

// Usage in tests:
let testDestination = TestLogDestination()
let logger = LoggingServiceFactory.createCustomLogger(destinations: [testDestination])
let service = MyService(logger: logger)

// After calling service methods
XCTAssertEqual(testDestination.loggedEntries.count, 3)
XCTAssertEqual(testDestination.loggedEntries[0].level, .info)
XCTAssertEqual(testDestination.loggedEntries[0].message, "Service started")
```

## Troubleshooting Common Issues

### Logs Not Appearing

1. Check minimum log level configuration
2. Ensure async calls are properly awaited
3. Verify destination configuration
4. Check for actor isolation issues

### Memory Usage Concerns

1. Use log rotation for file destinations
2. Keep metadata concise
3. Set appropriate minimum log levels for production

### Thread Safety Issues

1. Always access loggers from the same actor/task
2. Use `nonisolated(unsafe)` carefully
3. Avoid synchronous wrappers around async logging methods

## Further Reading

For more detailed information, refer to:

- [UmbraCore Logging README](./README.md)
- [Logging Migration Guide](./MIGRATION_GUIDE.md)
- [Alpha Dot Five Architecture Documentation](../architecture/ALPHA_DOT_FIVE.md)
