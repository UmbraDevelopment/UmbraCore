import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 * A keychain-specific log context for structured logging of keychain operations.
 *
 * This provides metadata tailored for keychain operations including operation type,
 * account information, and status with appropriate privacy controls.
 */
public struct KeychainLogContext: LogContextDTO {
  /// The domain name for the log
  public let domainName: String

  /// The source of the log entry
  public let source: String?

  /// Correlation ID for tracking related log entries
  public let correlationID: String?

  /// The metadata collection for this log entry
  public let metadata: LogMetadataDTOCollection

  /// The type of keychain operation being performed
  public let operation: String

  /// The account identifier (with privacy protection)
  public let account: String

  /// The status of the operation
  public let status: String

  /**
   * Creates a new keychain log context.
   *
   * - Parameters:
   *   - operation: The type of keychain operation
   *   - account: The account identifier
   *   - status: The status of the operation
   *   - source: The source of the log (optional)
   *   - domainName: The domain name for the log
   *   - correlationID: Optional correlation ID for tracking related logs
   *   - metadata: Additional metadata for the log entry
   */
  public init(
    operation: String,
    account: String,
    status: String,
    source: String?="KeychainServices",
    domainName: String="Keychain",
    correlationID: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.operation=operation
    self.account=account
    self.status=status
    self.source=source
    self.domainName=domainName
    self.correlationID=correlationID

    // Create a new metadata collection with keychain-specific fields
    var enhancedMetadata=metadata
    enhancedMetadata=enhancedMetadata.withPrivate(key: "operation", value: operation)
    enhancedMetadata=enhancedMetadata.withPrivate(key: "account", value: account)
    enhancedMetadata=enhancedMetadata.withPublic(key: "status", value: status)

    self.metadata=enhancedMetadata
  }

  /**
   * Creates an updated copy of this context with new metadata.
   *
   * - Parameter metadata: The new metadata collection
   * - Returns: A new context with updated metadata
   */
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> KeychainLogContext {
    KeychainLogContext(
      operation: operation,
      account: account,
      status: status,
      source: source,
      domainName: domainName,
      correlationID: correlationID,
      metadata: metadata
    )
  }

  /**
   * Returns the source of the log entry.
   *
   * - Returns: The source string or nil if not available
   */
  public func getSource() -> String? {
    source
  }

  /**
   * Converts the context to standard log metadata.
   *
   * - Returns: The log metadata representation of this context
   */
  public func asLogMetadata() -> LogMetadata {
    // Create a standard LogMetadata dictionary
    var logMetadata=LogMetadata()

    // Add standard context fields
    logMetadata["domain"]=domainName
    if let source {
      logMetadata["source"]=source
    }
    if let correlationID {
      logMetadata["correlationID"]=correlationID
    }

    // Add operation-specific fields
    logMetadata["operation"]=operation
    logMetadata["account"]=account
    logMetadata["status"]=status

    return logMetadata
  }
}
