import Foundation
import UmbraCoreTypes

/// Result data transfer object for security operations
/// Contains the outcome of security operations performed by the security provider
public struct SecurityResultDTO: Sendable {
  /// Result status
  public enum Status: String, Sendable, Equatable {
    /// Operation completed successfully
    case success = "Success"
    /// Operation failed
    case failure = "Failure"
    /// Operation requires additional input
    case needsInput = "NeedsInput"
    /// Operation partially completed
    case partial = "Partial"
  }
  
  /// Operation status
  public let status: Status
  
  /// Result data if applicable
  public let data: SecureBytes?
  
  /// Error information if operation failed
  public let error: Error?
  
  /// Additional metadata as key-value pairs
  public let metadata: [String: String]
  
  /// Initialise with operation result
  /// - Parameters:
  ///   - status: Operation status
  ///   - data: Result data (if any)
  ///   - error: Error information (if any)
  ///   - metadata: Additional metadata
  public init(
    status: Status,
    data: SecureBytes? = nil,
    error: Error? = nil,
    metadata: [String: String] = [:]
  ) {
    self.status = status
    self.data = data
    self.error = error
    self.metadata = metadata
  }
  
  /// Create a success result with data
  /// - Parameter data: The operation result data
  /// - Returns: A success result DTO
  public static func success(data: SecureBytes? = nil) -> SecurityResultDTO {
    SecurityResultDTO(status: .success, data: data, error: nil)
  }
  
  /// Create a failure result with error
  /// - Parameter error: The error that occurred
  /// - Returns: A failure result DTO
  public static func failure(error: Error) -> SecurityResultDTO {
    SecurityResultDTO(status: .failure, data: nil, error: error)
  }
  
  /// Create a result that requires additional input
  /// - Parameter metadata: Information about required input
  /// - Returns: A needs-input result DTO
  public static func needsInput(metadata: [String: String]) -> SecurityResultDTO {
    SecurityResultDTO(status: .needsInput, data: nil, error: nil, metadata: metadata)
  }
  
  /// Create a partial result with available data
  /// - Parameters:
  ///   - data: The partial result data
  ///   - metadata: Information about the partial result
  /// - Returns: A partial result DTO
  public static func partial(data: SecureBytes, metadata: [String: String]) -> SecurityResultDTO {
    SecurityResultDTO(status: .partial, data: data, error: nil, metadata: metadata)
  }
}

// Extend SecurityResultDTO to conform to Equatable
extension SecurityResultDTO: Equatable {
  public static func == (lhs: SecurityResultDTO, rhs: SecurityResultDTO) -> Bool {
    lhs.status == rhs.status &&
    lhs.data == rhs.data &&
    lhs.metadata == rhs.metadata &&
    // Compare errors by their string descriptions
    String(describing: lhs.error) == String(describing: rhs.error)
  }
}
