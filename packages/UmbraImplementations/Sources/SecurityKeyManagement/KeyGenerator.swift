import CoreSecurityTypes
import DomainSecurityTypes
import Foundation

/// Protocol for generating cryptographic keys
public protocol KeyGenerator {
  /// Generate a cryptographic key of the specified bit length
  /// - Parameter bitLength: Length of the key in bits
  /// - Returns: The generated key as SecureBytes
  func generateKey(bitLength: Int) async throws -> SecureBytes
}

/// Default implementation of KeyGenerator
public class DefaultKeyGenerator: KeyGenerator {
  /// Initialise a new key generator
  public init() {}

  /// Generate a cryptographic key of the specified bit length
  /// - Parameter bitLength: Length of the key in bits
  /// - Returns: The generated key as SecureBytes
  public func generateKey(bitLength: Int) async throws -> SecureBytes {
    // Calculate number of bytes needed (rounding up)
    let byteLength=(bitLength + 7) / 8

    // Generate random bytes for the key
    var keyBytes=[UInt8](repeating: 0, count: byteLength)

    // Fill with random data
    for i in 0..<byteLength {
      keyBytes[i]=UInt8.random(in: 0...255)
    }

    return SecureBytes(bytes: keyBytes)
  }
}
