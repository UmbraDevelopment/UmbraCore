import Foundation

/**
 # KeyIdentifier

 A strongly-typed identifier for cryptographic keys in the Alpha Dot Five architecture.
 Ensures type safety and prevents the use of raw strings for key identification.

 ## Usage
 ```swift
 let keyID = KeyIdentifier("master-key-2025")
 let derivedKeyID = KeyIdentifier(base: keyId, purpose: "file-encryption")
 ```
 */
public struct KeyIdentifier: Sendable, Hashable, Equatable, Codable {
  /// The unique identifier string
  public let identifier: String

  /// Creates a new key identifier with the given string
  public init(_ identifier: String) {
    self.identifier=identifier
  }

  /// Creates a derived key identifier from a base key with a specific purpose
  public init(base: KeyIdentifier, purpose: String) {
    identifier="\(base.identifier):\(purpose)"
  }

  public var description: String {
    // Return a redacted version for security purposes
    "KeyID-\(String(identifier.prefix(4)))****"
  }
}
