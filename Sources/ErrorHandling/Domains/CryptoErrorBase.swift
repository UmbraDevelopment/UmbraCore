import Foundation
import UmbraErrorsCore
// Use the shared declarations instead of local ones
import Interfaces


/// Error domain namespace

/// Error context protocol

/// Base error context implementation

extension UmbraErrors {
  /// Cryptography error domain
  public enum Crypto {
    // This namespace contains the various cryptography error types
    // Implementation in separate files:
    // - CryptoCoreErrors.swift - Core cryptography errors
    // - CryptoKeychainErrors.swift - Keychain-specific errors
  }
}
