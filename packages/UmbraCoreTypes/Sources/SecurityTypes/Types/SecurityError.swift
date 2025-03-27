import Foundation

/// Security error implementation
public struct SecurityErrorDTO: Error, Equatable, Sendable {
  /// Error domain for categorisation
  public let domain: String
  
  /// Error code for programmatic handling
  public let code: Int
  
  /// Human-readable error description
  public let description: String
  
  /// Additional information about the error
  public let info: [String: String]?
  
  /// Initialise with domain, code, and description
  /// - Parameters:
  ///   - domain: Error domain (e.g., "Security", "Crypto")
  ///   - code: Error code
  ///   - description: Human-readable description of the error
  ///   - info: Optional additional information
  public init(
    domain: String,
    code: Int,
    description: String,
    info: [String: String]? = nil
  ) {
    self.domain = domain
    self.code = code
    self.description = description
    self.info = info
  }
  
  /// Compare two SecurityErrorDTOs
  public static func == (lhs: SecurityErrorDTO, rhs: SecurityErrorDTO) -> Bool {
    lhs.domain == rhs.domain &&
    lhs.code == rhs.code &&
    lhs.description == rhs.description
  }
}

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Authentication domain
  public static let authentication = "Authentication" 
  /// Authorization domain
  public static let authorization = "Authorization"
  /// Application domain
  public static let application = "Application"
}
