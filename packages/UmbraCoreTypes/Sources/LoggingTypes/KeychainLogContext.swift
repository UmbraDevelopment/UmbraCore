import Foundation

/// A specialised log context for keychain operations
///
/// This structure provides contextual information specific to keychain
/// operations, with enhanced privacy controls for sensitive account data.
public struct KeychainLogContext: LogContextDTO, Sendable {
  /// The name of the domain this context belongs to
  public let domainName: String="Keychain"

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// Source information for the log (e.g., file, function, line)
  public let source: String?

  /// Privacy-aware metadata for this log context
  public let metadata: LogMetadataDTOCollection

  /// The account identifier being used
  public let account: String

  /// The operation being performed
  public let operation: String

  /// Creates a new keychain log context
  ///
  /// - Parameters:
  ///   - account: The account identifier
  ///   - operation: The operation being performed
  ///   - correlationId: Optional correlation identifier for tracing related logs
  ///   - source: Optional source information (e.g., file, function, line)
  ///   - additionalContext: Optional additional context with privacy annotations
  public init(
    account: String,
    operation: String,
    correlationID: String?=nil,
    source: String?=nil,
    additionalContext: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.account=account
    self.operation=operation
    self.correlationID=correlationID
    self.source=source

    // Start with the additional context
    var contextMetadata=additionalContext

    // Add account as private metadata (sensitive)
    contextMetadata=contextMetadata.withPrivate(key: "account", value: account)

    // Add operation as public metadata
    contextMetadata=contextMetadata.withPublic(key: "operation", value: operation)

    metadata=contextMetadata
  }

  /// Creates a new instance of this context with updated metadata
  ///
  /// - Parameter metadata: The metadata to add to the context
  /// - Returns: A new log context with the updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> KeychainLogContext {
    KeychainLogContext(
      account: account,
      operation: operation,
      correlationID: correlationID,
      source: source,
      additionalContext: self.metadata.merging(with: metadata)
    )
  }

  /// Creates a new instance of this context with a correlation ID
  ///
  /// - Parameter correlationId: The correlation ID to add
  /// - Returns: A new log context with the specified correlation ID
  public func withCorrelationID(_ correlationID: String) -> KeychainLogContext {
    KeychainLogContext(
      account: account,
      operation: operation,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }

  /// Creates a new instance of this context with source information
  ///
  /// - Parameter source: The source information to add
  /// - Returns: A new log context with the specified source
  public func withSource(_ source: String) -> KeychainLogContext {
    KeychainLogContext(
      account: account,
      operation: operation,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }
}
