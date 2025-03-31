import Foundation

/**
 # ErrorContext

 Provides contextual information about an error occurrence.

 ErrorContext carries metadata and source information to help with debugging,
 logging, and error handling. It follows the Alpha Dot Five architecture
 by providing a structured approach to error context.
 */
public struct ErrorContext: Sendable, Equatable {
  /// Source location information for the error
  public let source: ErrorSource

  /// Additional metadata about the error
  public let metadata: [String: String]

  /// Timestamp when the error occurred
  public let timestamp: Date

  /**
   Initialises a new error context with the specified parameters.

   - Parameters:
      - source: The source location information
      - metadata: Additional metadata about the error
      - timestamp: The timestamp when the error occurred (defaults to now)
   */
  public init(
    source: ErrorSource,
    metadata: [String: String]=[:],
    timestamp: Date=Date()
  ) {
    self.source=source
    self.metadata=metadata
    self.timestamp=timestamp
  }
}
