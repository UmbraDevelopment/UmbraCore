import CryptoInterfaces
import LoggingInterfaces
import LoggingServices
import LoggingTypes

/**
 # CryptoServices Module

 Provides concrete implementations of cryptographic services following the
 Alpha Dot Five architecture pattern with full Swift 6 compliance.

 This module implements the interfaces defined in CryptoInterfaces using
 a proper actor-based architecture for concurrency safety.

 ## Main Components

 - `DefaultCryptoServiceImpl`: Actor-based implementation of cryptographic operations
 - `LoggingCryptoService`: Logging wrapper for cryptographic operations
 - `CryptoServiceFactory`: Factory for creating crypto service instances

 ## Usage Example

 ```swift
 // Create a default crypto service
 let cryptoService = await CryptoServices.createDefault()

 // Generate a secure random key
 let key = try await cryptoService.generateSecureRandomKey(length: 32)
 ```
 */

/**
 # CryptoServices

 Main entry point for cryptographic services in the Umbra system.
 Provides convenient access to cryptographic service factories aligned
 with the Alpha Dot Five architecture.
 */
public enum CryptoServices {
  /// Current version of the CryptoServices module
  public static let version="2.0.0"

  /**
   Creates a default crypto service implementation.

   This factory method provides a convenient way to create a properly
   configured crypto service instance using the default implementation.

   - Returns: A CryptoServiceProtocol implementation
   */
  public static func createDefault() async -> CryptoServiceProtocol {
    await CryptoServiceFactory.createDefault()
  }

  /**
   Creates a logging-enabled crypto service.

   This factory method creates a crypto service with comprehensive
   logging of all operations for debugging and audit purposes.

   - Parameter logger: The logger to use (defaults to a standard logger if nil)
   - Returns: A logging-enabled CryptoServiceProtocol implementation
   */
  public static func createWithLogging(logger: LoggingProtocol?=nil) async
  -> CryptoServiceProtocol {
    let defaultService=await CryptoServiceFactory.createDefault()

    // Use provided logger or create a default one
    let actualLogger: LoggingProtocol=logger ?? DefaultLogger()

    // The factory method is async
    return await CryptoServiceFactory.createLogging(
      wrapped: defaultService,
      logger: actualLogger
    )
  }

  /**
   Creates a mock crypto service for testing.

   This factory method provides a consistent way to create a mock
   implementation suitable for testing without actual cryptographic operations.

   - Returns: A mock CryptoServiceProtocol implementation
   */
  public static func createMock() async -> CryptoServiceProtocol {
    await CryptoServiceFactory.createMock()
  }
}

/**
 Basic logger implementation for when no logger is provided.
 */
private struct DefaultLogger: LoggingProtocol {
  // Add loggingActor property required by LoggingProtocol
  var loggingActor: LoggingInterfaces.LoggingActor = .init(destinations: [])

  // Core method required by CoreLoggingProtocol
  func logMessage(_: LoggingTypes.LogLevel, _: String, context _: LoggingTypes.LogContext) async {
    // Empty implementation for this stub
  }

  // Implement all required methods with proper parameter types
  func debug(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func info(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func notice(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func warning(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func error(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func critical(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func trace(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
}
