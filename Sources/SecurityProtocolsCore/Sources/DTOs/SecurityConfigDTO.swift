import UmbraCoreTypes

/// FoundationIndependent configuration for security operations.
/// This struct provides configuration options for various security operations
/// without using any Foundation types.
public struct SecurityConfigDTO: Sendable, Equatable {
  // MARK: - Configuration Properties

  /// The algorithm to use for the operation
  public let algorithm: String

  /// Key size in bits
  public let keySizeInBits: Int

  /// Initialization vector or nonce if required
  public let initializationVector: SecureBytes?

  /// Additional authenticated data for AEAD ciphers
  public let additionalAuthenticatedData: SecureBytes?

  /// Iteration count for key derivation functions
  public let iterations: Int?

  /// Options dictionary for algorithm-specific parameters
  public let options: [String: String]

  /// Key identifier for retrieving keys from storage
  public let keyIdentifier: String?

  /// Input data for the security operation
  public let inputData: SecureBytes?

  /// Key used for operations (alternative to keyIdentifier)
  public let key: SecureBytes?

  /// Additional data for verification operations
  public let additionalData: SecureBytes?

  // MARK: - Initializers

  /// Full initializer with all configuration options
  /// - Parameters:
  ///   - algorithm: The algorithm identifier (e.g., "AES-GCM", "RSA", "PBKDF2")
  ///   - keySizeInBits: Key size in bits
  ///   - initializationVector: Optional initialization vector
  ///   - additionalAuthenticatedData: Optional AAD for AEAD ciphers
  ///   - iterations: Optional iteration count for KDFs
  ///   - options: Additional algorithm-specific options
  ///   - keyIdentifier: Optional key identifier for key retrieval
  ///   - inputData: Optional input data for the operation
  ///   - key: Optional key for the operation
  ///   - additionalData: Optional additional data for verification
  public init(
    algorithm: String,
    keySizeInBits: Int,
    initializationVector: SecureBytes?=nil,
    additionalAuthenticatedData: SecureBytes?=nil,
    iterations: Int?=nil,
    options: [String: String]=[:],
    keyIdentifier: String?=nil,
    inputData: SecureBytes?=nil,
    key: SecureBytes?=nil,
    additionalData: SecureBytes?=nil
  ) {
    self.algorithm=algorithm
    self.keySizeInBits=keySizeInBits
    self.initializationVector=initializationVector
    self.additionalAuthenticatedData=additionalAuthenticatedData
    self.iterations=iterations
    self.options=options
    self.keyIdentifier=keyIdentifier
    self.inputData=inputData
    self.key=key
    self.additionalData=additionalData
  }

  // MARK: - Factory Methods

  /// Create a configuration for AES-GCM symmetric encryption
  /// - Parameters:
  ///   - keySizeInBits: Key size in bits (128, 192, or 256)
  ///   - iv: Optional initialization vector (if nil, one will be generated)
  ///   - aad: Optional additional authenticated data
  /// - Returns: Configuration for AES-GCM
  public static func aesGCM(
    keySizeInBits: Int=256,
    iv: SecureBytes?=nil,
    aad: SecureBytes?=nil
  ) -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: "AES-GCM",
      keySizeInBits: keySizeInBits,
      initializationVector: iv,
      additionalAuthenticatedData: aad
    )
  }

  /// Create a configuration for RSA asymmetric encryption
  /// - Parameter keySizeInBits: Key size in bits (2048, 3072, or 4096)
  /// - Returns: Configuration for RSA
  public static func rsa(keySizeInBits: Int=2048) -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: "RSA",
      keySizeInBits: keySizeInBits
    )
  }

  /// Create a configuration for PBKDF2 key derivation
  /// - Parameters:
  ///   - iterations: Number of iterations
  ///   - outputKeySizeInBits: Size of the derived key in bits
  /// - Returns: Configuration for PBKDF2
  public static func pbkdf2(
    iterations: Int=10000,
    outputKeySizeInBits: Int=256
  ) -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: "PBKDF2",
      keySizeInBits: outputKeySizeInBits,
      iterations: iterations
    )
  }

  // MARK: - Builder Methods

  /// Add a key identifier to the configuration
  /// - Parameter identifier: The key identifier to use
  /// - Returns: A new configuration with the specified key identifier
  public func withKeyIdentifier(_ identifier: String) -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: algorithm,
      keySizeInBits: keySizeInBits,
      initializationVector: initializationVector,
      additionalAuthenticatedData: additionalAuthenticatedData,
      iterations: iterations,
      options: options,
      keyIdentifier: identifier,
      inputData: inputData,
      key: key,
      additionalData: additionalData
    )
  }

  /// Add input data to the configuration
  /// - Parameter data: The input data to use
  /// - Returns: A new configuration with the specified input data
  public func withInputData(_ data: SecureBytes) -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: algorithm,
      keySizeInBits: keySizeInBits,
      initializationVector: initializationVector,
      additionalAuthenticatedData: additionalAuthenticatedData,
      iterations: iterations,
      options: options,
      keyIdentifier: keyIdentifier,
      inputData: data,
      key: key,
      additionalData: additionalData
    )
  }

  /// Add a key to the configuration
  /// - Parameter key: The key to use
  /// - Returns: A new configuration with the specified key
  public func withKey(_ key: SecureBytes) -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: algorithm,
      keySizeInBits: keySizeInBits,
      initializationVector: initializationVector,
      additionalAuthenticatedData: additionalAuthenticatedData,
      iterations: iterations,
      options: options,
      keyIdentifier: keyIdentifier,
      inputData: inputData,
      key: key,
      additionalData: additionalData
    )
  }

  /// Add an initialization vector to the configuration
  /// - Parameter iv: The initialization vector to use
  /// - Returns: A new configuration with the specified initialization vector
  public func withInitializationVector(_ iv: SecureBytes) -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: algorithm,
      keySizeInBits: keySizeInBits,
      initializationVector: iv,
      additionalAuthenticatedData: additionalAuthenticatedData,
      iterations: iterations,
      options: options,
      keyIdentifier: keyIdentifier,
      inputData: inputData,
      key: key,
      additionalData: additionalData
    )
  }

  /// Add additional data to the configuration for verification operations
  /// - Parameter data: The additional data to use
  /// - Returns: A new configuration with the specified additional data
  public func withAdditionalData(_ data: SecureBytes) -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: algorithm,
      keySizeInBits: keySizeInBits,
      initializationVector: initializationVector,
      additionalAuthenticatedData: additionalAuthenticatedData,
      iterations: iterations,
      options: options,
      keyIdentifier: keyIdentifier,
      inputData: inputData,
      key: key,
      additionalData: data
    )
  }

  /// Add options to the configuration
  /// - Parameter options: The options to use
  /// - Returns: A new configuration with the specified options
  public func withOptions(_ options: [String: String]) -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: algorithm,
      keySizeInBits: keySizeInBits,
      initializationVector: initializationVector,
      additionalAuthenticatedData: additionalAuthenticatedData,
      iterations: iterations,
      options: options,
      keyIdentifier: keyIdentifier,
      inputData: inputData,
      key: key,
      additionalData: additionalData
    )
  }
}
