/// Foundation-independent configuration for security operations.
/// This struct provides configuration options for various security operations
/// without using any Foundation types.
public struct SecurityConfigDTO: Sendable, Equatable {
  // MARK: - Configuration Properties

  /// The algorithm to use for the operation
  public let algorithm: String

  /// Key size in bits
  public let keySizeInBits: Int

  /// Options dictionary for algorithm-specific parameters
  public let options: [String: String]

  /// Input data for the security operation
  public let inputData: [UInt8]?

  // MARK: - Initializers

  /// Initialise a security configuration
  /// - Parameters:
  ///   - algorithm: The algorithm identifier (e.g., "AES-GCM", "RSA", "PBKDF2")
  ///   - keySizeInBits: Key size in bits
  ///   - options: Additional algorithm-specific options
  ///   - inputData: Optional input data for the operation
  public init(
    algorithm: String,
    keySizeInBits: Int,
    options: [String: String]=[:],
    inputData: [UInt8]?=nil
  ) {
    self.algorithm=algorithm
    self.keySizeInBits=keySizeInBits
    self.options=options
    self.inputData=inputData
  }

  /// Create a new instance with updated options
  /// - Parameter newOptions: Additional options to merge with existing ones
  /// - Returns: A new SecurityConfigDTO with updated options
  public func withOptions(_ newOptions: [String: String]) -> SecurityConfigDTO {
    var mergedOptions=options
    for (key, value) in newOptions {
      mergedOptions[key]=value
    }

    return SecurityConfigDTO(
      algorithm: algorithm,
      keySizeInBits: keySizeInBits,
      options: mergedOptions,
      inputData: inputData
    )
  }

  /// Create a new instance with input data
  /// - Parameter data: The input data to use
  /// - Returns: A new SecurityConfigDTO with the specified input data
  public func withInputData(_ data: [UInt8]) -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: algorithm,
      keySizeInBits: keySizeInBits,
      options: options,
      inputData: data
    )
  }

  /// Create a new instance with a key stored in the options
  /// - Parameter key: The key as a byte array
  /// - Returns: A new SecurityConfigDTO with the key stored in options
  public func withKey(_ key: [UInt8]) -> SecurityConfigDTO {
    // Store the key in the options as a Base64 encoded string
    let base64Key = encodeBase64(key)
    return withOptions(["key": base64Key])
  }

  /// Extract a key from options, if present
  /// - Returns: Key bytes if found and properly decoded, nil otherwise
  public func extractKey() -> [UInt8]? {
    guard let base64Key=options["key"] else {
      return nil
    }
    
    return decodeBase64(base64Key)
  }
  
  // MARK: - Private Methods
  
  /// Internal Base64 encoding implementation
  /// - Parameter bytes: Bytes to encode
  /// - Returns: Base64-encoded string
  private func encodeBase64(_ bytes: [UInt8]) -> String {
    let data = Data(bytes)
    return data.base64EncodedString()
  }
  
  /// Internal Base64 decoding implementation
  /// - Parameter base64String: String to decode
  /// - Returns: Decoded bytes or nil if invalid
  private func decodeBase64(_ base64String: String) -> [UInt8]? {
    guard let data = Data(base64Encoded: base64String) else {
      return nil
    }
    return [UInt8](data)
  }
}

// MARK: - Factory Methods

extension SecurityConfigDTO {
  /// Create a configuration for AES-GCM with 256-bit key
  /// - Returns: A SecurityConfigDTO configured for AES-GCM
  public static func aesGCM() -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: "AES-GCM",
      keySizeInBits: 256
    )
  }

  /// Create a configuration for RSA with 2048-bit key
  /// - Returns: A SecurityConfigDTO configured for RSA
  public static func rsa() -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: "RSA",
      keySizeInBits: 2048
    )
  }

  /// Create a configuration for PBKDF2 with SHA-256
  /// - Parameters:
  ///   - iterations: Number of iterations for key derivation
  /// - Returns: A SecurityConfigDTO configured for PBKDF2
  public static func pbkdf2(iterations: Int=10000) -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: "PBKDF2",
      keySizeInBits: 256,
      options: ["iterations": String(iterations), "hashAlgorithm": "SHA256"]
    )
  }
}

import CoreSecurityTypes
import DomainSecurityTypes
