import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Represents the result of a log write operation to a destination.

 Contains information about the success or failure of the operation,
 as well as any error information or additional metadata.
 */
public struct LogWriteResultDTO: Sendable, Equatable {
  /// Destination ID that was written to
  public let destinationID: String

  /// Whether the write operation was successful
  public let success: Bool

  /// Error information (if operation failed)
  public let error: Error?

  /// Additional metadata about the write operation
  public let metadata: [String: String]

  /**
   Initialises a new log write result.

   - Parameters:
      - destinationId: Destination ID that was written to
      - success: Whether the write operation was successful
      - error: Error information (if operation failed)
      - metadata: Additional metadata about the write operation
   */
  public init(
    destinationID: String,
    success: Bool,
    error: Error?=nil,
    metadata: [String: String]=[:]
  ) {
    self.destinationID=destinationID
    self.success=success
    self.error=error
    self.metadata=metadata
  }

  /// Creates a successful result
  public static func success(
    destinationID: String,
    metadata: [String: String]=[:]
  ) -> LogWriteResultDTO {
    LogWriteResultDTO(
      destinationID: destinationID,
      success: true,
      metadata: metadata
    )
  }

  /// Creates a failure result
  public static func failure(destinationID: String, error: Error) -> LogWriteResultDTO {
    LogWriteResultDTO(
      destinationID: destinationID,
      success: false,
      error: error
    )
  }
}

// Allow comparing with different error types
extension LogWriteResultDTO {
  public static func == (lhs: LogWriteResultDTO, rhs: LogWriteResultDTO) -> Bool {
    if lhs.destinationID != rhs.destinationID { return false }
    if lhs.success != rhs.success { return false }
    if lhs.metadata != rhs.metadata { return false }

    // For errors, just check if both have an error or both don't
    let lhsHasError=lhs.error != nil
    let rhsHasError=rhs.error != nil
    return lhsHasError == rhsHasError
  }
}
