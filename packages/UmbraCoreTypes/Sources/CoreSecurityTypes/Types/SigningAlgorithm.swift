import Foundation

/**
 # Signing Algorithm

 Defines the digital signature algorithms supported by the Alpha Dot Five architecture.
 Provides strong typing for signature operations to prevent algorithm misconfigurations.

 ## Supported Algorithms
 - ED25519: Modern elliptic curve signature algorithm optimised for security and performance
 - ECDSA: Elliptic Curve Digital Signature Algorithm with different curve options
 - RSA: Classic RSA signature algorithm (included for compatibility)
 */
public enum SigningAlgorithm: String, Sendable, Equatable, Codable, CaseIterable {
  /// ED25519 signature algorithm
  case ed25519

  /// ECDSA with P-256 curve
  case ecdsaP256

  /// ECDSA with P-384 curve
  case ecdsaP384

  /// ECDSA with P-521 curve
  case ecdsaP521

  /// RSA with PKCS#1 padding and SHA-256
  case rsaPkcs1Sha256

  /// RSA with PKCS#1 padding and SHA-384
  case rsaPkcs1Sha384

  /// RSA with PKCS#1 padding and SHA-512
  case rsaPkcs1Sha512

  /// RSA with PSS padding and SHA-256
  case rsaPssSha256

  /// RSA with PSS padding and SHA-384
  case rsaPssSha384

  /// RSA with PSS padding and SHA-512
  case rsaPssSha512
}
