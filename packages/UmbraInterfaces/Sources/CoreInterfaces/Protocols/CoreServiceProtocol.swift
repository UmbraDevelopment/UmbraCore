import Foundation
import UmbraErrors
import LoggingInterfaces

/**
 # Core Service Protocol

 This protocol defines the main entry point for accessing core services throughout the application.

 ## Actor-Based Implementation

 Implementations of this protocol MUST use Swift actors to ensure proper
 state isolation and thread safety for core service operations:

 ```swift
 actor CoreServiceActor: CoreServiceProtocol {
     // Private state should be isolated within the actor
     private let serviceRegistry: ServiceRegistry
     private let logger: PrivacyAwareLoggingProtocol

     // All function implementations must use 'await' appropriately when
     // accessing actor-isolated state or calling other actor methods
 }
 ```

 ## Protocol Forwarding

 To support proper protocol conformance while maintaining actor isolation,
 implementations should consider using the protocol forwarding pattern:

 ```swift
 // Public non-actor class that conforms to protocol
 public final class CoreService: CoreServiceProtocol {
     private let actor: CoreServiceActor

     // Forward all protocol methods to the actor
     public func getCryptoService() async throws -> CoreCryptoServiceProtocol {
         try await actor.getCryptoService()
     }
 }
 ```

 ## Privacy Considerations

 Core services manage access to critical system components. Implementations must:
 - Use privacy-aware logging for all service lifecycle events
 - Apply proper redaction to sensitive configuration information
 - Implement appropriate error handling without exposing internal system details
 - Ensure proper isolation of security-critical components

 ## Purpose

 - Serves as the central access point for all core system services
 - Manages initialisation and lifecycle of critical system components
 - Provides service location functionality via a dependency container

 ## Architecture Notes

 The CoreServiceProtocol follows the façade pattern, simplifying access to
 the various subsystems while managing their lifecycle. It uses adapter protocols
 to isolate components from implementation details of other system parts.
 */
public protocol CoreServiceProtocol: Sendable {
  /**
   Container for resolving service dependencies

   This container manages the registration and resolution of service instances,
   facilitating dependency injection throughout the application.
   */
  var container: ServiceContainerProtocol { get }

  /**
   Initialises all core services

   Performs necessary setup and initialisation of all managed services,
   ensuring they are ready for use.

   - Parameter options: Configuration options for initialisation
   - Throws: CoreError if initialisation fails for any required service
   */
  func initialise(options: CoreServiceOptions?) async throws

  /**
   Gets the crypto service for cryptographic operations

   Returns an adapter that provides simplified access to the full
   cryptographic implementation.

   - Returns: Crypto service implementation conforming to CoreCryptoServiceProtocol
   - Throws: CoreError if service not available
   */
  func getCryptoService() async throws -> CoreCryptoServiceProtocol

  /**
   Gets the security service for security operations

   Returns an adapter that provides simplified access to the full
   security implementation.

   - Returns: Security service implementation conforming to CoreSecurityProviderProtocol
   - Throws: CoreError if service not available
   */
  func getSecurityService() async throws -> CoreSecurityProviderProtocol

  /**
   Gets a logger configured for a specific domain

   Returns a domain-specific logger with appropriate privacy controls.

   - Parameter domain: The domain to create a logger for
   - Returns: Logger implementation conforming to PrivacyAwareLoggingProtocol
   - Throws: CoreError if service not available
   */
  func getDomainLogger(for domain: LoggingDomain) async throws -> any PrivacyAwareLoggingProtocol

  /**
   Shuts down all services

   Performs necessary cleanup and orderly shutdown of all managed services.

   - Parameter options: Configuration options for shutdown
   */
  func shutdown(options: ShutdownOptions?) async
}

/**
 Options for initialising core services.
 */
public struct CoreServiceOptions: Sendable, Equatable {
  /// Standard options for most scenarios
  public static let standard=CoreServiceOptions()

  /// Whether to enable debug features
  public let debugMode: Bool

  /// Environment configuration
  public let environment: CoreEnvironment

  /// Configuration for logging
  public let logging: LoggingConfiguration

  /// Creates new core service options
  public init(
    debugMode: Bool=false,
    environment: CoreEnvironment = .production,
    logging: LoggingConfiguration = .standard
  ) {
    self.debugMode=debugMode
    self.environment=environment
    self.logging=logging
  }
}

/**
 Core environment settings.
 */
public enum CoreEnvironment: String, Sendable, Equatable {
  /// Development environment
  case development

  /// Testing environment
  case testing

  /// Staging environment
  case staging

  /// Production environment
  case production
}

/**
 Configuration for logging.
 */
public struct LoggingConfiguration: Sendable, Equatable {
  /// Standard configuration for most scenarios
  public static let standard=LoggingConfiguration()

  /// Minimum log level to record
  public let minimumLevel: LogLevel

  /// Whether to enable privacy redaction in logs
  public let privacyRedactionEnabled: Bool

  /// Maximum size of log files
  public let maxLogFileSizeMB: Int

  /// Maximum age of log files in days
  public let maxLogAgeInDays: Int

  /// Creates new logging configuration
  public init(
    minimumLevel: LogLevel = .info,
    privacyRedactionEnabled: Bool=true,
    maxLogFileSizeMB: Int=10,
    maxLogAgeInDays: Int=7
  ) {
    self.minimumLevel=minimumLevel
    self.privacyRedactionEnabled=privacyRedactionEnabled
    self.maxLogFileSizeMB=maxLogFileSizeMB
    self.maxLogAgeInDays=maxLogAgeInDays
  }
}

/**
 Log level for determining which messages to record.
 */
public enum LogLevel: String, Sendable, Equatable, Comparable {
  /// Detailed debugging information
  case trace

  /// Debugging information
  case debug

  /// General information
  case info

  /// Warning conditions
  case warning

  /// Error conditions
  case error

  /// Critical failures
  case critical

  public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
    let order: [LogLevel]=[.trace, .debug, .info, .warning, .error, .critical]
    guard
      let lhsIndex=order.firstIndex(of: lhs),
      let rhsIndex=order.firstIndex(of: rhs)
    else {
      return false
    }
    return lhsIndex < rhsIndex
  }
}

/**
 Logging domains for categorising log messages.
 */
public enum LoggingDomain: String, Sendable, Equatable, CaseIterable {
  /// Core system operations
  case core

  /// Security operations
  case security

  /// Cryptographic operations
  case crypto

  /// Backup operations
  case backup

  /// File system operations
  case fileSystem

  /// Network operations
  case network

  /// API operations
  case api

  /// User interface
  case ui
}

/**
 Options for shutting down services.
 */
public struct ShutdownOptions: Sendable, Equatable {
  /// Standard options for most scenarios
  public static let standard=ShutdownOptions()

  /// Whether to force immediate shutdown
  public let force: Bool

  /// Maximum time to wait for graceful shutdown in seconds
  public let timeoutSeconds: Int

  /// Creates new shutdown options
  public init(
    force: Bool=false,
    timeoutSeconds: Int=10
  ) {
    self.force=force
    self.timeoutSeconds=timeoutSeconds
  }
}
