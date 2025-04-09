import LoggingInterfaces
import LoggingTypes

/// Factory for creating domain-specific loggers
///
/// This factory provides a centralised way to create domain-specific loggers
/// with the appropriate privacy controls and configuration.
public actor LoggerFactory {
  /// The underlying logging service
  private let loggingService: LoggingServiceProtocol

  /// Creates a new logger factory
  ///
  /// - Parameter loggingService: The logging service to use for all loggers
  public init(loggingService: LoggingServiceProtocol) {
    self.loggingService=loggingService
  }

  /// Creates a security domain logger
  ///
  /// - Returns: A security-specific logger
  public func createSecurityLogger() async -> SecurityLogger {
    SecurityLogger(loggingService: loggingService)
  }

  /// Creates a cryptographic domain logger
  ///
  /// - Returns: A crypto-specific logger
  public func createCryptoLogger() async -> CryptoLogger {
    CryptoLogger(loggingService: loggingService)
  }

  /// Creates a base domain logger with the specified domain name
  ///
  /// - Parameter domainName: The name of the domain for this logger
  /// - Returns: A domain-specific logger
  public func createDomainLogger(forDomain domainName: String) async -> BaseDomainLogger {
    BaseDomainLogger(domainName: domainName, loggingService: loggingService)
  }

  /// Creates a new logger with custom configuration
  ///
  /// - Parameters:
  ///   - domainName: The name of the domain for this logger
  ///   - configuration: Custom configuration for the logger
  /// - Returns: A configured domain-specific logger
  public func createCustomLogger(
    forDomain domainName: String,
    configuration _: LoggerConfiguration
  ) async -> BaseDomainLogger {
    // In a more advanced implementation, we would apply the configuration here
    // For now, we just create a standard domain logger
    BaseDomainLogger(domainName: domainName, loggingService: loggingService)
  }
}

/// Configuration options for custom loggers
public struct LoggerConfiguration: Sendable {
  /// The minimum log level to capture
  public let minimumLevel: LogLevel

  /// Whether to include source information in logs
  public let includeSourceInfo: Bool

  /// Whether to include correlation IDs in logs
  public let includeCorrelationIDs: Bool

  /// Creates a new logger configuration
  ///
  /// - Parameters:
  ///   - minimumLevel: The minimum log level to capture
  ///   - includeSourceInfo: Whether to include source information in logs
  ///   - includeCorrelationIds: Whether to include correlation IDs in logs
  public init(
    minimumLevel: LogLevel = .info,
    includeSourceInfo: Bool=true,
    includeCorrelationIDs: Bool=true
  ) {
    self.minimumLevel=minimumLevel
    self.includeSourceInfo=includeSourceInfo
    self.includeCorrelationIDs=includeCorrelationIDs
  }

  /// Default configuration with reasonable defaults
  public static let standard=LoggerConfiguration()

  /// Configuration optimised for production use
  public static let production=LoggerConfiguration(
    minimumLevel: .warning,
    includeSourceInfo: false,
    includeCorrelationIDs: true
  )

  /// Configuration optimised for debugging
  public static let debug=LoggerConfiguration(
    minimumLevel: .debug,
    includeSourceInfo: true,
    includeCorrelationIDs: true
  )
}
