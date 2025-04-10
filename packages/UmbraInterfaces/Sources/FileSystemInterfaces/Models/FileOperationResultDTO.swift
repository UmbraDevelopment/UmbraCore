import Foundation

/**
 # File Operation Result DTO

 Represents the result of a file system operation, including
 status, metadata, and contextual information.

 This DTO provides a standardised way to return results from all
 file system operations in the Alpha Dot Five architecture.

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable struct for thread safety
 - Provides rich metadata about operations
 - Implements Sendable for concurrency safety
 - Uses British spelling in documentation
 */
public struct FileOperationResultDTO: Sendable, Equatable {
  /// Status of the file operation
  public enum Status: String, Sendable, Equatable {
    /// Operation completed successfully
    case success

    /// Operation completed with warnings
    case warning

    /// Operation failed
    case failure
  }

  /// The status of the operation
  public let status: Status

  /// Path that was operated on
  public let path: String

  /// Timestamp when the operation was completed
  public let timestamp: Date

  /// Optional file metadata from the operation
  public let metadata: FileMetadataDTO?

  /// Optional context information about the operation
  public let context: [String: String]?

  /// Optional warning messages, if any
  public let warnings: [String]?

  /// Creates a new file operation result
  public init(
    status: Status,
    path: String,
    timestamp: Date=Date(),
    metadata: FileMetadataDTO?=nil,
    context: [String: String]?=nil,
    warnings: [String]?=nil
  ) {
    self.status=status
    self.path=path
    self.timestamp=timestamp
    self.metadata=metadata
    self.context=context
    self.warnings=warnings
  }

  /// Creates a success result for the given path
  public static func success(
    path: String,
    metadata: FileMetadataDTO?=nil
  ) -> FileOperationResultDTO {
    FileOperationResultDTO(
      status: .success,
      path: path,
      metadata: metadata
    )
  }

  /// Creates a warning result for the given path
  public static func warning(
    path: String,
    warnings: [String],
    metadata: FileMetadataDTO?=nil
  ) -> FileOperationResultDTO {
    FileOperationResultDTO(
      status: .warning,
      path: path,
      metadata: metadata,
      warnings: warnings
    )
  }

  /// Creates a failure result for the given path
  public static func failure(
    path: String,
    context: [String: String]?=nil
  ) -> FileOperationResultDTO {
    FileOperationResultDTO(
      status: .failure,
      path: path,
      context: context
    )
  }
}
