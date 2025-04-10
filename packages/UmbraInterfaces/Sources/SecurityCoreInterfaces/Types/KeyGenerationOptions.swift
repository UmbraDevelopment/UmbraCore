import CoreSecurityTypes
import Foundation

/**
 Options for key generation operations.

 This struct defines the options that can be used when generating cryptographic keys
 through the security interfaces. It allows specifying the key type, whether to use
 secure hardware (if available), and whether the key should be extractable.
 */
public struct KeyGenerationOptions: Sendable, Equatable {
  /// The type of key to generate
  public let keyType: CoreSecurityTypes.KeyType

  /// Whether to use the Secure Enclave (if available)
  public let useSecureEnclave: Bool

  /// Whether the key should be extractable
  public let isExtractable: Bool

  /**
   Initialises a new KeyGenerationOptions instance.

   - Parameters:
      - keyType: The type of key to generate
      - useSecureEnclave: Whether to use the Secure Enclave (if available)
      - isExtractable: Whether the key should be extractable
   */
  public init(
    keyType: CoreSecurityTypes.KeyType = .aes,
    useSecureEnclave: Bool=false,
    isExtractable: Bool=true
  ) {
    self.keyType=keyType
    self.useSecureEnclave=useSecureEnclave
    self.isExtractable=isExtractable
  }
}

// MARK: - Codable Implementation

extension KeyGenerationOptions: Codable {
  private enum CodingKeys: String, CodingKey {
    case keyType
    case useSecureEnclave
    case isExtractable
  }

  public func encode(to encoder: Encoder) throws {
    var container=encoder.container(keyedBy: CodingKeys.self)

    // Encode the key type as a string
    try container.encode(keyType.rawValue, forKey: .keyType)
    try container.encode(useSecureEnclave, forKey: .useSecureEnclave)
    try container.encode(isExtractable, forKey: .isExtractable)
  }

  public init(from decoder: Decoder) throws {
    let container=try decoder.container(keyedBy: CodingKeys.self)

    // Decode the key type from a string
    let keyTypeString=try container.decode(String.self, forKey: .keyType)
    guard let keyType=CoreSecurityTypes.KeyType(rawValue: keyTypeString) else {
      throw DecodingError.dataCorruptedError(
        forKey: .keyType,
        in: container,
        debugDescription: "Invalid key type: \(keyTypeString)"
      )
    }

    self.keyType=keyType
    useSecureEnclave=try container.decode(Bool.self, forKey: .useSecureEnclave)
    isExtractable=try container.decode(Bool.self, forKey: .isExtractable)
  }
}
