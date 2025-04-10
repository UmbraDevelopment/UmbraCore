import Foundation
import LoggingInterfaces
import LoggingTypes

/// Examples demonstrating how to use the logging system
///
/// This file contains usage examples for the various logging
/// components of the Alpha Dot Five logging architecture.
public enum LoggingExamples {
  // MARK: - Security Logging Examples

  /// Demonstrates security logger usage for key operations
  public static func demonstrateSecurityLogging(factory: LoggerFactory) async {
    // Get a domain-specific security logger
    let securityLogger=await factory.createSecurityLogger()

    // Basic logging with different levels
    await securityLogger.debug("Debug security message")
    await securityLogger.info("Informational security message")
    await securityLogger.warning("Warning security message")
    await securityLogger.error("Error security message")
    await securityLogger.critical("Critical security message")

    // Create contextual metadata
    _=LogMetadataDTOCollection()
      .withPublic(key: "keyType", value: "AES256")
      .withPublic(key: "purpose", value: "FileEncryption")
      .withPrivate(key: "identifier", value: "key-12345")

    // Use the log operation method
    await securityLogger.logOperation(
      "KeyRegistration",
      component: "KeyRegistry",
      message: "Registered new encryption key"
    )

    // Create a security log context directly
    let keyContext=SecurityLogContext(
      operation: "KeyOperation",
      component: "KeyRegistry"
    )

    // Log with context
    await securityLogger.logWithContext(
      .info,
      "Performed key rotation for encryption key",
      context: keyContext
    )

    // Error logging with privacy controls
    struct SecurityTestError: Error, LocalizedError {
      var errorDescription: String? { "Failed to access key material" }
    }

    // Use the standard error logging method
    await securityLogger.logError(
      SecurityTestError(),
      context: keyContext,
      privacyLevel: PrivacyClassification.private
    )

    // Result logging with context and level
    await securityLogger.logWithContext(
      .info,
      "User authenticated successfully",
      context: SecurityLogContext(
        operation: "Authentication",
        component: "AccessControl"
      )
    )
  }

  // MARK: - Cryptographic Logging Examples

  /// Demonstrates crypto logger usage for cryptographic operations
  public static func demonstrateCryptoLogging(factory: LoggerFactory) async {
    // Get a domain-specific cryptographic logger
    let cryptoLogger=await factory.createCryptoLogger()

    // Basic logging with different levels
    await cryptoLogger.debug("Debug crypto message")
    await cryptoLogger.info("Informational crypto message")
    await cryptoLogger.warning("Warning crypto message")
    await cryptoLogger.error("Error crypto message")
    await cryptoLogger.critical("Critical crypto message")

    // Logging specific crypto operations
    await cryptoLogger.logOperation(
      "Encryption",
      algorithm: "AES-GCM",
      message: "Encrypted data with AES-GCM"
    )

    // Create crypto metadata
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "algorithm", value: "ECDH")
      .withPublic(key: "keySize", value: "256")
      .withPrivate(key: "purpose", value: "KeyExchange")

    // Log with additional metadata
    await cryptoLogger.logOperation(
      "KeyExchange",
      algorithm: "ECDH",
      message: "Performed key exchange",
      metadata: metadata
    )

    // Error logging for crypto operations
    struct CryptoError: Error, LocalizedError {
      var errorDescription: String? { "Failed to perform cryptographic operation" }
    }

    await cryptoLogger.logError(
      CryptoError(),
      operation: "Decryption",
      algorithm: "AES-GCM"
    )
  }

  // MARK: - Error Logging Examples

  /// Demonstrates error logging with privacy controls
  public static func demonstrateErrorLogging(factory: LoggerFactory) async {
    let logger=await factory.createDomainLogger(forDomain: "ErrorDemo")

    // Define a custom error with privacy classification
    struct SensitiveDataError: Error, LoggableErrorProtocol {
      let message: String
      let source: String="LoggingExamples.swift:SensitiveDataError"
      let username: String
      let dataID: String

      // Store metadata directly as LogMetadataDTOCollection
      private let metadataCollection: LogMetadataDTOCollection

      init(message: String, username: String, dataID: String) {
        self.message=message
        self.username=username
        self.dataID=dataID

        // Build privacy-aware metadata
        metadataCollection=LogMetadataDTOCollection()
          .withPublic(key: "operation", value: "DataFetch")
          .withPrivate(key: "username", value: username)
          .withSensitive(key: "dataID", value: dataID)
      }

      // LoggableErrorProtocol implementation
      public func getLogMessage() -> String { message }
      public func getSource() -> String { source }

      // New method that replaces getPrivacyMetadata
      public func createMetadataCollection() -> LogMetadataDTOCollection {
        metadataCollection
      }

      // Deprecated method for backwards compatibility
      @available(*, deprecated, message: "Use createMetadataCollection() instead")
      public func getPrivacyMetadata() -> PrivacyMetadata {
        metadataCollection.toPrivacyMetadata()
      }
    }

    // Create and log a loggable error
    let sensitiveError=SensitiveDataError(
      message: "Failed to access user data",
      username: "johnsmith",
      dataID: "12345-ABCDE-67890"
    )

    // Create a basic log context
    let errorContext=BasicLogContext(
      domain: "ErrorDemo",
      correlationID: "OP-123456",
      source: "DataAccessModule"
    )

    await logger.logError(
      sensitiveError,
      context: errorContext,
      privacyLevel: PrivacyClassification.private
    )

    // Convert standard error to loggable error
    struct StandardError: Error, LocalizedError {
      var errorDescription: String? { "Standard error occurred" }
    }

    let standardError=StandardError()

    // Use a basic context for non-loggable errors
    let context=BasicLogContext(domain: "ErrorHandling")

    await logger.logError(
      standardError,
      context: context,
      privacyLevel: PrivacyClassification.public
    )
  }
}

/// A basic implementation of LogContextDTO for simple cases
public struct BasicLogContext: LogContextDTO {
  public let domainName: String
  public let correlationID: String?
  public let source: String?
  public var metadata: LogMetadataDTOCollection

  public init(
    domain: String,
    correlationID: String?=nil,
    source: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    domainName=domain
    self.correlationID=correlationID
    self.source=source
    self.metadata=metadata
  }

  public func toMetadata() -> LogMetadataDTOCollection {
    metadata
  }

  public func toPrivacyMetadata() -> PrivacyMetadata {
    metadata.toPrivacyMetadata()
  }

  public func withUpdatedMetadata(_ newMetadata: LogMetadataDTOCollection) -> Self {
    var updatedMetadata=metadata
    for entry in newMetadata.entries {
      updatedMetadata=updatedMetadata.with(
        key: entry.key,
        value: entry.value,
        privacyLevel: entry.privacyLevel
      )
    }

    return BasicLogContext(
      domain: domainName,
      correlationID: correlationID,
      source: source,
      metadata: updatedMetadata
    )
  }
}
