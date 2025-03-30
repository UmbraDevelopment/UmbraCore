import Foundation
import SecurityCoreTypes
import SecurityTypes

/// Extends support for cryptographic algorithms beyond those defined in SecurityConfigDTO
public enum ExtendedAlgorithm: String, Sendable, Equatable {
  // Standard algorithms from SecurityConfigDTO
  case aes="AES"
  case rsa="RSA"
  case chacha20="ChaCha20"

  // Extended algorithms
  case twofish="Twofish"
  case serpent="Serpent"
  case camellia="Camellia"
  case blowfish="Blowfish"
  case idea="IDEA"

  /// Convert from core algorithm string
  public init?(from coreAlgorithm: String) {
    switch coreAlgorithm {
      case "AES":
        self = .aes
      case "RSA":
        self = .rsa
      case "ChaCha20":
        self = .chacha20
      case "Twofish":
        self = .twofish
      case "Serpent":
        self = .serpent
      case "Camellia":
        self = .camellia
      case "Blowfish":
        self = .blowfish
      case "IDEA":
        self = .idea
      default:
        return nil
    }
  }

  /// Convert to core algorithm string
  public var coreAlgorithmString: String {
    rawValue
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
  public func supportsMode(_ mode: String) -> Bool {
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
        mode != "GCM"
    }
  }
}

/// Extends support for cipher modes beyond those in SecurityConfigDTO
public enum ExtendedMode: String, Sendable, Equatable {
  // Standard modes
  case gcm="GCM"
  case cbc="CBC"
  case ctr="CTR"
  case ecb="ECB"

  // Extended modes
  case ofb="OFB"
  case cfb="CFB"
  case xts="XTS"
  case ccm="CCM"

  /// Convert from core mode string
  public init?(from coreMode: String) {
    switch coreMode {
      case "GCM":
        self = .gcm
      case "CBC":
        self = .cbc
      case "CTR":
        self = .ctr
      case "ECB":
        self = .ecb
      case "OFB":
        self = .ofb
      case "CFB":
        self = .cfb
      case "XTS":
        self = .xts
      case "CCM":
        self = .ccm
      default:
        return nil
    }
  }

  /// Convert to core mode string
  public var coreModeString: String {
    rawValue
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

/// Extends support for hash algorithms beyond those in SecurityConfigDTO
public enum ExtendedHashAlgorithm: String, Sendable, Equatable {
  // Standard hash algorithms
  case sha256="SHA256"
  case sha512="SHA512"
  case md5="MD5"
  case sha1="SHA1"

  // Extended hash algorithms
  case blake2b="BLAKE2b"
  case blake2s="BLAKE2s"
  case sha3_256="SHA3-256"
  case sha3_512="SHA3-512"

  /// Convert from core hash algorithm string
  public init?(from coreHashAlgorithm: String) {
    switch coreHashAlgorithm {
      case "SHA256":
        self = .sha256
      case "SHA512":
        self = .sha512
      case "MD5":
        self = .md5
      case "SHA1":
        self = .sha1
      case "BLAKE2b":
        self = .blake2b
      case "BLAKE2s":
        self = .blake2s
      case "SHA3-256":
        self = .sha3_256
      case "SHA3-512":
        self = .sha3_512
      default:
        return nil
    }
  }

  /// Convert to core hash algorithm string
  public var coreHashAlgorithmString: String {
    rawValue
  }
}

/// Extension to SecurityConfigDTO to provide convenient access to extended algorithms
extension SecurityConfigDTO {
  /// Get the extended algorithm representation, if applicable
  public var extendedAlgorithm: ExtendedAlgorithm? {
    ExtendedAlgorithm(from: algorithm)
  }

  /// Get the extended mode representation, if applicable
  public var extendedMode: ExtendedMode? {
    guard let mode else { return nil }
    return ExtendedMode(from: mode)
  }

  /// Get the extended hash algorithm representation, if applicable
  public var extendedHashAlgorithm: ExtendedHashAlgorithm? {
    guard let hashAlgorithm else { return nil }
    return ExtendedHashAlgorithm(from: hashAlgorithm)
  }
}

/// Extended configuration builder that supports additional algorithms
public struct ExtendedSecurityConfig {
  public let algorithm: ExtendedAlgorithm
  public let mode: ExtendedMode?
  public let keySize: Int
  public let hashAlgorithm: ExtendedHashAlgorithm
  public let options: [String: String]

  /// Initialize with extended options
  public init(
    algorithm: ExtendedAlgorithm,
    mode: ExtendedMode?=nil,
    keySize: Int?=nil,
    hashAlgorithm: ExtendedHashAlgorithm = .sha256,
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
    let coreAlgorithm=algorithm.coreAlgorithmString
    let coreMode=mode?.coreModeString

    return SecurityConfigDTO(
      algorithm: coreAlgorithm,
      keySize: keySize,
      mode: coreMode,
      hashAlgorithm: hashAlgorithm.coreHashAlgorithmString,
      options: options
    )
  }
}
