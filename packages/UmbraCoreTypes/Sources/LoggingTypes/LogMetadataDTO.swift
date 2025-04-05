import Foundation

/// Represents a single metadata entry with privacy classification
///
/// This structure enables privacy-aware logging by attaching privacy
/// classifications to individual metadata entries.
public struct LogMetadataDTO: Sendable, Equatable, Hashable {
  /// The key identifier for this metadata entry
  public let key: String

  /// The value of this metadata entry
  public let value: String

  /// The privacy classification for this metadata value
  public let privacyLevel: PrivacyClassification

  /// Creates a new metadata entry with the specified privacy level
  ///
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  ///   - privacyLevel: The privacy classification to apply to this entry
  public init(key: String, value: String, privacyLevel: PrivacyClassification) {
    self.key=key
    self.value=value
    self.privacyLevel=privacyLevel
  }

  /// Creates a public metadata entry
  ///
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A metadata entry with public privacy classification
  public static func publicEntry(key: String, value: String) -> LogMetadataDTO {
    LogMetadataDTO(key: key, value: value, privacyLevel: .public)
  }

  /// Creates a private metadata entry
  ///
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A metadata entry with private privacy classification
  public static func privateEntry(key: String, value: String) -> LogMetadataDTO {
    LogMetadataDTO(key: key, value: value, privacyLevel: .private)
  }

  /// Creates a sensitive metadata entry
  ///
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A metadata entry with sensitive privacy classification
  public static func sensitiveEntry(key: String, value: String) -> LogMetadataDTO {
    LogMetadataDTO(key: key, value: value, privacyLevel: .sensitive)
  }

  /// Creates a hashed metadata entry
  ///
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A metadata entry with hashed privacy classification
  public static func hashedEntry(key: String, value: String) -> LogMetadataDTO {
    LogMetadataDTO(key: key, value: value, privacyLevel: .hash)
  }
  
  /// Creates an automatically-classified metadata entry
  ///
  /// This classification will use the system's built-in heuristics to 
  /// determine the appropriate privacy level based on the value's content.
  ///
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A metadata entry with automatic privacy classification
  public static func autoClassifiedEntry(key: String, value: String) -> LogMetadataDTO {
    LogMetadataDTO(key: key, value: value, privacyLevel: .auto)
  }
}
