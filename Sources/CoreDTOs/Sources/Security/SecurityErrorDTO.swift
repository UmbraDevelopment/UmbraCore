import UmbraCoreTypes

/// FoundationIndependent representation of a security error.
/// This data transfer object encapsulates security error information
/// without using any Foundation types.
public struct SecurityErrorDTO: Error, Sendable, Equatable, CustomStringConvertible {
  // MARK: - Properties

  /// Error code value
  public let code: Int32

  /// Error domain identifier
  public let domain: String

  /// Human-readable error message
  public let message: String

  /// Additional error details
  public let details: [String: String]

  // MARK: - Initializers

  /// Create a security error
  /// - Parameters:
  ///   - code: Error code
  ///   - domain: Error domain
  ///   - message: Error message
  ///   - details: Additional details
  public init(
    code: Int32,
    domain: String = "security",
    message: String,
    details: [String: String] = [:]
  ) {
    self.code = code
    self.domain = domain
    self.message = message
    self.details = details
  }

  // MARK: - CustomStringConvertible

  /// Human-readable description
  public var description: String {
    "[\(domain):\(code)] \(message)"
  }

  // MARK: - Factory Methods

  /// Create an encryption error
  /// - Parameters:
  ///   - message: Error message
  ///   - details: Additional details
  /// - Returns: A SecurityErrorDTO
  public static func encryptionError(
    message: String,
    details: [String: String] = [:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: 1_001,
      message: message,
      details: details
    )
  }

  /// Create a decryption error
  /// - Parameters:
  ///   - message: Error message
  ///   - details: Additional details
  /// - Returns: A SecurityErrorDTO
  public static func decryptionError(
    message: String,
    details: [String: String] = [:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: 1_002,
      message: message,
      details: details
    )
  }

  /// Create a key error
  /// - Parameters:
  ///   - message: Error message
  ///   - details: Additional details
  /// - Returns: A SecurityErrorDTO
  public static func keyError(
    message: String,
    details: [String: String] = [:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: 1_003,
      message: message,
      details: details
    )
  }

  /// Create a storage error
  /// - Parameters:
  ///   - message: Error message
  ///   - details: Additional details
  /// - Returns: A SecurityErrorDTO
  public static func storageError(
    message: String,
    details: [String: String] = [:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: 1_004,
      message: message,
      details: details
    )
  }

  /// Create an access error
  /// - Parameters:
  ///   - message: Error message
  ///   - details: Additional details
  /// - Returns: A SecurityErrorDTO
  public static func accessError(
    message: String,
    details: [String: String] = [:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: 1_005,
      message: message,
      details: details
    )
  }

  /// Create an internal error
  /// - Parameters:
  ///   - message: Error message
  ///   - details: Additional details
  /// - Returns: A SecurityErrorDTO
  public static func internalError(
    message: String,
    details: [String: String] = [:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: 1_006,
      message: message,
      details: details
    )
  }

  /// Create an unknown error
  /// - Parameters:
  ///   - message: Error message
  ///   - details: Additional details
  /// - Returns: A SecurityErrorDTO
  public static func unknown(
    message: String,
    details: [String: String] = [:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: 9_999,
      message: message,
      details: details
    )
  }

  /// Create an invalid path error
  /// - Parameters:
  ///   - path: The invalid path
  ///   - details: Additional details
  /// - Returns: A SecurityErrorDTO
  public static func invalidPath(
    path: String,
    details: [String: String] = [:]
  ) -> SecurityErrorDTO {
    var allDetails = details
    allDetails["path"] = path
    return SecurityErrorDTO(
      code: 1_007,
      domain: "security.bookmark",
      message: "Invalid path: \(path)",
      details: allDetails
    )
  }

  /// Create a bookmark creation failed error
  /// - Parameters:
  ///   - path: The path for which bookmark creation failed
  ///   - details: Additional details
  /// - Returns: A SecurityErrorDTO
  public static func bookmarkCreationFailed(
    path: String,
    details: [String: String] = [:]
  ) -> SecurityErrorDTO {
    var allDetails = details
    allDetails["path"] = path
    return SecurityErrorDTO(
      code: 1_008,
      message: "Failed to create bookmark",
      details: allDetails
    )
  }

  /// Create a bookmark resolution failed error
  /// - Parameters:
  ///   - details: Error details
  /// - Returns: A SecurityErrorDTO
  public static func bookmarkResolutionFailed(
    details: [String: String] = [:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: 1_009,
      message: "Failed to resolve bookmark",
      details: details
    )
  }

  /// Default general error code
  public static let generalErrorCode: Int32 = 9_999
}
