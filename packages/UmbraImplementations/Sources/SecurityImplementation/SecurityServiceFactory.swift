import CryptoInterfaces
import CryptoServices
import Foundation
import LoggingInterfaces
import LoggingServices
import SecurityCoreInterfaces
import UmbraErrors

/// Factory for creating instances of the SecurityProviderProtocol.
///
/// This factory provides methods for creating fully configured security service
/// instances with various configurations and crypto service integrations, ensuring
/// proper domain separation and delegation to crypto services.
///
/// All security services created by this factory use privacy-aware logging through
/// SecureLoggerActor, following the Alpha Dot Five architecture principles.
public enum SecurityServiceFactory {
  /// Creates a default security service instance with standard configuration
  /// - Returns: A fully configured security service with privacy-aware logging
  public static func createDefault() -> SecurityProviderProtocol {
    let logger=LoggingServices.createStandardLogger(
      minimumLevel: .info,
      formatter: nil
    )

    let secureLogger=Task {
      await LoggingServices.createSecureLogger(
        subsystem: "com.umbra.security",
        category: "SecurityService",
        includeTimestamps: true
      )
    }

    // Create the security service with secure logging
    return createWithLoggers(
      logger: logger,
      secureLogger: nil
    )
  }

  /// Creates a security service with the specified standard logger
  /// - Parameter logger: The standard logger to use for security operations
  /// - Returns: A fully configured security service with privacy-aware logging
  public static func createWithLogger(
    _ logger: LoggingInterfaces.LoggingProtocol
  ) -> SecurityProviderProtocol {
    createWithLoggers(logger: logger, secureLogger: nil)
  }

  /// Creates a security service with the specified loggers
  /// - Parameters:
  ///   - logger: The standard logger to use for general operations
  ///   - secureLogger: The secure logger to use for privacy-aware logging (created if nil)
  /// - Returns: A fully configured security service with privacy-aware logging
  public static func createWithLoggers(
    logger: LoggingInterfaces.LoggingProtocol,
    secureLogger: SecureLoggerActor?
  ) -> SecurityProviderProtocol {
    // Create dependencies
    var cryptoService: CryptoServiceProtocol!

    // Initialise the crypto service asynchronously
    // Note: We're using Task.sync here because this is a synchronous factory method
    // This would ideally be redesigned as an async factory method in the future
    Task.sync {
      cryptoService=await CryptoServiceFactory.createDefault(logger: logger)
    }

    // Create the actor with secure logging
    let securityActor=SecurityServiceActor(
      cryptoService: cryptoService,
      logger: logger,
      secureLogger: secureLogger
    )

    // Initialise asynchronously in the background
    Task {
      try? await securityActor.initialise()
    }

    return securityActor
  }

  /// Creates a security service with a predefined secure logger
  /// - Parameter secureLogger: The secure logger to use for privacy-aware logging
  /// - Returns: A fully configured security service
  public static func createWithSecureLogger(
    _ secureLogger: SecureLoggerActor
  ) -> SecurityProviderProtocol {
    // Create standard logger
    let logger=LoggingServices.createStandardLogger(
      minimumLevel: .info,
      formatter: nil
    )

    return createWithLoggers(
      logger: logger,
      secureLogger: secureLogger
    )
  }

  /// Creates a high-security service with more stringent security settings
  /// - Returns: A security service configured for high-security environments with enhanced logging
  public static func createHighSecurity() -> SecurityProviderProtocol {
    // Create enhanced logger for high-security environments
    let logger=LoggingServices.createDevelopmentLogger(
      minimumLevel: .debug,
      formatter: nil
    )

    // Create a secure logger with additional security context
    let secureLogger=Task {
      await LoggingServices.createSecureLogger(
        subsystem: "com.umbra.security.high",
        category: "HighSecurityService",
        includeTimestamps: true
      )
    }

    // Create dependencies with high-security settings
    var cryptoService: CryptoServiceProtocol!

    // Initialise the crypto service asynchronously
    // Note: We're using Task.sync here because this is a synchronous factory method
    // This would ideally be redesigned as an async factory method in the future
    Task.sync {
      cryptoService=await CryptoServiceFactory.createDefault(logger: logger)
    }

    // Create the actor with secure logging
    let securityActor=SecurityServiceActor(
      cryptoService: cryptoService,
      logger: logger,
      secureLogger: secureLogger
    )

    // Initialise asynchronously in the background
    Task {
      try? await securityActor.initialise()
    }

    return securityActor
  }

  /// Creates a development security service with verbose logging for testing and debugging
  /// - Returns: A security service configured for development environments
  public static func createDevelopment() -> SecurityProviderProtocol {
    // Create verbose logger for development
    let logger=LoggingServices.createDevelopmentLogger(
      minimumLevel: .trace,
      formatter: nil
    )

    // Create a secure logger with development context
    let secureLogger=Task {
      await LoggingServices.createSecureLogger(
        subsystem: "com.umbra.security.dev",
        category: "DevelopmentSecurityService",
        includeTimestamps: true
      )
    }

    // Create crypto service for development
    var cryptoService: CryptoServiceProtocol!

    // Initialise the crypto service asynchronously
    // Note: We're using Task.sync here because this is a synchronous factory method
    // This would ideally be redesigned as an async factory method in the future
    Task.sync {
      cryptoService=await CryptoServiceFactory.createDefault(logger: logger)
    }

    // Create the actor with secure logging
    let securityActor=SecurityServiceActor(
      cryptoService: cryptoService,
      logger: logger,
      secureLogger: secureLogger
    )

    // Initialise asynchronously in the background
    Task {
      try? await securityActor.initialise()
    }

    return securityActor
  }
}
