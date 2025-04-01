import CoreSecurityTypes
import DomainSecurityTypes
import Foundation

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

  /// Check if mode requires an IV/nonce
  public var requiresIV: Bool {
    switch self {
      case .ecb:
        false
      default:
        true
    }
  }

  /// Get recommended IV size for this mode in bytes
  public var recommendedIVSize: Int {
    switch self {
      case .gcm, .ccm:
        12 // GCM/CCM prefer 12-byte nonces
      case .cbc, .cfb, .ofb:
        16 // Full block size for AES
      case .ctr:
        8 // Counter typically uses half-block
      case .xts:
        16 // XTS uses a 16-byte tweak
      case .ecb:
        0 // ECB doesn't use an IV
    }
  }
}

/// Extends support for hash algorithms beyond those in SecurityConfigDTO
public enum ExtendedHashAlgorithm: String, Sendable, Equatable {
  // Standard hash algorithms
  case sha256="SHA-256"
  case sha384="SHA-384"
  case sha512="SHA-512"

  // Extended hash algorithms
  case sha3_256="SHA3-256"
  case sha3_384="SHA3-384"
  case sha3_512="SHA3-512"
  case blake2b="BLAKE2b"
  case blake2s="BLAKE2s"

  /// Convert from core hash algorithm string
  public init?(from coreHashAlgorithm: String) {
    switch coreHashAlgorithm {
      case "SHA-256", "SHA256":
        self = .sha256
      case "SHA-384", "SHA384":
        self = .sha384
      case "SHA-512", "SHA512":
        self = .sha512
      case "SHA3-256":
        self = .sha3_256
      case "SHA3-384":
        self = .sha3_384
      case "SHA3-512":
        self = .sha3_512
      case "BLAKE2b":
        self = .blake2b
      case "BLAKE2s":
        self = .blake2s
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
    ExtendedAlgorithm(from: encryptionAlgorithm.rawValue)
  }

  /// Get the extended mode representation, if applicable
  public var extendedMode: ExtendedMode? {
    // Access mode information from encryptionAlgorithm if available
    // Use runtime check to determine if mode exists on encryptionAlgorithm
    let mirror=Mirror(reflecting: encryptionAlgorithm)
    for child in mirror.children {
      if child.label == "mode", let modeString=child.value as? String {
        return ExtendedMode(from: modeString)
      }
    }
    return nil
  }

  /// Get the extended hash algorithm representation, if applicable
  public var extendedHashAlgorithm: ExtendedHashAlgorithm? {
    ExtendedHashAlgorithm(from: hashAlgorithm.rawValue)
  }
}

/// Extended configuration builder that supports additional algorithms
public struct ExtendedSecurityConfig {
  public let algorithm: ExtendedAlgorithm
  public let mode: ExtendedMode?
  public let keySize: Int
  public let hashAlgorithm: ExtendedHashAlgorithm
  public let options: [String: String]
  public let providerType: SecurityProviderType

  /// Initialize with extended options
  public init(
    algorithm: ExtendedAlgorithm,
    mode: ExtendedMode?=nil,
    keySize: Int?=nil,
    hashAlgorithm: ExtendedHashAlgorithm = .sha256,
    providerType: SecurityProviderType = .basic,
    options: [String: String]=[:]
  ) {
    self.algorithm=algorithm
    self.mode=mode
    self.keySize=keySize ?? algorithm.recommendedKeySize
    self.hashAlgorithm=hashAlgorithm
    self.providerType=providerType
    self.options=options
  }

  /// Convert to core SecurityConfigDTO
  public func toConfigDTO() -> SecurityConfigDTO {
    // Create encryption algorithm from rawValue
    let encryptionAlg=EncryptionAlgorithm(rawValue: algorithm.coreAlgorithmString)!

    // Create hash algorithm from rawValue
    let hashAlg=HashAlgorithm(rawValue: hashAlgorithm.coreHashAlgorithmString)!

    // Create security config options if needed
    let configOptions: SecurityConfigOptions?
    if options.isEmpty {
      configOptions=nil
    } else {
      // Extract specific known options if they exist
      let enableLogging=options["enableDetailedLogging"].flatMap { $0 == "true" } ?? false
      let keyIterations=options["keyDerivationIterations"].flatMap { Int($0) } ?? 100_000
      let memoryLimit=options["memoryLimitBytes"].flatMap { Int($0) } ?? 65536
      let useHardware=options["useHardwareAcceleration"].flatMap { $0 == "true" } ?? true
      let timeout=options["operationTimeoutSeconds"].flatMap { TimeInterval($0) } ?? 30.0
      let verify=options["verifyOperations"].flatMap { $0 == "true" } ?? true

      // Put any remaining options into metadata
      var metadata: [String: String]?=nil
      let knownKeys=[
        "enableDetailedLogging",
        "keyDerivationIterations",
        "memoryLimitBytes",
        "useHardwareAcceleration",
        "operationTimeoutSeconds",
        "verifyOperations"
      ]

      let remainingOptions=options.filter { !knownKeys.contains($0.key) }
      if !remainingOptions.isEmpty {
        metadata=remainingOptions
      }

      // Create SecurityConfigOptions with individual parameters
      configOptions=SecurityConfigOptions(
        enableDetailedLogging: enableLogging,
        keyDerivationIterations: keyIterations,
        memoryLimitBytes: memoryLimit,
        useHardwareAcceleration: useHardware,
        operationTimeoutSeconds: timeout,
        verifyOperations: verify,
        metadata: metadata
      )
    }

    // Create the config DTO
    return SecurityConfigDTO(
      encryptionAlgorithm: encryptionAlg,
      hashAlgorithm: hashAlg,
      providerType: providerType,
      options: configOptions
    )
  }
}
