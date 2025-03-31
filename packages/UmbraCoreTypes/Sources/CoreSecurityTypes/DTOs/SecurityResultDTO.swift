import Foundation

/**
 Data transfer object for security operation results.

 This DTO provides a standardised way to return results from security
 operations while maintaining type safety and actor isolation.
 */
public struct SecurityResultDTO: Sendable, Equatable {
  /// Whether the operation was successful
  public let successful: Bool

  /// Result data if the operation was successful
  public let resultData: Data?

  /// Error details if the operation failed
  public let errorDetails: String?

  /// Operation execution time in milliseconds
  public let executionTimeMs: Double

  /// Additional metadata about the operation
  public let metadata: [String: String]?

  /**
   Initialises a successful security operation result.

   - Parameters:
     - resultData: Result data from the operation
     - executionTimeMs: Execution time in milliseconds
     - metadata: Optional additional metadata
   */
  public static func success(
    resultData: Data?=nil,
    executionTimeMs: Double,
    metadata: [String: String]?=nil
  ) -> SecurityResultDTO {
    SecurityResultDTO(
      successful: true,
      resultData: resultData,
      errorDetails: nil,
      executionTimeMs: executionTimeMs,
      metadata: metadata
    )
  }

  /**
   Initialises a failed security operation result.

   - Parameters:
     - errorDetails: Error details explaining the failure
     - executionTimeMs: Execution time in milliseconds
     - metadata: Optional additional metadata
   */
  public static func failure(
    errorDetails: String,
    executionTimeMs: Double,
    metadata: [String: String]?=nil
  ) -> SecurityResultDTO {
    SecurityResultDTO(
      successful: false,
      resultData: nil,
      errorDetails: errorDetails,
      executionTimeMs: executionTimeMs,
      metadata: metadata
    )
  }

  private init(
    successful: Bool,
    resultData: Data?,
    errorDetails: String?,
    executionTimeMs: Double,
    metadata: [String: String]?
  ) {
    self.successful=successful
    self.resultData=resultData
    self.errorDetails=errorDetails
    self.executionTimeMs=executionTimeMs
    self.metadata=metadata
  }
}
