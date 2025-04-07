import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 * A bookmark-specific log context for structured logging of security bookmark operations.
 *
 * This provides metadata tailored for bookmark operations including operation type,
 * bookmark identifiers, and status with appropriate privacy controls.
 */
public struct BookmarkLogContext: LogContextDTO {
  /// The domain name for the log
  public let domainName: String

  /// The source of the log entry
  public let source: String?

  /// Correlation ID for tracking related log entries
  public let correlationID: String?

  /// The metadata collection for this log entry
  public let metadata: LogMetadataDTOCollection

  /// The type of bookmark operation being performed
  public let operation: String

  /// The bookmark identifier (with privacy protection)
  public let identifier: String?

  /// The status of the operation
  public let status: String

  /**
   * Creates a new bookmark log context.
   *
   * - Parameters:
   *   - operation: The type of bookmark operation
   *   - identifier: The bookmark identifier (optional)
   *   - status: The status of the operation
   *   - source: The source of the log (optional)
   *   - domainName: The domain name for the log
   *   - correlationID: Optional correlation ID for tracking related logs
   *   - metadata: Additional metadata for the log entry
   */
  public init(
    operation: String,
    identifier: String?=nil,
    status: String,
    source: String?="BookmarkServices",
    domainName: String="BookmarkServices",
    correlationID: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.operation=operation
    self.identifier=identifier
    self.status=status
    self.source=source
    self.domainName=domainName
    self.correlationID=correlationID

    // Create a new metadata collection with bookmark-specific fields
    var enhancedMetadata=metadata
    enhancedMetadata=enhancedMetadata.withPublic(key: "operation", value: operation)
    enhancedMetadata=enhancedMetadata.withPublic(key: "status", value: status)

    if let identifier {
      enhancedMetadata=enhancedMetadata.withPrivate(key: "identifier", value: identifier)
    }

    self.metadata=enhancedMetadata
  }

  /**
   * Creates an updated copy of this context with new metadata.
   *
   * - Parameter metadata: The new metadata collection
   * - Returns: A new context with updated metadata
   */
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> BookmarkLogContext {
    BookmarkLogContext(
      operation: operation,
      identifier: identifier,
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
    logMetadata["status"]=status

    if let identifier {
      logMetadata["identifier"]=identifier
    }

    return logMetadata
  }
}
