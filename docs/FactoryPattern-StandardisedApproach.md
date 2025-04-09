# UmbraCore Factory Pattern: Standardised Approach

## Overview

This document outlines the standardised factory pattern approach used throughout the UmbraCore project. The factory pattern provides a consistent way to create service instances with various configurations, promoting dependency injection and testability.

## Factory Method Naming Conventions

To ensure consistency across the codebase, the following naming conventions have been established:

1. **`createDefault()`**: Creates a service instance with default configuration.
   - No parameters or minimal required parameters
   - Suitable for most common use cases
   - Example: `let service = await ServiceFactory.createDefault()`

2. **`createService(...)`**: Creates a service instance with custom configuration.
   - Takes specific parameters to customise the service
   - Provides fine-grained control over service behaviour
   - Example: `let service = await ServiceFactory.createService(parameter1: value1, parameter2: value2)`

3. **Domain-specific creation methods**: Creates specialised service instances for specific domains.
   - Named according to their domain and purpose
   - Example: `let logger = LoggerFactory.createSecurityLogger(source: "SecurityService")`

## Factory Implementation Patterns

### Singleton Factories

For factories that maintain state or caching:

```swift
public actor ServiceFactory {
  /// Shared singleton instance
  public static let shared = ServiceFactory()
  
  /// Private cache of created services
  private var serviceCache: [String: Any] = [:]
  
  /// Create a default service instance
  public func createDefault() async -> ServiceProtocol {
    // Implementation
  }
}
```

### Stateless Factories

For factories that don't require state:

```swift
public enum ServiceFactory {
  /// Create a default service instance
  public static func createDefault() -> ServiceProtocol {
    // Implementation
  }
  
  /// Create a service with custom configuration
  public static func createService(
    parameter1: Type1,
    parameter2: Type2
  ) -> ServiceProtocol {
    // Implementation
  }
}
```

## Best Practices

1. **Dependency Injection**: Factories should accept dependencies as parameters rather than creating them internally.

2. **Caching**: Consider caching service instances when appropriate to improve performance.

3. **Thread Safety**: Use actors for factories that maintain state to ensure thread safety.

4. **Logging**: Include logging capabilities in factories to track service creation and configuration.

5. **Error Handling**: Provide clear error handling for factory methods that might fail.

6. **Documentation**: Document factory methods with clear examples and parameter descriptions.

## Factory Interfaces

Factory interfaces should be defined in the appropriate interfaces package:

```swift
public protocol ServiceFactoryProtocol: Sendable {
  /// Creates a default service
  func createDefault() -> any ServiceProtocol
  
  /// Creates a service with custom configuration
  func createService(
    parameter1: Type1,
    parameter2: Type2
  ) -> any ServiceProtocol
}
```

## Examples

### LoggerFactory

```swift
// Create a domain-specific logger
let cryptoLogger = LoggerFactory.createCryptoLogger(source: "CryptoService")

// Create a logger with subsystem and category
let osLogger = LoggerFactory.createOSLogger(
  subsystem: "com.example.myapp",
  category: "networking"
)

// Create a secure logger
let secureLogger = await LoggerFactory.createSecureLogger(
  category: "SecurityOperations"
)
```

### KeychainServiceFactory

```swift
// Create a default keychain service
let keychainService = await KeychainServiceFactory.createDefault()

// Create a keychain service with custom configuration
let customService = await KeychainServiceFactory.createService(
  serviceIdentifier: "com.example.customservice",
  logger: customLogger
)
```

## Migration Guide

When migrating existing code to use the standardised factory pattern:

1. Rename `createDefaultService()` methods to `createDefault()`
2. Ensure all factory methods follow the established naming conventions
3. Update all references to the renamed methods
4. Consider consolidating duplicate factory implementations

## Conclusion

By following these standardised factory patterns, the UmbraCore project maintains a consistent, maintainable, and testable approach to service creation across all modules.
