import UmbraCoreTypes
#if canImport(Darwin)
  import Darwin
#endif

/// Foundation-independent DTO for representing XPC Service operations and status
/// Provides structured data types for XPC communication without using Foundation types
public struct XPCServiceDTO: Sendable, Equatable {
  // MARK: - Service Status DTO

  /// Status information for an XPC service
  public struct ServiceStatusDTO: Sendable, Equatable {
    /// Current operating status
    public let status: String

    /// Service version
    public let version: String

    /// Performance metrics
    public let metrics: [String: Double]

    /// Additional string information
    public let stringInfo: [String: String]

    /// Create a service status DTO
    /// - Parameters:
    ///   - status: Current operating status
    ///   - version: Service version
    ///   - metrics: Performance metrics
    ///   - stringInfo: Additional string information
    public init(
      status: String,
      version: String,
      metrics: [String: Double]=[:],
      stringInfo: [String: String]=[:]
    ) {
      self.status=status
      self.version=version
      self.metrics=metrics
      self.stringInfo=stringInfo
    }

    /// Create a status DTO representing a healthy service
    /// - Parameter version: Version string
    /// - Returns: A healthy service status
    public static func healthy(version: String) -> ServiceStatusDTO {
      ServiceStatusDTO(
        status: "healthy",
        version: version
      )
    }

    /// Create a status DTO representing a degraded service
    /// - Parameters:
    ///   - version: Version string
    ///   - reason: Reason for degradation
    /// - Returns: A degraded service status
    public static func degraded(
      version: String,
      reason: String
    ) -> ServiceStatusDTO {
      ServiceStatusDTO(
        status: "degraded",
        version: version,
        stringInfo: ["degradedReason": reason]
      )
    }

    /// Create a status DTO representing an unavailable service
    /// - Parameters:
    ///   - version: Version string
    ///   - reason: Reason for unavailability
    /// - Returns: An unavailable service status
    public static func unavailable(
      version: String,
      reason: String
    ) -> ServiceStatusDTO {
      ServiceStatusDTO(
        status: "unavailable",
        version: version,
        stringInfo: ["unavailableReason": reason]
      )
    }
  }

  // MARK: - Key Information DTO

  /// Information about a cryptographic key
  public struct KeyInfoDTO: Sendable, Equatable {
    /// Key identifier
    public let keyID: String

    /// Key algorithm
    public let algorithm: String

    /// Key size in bits
    public let keySizeInBits: Int

    /// Key usage (encryption, signing, etc.)
    public let keyUsage: String

    /// Key creation timestamp (seconds since epoch)
    public let createdAt: Int64

    /// Key metadata
    public let metadata: [String: String]

    /// Create a key info DTO
    /// - Parameters:
    ///   - keyId: Key identifier
    ///   - algorithm: Key algorithm
    ///   - keySizeInBits: Key size in bits
    ///   - keyUsage: Key usage
    ///   - createdAt: Creation timestamp (seconds since epoch)
    ///   - metadata: Additional metadata
    public init(
      keyID: String,
      algorithm: String,
      keySizeInBits: Int,
      keyUsage: String,
      createdAt: Int64,
      metadata: [String: String]=[:]
    ) {
      self.keyID=keyID
      self.algorithm=algorithm
      self.keySizeInBits=keySizeInBits
      self.keyUsage=keyUsage
      self.createdAt=createdAt
      self.metadata=metadata
    }
  }

  // MARK: - Key Types DTO

  /// Key type enumeration
  public enum KeyTypeDTO: String, Sendable, Equatable {
    /// Symmetric key
    case symmetric
    /// Asymmetric key (private)
    case asymmetricPrivate
    /// Asymmetric key (public)
    case asymmetricPublic
    /// Key derivation key
    case derivation
    /// Signing key
    case signing
    /// Verification key
    case verification
  }

  /// Key format enumeration
  public enum KeyFormatDTO: String, Sendable, Equatable {
    /// Raw key format (binary)
    case raw
    /// PKCS#8 format
    case pkcs8
    /// PKCS#12 format
    case pkcs12
    /// PEM format
    case pem
    /// JWK format
    case jwk
  }
}

/// Extension with factory methods for creating common configurations
extension XPCServiceDTO {
  /// Create a default service status DTO
  /// - Returns: A default service status DTO
  public static func defaultServiceStatus() -> XPCServiceDTO.ServiceStatusDTO {
    .healthy(version: "1.0.0")
  }

  /// Create a key info DTO for a symmetric key
  /// - Parameters:
  ///   - keyId: Key identifier
  ///   - algorithm: Algorithm (AES, ChaCha20, etc.)
  ///   - keySizeInBits: Key size in bits
  /// - Returns: A key info DTO
  public static func symmetricKeyInfo(
    keyID: String,
    algorithm: String="AES",
    keySizeInBits: Int=256
  ) -> XPCServiceDTO.KeyInfoDTO {
    let timestamp: Int64
    do {
      timestamp=try Int64(currentTimestamp())
    } catch {
      timestamp=0
    }

    return XPCServiceDTO.KeyInfoDTO(
      keyID: keyID,
      algorithm: algorithm,
      keySizeInBits: keySizeInBits,
      keyUsage: "encryption",
      createdAt: timestamp
    )
  }

  /// Create a key info DTO for a signing key
  /// - Parameters:
  ///   - keyId: Key identifier
  ///   - algorithm: Algorithm (RSA, EC, ED25519, etc.)
  ///   - keySizeInBits: Key size in bits
  /// - Returns: A key info DTO
  public static func signingKeyInfo(
    keyID: String,
    algorithm: String="ED25519",
    keySizeInBits: Int=256
  ) -> XPCServiceDTO.KeyInfoDTO {
    let timestamp: Int64
    do {
      timestamp=try Int64(currentTimestamp())
    } catch {
      timestamp=0
    }

    return XPCServiceDTO.KeyInfoDTO(
      keyID: keyID,
      algorithm: algorithm,
      keySizeInBits: keySizeInBits,
      keyUsage: "signing",
      createdAt: timestamp
    )
  }

  /// Helper function to get current timestamp
  private static func currentTimestamp() throws -> Int {
    #if canImport(Darwin)
      var tv=timeval()
      guard gettimeofday(&tv, nil) == 0 else {
        throw TimestampError.notAvailable
      }
      return Int(tv.tv_sec)
    #else
      throw TimestampError.notAvailable
    #endif
  }

  public enum TimestampError: Error {
    case notAvailable
  }
}
