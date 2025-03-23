import Foundation

/// Error handling framework
public enum ErrorHandling {
  /// Current version
  public static let version = "1.0.0"

  /// Initialisation
  public static func initialize() {
    // Configure error handling system
  }

  /// Error domains
  public enum Domains {
    /// General error domain
    public static let general = "General"

    /// Security error domain
    public static let security = "Security"

    /// Crypto error domain
    public static let crypto = "Crypto"
  }
}
