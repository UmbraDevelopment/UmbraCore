import Foundation

/// A lightweight Data Transfer Object representing an error
/// Used to break circular dependencies between error modules
public struct ErrorDTO: Equatable, Hashable, Sendable {
  /// Unique identifier for the error
  public let identifier: String

  /// The domain of the error
  public let domain: String

  /// Human-readable description of the error
  public let description: String

  /// Error code if available
  public let code: Int?

  /// Additional contextual information as key-value pairs
  public let contextData: [String: String]

  /// Creates a new ErrorDTO
  /// - Parameters:
  ///   - identifier: Unique identifier for the error
  ///   - domain: The domain of the error
  ///   - description: Human-readable description of the error
  ///   - code: Error code if available
  ///   - contextData: Additional contextual information
  public init(
    identifier: String,
    domain: String,
    description: String,
    code: Int?=nil,
    contextData: [String: String]=[:]
  ) {
    self.identifier=identifier
    self.domain=domain
    self.description=description
    self.code=code
    self.contextData=contextData
  }

  /// Creates an ErrorDTO from any Error
  /// - Parameter error: The source error
  /// - Returns: An ErrorDTO representing the error
  public static func from(_ error: Error) -> ErrorDTO {
    // If the error is already an ErrorDTO, just return it
    if let errorDTO=error as? ErrorDTO {
      return errorDTO
    }

    // Extract information using ErrorHandlingInterfaces if available
    let domain=(error as NSError).domain
    let code=(error as NSError).code
    let description=error.localizedDescription

    return ErrorDTO(
      identifier: "\(domain).\(code)",
      domain: domain,
      description: description,
      code: code,
      contextData: [:]
    )
  }
}

// MARK: - Error Conformance

extension ErrorDTO: Error {
  public var localizedDescription: String {
    description
  }
}

// MARK: - Codable

extension ErrorDTO: Codable {
  private enum CodingKeys: String, CodingKey {
    case identifier
    case domain
    case description
    case code
    case contextData
  }
}
