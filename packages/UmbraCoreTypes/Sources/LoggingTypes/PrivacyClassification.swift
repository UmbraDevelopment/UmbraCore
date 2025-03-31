import Foundation

/**
 # Privacy Classification

 Defines privacy levels for logged data in accordance with
 the Alpha Dot Five architecture privacy-enhanced logging system.

 These classifications determine how data is handled in logs,
 including how it's redacted, encrypted, or displayed in different
 environments.
 */
public enum PrivacyClassification: String, Codable, Sendable, Equatable, CaseIterable {
  /// Public information (no redaction needed)
  case `public`

  /// Private information (redacted in release but visible in debug)
  case `private`

  /// Sensitive information (always redacted, but maintained for diagnostic purposes)
  case sensitive

  /// Hashed information (stored as a secure hash)
  case hash

  /// Auto-classified based on context
  case auto

  /// The display name suitable for UI
  public var displayName: String {
    switch self {
      case .public:
        "Public"
      case .private:
        "Private"
      case .sensitive:
        "Sensitive"
      case .hash:
        "Hashed"
      case .auto:
        "Auto-classified"
    }
  }

  /// Description of what happens to this classification in logs
  public var description: String {
    switch self {
      case .public:
        "Visible in all environments"
      case .private:
        "Visible in debug, redacted in release"
      case .sensitive:
        "Always redacted, retained for diagnostics"
      case .hash:
        "Stored as secure hash"
      case .auto:
        "Automatically classified based on content"
    }
  }
}
