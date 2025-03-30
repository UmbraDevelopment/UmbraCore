# Alpha Dot Five: Privacy-Enhanced Logging System

## Overview

This document outlines the design and implementation of a privacy-enhanced logging system for the Alpha Dot Five architecture. The system prioritises data privacy and security while maintaining comprehensive logging capabilities essential for debugging, monitoring, and auditing.

## Core Components

### 1. Privacy Levels

```swift
public enum LogPrivacyLevel: Sendable {
    /// Public information
    case `public`
    /// Private information that should be redacted in logs
    case `private`
    /// Sensitive information that requires special handling
    case sensitive
    /// Information that should be hashed before logging
    case hash
    /// Auto-redacted content based on type analysis
    case auto
}
```

### 2. Enhanced Log Context

The `LogContext` structure provides rich contextual information about log events with privacy annotations:

```swift
public struct LogContext: Sendable, Equatable {
    /// Component that generated the log
    public let source: String
    
    /// Additional structured data with privacy annotations
    public let metadata: [String: (value: Any, privacy: LogPrivacyLevel)]?
    
    /// For tracking related logs across components
    public let correlationId: UUID
    
    /// When the log was created
    public let timestamp: Date
    
    public init(
        source: String,
        metadata: [String: (value: Any, privacy: LogPrivacyLevel)]? = nil,
        correlationId: UUID = UUID(),
        timestamp: Date = Date()
    ) {
        self.source = source
        self.metadata = metadata
        self.correlationId = correlationId
        self.timestamp = timestamp
    }
}
```

### 3. String Interpolation with Privacy Controls

```swift
@frozen public struct PrivacyString: ExpressibleByStringInterpolation {
    // Implementation that allows for privacy-aware string interpolation
    // Usage: "Processing account \(private: accountId)"
}
```

## Protocol Hierarchy

### 1. Core Logging Protocol

```swift
public protocol CoreLoggingProtocol: Sendable {
    /// Log a message with the specified level and context
    func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async
}
```

### 2. Standard Logging Protocol

```swift
public protocol LoggingProtocol: CoreLoggingProtocol {
    func trace(_ message: String, metadata: LogMetadata?, source: String) async
    func debug(_ message: String, metadata: LogMetadata?, source: String) async
    func info(_ message: String, metadata: LogMetadata?, source: String) async
    func warning(_ message: String, metadata: LogMetadata?, source: String) async
    func error(_ message: String, metadata: LogMetadata?, source: String) async
    func critical(_ message: String, metadata: LogMetadata?, source: String) async
}
```

### 3. Privacy-Aware Logging Protocol

```swift
public protocol PrivacyAwareLoggingProtocol: LoggingProtocol {
    /// Log with explicit privacy controls
    func log(
        _ level: LogLevel,
        _ message: PrivacyString,
        metadata: [String: (value: Any, privacy: LogPrivacyLevel)]?,
        source: String
    ) async
    
    /// Log sensitive information with appropriate redaction
    func logSensitive(
        _ level: LogLevel,
        _ message: String,
        sensitiveValues: [String: Any],
        source: String
    ) async
}
```

## Implementation Classes

### 1. Privacy-Aware Logger

```swift
public actor PrivacyAwareLogger: PrivacyAwareLoggingProtocol {
    private let minimumLevel: LogLevel
    private let identifier: String
    private let backend: LoggingBackend
    
    // Implementation of all protocol methods with privacy controls
}
```

### 2. OSLog Backend with Privacy Controls

```swift
public struct OSLogPrivacyBackend: LoggingBackend {
    public func writeLog(
        level: LogLevel,
        message: String,
        context: LogContext,
        subsystem: String
    ) async {
        // Implementation using OSLog with privacy annotations
    }
}
```

## Factory Pattern

```swift
public enum PrivacyAwareLoggingFactory {
    /// Create a logger with privacy features
    public static func createLogger(
        minimumLevel: LogLevel = .info,
        identifier: String,
        backend: LoggingBackend? = nil,
        privacyLevel: LogPrivacyLevel = .auto
    ) -> any PrivacyAwareLoggingProtocol {
        // Implementation that creates the appropriate logger
    }
}
```

## MVVM Integration

The logging system integrates cleanly with the MVVM architecture:

### ViewModel Example

```swift
public class KeychainSecurityViewModel {
    private let logger: PrivacyAwareLoggingProtocol
    private let keychainService: KeychainSecurityProtocol
    
    @Published private(set) var status: KeychainOperationStatus = .idle
    
    // Implementation that uses the privacy-aware logging
    public func storeSecret(_ secret: String, forAccount account: String) async {
        await logger.log(
            .info,
            "Processing secret storage for \(private: account)",
            metadata: [
                "secretLength": (value: secret.count, privacy: .public)
            ],
            source: "KeychainSecurityViewModel"
        )
        
        // Additional implementation with privacy controls
    }
}
```

## Usage Examples

### 1. Basic Logging with Privacy Controls

```swift
// Log with explicit privacy annotations
await logger.log(
    .info,
    "Processing payment for user \(private: userId) with amount \(public: amount)",
    metadata: [
        "transactionId": (value: transactionId, privacy: .public),
        "cardInfo": (value: cardLastFour, privacy: .private)
    ],
    source: "PaymentProcessor"
)
```

### 2. Sensitive Data Handling

```swift
// Simplified logging of sensitive data
await logger.logSensitive(
    .debug,
    "Authentication attempt",
    sensitiveValues: [
        "username": username,
        "ipAddress": ipAddress
    ],
    source: "AuthenticationService"
)
```

### 3. Error Logging with Privacy

```swift
do {
    // Operation code
} catch {
    await logger.log(
        .error,
        "Operation failed: \(private: error.localizedDescription)",
        metadata: [
            "errorCode": (value: (error as? AppError)?.code ?? -1, privacy: .public),
            "timestamp": (value: Date(), privacy: .public)
        ],
        source: "OperationManager"
    )
}
```

## Benefits

1. **Privacy by Design**: Data privacy is a first-class concern in the logging architecture
2. **Regulatory Compliance**: Helps meet GDPR, CCPA, and other privacy regulations
3. **Development-friendly**: More verbose in development, appropriately redacted in production
4. **Type Safety**: Strong typing for privacy annotations
5. **Contextual Richness**: Preserves important context while protecting sensitive data
6. **MVVM Compatibility**: Seamlessly integrates with the MVVM architecture
7. **Extensibility**: Easy to adapt for different logging backends

## Implementation Guidelines

1. Always use the appropriate privacy level for personal or sensitive data
2. Prefer explicit privacy annotations over relying on automatic redaction
3. Keep public metadata separate from private metadata
4. Use correlation IDs to trace related log events across components
5. Configure minimum log levels appropriately for each environment

## Future Enhancements

1. Machine learning-based auto-detection of sensitive information
2. Integration with centralised logging systems
3. Audit trail generation for sensitive operations
4. Privacy budget tracking to prevent data over-exposure
5. Advanced filtering and search capabilities with privacy controls

## Migration Guide

When migrating from the existing adapter-based logging system:

1. Replace `LoggingAdapter` instances with direct `PrivacyAwareLogger` instances
2. Update logging calls to use the privacy-enhanced methods
3. Add appropriate privacy annotations to sensitive data
4. Update dependencies to inject the new logger types
