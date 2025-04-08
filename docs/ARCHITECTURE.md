# UmbraCore Architecture Documentation

## Alpha Dot Five Architecture

UmbraCore follows the Alpha Dot Five architecture, our modern approach to building secure, performant, and maintainable MVP Swift applications. This document provides an overview of the architecture and its key components.

## Table of Contents

1. [Core Principles](#core-principles)
2. [Actor-Based Concurrency](#actor-based-concurrency)
3. [Domain Handlers](#domain-handlers)
4. [Privacy-Aware Logging](#privacy-aware-logging)
5. [Rate Limiting](#rate-limiting)
6. [Service Providers](#service-providers)
7. [Factory Pattern](#factory-pattern)
8. [Error Handling](#error-handling)
9. [Best Practices](#best-practices)

## Core Principles

The Alpha Dot Five architecture is built on the following core principles:

1. **Actor-Based Concurrency**: Services utilise Swift actors for thread safety and structured concurrency.

2. **Provider-Based Abstraction**: Multiple implementations are supported through provider interfaces.

3. **Privacy-By-Design**: Enhanced privacy-aware error handling and logging to prevent sensitive information leakage.

4. **Type Safety**: Using strongly-typed interfaces that make illegal states unrepresentable.

5. **Async/Await**: Full adoption of Swift's modern concurrency model.

## Actor-Based Concurrency

UmbraCore uses Swift's actor model to ensure thread safety and memory isolation. Actors provide automatic synchronisation and eliminate potential race conditions when handling concurrent requests.

### Key Benefits

- **Thread Safety**: Actors ensure that only one task can access mutable state at a time.
- **Memory Isolation**: Actor state is isolated from other parts of the system.
- **Structured Concurrency**: Actors work seamlessly with Swift's async/await model.

### Example

```swift
public actor SecurityDomainHandler: DomainHandlerProtocol {
    private let securityService: SecurityServiceProtocol
    private var keyMetadataCache: [String: KeyMetadata] = [:]
    
    public func handleOperation<T: APIOperation>(operation: T) async throws -> Any {
        // Implementation with automatic thread safety
    }
}
```

## Domain Handlers

Domain handlers are responsible for processing API operations within a specific domain. They follow a consistent pattern and provide optimised performance through caching and batch processing.

### Key Components

- **BaseDomainHandler**: Provides common functionality for all domain handlers.
- **DomainHandlerProtocol**: Ensures consistent implementation across all handlers.
- **Caching**: Improves performance by caching frequently accessed resources.
- **Batch Processing**: Optimises handling of multiple operations of the same type.

### Available Domain Handlers

- **SecurityDomainHandler**: Handles security-related operations (encryption, decryption, etc.).
- **BackupDomainHandler**: Handles backup-related operations (snapshots, restores, etc.).
- **RepositoryDomainHandler**: Handles repository-related operations (creation, retrieval, etc.).

## Privacy-Aware Logging

UmbraCore implements a privacy-aware logging system that ensures sensitive data is properly protected. The system supports different privacy classifications and environment-based redaction.

### Privacy Classifications

- **Public**: Displayed normally in all environments.
- **Private**: Redacted in production, displayed in development.
- **Sensitive**: Always redacted, but can be accessed with proper authorisation.
- **Hash**: Replaced with a hash of the original value.
- **Auto**: Automatically detected based on content patterns.

### Key Components

- **PrivacyAwareLogFormatter**: Applies privacy controls to log messages.
- **PrivacyAwareLoggingActor**: Implements the `PrivacyAwareLoggingProtocol`.
- **LogMetadataDTO**: Represents a single metadata entry with privacy classification.
- **LogMetadataDTOCollection**: Builder for a collection of metadata entries.

### Example

```swift
let metadata = LogMetadataDTOCollection()
    .withPublic(key: "operation", value: "encryptData")
    .withPrivate(key: "userId", value: "12345")
    .withSensitive(key: "apiKey", value: "sk_live_1234567890")

await logger.info(
    "Processing encryption request",
    context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: metadata
    )
)
```

## Rate Limiting

UmbraCore includes a rate limiting system to prevent abuse and ensure fair resource usage. The system uses the token bucket algorithm for flexible rate limiting with burst capabilities.

### Key Components

- **RateLimiter**: Implements the token bucket algorithm.
- **RateLimiterFactory**: Creates and manages rate limiters for different operations.
- **High-Security Configuration**: Stricter limits for sensitive operations.

### Example

```swift
// Get a rate limiter for a high-security operation
let rateLimiter = await RateLimiterFactory.shared.getHighSecurityRateLimiter(
    domain: "security",
    operation: "encryptData"
)

// Try to consume a token
if await rateLimiter.tryConsume() {
    // Proceed with the operation
} else {
    // Rate limit exceeded
    throw APIError.rateLimitExceeded(
        message: "Rate limit exceeded for encryption operations",
        retryAfter: 5
    )
}
```

## Service Providers

UmbraCore supports multiple service implementations through provider interfaces. This allows for flexibility and adaptability to different environments and requirements.

### Security Providers

1. **DefaultCryptoServiceImpl**:
   - Acts as the fallback implementation when more specialised providers aren't selected
   - Implements CryptoServiceProtocol using SecureStorageProtocol
   - Available on all platforms as a baseline implementation

2. **AppleSecurityProvider (Apple CryptoKit)**:
   - Native implementation for Apple platforms (macOS 10.15+, iOS 13.0+, etc.)
   - Takes advantage of hardware acceleration where available
   - Uses AES-GCM for authenticated encryption
   - Optimised for Apple platforms

3. **RingSecurityProvider (Rust FFI)**:
   - Cross-platform implementation using Rust's Ring cryptography library via FFI
   - Works on any platform with Ring FFI bindings
   - Uses constant-time implementations to prevent timing attacks
   - Provides high-quality cryptographic primitives regardless of platform

### Backup Providers

1. **LocalBackupStorageProvider**:
   - Stores backups on the local file system
   - Suitable for desktop applications and testing

2. **CloudBackupStorageProvider**:
   - Stores backups in cloud storage
   - Supports various cloud providers

3. **HybridBackupStorageProvider**:
   - Combines local and cloud storage
   - Provides redundancy and flexibility

### Repository Providers

1. **StandardRepositoryProvider**:
   - Default implementation for repository operations
   - Suitable for most use cases

2. **DistributedRepositoryProvider**:
   - Supports distributed repositories
   - Handles synchronisation and conflict resolution

3. **LegacyRepositoryProvider**:
   - Provides compatibility with legacy systems
   - Handles format conversion and migration

## Factory Pattern

UmbraCore uses the factory pattern to create and configure services and handlers. This provides a centralised way to manage dependencies and ensure proper configuration.

### Key Factories

- **DomainHandlerFactory**: Creates and manages domain handlers.
- **SecurityServiceFactory**: Creates and configures security services.
- **BackupServiceFactory**: Creates and configures backup services.
- **RepositoryServiceFactory**: Creates and configures repository services.
- **LoggingServiceFactory**: Creates and configures logging services.
- **RateLimiterFactory**: Creates and manages rate limiters.

### Example

```swift
// Create a domain handler for security operations
let securityHandler = try await DomainHandlerFactory.shared.createHandler(for: .security)

// Execute a security operation
let result = try await securityHandler.handleOperation(operation: encryptDataOperation)
```

## Error Handling

UmbraCore implements a comprehensive error handling system that provides clear, informative errors while protecting sensitive information.

### Key Error Types

- **APIError**: Standardised errors for API operations.
- **SecurityError**: Security-specific errors.
- **BackupError**: Backup-specific errors.
- **RepositoryError**: Repository-specific errors.

### Error Mapping

Domain-specific errors are mapped to standardised API errors to provide a consistent interface to clients.

```swift
private func mapToAPIError(_ error: Error) -> APIError {
    // If it's already an APIError, return it
    if let apiError = error as? APIError {
        return apiError
    }

    // Handle specific security error types
    if let securityError = error as? SecurityError {
        return mapSecurityError(securityError)
    }

    // Default to a generic error for unhandled error types
    return APIError.internalError(
        message: "An unexpected error occurred",
        underlyingError: error
    )
}
```

## Best Practices

When working with the Alpha Dot Five architecture, follow these best practices:

1. **Use Actors for Shared State**: Any component that manages shared mutable state should be implemented as an actor.

2. **Respect Privacy Classifications**: Always use the appropriate privacy classification for sensitive data.

3. **Implement Caching Carefully**: Cache invalidation is hard; make sure to clear caches when data changes.

4. **Batch Operations When Possible**: Use batch processing for multiple operations of the same type.

5. **Handle Errors Appropriately**: Map domain-specific errors to standardised API errors.

6. **Use Rate Limiting for Sensitive Operations**: Apply stricter rate limits to high-security operations.

7. **Follow the Factory Pattern**: Use factories to create and configure components.

8. **Test Thoroughly**: Write unit tests for all components, especially actors and rate limiters.

9. **Document Your Code**: Provide clear documentation for all public interfaces.

10. **Stay Consistent**: Follow the established patterns and conventions throughout the codebase.
