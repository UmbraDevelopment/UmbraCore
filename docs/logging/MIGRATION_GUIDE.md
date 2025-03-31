# Logging System Migration Guide

## Overview

This guide will help you migrate from previous UmbraCore logging implementations to the new Alpha Dot Five compliant logging architecture. The new system has been completely refactored to provide thread-safe, actor-based logging with proper separation of concerns.

## Key Differences

### Architecture Changes

| Previous Implementation | Alpha Dot Five Implementation |
|------------------------|-------------------------------|
| Type aliases and mixed concerns | Clear separation of types, interfaces, and implementations |
| Callback-based asynchrony | Swift concurrency (async/await) |
| Global shared instances | Dependency injection |
| Class-based threading model | Actor-based concurrency |
| Limited error handling | Comprehensive domain-specific errors |
| Foundation-dependent | Foundation-free core types |

### API Changes

1. All logging methods are now `async`
2. Log destinations are now protocol-based with clear interfaces
3. Metadata is now strongly typed via `LogMetadata`
4. Timestamps use the foundation-free `TimePointAdapter`
5. Log entries include source component information

## Migration Steps

### Step 1: Update Import Statements

Replace previous imports with the new module structure:

```swift
// Old approach
import UmbraCore
import UmbraLogging

// New approach
import LoggingTypes
import LoggingInterfaces
import LoggingServices
```

### Step 2: Replace Logger Initialisation

```swift
// Old approach
let logger = Logger.shared
// or
let logger = Logger(label: "com.umbra.mycomponent")

// New approach
let logger = LoggingServiceFactory.createStandardLogger()
// or for development
let logger = LoggingServiceFactory.createDevelopmentLogger()
// or for production with file logging
let logger = LoggingServiceFactory.createProductionLogger(
    logDirectoryPath: "/path/to/logs",
    logFileName: "application.log"
)
```

### Step 3: Update Logging Method Calls

```swift
// Old approach
logger.debug("Debug message", metadata: ["key": "value"])
logger.error("Error occurred", error: error)

// New approach
await logger.debug("Debug message", metadata: LogMetadata(["key": "value"]))
await logger.error("Error occurred", metadata: LogMetadata(["error": error.localizedDescription]))
```

### Step 4: Handle Custom Log Destinations

```swift
// Old approach
let customDestination = CustomLogHandler(label: "custom")
LoggingSystem.bootstrap { _ in customDestination }

// New approach
let customDestination = MyCustomLogDestination(identifier: "custom")
let logger = LoggingServiceFactory.createCustomLogger(destinations: [customDestination])
// or
let logger = LoggingServiceFactory.createStandardLogger()
try await logger.addDestination(customDestination)
```

### Step 5: Update Error Handling

```swift
// Old approach
do {
    try riskyOperation()
} catch {
    logger.error("Operation failed", error: error)
}

// New approach
do {
    try await riskyOperation()
} catch {
    await logger.error(
        "Operation failed",
        metadata: LogMetadata([
            "error": error.localizedDescription,
            "errorType": String(describing: type(of: error))
        ]),
        source: "MyComponent"
    )
}
```

## Creating a Custom Log Destination

If you had custom log destinations, you'll need to update them to conform to the new `LogDestination` protocol:

```swift
import LoggingTypes
import LoggingInterfaces

public struct MyCustomLogDestination: LogDestination {
    public let identifier: String
    public var minimumLevel: UmbraLogLevel
    
    public init(identifier: String, minimumLevel: UmbraLogLevel = .info) {
        self.identifier = identifier
        self.minimumLevel = minimumLevel
    }
    
    public func write(_ entry: LogEntry) async throws {
        // Your custom logging implementation
        // For example, sending logs to a third-party service
    }
    
    public func flush() async throws {
        // Implement if needed
    }
}
```

## Transitioning from Sync to Async

Since all logging methods are now asynchronous, you'll need to update calling code:

```swift
// Option 1: Call from an async context
func myAsyncFunction() async {
    await logger.info("This is an async log message")
}

// Option 2: Create a Task
func myNonAsyncFunction() {
    Task {
        await logger.info("Logging from a Task")
    }
}

// Option 3: Use detached Task if needed
func backgroundLogging() {
    Task.detached {
        await logger.info("Background logging")
    }
}
```

## Known Issues and Workarounds

### 1. Actor Isolation in SwiftUI

When using the logger in SwiftUI views, you may encounter actor isolation warnings. Use the following approach:

```swift
struct MyView: View {
    @State private var logger = LoggingServiceFactory.createStandardLogger()
    
    var body: some View {
        Button("Log") {
            Task {
                await logger.info("Button pressed")
            }
        }
    }
}
```

### 2. Handling Optional Metadata

The new system uses optional metadata. When migrating, convert any nil metadata to properly typed optional:

```swift
// Old approach
let metadata: [String: String]? = nil
logger.info("Message", metadata: metadata ?? [:])

// New approach
let metadata: LogMetadata? = nil  // Directly use the optional
await logger.info("Message", metadata: metadata)
```

## Troubleshooting

### Logging Not Working

1. Ensure you're awaiting logging calls
2. Check that your minimum log level isn't filtering messages
3. Verify log destinations are correctly configured

### Compilation Errors

1. "Actor-isolated property cannot satisfy non-isolated requirement"
   - This typically occurs when implementing `LogDestination` with an actor
   - Use `nonisolated(unsafe)` for the `minimumLevel` property

2. "Extension declares a conformance of imported type to protocol"
   - Use `@unchecked Sendable` when extending external types

## Timeline

The old logging system will be deprecated in the next major release and removed entirely in the following release. We recommend migrating to the new system as soon as possible.
