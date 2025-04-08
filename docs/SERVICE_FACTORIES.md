# Service Factories Documentation

## Overview

Service factories in UmbraCore provide a centralised way to create and configure services with appropriate dependencies and settings. They ensure consistent service creation across the application and simplify dependency management.

## Table of Contents

1. [Architecture](#architecture)
2. [Key Factories](#key-factories)
3. [Provider Types](#provider-types)
4. [Usage Examples](#usage-examples)
5. [Best Practices](#best-practices)
6. [Dependency Injection](#dependency-injection)
7. [Configuration Guidelines](#configuration-guidelines)

## Architecture

Service factories follow a simple but effective architecture:

1. **Factory Methods**: Static methods that create and configure services.
2. **Provider Selection**: Support for different provider implementations.
3. **Dependency Injection**: Automatic injection of dependencies like loggers.
4. **Configuration Options**: Customisation through configuration parameters.

## Key Factories

### SecurityServiceFactory

Creates and configures security services.

```swift
public enum SecurityServiceFactory {
    public static func createSecurityService(
        providerType: SecurityProviderType = .platform,
        logger: (any LoggingProtocol)? = nil
    ) throws -> SecurityServiceProtocol
}
```

### BackupServiceFactory

Creates and configures backup services.

```swift
public enum BackupServiceFactory {
    public static func createBackupService(
        storageProvider: BackupStorageProviderType = .local,
        logger: (any LoggingProtocol)? = nil
    ) throws -> BackupServiceProtocol
}
```

### RepositoryServiceFactory

Creates and configures repository services.

```swift
public enum RepositoryServiceFactory {
    public static func createRepositoryService(
        repositoryType: RepositoryProviderType = .standard,
        logger: (any LoggingProtocol)? = nil
    ) throws -> RepositoryServiceProtocol
}
```

### LoggingServiceFactory

Creates and configures logging services.

```swift
public enum LoggingServiceFactory {
    public static func createStandardLogger(
        minimumLevel: LoggingTypes.UmbraLogLevel = .info,
        formatter: LoggingInterfaces.LogFormatterProtocol? = nil
    ) -> LoggingServiceActor
    
    public static func createPrivacyAwareLogger(
        minimumLevel: LoggingTypes.UmbraLogLevel = .info,
        environment: DeploymentEnvironment = .development,
        formatter: LoggingInterfaces.LogFormatterProtocol? = nil
    ) -> PrivacyAwareLoggingActor
    
    // Additional factory methods...
}
```

### DomainHandlerFactory

Creates and manages domain handlers.

```swift
public actor DomainHandlerFactory {
    public static let shared = DomainHandlerFactory()
    
    public func createHandler(for domain: APIDomain, forceNew: Bool = false) throws -> any DomainHandlerProtocol
    public func createAllHandlers(forceNew: Bool = false) -> [APIDomain: any DomainHandlerProtocol]
    public func clearHandlerCache() async
}
```

### RateLimiterFactory

Creates and manages rate limiters.

```swift
public actor RateLimiterFactory {
    public static let shared = RateLimiterFactory()
    
    public func getRateLimiter(
        domain: String,
        operation: String,
        capacity: Int = 10,
        refillRate: Double = 1.0
    ) async -> RateLimiter
    
    public func getHighSecurityRateLimiter(
        domain: String,
        operation: String
    ) async -> RateLimiter
    
    // Additional factory methods...
}
```

## Provider Types

UmbraCore supports different provider implementations for various services.

### Security Providers

```swift
public enum SecurityProviderType {
    /// Native platform security provider (Apple CryptoKit)
    case platform
    
    /// Custom security provider (Ring FFI)
    case custom
    
    /// Default fallback security provider
    case `default`
}
```

#### Provider Implementations

1. **AppleSecurityProvider (platform)**:
   - Native implementation for Apple platforms (macOS 10.15+, iOS 13.0+, etc.)
   - Takes advantage of hardware acceleration where available
   - Uses AES-GCM for authenticated encryption
   - Optimised for Apple platforms

2. **RingSecurityProvider (custom)**:
   - Cross-platform implementation using Rust's Ring cryptography library via FFI
   - Works on any platform with Ring FFI bindings
   - Uses constant-time implementations to prevent timing attacks
   - Provides high-quality cryptographic primitives regardless of platform

3. **DefaultSecurityProvider (default)**:
   - Acts as the fallback implementation when more specialised providers aren't selected
   - Implements basic cryptographic operations
   - Available on all platforms as a baseline implementation

### Backup Storage Providers

```swift
public enum BackupStorageProviderType {
    /// Local file system storage
    case local
    
    /// Cloud storage
    case cloud
    
    /// Hybrid storage (local + cloud)
    case hybrid
}
```

#### Provider Implementations

1. **LocalBackupStorageProvider (local)**:
   - Stores backups on the local file system
   - Suitable for desktop applications and testing

2. **CloudBackupStorageProvider (cloud)**:
   - Stores backups in cloud storage
   - Supports various cloud providers

3. **HybridBackupStorageProvider (hybrid)**:
   - Combines local and cloud storage
   - Provides redundancy and flexibility

### Repository Providers

```swift
public enum RepositoryProviderType {
    /// Standard repository provider
    case standard
    
    /// Distributed repository provider
    case distributed
    
    /// Legacy repository provider for backward compatibility
    case legacy
}
```

#### Provider Implementations

1. **StandardRepositoryProvider (standard)**:
   - Default implementation for repository operations
   - Suitable for most use cases

2. **DistributedRepositoryProvider (distributed)**:
   - Supports distributed repositories
   - Handles synchronisation and conflict resolution

3. **LegacyRepositoryProvider (legacy)**:
   - Provides compatibility with legacy systems
   - Handles format conversion and migration

## Usage Examples

### Creating a Security Service

```swift
// Create a security service with the platform provider
let securityService = try SecurityServiceFactory.createSecurityService(
    providerType: .platform,
    logger: privacyAwareLogger
)

// Use the security service
let encryptedData = try await securityService.encrypt(
    data: plaintext,
    keyIdentifier: "my-key",
    algorithm: "AES-256-GCM"
)
```

### Creating a Backup Service

```swift
// Create a backup service with the local storage provider
let backupService = try BackupServiceFactory.createBackupService(
    storageProvider: .local,
    logger: privacyAwareLogger
)

// Use the backup service
let snapshot = try await backupService.createSnapshot(
    name: "Daily Backup",
    data: backupData,
    metadata: snapshotMetadata
)
```

### Creating a Repository Service

```swift
// Create a repository service with the standard provider
let repositoryService = try RepositoryServiceFactory.createRepositoryService(
    repositoryType: .standard,
    logger: privacyAwareLogger
)

// Use the repository service
let repository = try await repositoryService.createRepository(
    name: "Main Repository",
    location: repositoryURL,
    credentials: repositoryCredentials
)
```

### Creating a Domain Handler

```swift
// Create a domain handler factory
let factory = DomainHandlerFactory.shared

// Create a security domain handler
let securityHandler = try await factory.createHandler(for: .security)

// Use the domain handler
let result = try await securityHandler.handleOperation(operation: encryptDataOperation)
```

### Creating a Privacy-Aware Logger

```swift
// Create a privacy-aware logger for development
let logger = LoggingServiceFactory.createPrivacyAwareLogger(
    minimumLevel: .debug,
    environment: .development
)

// Use the logger
await logger.info(
    "Application started",
    context: CoreLogContext(
        source: "AppDelegate",
        metadata: LogMetadataDTOCollection()
            .withPublic(key: "version", value: appVersion)
    )
)
```

## Best Practices

When working with service factories, follow these best practices:

1. **Use Factory Methods**: Always create services through factory methods rather than direct initialisation.

2. **Provide Appropriate Loggers**: Pass privacy-aware loggers to services for proper logging.

3. **Select Appropriate Providers**: Choose the provider type that best matches your requirements.

4. **Handle Factory Errors**: Factory methods can throw errors, so handle them appropriately.

5. **Use Shared Instances**: Use shared factory instances when available to benefit from caching.

6. **Configure for Environment**: Use environment-appropriate configuration for services.

7. **Inject Dependencies**: Use the factory pattern for proper dependency injection.

8. **Document Provider Selection**: Document why specific providers are selected for different scenarios.

9. **Test with Different Providers**: Test your code with different provider implementations.

10. **Consider Performance Implications**: Different providers may have different performance characteristics.

## Dependency Injection

Service factories in UmbraCore implement the dependency injection pattern, which provides several benefits:

1. **Loose Coupling**: Services depend on abstractions (protocols) rather than concrete implementations.

2. **Testability**: Dependencies can be easily mocked or stubbed for testing.

3. **Flexibility**: Different implementations can be injected based on requirements.

4. **Centralised Configuration**: Configuration is centralised in factory methods.

### Example

```swift
// Factory method with dependency injection
public static func createSecurityService(
    providerType: SecurityProviderType = .platform,
    logger: (any LoggingProtocol)? = nil
) throws -> SecurityServiceProtocol {
    // Create a privacy-aware logger if one wasn't provided
    let securityLogger = logger ?? LoggingServiceFactory.createPrivacyAwareLogger(
        minimumLevel: .info,
        environment: .development
    )
    
    // Create the appropriate security provider based on type
    let securityProvider: SecurityProviderProtocol
    
    switch providerType {
    case .platform:
        securityProvider = try AppleSecurityProvider(logger: securityLogger)
    case .custom:
        securityProvider = try RingSecurityProvider(logger: securityLogger)
    case .default:
        securityProvider = try DefaultSecurityProvider(logger: securityLogger)
    }
    
    // Create the rate limiter for high-security operations
    let rateLimiter = await RateLimiterFactory.shared.getHighSecurityRateLimiter(
        domain: "security",
        operation: "highSecurity"
    )
    
    // Create and return the security service with injected dependencies
    return DefaultCryptoServiceWithProviderImpl(
        provider: securityProvider,
        logger: securityLogger,
        rateLimiter: rateLimiter
    )
}
```

## Configuration Guidelines

### Security Service Configuration

| Environment | Provider Type | Notes |
|-------------|--------------|-------|
| Development | platform     | Use native platform for development |
| Testing     | all          | Test with all provider types |
| Staging     | custom       | Test cross-platform compatibility |
| Production  | platform     | Use optimised native implementation |

### Backup Service Configuration

| Environment | Storage Provider | Notes |
|-------------|-----------------|-------|
| Development | local           | Use local storage for development |
| Testing     | all             | Test with all storage providers |
| Staging     | hybrid          | Test hybrid storage configuration |
| Production  | cloud           | Use cloud storage for production |

### Repository Service Configuration

| Environment | Repository Type | Notes |
|-------------|----------------|-------|
| Development | standard       | Use standard provider for development |
| Testing     | all            | Test with all repository types |
| Staging     | distributed    | Test distributed repository configuration |
| Production  | standard       | Use standard provider for production |

### Logging Configuration

| Environment | Logger Type | Minimum Level | Notes |
|-------------|-------------|--------------|-------|
| Development | privacy-aware | debug      | Show detailed logs in development |
| Testing     | privacy-aware | debug      | Show detailed logs in testing |
| Staging     | privacy-aware | info       | Show moderate logs in staging |
| Production  | privacy-aware | warning    | Show only important logs in production |
