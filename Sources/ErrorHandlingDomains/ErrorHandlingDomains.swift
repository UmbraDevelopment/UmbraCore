import Foundation

/// Error domain constants - NOT using typealiases
public struct ErrorDomains {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"

  // Private initializer to prevent instantiation
  private init() {}
}
