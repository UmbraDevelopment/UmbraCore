import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import RepositoryInterfaces
import SecurityInterfaces

/**
 # Security Service Factory

 Creates and configures security services for the Alpha Dot Five architecture.
 This factory provides properly configured security services with appropriate
 dependencies and logging.

 As an actor, this factory provides thread safety for service creation
 and maintains a cache of created services for improved performance.
 */
public actor SecurityServiceFactory {
  /// Shared singleton instance
  public static let shared=SecurityServiceFactory()

  /// Cache of created services by configuration key
  private var serviceCache: [String: SecurityServiceProtocol]=[:]

  /// Initialiser
  public init() {}

  /**
   Creates a security service with the appropriate configuration.

   - Parameters:
     - providerType: The type of security provider to use
     - logger: Optional logger for privacy-aware operation recording
     - useCache: Whether to cache and reuse the created service
   - Returns: A configured security service
   - Throws: Error if the service cannot be created
   */
  public func createSecurityService(
    providerType: SecurityProviderType = .platform,
    logger: (any LoggingProtocol)?=nil,
    useCache: Bool=true
  ) async throws -> SecurityServiceProtocol {
    let cacheKey="security-\(providerType.rawValue)"

    if useCache, let cachedService=serviceCache[cacheKey] {
      return cachedService
    }

    // Create a privacy-aware logger if one wasn't provided
    let securityLogger=logger ?? await LoggingServiceFactory.shared.createPrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "securityService",
      environment: .development
    )

    // Create the appropriate security provider based on type
    let securityProvider: SecurityProviderProtocol=switch providerType {
      case .platform:
        // Use the native platform security provider (Apple CryptoKit)
        try AppleSecurityProvider(logger: securityLogger)

      case .custom:
        // Use the Ring FFI security provider for cross-platform support
        try RingSecurityProvider(logger: securityLogger)

      case .default:
        // Use the default implementation as a fallback
        try DefaultSecurityProvider(logger: securityLogger)
    }

    // Create the rate limiter for high-security operations
    let rateLimiter=await RateLimiterFactory.shared.getHighSecurityRateLimiter(
      domain: "security",
      operation: "highSecurity"
    )

    // Create the security service
    let service=DefaultCryptoServiceWithProviderImpl(
      provider: securityProvider,
      logger: securityLogger,
      rateLimiter: rateLimiter
    )

    // Cache the service if enabled
    if useCache {
      serviceCache[cacheKey]=service
    }

    return service
  }

  /**
   Creates a high-security service with stricter rate limiting and enhanced logging.

   - Parameters:
     - logger: Optional logger for privacy-aware operation recording
     - useCache: Whether to cache and reuse the created service
   - Returns: A configured high-security service
   - Throws: Error if the service cannot be created
   */
  public func createHighSecurityService(
    logger: (any LoggingProtocol)?=nil,
    useCache: Bool=true
  ) async throws -> SecurityServiceProtocol {
    let cacheKey="high-security"

    if useCache, let cachedService=serviceCache[cacheKey] {
      return cachedService
    }

    // Create a privacy-aware logger with enhanced security settings
    let securityLogger=logger ?? await LoggingServiceFactory.shared.createPrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "highSecurityService",
      environment: .production
    )

    // Use the platform provider for maximum security
    let securityProvider=try AppleSecurityProvider(logger: securityLogger)

    // Create a more restrictive rate limiter for high-security operations
    let rateLimiter=await RateLimiterFactory.shared.getHighSecurityRateLimiter(
      domain: "security",
      operation: "criticalSecurity",
      maxTokens: 3,
      tokensPerSecond: 0.1 // One operation per 10 seconds
    )

    // Create the security service
    let service=DefaultCryptoServiceWithProviderImpl(
      provider: securityProvider,
      logger: securityLogger,
      rateLimiter: rateLimiter
    )

    // Cache the service if enabled
    if useCache {
      serviceCache[cacheKey]=service
    }

    return service
  }

  /// Clears the service cache
  ///
  /// This can be useful when testing or when services need to be recreated
  /// with fresh configurations.
  public func clearCache() {
    serviceCache.removeAll()
  }

  /// Removes a specific service from the cache
  ///
  /// - Parameter cacheKey: The cache key for the service to remove
  /// - Returns: True if a service was removed, false if no service was found
  public func removeFromCache(cacheKey: String) -> Bool {
    if serviceCache[cacheKey] != nil {
      serviceCache[cacheKey]=nil
      return true
    }
    return false
  }
}

/**
 # Backup Service Factory

 Creates and configures backup services for the Alpha Dot Five architecture.
 This factory provides properly configured backup services with appropriate
 dependencies and logging.
 */
public enum BackupServiceFactory {
  /**
   Creates a backup service with the appropriate configuration.

   - Parameters:
     - storageProvider: The type of storage provider to use
     - logger: Optional logger for privacy-aware operation recording
   - Returns: A configured backup service
   - Throws: Error if the service cannot be created
   */
  public static func createBackupService(
    storageProvider: BackupStorageProviderType = .local,
    logger: (any LoggingProtocol)?=nil
  ) throws -> BackupServiceProtocol {
    // Create a privacy-aware logger if one wasn't provided
    let backupLogger=logger ?? LoggingServiceFactory.createPrivacyAwareLogger(
      minimumLevel: .info,
      environment: .development
    )

    // Create the appropriate backup provider based on type
    let backupProvider: BackupStorageProviderProtocol=switch storageProvider {
      case .local:
        // Use the local storage provider
        try LocalBackupProvider(logger: backupLogger)

      case .remote:
        // Use the remote storage provider
        try RemoteBackupProvider(logger: backupLogger)

      case .hybrid:
        // Use the hybrid storage provider
        try HybridBackupProvider(logger: backupLogger)
    }

    // Create the security service for encryption/decryption
    let securityService=try SecurityServiceFactory.shared.createSecurityService(
      logger: backupLogger
    )

    // Create and return the backup service
    return DefaultBackupServiceImpl(
      provider: backupProvider,
      securityService: securityService,
      logger: backupLogger
    )
  }
}

/**
 # Repository Service Factory

 Creates and configures repository services for the Alpha Dot Five architecture.
 This factory provides properly configured repository services with appropriate
 dependencies and logging.
 */
public enum RepositoryServiceFactory {
  /**
   Creates a repository service with the appropriate configuration.

   - Parameters:
     - repositoryType: The type of repository to use
     - logger: Optional logger for privacy-aware operation recording
   - Returns: A configured repository service
   - Throws: Error if the service cannot be created
   */
  public static func createRepositoryService(
    repositoryType: RepositoryType = .standard,
    logger: (any LoggingProtocol)?=nil
  ) throws -> RepositoryServiceProtocol {
    // Create a privacy-aware logger if one wasn't provided
    let repositoryLogger=logger ?? LoggingServiceFactory.createPrivacyAwareLogger(
      minimumLevel: .info,
      environment: .development
    )

    // Create the appropriate repository provider based on type
    let repositoryProvider: RepositoryProviderProtocol=switch repositoryType {
      case .standard:
        // Use the standard repository provider
        try StandardRepositoryProvider(logger: repositoryLogger)

      case .distributed:
        // Use the distributed repository provider
        try DistributedRepositoryProvider(logger: repositoryLogger)

      case .legacy:
        // Use the legacy repository provider
        try LegacyRepositoryProvider(logger: repositoryLogger)
    }

    // Create and return the repository service
    return DefaultRepositoryServiceImpl(
      provider: repositoryProvider,
      logger: repositoryLogger
    )
  }
}

/**
 Type of security provider to use.
 */
public enum SecurityProviderType {
  /// Native platform security provider (Apple CryptoKit)
  case platform

  /// Custom security provider (Ring FFI)
  case custom

  /// Default fallback security provider
  case `default`
}

/**
 Type of backup storage provider to use.
 */
public enum BackupStorageProviderType {
  /// Local file system storage
  case local

  /// Cloud storage
  case cloud

  /// Hybrid storage (local + cloud)
  case hybrid
}

/**
 Type of repository provider to use.
 */
public enum RepositoryProviderType {
  /// Standard repository provider
  case standard

  /// Distributed repository provider
  case distributed

  /// Legacy repository provider for backward compatibility
  case legacy
}

// MARK: - Placeholder Implementations

/**
 These are placeholder implementations that would be replaced by actual implementations
 in a complete codebase. They are included here to make the factory methods compile.
 */

// Security Providers
public class AppleSecurityProvider: SecurityProviderProtocol {
  public init(logger _: (any LoggingProtocol)?) throws {}
}

public class RingSecurityProvider: SecurityProviderProtocol {
  public init(logger _: (any LoggingProtocol)?) throws {}
}

public class DefaultSecurityProvider: SecurityProviderProtocol {
  public init(logger _: (any LoggingProtocol)?) throws {}
}

public class DefaultCryptoServiceWithProviderImpl: SecurityServiceProtocol {
  public init(
    provider _: SecurityProviderProtocol,
    logger _: (any LoggingProtocol)?,
    rateLimiter _: RateLimiter
  ) {}
}

// Backup Providers
public class LocalBackupStorageProvider: BackupStorageProviderProtocol {
  public init(logger _: (any LoggingProtocol)?) throws {}
}

public class CloudBackupStorageProvider: BackupStorageProviderProtocol {
  public init(logger _: (any LoggingProtocol)?) throws {}
}

public class HybridBackupStorageProvider: BackupStorageProviderProtocol {
  public init(logger _: (any LoggingProtocol)?) throws {}
}

public class DefaultBackupServiceImpl: BackupServiceProtocol {
  public init(
    storageProvider _: BackupStorageProviderProtocol,
    securityService _: SecurityServiceProtocol,
    logger _: (any LoggingProtocol)?
  ) {}
}

// Repository Providers
public class StandardRepositoryProvider: RepositoryProviderProtocol {
  public init(logger _: (any LoggingProtocol)?) throws {}
}

public class DistributedRepositoryProvider: RepositoryProviderProtocol {
  public init(logger _: (any LoggingProtocol)?) throws {}
}

public class LegacyRepositoryProvider: RepositoryProviderProtocol {
  public init(logger _: (any LoggingProtocol)?) throws {}
}

public class DefaultRepositoryServiceImpl: RepositoryServiceProtocol {
  public init(
    provider _: RepositoryProviderProtocol,
    logger _: (any LoggingProtocol)?
  ) {}
}

// Protocols
public protocol SecurityProviderProtocol {}
public protocol BackupStorageProviderProtocol {}
public protocol RepositoryProviderProtocol {}
