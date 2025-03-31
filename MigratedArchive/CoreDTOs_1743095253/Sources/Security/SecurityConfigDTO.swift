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

  /// Options dictionary for algorithm-specific parameters
  public let options: [String: String]

  /// Input data for the security operation
  public let inputData: [UInt8]?

  // MARK: - Initializers

  /// Initialize a security configuration
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

  /// Create a new instance with input data from SecureBytes
  /// - Parameter data: The SecureBytes input data to use
  /// - Returns: A new SecurityConfigDTO with the specified input data
  public func withInputData(_ data: SecureBytes) -> SecurityConfigDTO {
    var bytes=[UInt8]()
    for i in 0..<data.count {
      bytes.append(data[i])
    }
    return withInputData(bytes)
  }

  /// Create a new instance with a key stored in the options
  /// - Parameter key: The key as SecureBytes
  /// - Returns: A new SecurityConfigDTO with the key stored in options
  public func withKey(_ key: SecureBytes) -> SecurityConfigDTO {
    var bytes=[UInt8]()
    for i in 0..<key.count {
      bytes.append(key[i])
    }

    // Store the key in the options as a Base64 encoded string
    let base64Key=encodeBase64(bytes)

    return withOptions(["key": base64Key])
  }

  // Helper method to Base64 encode bytes without Foundation
  private func encodeBase64(_ bytes: [UInt8]) -> String {
    let base64Chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    var result=""

    var i=0
    while i < bytes.count {
      let remaining=bytes.count - i

      // Process 3 bytes at a time, or whatever remains
      let byte1=bytes[i]
      let byte2=remaining > 1 ? bytes[i + 1] : 0
      let byte3=remaining > 2 ? bytes[i + 2] : 0

      // Extract 4 6-bit values
      let char1=byte1 >> 2
      let char2=((byte1 & 0x3) << 4) | (byte2 >> 4)
      let char3=remaining > 1 ? ((byte2 & 0xF) << 2) | (byte3 >> 6) : 64 // 64 = padding
      let char4=remaining > 2 ? byte3 & 0x3F : 64 // 64 = padding

      // Map to Base64 characters
      result.append(base64Chars[String.Index(utf16Offset: Int(char1), in: base64Chars)])
      result.append(base64Chars[String.Index(utf16Offset: Int(char2), in: base64Chars)])

      if char3 != 64 {
        result.append(base64Chars[String.Index(utf16Offset: Int(char3), in: base64Chars)])
      } else {
        result.append("=")
      }

      if char4 != 64 {
        result.append(base64Chars[String.Index(utf16Offset: Int(char4), in: base64Chars)])
      } else {
        result.append("=")
      }

      i += 3
    }

    return result
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
