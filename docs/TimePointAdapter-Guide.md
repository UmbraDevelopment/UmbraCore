# TimePointAdapter: Integrating with the Actor-Based Logging System

## Overview

The TimePointAdapter provides a bridge between system time representations and the logging system's `LogTimestamp` structure. It ensures consistent and thread-safe timestamp generation across the Alpha Dot Five architecture.

This guide explains how to use the TimePointAdapter effectively with the actor-based logging system.

## Integration with LogTimestamp

The TimePointAdapter works closely with the `LogTimestamp` struct, which uses an actor-based approach to provide thread-safe timestamp generation.

### Basic Usage

```swift
// Get the current time point
let timePoint = TimePointAdapter.currentTimePoint()

// Convert to a LogTimestamp
let timestamp = TimePointAdapter.toLogTimestamp(timePoint)

// Use in logging
let entry = LogEntry(
    level: .info,
    message: "System event occurred",
    source: "SystemMonitor",
    timestamp: timestamp
)
```

### Asynchronous Timestamp Generation

When working with the new actor-based logging system, you'll typically use the asynchronous methods:

```swift
// Asynchronously get a current timestamp
let timestamp = await LogTimestamp.now()

// Create a log entry with the current timestamp
let entry = await LogEntry.create(
    level: .info,
    message: "Operation completed successfully",
    source: "TaskManager"
)
```

## Time Zone Handling

The TimePointAdapter handles time zone conversions, ensuring logs maintain consistent timestamps regardless of the local system settings:

```swift
// Get time in a specific time zone
let londonTime = TimePointAdapter.timePointInTimeZone(
    timePoint: systemTime,
    timeZone: TimeZone(identifier: "Europe/London")!
)

// Format for display
let formattedTime = TimePointAdapter.formatTimePoint(
    londonTime,
    format: "dd/MM/yyyy HH:mm:ss"  // British date format
)
```

## Performance Considerations

The TimePointAdapter is designed to be lightweight, but there are some performance considerations:

1. **Caching**: Consider caching timestamps for closely related log entries rather than generating new ones for each entry
2. **Time Zone Conversions**: Minimise time zone conversions in performance-critical code
3. **Format Only When Needed**: Formatting time points is relatively expensive, so only format when needed for display

## Integration with LogContext

The TimePointAdapter works seamlessly with the LogContext structure:

```swift
// Create a context with the current time
let context = await LogContext.create(source: "ModuleName")

// The LogContext will automatically use LogTimestamp.now() internally
await logger.info("Message with automatic context generation")
```

## Handling Historical Data

For processing historical data or simulating timestamps:

```swift
// Create a specific timestamp (e.g., for replay or testing)
let historicalDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00
let timePoint = TimePointAdapter.toTimePoint(historicalDate)
let timestamp = TimePointAdapter.toLogTimestamp(timePoint)

// Use in logging historical events
let historicalEntry = LogEntry(
    level: .info,
    message: "Historical event",
    source: "DataImporter",
    timestamp: timestamp
)
```

## Testing and Mocking

The TimePointAdapter can be extended to support testing scenarios:

```swift
// Example extension for testing
extension TimePointAdapter {
    static var mockTimePoint: TimePoint?
    
    static func withMockedTime(_ timePoint: TimePoint, perform action: () throws -> Void) rethrows {
        let originalMock = mockTimePoint
        mockTimePoint = timePoint
        defer { mockTimePoint = originalMock }
        try action()
    }
    
    static func currentTimePoint() -> TimePoint {
        return mockTimePoint ?? systemCurrentTimePoint()
    }
    
    private static func systemCurrentTimePoint() -> TimePoint {
        // Original implementation
    }
}
```

## Best Practices

1. **Use LogTimestamp.now() for logs**: Whenever possible, use the actor-based `now()` method
2. **Consistent formatting**: Use consistent date and time formats in logs
3. **Include time zones when relevant**: If time zone matters, include it in log messages
4. **Performance awareness**: Be mindful of timestamp generation in high-frequency logging scenarios
5. **Correlation**: Use the same timestamp for related log entries to aid in correlation

## Common Patterns

### Timed Operations

```swift
func performTimedOperation() async {
    let startTime = await LogTimestamp.now()
    
    // Perform operation
    let result = await performExpensiveOperation()
    
    let endTime = await LogTimestamp.now()
    let duration = endTime.secondsSinceEpoch - startTime.secondsSinceEpoch
    
    await logger.info("Operation completed in \(duration) seconds")
}
```

### Batched Logging with Same Timestamp

```swift
func processBatch(items: [Item]) async {
    let batchTimestamp = await LogTimestamp.now()
    
    for (index, item) in items.enumerated() {
        let entry = LogEntry(
            level: .debug,
            message: "Processing item \(index+1)/\(items.count)",
            source: "BatchProcessor",
            timestamp: batchTimestamp
        )
        
        await loggingActor.write(entry)
    }
}
```

### Custom Time Formatters

```swift
extension TimePointAdapter {
    static func formatBritishStyle(_ timePoint: TimePoint) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Europe/London")
        return formatter.string(from: toDate(timePoint))
    }
}
```

---

This guide should be used in conjunction with the main Actor-Based Logging System documentation to provide a complete understanding of the time-related components in the logging architecture.
