import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces

/**
  # CryptoServices Module

  This module provides cryptographic services for the UmbraCore platform, following
  the Alpha Dot Five architecture principles with actor-based concurrency.

  The module supports these key operations:
  - Encryption and decryption of data
  - Secure hashing of data
  - Hash verification

  ## Usage Example

 ```swift
 // Create a default implementation
 let cryptoService = await CryptoServiceFactory.createDefault(logger: myLogger)

 // Encrypt some data
 let data: [UInt8] = [1, 2, 3, 4]
 let key: [UInt8] = Array(repeating: 0, count: 32)
 let result = await cryptoService.encrypt(data: data, using: key)

 // Process the result
 switch result {
 case .success(let encryptedData):
     print("Encrypted successfully: \(encryptedData.count) bytes")
 case .failure(let error):
     print("Encryption failed: \(error)")
 }
 ```

  ## Key Components

  - **CryptoServices**: Primary static factory for obtaining implementations
  - **CryptoServiceFactory**: Internal factory for different implementations
  */
public enum CryptoServices {
  /**
   Creates a default implementation of CryptoServiceProtocol.

   - Parameter secureStorage: The secure storage implementation to use
   - Returns: A CryptoServiceProtocol implementation
   */
  public static func createDefault(
    secureStorage: SecureStorageProtocol
  ) async -> CryptoServiceProtocol {
    await CryptoServiceFactory.createDefault(secureStorage: secureStorage)
  }

  /**
   Creates a crypto service with logging capabilities.

   - Parameters:
     - secureStorage: The secure storage implementation to use
     - logger: Optional logger to use, default logger will be used if nil
   - Returns: A CryptoServiceProtocol implementation with logging
   */
  public static func createWithLogging(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol
  ) async -> CryptoServiceProtocol {
    let defaultService=await CryptoServiceFactory.createDefault(secureStorage: secureStorage)
    return await CryptoServiceFactory.createLoggingDecorator(
      wrapped: defaultService,
      logger: logger
    )
  }

  /**
   Creates a mock implementation of CryptoServiceProtocol for testing.

   - Parameters:
     - secureStorage: The secure storage implementation to use
     - configuration: Configuration for the mock behavior
   - Returns: A mock CryptoServiceProtocol implementation
   */
  public static func createMock(
    secureStorage: SecureStorageProtocol,
    configuration: MockCryptoServiceImpl.Configuration = .init()
  ) async -> CryptoServiceProtocol {
    await CryptoServiceFactory.createMock(
      secureStorage: secureStorage,
      configuration: configuration
    )
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
