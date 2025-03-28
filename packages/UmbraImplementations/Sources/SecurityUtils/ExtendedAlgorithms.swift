import Foundation
import SecurityCoreTypes
import SecurityTypes

/// Extends support for cryptographic algorithms beyond those defined in SecurityConfigDTO
public enum ExtendedAlgorithm: String, Sendable, Equatable {
  // Standard algorithms from SecurityConfigDTO.Algorithm
  case aes="AES"
  case rsa="RSA"
  case chacha20="ChaCha20"

  // Extended algorithms
  case twofish="Twofish"
  case serpent="Serpent"
  case camellia="Camellia"
  case blowfish="Blowfish"
  case idea="IDEA"

  /// Convert from core Algorithm type
  public init(from coreAlgorithm: SecurityConfigDTO.Algorithm) {
    switch coreAlgorithm {
      case .aes:
        self = .aes
      case .rsa:
        self = .rsa
      case .chacha20:
        self = .chacha20
    }
  }

  /// Convert to core Algorithm type if possible
  public func toCoreAlgorithm() -> SecurityConfigDTO.Algorithm? {
    switch self {
      case .aes:
        .aes
      case .rsa:
        .rsa
      case .chacha20:
        .chacha20
      default:
        nil
    }
  }

  /// Get recommended key size for the algorithm
  public var recommendedKeySize: Int {
    switch self {
      case .aes, .chacha20, .twofish, .serpent, .camellia:
        256
      case .rsa:
        2048
      case .blowfish, .idea:
        128
    }
  }

  /// Check if algorithm supports a specific mode
  public func supportsMode(_ mode: SecurityConfigDTO.Mode) -> Bool {
    switch self {
      case .aes, .twofish, .serpent, .camellia:
        // Block ciphers support all modes
        true
      case .chacha20:
        // Stream cipher doesn't use block cipher modes
        false
      case .rsa:
        // RSA doesn't use block cipher modes
        false
      case .blowfish, .idea:
        // These support some modes but not GCM
        mode != .gcm
    }
  }
}

/// Extended mode options beyond those in SecurityConfigDTO
public enum ExtendedMode: String, Sendable, Equatable {
  // Standard modes from SecurityConfigDTO.Mode
  case gcm="GCM"
  case cbc="CBC"
  case ctr="CTR"

  // Extended modes
  case ofb="OFB"
  case cfb="CFB"
  case xts="XTS"
  case ecb="ECB" // Added missing ECB mode

  /// Convert from core Mode type
  public init(from coreMode: SecurityConfigDTO.Mode) {
    switch coreMode {
      case .gcm:
        self = .gcm
      case .cbc:
        self = .cbc
      case .ctr:
        self = .ctr
    }
  }

  /// Convert to core Mode type if possible
  public func toCoreMode() -> SecurityConfigDTO.Mode? {
    switch self {
      case .gcm:
        .gcm
      case .cbc:
        .cbc
      case .ctr:
        .ctr
      default:
        nil
    }
  }

  /// Check if mode requires initialization vector
  public var requiresIV: Bool {
    switch self {
      case .ecb:
        false
      default:
        true
    }
  }
}

/// Extended configuration builder that supports additional algorithms
public struct ExtendedSecurityConfig {
  public let algorithm: ExtendedAlgorithm
  public let mode: ExtendedMode?
  public let keySize: Int
  public let hashAlgorithm: SecurityCoreTypes.HashAlgorithm
  public let options: [String: String]

  /// Initialize with extended options
  public init(
    algorithm: ExtendedAlgorithm,
    mode: ExtendedMode?=nil,
    keySize: Int?=nil,
    hashAlgorithm: SecurityCoreTypes.HashAlgorithm = .sha256,
    options: [String: String]=[:]
  ) {
    self.algorithm=algorithm
    self.mode=mode
    self.keySize=keySize ?? algorithm.recommendedKeySize
    self.hashAlgorithm=hashAlgorithm
    self.options=options
  }

  /// Convert to core SecurityConfigDTO
  public func toConfigDTO() -> SecurityConfigDTO {
    let coreAlgorithm=algorithm.toCoreAlgorithm() ?? .aes
    let coreMode=mode?.toCoreMode()

    return SecurityConfigDTO(
      keySize: keySize,
      algorithm: coreAlgorithm,
      mode: coreMode,
      hashAlgorithm: hashAlgorithm,
      options: options
    )
  }
}
