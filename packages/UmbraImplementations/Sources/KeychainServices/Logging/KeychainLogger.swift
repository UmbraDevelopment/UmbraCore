import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Keychain Logger

 A domain-specific privacy-aware logger for keychain operations that follows
 the Alpha Dot Five architecture principles for structured logging.

 This logger ensures that sensitive information related to keychain operations
 is properly classified with appropriate privacy levels, with British spelling
 in documentation and comments.
 */
public struct KeychainLogger: Sendable {
  /// The underlying logger
  private let logger: any LoggingProtocol

  /**
   Initialises a new keychain logger.

   - Parameter logger: The core logger to wrap
   */
  public init(logger: LoggingProtocol) {
    self.logger=logger
  }

  /**
   Logs the start of a keychain operation.

   - Parameters:
      - operation: The operation being performed
      - account: Optional account identifier (private metadata)
      - additionalMetadata: Any additional metadata to include
   */
  public func logOperationStart(
    operation: String,
    account: String?=nil,
    additionalMetadata: [String: Any]=[:]
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "operation", value: operation)

    if let account {
      metadata=metadata.withPrivate(key: "account", value: account)
    }

    // Add any additional metadata
    for (key, value) in additionalMetadata {
      metadata=metadata.with(key: key, value: String(describing: value), privacyLevel: .auto)
    }

    let context = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurity", metadata: metadata
    )
    await logger.info(
      "Starting keychain operation: \(operation)", context: context
    )
  }

  /**
   Logs the start of a keychain operation with key identifier.

   - Parameters:
      - account: The account identifier (private metadata)
      - operation: The operation being performed
      - keyIdentifier: The key identifier (private metadata)
      - additionalContext: Optional additional structured context
   */
  public func logOperationStart(
    account: String?=nil,
    operation: String,
    keyIdentifier: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "operation", value: operation)

    if let account {
      metadata=metadata.withPrivate(key: "account", value: account)
    }

    if let keyIdentifier {
      metadata=metadata.withPrivate(key: "keyIdentifier", value: keyIdentifier)
    }

    // Add additional context if provided
    if let additionalContext {
      metadata=metadata.merging(with: additionalContext)
    }

    let context = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurity", metadata: metadata
    )
    await logger.info(
      "Starting keychain operation: \(operation)", context: context
    )
  }

  /**
   Logs the successful completion of a keychain operation.

   - Parameters:
      - operation: The operation that was performed
      - account: Optional account identifier (private metadata)
      - additionalMetadata: Any additional metadata to include
   */
  public func logOperationSuccess(
    operation: String,
    account: String?=nil,
    additionalMetadata: [String: Any]=[:]
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "operation", value: operation)
    metadata=metadata.withPublic(key: "status", value: "success")

    if let account {
      metadata=metadata.withPrivate(key: "account", value: account)
    }

    // Add any additional metadata
    for (key, value) in additionalMetadata {
      metadata=metadata.with(key: key, value: String(describing: value), privacyLevel: .auto)
    }

    let context = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurity", metadata: metadata
    )
    await logger.info(
      "Completed keychain operation: \(operation)", context: context
    )
  }

  /**
   Logs the successful completion of a keychain operation with key identifier.

   - Parameters:
      - account: The account identifier (private metadata)
      - operation: The operation that was performed
      - keyIdentifier: The key identifier (private metadata)
      - additionalContext: Optional additional structured context
   */
  public func logOperationSuccess(
    account: String?=nil,
    operation: String,
    keyIdentifier: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "operation", value: operation)
    metadata=metadata.withPublic(key: "status", value: "success")

    if let account {
      metadata=metadata.withPrivate(key: "account", value: account)
    }

    if let keyIdentifier {
      metadata=metadata.withPrivate(key: "keyIdentifier", value: keyIdentifier)
    }

    // Add additional context if provided
    if let additionalContext {
      metadata=metadata.merging(with: additionalContext)
    }

    let context = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurity", metadata: metadata
    )
    await logger.info(
      "Completed keychain operation: \(operation)", context: context
    )
  }

  /**
   Logs an error that occurred during a keychain operation.

   - Parameters:
      - operation: The operation where the error occurred
      - error: The error that occurred
      - account: Optional account identifier (private metadata)
      - additionalMetadata: Any additional metadata to include
   */
  public func logOperationError(
    operation: String,
    error: Error,
    account: String?=nil,
    additionalMetadata: [String: Any]=[:]
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "operation", value: operation)
    metadata=metadata.withPublic(key: "status", value: "error")
    metadata=metadata.withPublic(key: "errorType", value: String(describing: type(of: error)))
    metadata=metadata.withPrivate(key: "errorMessage", value: error.localizedDescription)

    if let account {
      metadata=metadata.withPrivate(key: "account", value: account)
    }

    // Add any additional metadata
    for (key, value) in additionalMetadata {
      metadata=metadata.with(key: key, value: String(describing: value), privacyLevel: .auto)
    }

    let context = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurity", metadata: metadata
    )
    await logger.error(
      "Error during keychain operation: \(operation)", context: context
    )
  }

  /**
   Logs an error that occurred during a keychain operation with key identifier.

   - Parameters:
      - account: The account identifier (private metadata)
      - operation: The operation where the error occurred
      - error: The error that occurred
      - keyIdentifier: The key identifier (private metadata)
      - additionalContext: Optional additional structured context
      - message: Optional custom message override
   */
  public func logOperationError(
    account: String?=nil,
    operation: String,
    error: Error,
    keyIdentifier: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "operation", value: operation)
    metadata=metadata.withPublic(key: "status", value: "error")
    metadata=metadata.withPublic(key: "errorType", value: String(describing: type(of: error)))
    metadata=metadata.withPrivate(key: "errorMessage", value: error.localizedDescription)

    if let account {
      metadata=metadata.withPrivate(key: "account", value: account)
    }

    if let keyIdentifier {
      metadata=metadata.withPrivate(key: "keyIdentifier", value: keyIdentifier)
    }

    // Add additional context if provided
    if let additionalContext {
      metadata=metadata.merging(with: additionalContext)
    }

    let defaultMessage="Error during keychain operation: \(operation)"

    let context = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurity", metadata: metadata
    )
    await logger.error(
      message ?? defaultMessage, context: context
    )
  }
}
