import LoggingInterfaces
import LoggingTypes

/// Factory for creating privacy-aware logging instances.
/// This provides a clean interface for creating loggers with different configurations.
public enum PrivacyAwareLoggingFactory {
  /// Create a logger with privacy features
  /// - Parameters:
  ///   - minimumLevel: The minimum log level to process (defaults to .info)
  ///   - identifier: The identifier for the logger, typically the subsystem name
  ///   - backend: The backend to use for writing logs (defaults to OSLogPrivacyBackend)
  ///   - privacyLevel: The default privacy level for unannotated values
  /// - Returns: A logger that implements the PrivacyAwareLoggingProtocol
  public static func createLogger(
    minimumLevel: LogLevel = .info,
    identifier: String,
    backend: LoggingBackend?=nil,
    privacyLevel _: LogPrivacyLevel = .auto
  ) -> any PrivacyAwareLoggingProtocol {
    // Use the provided backend or create a default OSLogPrivacyBackend
    let loggingBackend=backend ?? OSLogPrivacyBackend(subsystem: identifier)

    // Create and return the logger
    return PrivacyAwareLogger(
      minimumLevel: minimumLevel,
      identifier: identifier,
      backend: loggingBackend
    )
  }

  /// Create a console-based logger for development and testing
  /// - Parameters:
  ///   - minimumLevel: The minimum log level to process (defaults to .debug)
  ///   - identifier: The identifier for the logger
  /// - Returns: A logger that implements the PrivacyAwareLoggingProtocol
  public static func createConsoleLogger(
    minimumLevel: LogLevel = .debug,
    identifier: String
  ) -> any PrivacyAwareLoggingProtocol {
    // Create a console backend
    let consoleBackend=ConsoleLoggingBackend()

    // Create and return the logger
    return PrivacyAwareLogger(
      minimumLevel: minimumLevel,
      identifier: identifier,
      backend: consoleBackend
    )
  }

  /// Create a logger that writes to multiple backends
  /// - Parameters:
  ///   - minimumLevel: The minimum log level to process
  ///   - identifier: The identifier for the logger
  ///   - backends: The backends to write logs to
  /// - Returns: A logger that implements the PrivacyAwareLoggingProtocol
  public static func createMultiLogger(
    minimumLevel: LogLevel,
    identifier: String,
    backends: [LoggingBackend]
  ) -> any PrivacyAwareLoggingProtocol {
    // Create a multi-backend
    let multiBackend=MultiLoggingBackend(backends: backends)

    // Create and return the logger
    return PrivacyAwareLogger(
      minimumLevel: minimumLevel,
      identifier: identifier,
      backend: multiBackend
    )
  }

  // MARK: - Domain-Specific Loggers

  /// Creates a domain-specific logger for key management operations.
  ///
  /// This provides a logger specialised for securely logging key management
  /// operations with appropriate privacy controls.
  ///
  /// - Parameter logger: The underlying logger to use.
  /// - Returns: A KeyManagementLogger instance.
  public static func createKeyManagementLogger(
    logger: LoggingProtocol
  ) -> KeyManagementLogger {
    KeyManagementLogger(logger: logger)
  }

  /// Creates a domain-specific logger for keychain operations.
  ///
  /// This provides a logger specialised for securely logging keychain
  /// operations with appropriate privacy controls for account information.
  ///
  /// - Parameter logger: The underlying logger to use.
  /// - Returns: A KeychainLogger instance.
  public static func createKeychainLogger(
    logger: LoggingProtocol
  ) -> KeychainLogger {
    KeychainLogger(logger: logger)
  }

  /// Creates a domain-specific logger for cryptographic operations.
  ///
  /// This provides a logger specialised for securely logging cryptographic
  /// operations with appropriate privacy controls.
  ///
  /// - Parameter logger: The underlying logger to use.
  /// - Returns: A CryptoLogger instance.
  public static func createCryptoLogger(
    logger: LoggingProtocol
  ) -> CryptoLogger {
    CryptoLogger(logger: logger)
  }

  /// Creates an error logger with enhanced privacy controls.
  ///
  /// - Parameter logger: The base logger to use
  /// - Returns: An error logger with privacy controls
  public static func createErrorLogger(
    logger: LoggingProtocol
  ) -> LegacyErrorLoggingProtocol {
    EnhancedErrorLogger(logger: logger)
  }

  /// Creates a domain-specific logger for file system operations.
  ///
  /// This provides a logger specialised for securely logging file operations
  /// with appropriate privacy controls for paths and other sensitive information.
  ///
  /// - Parameter logger: The underlying logger to use.
  /// - Returns: A FileSystemLogger instance.
  public static func createFileSystemLogger(
    logger: LoggingProtocol
  ) -> FileSystemLogger {
    FileSystemLogger(logger: logger)
  }

  /// Creates a domain-specific logger for snapshot operations.
  ///
  /// This provides a logger specialised for securely logging snapshot
  /// operations with appropriate privacy controls.
  ///
  /// - Parameter logger: The underlying logger to use.
  /// - Returns: A SnapshotLogger instance.
  public static func createSnapshotLogger(
    logger: LoggingProtocol
  ) -> SnapshotLogger {
    SnapshotLogger(logger: logger)
  }
}
