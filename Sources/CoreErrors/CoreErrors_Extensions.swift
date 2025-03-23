import Foundation

/// Namespace for CoreErrors
public enum CoreErrors {
  /// Represents security errors
  public typealias Security=SecurityError

  /// Represents crypto errors
  public typealias Crypto=CryptoError

  /// Represents key manager errors
  public typealias KeyManager=KeyManagerError
}
