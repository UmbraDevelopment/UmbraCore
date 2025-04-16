import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

/// Crypto Format Utilities
///
/// This utility handles the packaging and parsing of encrypted data.
/// It provides a consistent format for storing encrypted data with
/// metadata such as IV, version, and authentication tags.
///
/// The format is designed to be both forwards and backwards compatible.
public enum CryptoFormat: Sendable {
  /// The current version of the crypto format
  public static let formatVersion: UInt8 = 1

  /// Format magic bytes for identification
  private static let magicBytes: [UInt8] = [0x55, 0x4D, 0x42, 0x52] // "UMBR" in hex

  /// Header size in bytes (magic + version)
  private static let headerSize = 5

  /// Size of IV in bytes (16 bytes / 128 bits)
  private static let ivSize = 16

  /// Size of GCM tag in bytes (16 bytes / 128 bits)
  private static let gcmTagSize = 16

  /// Unpackage encrypted data into its components.
  ///
  /// - Parameter packagedData: The packaged data to parse
  /// - Returns: A tuple containing the IV, ciphertext, and optional tag
  /// - Throws: SecurityStorageError if the data is invalid
  public static func unpackageEncryptedData(_ packagedData: [UInt8]) throws -> (iv: [UInt8], ciphertext: [UInt8], tag: [UInt8]?) {
    // Validate minimum size (header + iv)
    if packagedData.count < headerSize + ivSize {
      throw SecurityStorageError.invalidInput("Invalid data format: data too short")
    }
    
    // Validate magic bytes
    for i in 0..<4 {
      if packagedData[i] != magicBytes[i] {
        throw SecurityStorageError.invalidInput("Invalid data format: magic bytes mismatch")
      }
    }
    
    // Check version
    let version = packagedData[4]
    if version > formatVersion {
      throw SecurityStorageError.generalError(reason: "Unsupported data format version: \(version)")
    }
    
    // Extract IV
    let iv = Array(packagedData[headerSize..<headerSize + ivSize])
    
    // Determine if we have a tag (GCM mode)
    let hasTag = (packagedData.count >= headerSize + ivSize + gcmTagSize + 1)
    
    // Extract tag and ciphertext based on format
    if hasTag {
      let tagOffset = packagedData.count - gcmTagSize
      let tag = Array(packagedData[tagOffset..<packagedData.count])
      let ciphertext = Array(packagedData[headerSize + ivSize..<tagOffset])
      return (iv, ciphertext, tag)
    } else {
      // No tag (CBC mode)
      let ciphertext = Array(packagedData[headerSize + ivSize..<packagedData.count])
      return (iv, ciphertext, nil)
    }
  }
  
  /// Package encrypted data with IV and optional tag.
  ///
  /// - Parameters:
  ///   - iv: The initialisation vector
  ///   - ciphertext: The encrypted data
  ///   - tag: The authentication tag (for authenticated encryption)
  /// - Returns: Packaged data with format header
  public static func packageEncryptedData(
    iv: [UInt8],
    ciphertext: [UInt8],
    tag: [UInt8]? = nil
  ) -> [UInt8] {
    // Create the header
    var packagedData = [UInt8]()
    
    // Add magic bytes
    packagedData.append(contentsOf: magicBytes)
    
    // Add format version
    packagedData.append(formatVersion)
    
    // Add IV
    packagedData.append(contentsOf: iv)
    
    // Add ciphertext
    packagedData.append(contentsOf: ciphertext)
    
    // Add tag if present
    if let tag = tag {
      packagedData.append(contentsOf: tag)
    }
    
    return packagedData
  }
  
  /// Determine if the data is in the standard format.
  ///
  /// - Parameter data: The data to check
  /// - Returns: Whether the data is in the standard format
  public static func isStandardFormat(_ data: [UInt8]) -> Bool {
    // Check if the data has at least a header
    if data.count < headerSize {
      return false
    }
    
    // Check magic bytes
    for i in 0..<4 {
      if data[i] != magicBytes[i] {
        return false
      }
    }
    
    return true
  }
  
  /// Get the algorithm string based on format.
  ///
  /// - Parameter hasTag: Whether the format includes a tag
  /// - Returns: The corresponding algorithm as a string
  private static func getAlgorithmFromFormat(hasTag: Bool) -> String {
    hasTag ? "AES-256-GCM" : "AES-256-CBC"
  }
  
  /// Create a standard security result from encrypted data components.
  ///
  /// - Parameters:
  ///   - iv: The initialisation vector
  ///   - ciphertext: The encrypted data
  ///   - tag: The authentication tag (for GCM mode)
  /// - Returns: A SecurityResultDTO containing the packaged data
  public static func createSecurityResult(
    iv: [UInt8],
    ciphertext: [UInt8],
    tag: [UInt8]? = nil
  ) -> SecurityResultDTO {
    // Package the data in the standard format
    let packagedData = packageEncryptedData(
      iv: iv,
      ciphertext: ciphertext,
      tag: tag
    )

    // Create metadata for the result
    let metadata: [String: String] = [
      "algorithm": getAlgorithmFromFormat(hasTag: tag != nil),
      "format": "standard"
    ]

    // Create a successful result with the packaged data
    return SecurityResultDTO.success(
      resultData: Data(packagedData),
      executionTimeMs: 0,  // No timing information available in this context
      metadata: metadata
    )
  }

  /// Create a standard security result from encrypted data components.
  ///
  /// - Parameters:
  ///   - iv: The initialisation vector as Data
  ///   - ciphertext: The encrypted data as Data
  ///   - tag: The authentication tag as Data (for GCM mode)
  /// - Returns: A SecurityResultDTO containing the packaged data
  public static func createSecurityResult(
    iv: Data,
    ciphertext: Data,
    tag: Data? = nil
  ) -> SecurityResultDTO {
    createSecurityResult(
      iv: [UInt8](iv),
      ciphertext: [UInt8](ciphertext),
      tag: tag.map { [UInt8]($0) }
    )
  }
}
