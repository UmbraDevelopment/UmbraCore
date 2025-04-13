import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

/**
 # Crypto Format Utilities

 This component defines standardised formats for encrypted data in the UmbraCore system.
 It provides utilities for packaging and unpacking encrypted data with metadata such as:
 - Initialisation vectors (IVs)
 - Authentication tags
 - Format version information

 By using these standardised formats, we ensure data encrypted by one component can be
 properly decrypted by another, even across process boundaries or persistence.
 */
public enum CryptoFormat: Sendable {
  /// The current version of the crypto format
  public static let formatVersion: UInt8 = 1

  /// Format magic bytes for identification
  private static let magicBytes: [UInt8] = [0x55, 0x4D, 0x42, 0x52] // "UMBR" in hex

  /// Standard IV size for AES-GCM in bytes
  public static let ivSize = 12

  /// Standard GCM authentication tag size in bytes
  public static let tagSize = 16

  /// Header size for encrypted data (magic + version + reserved)
  private static let headerSize = 8 // 4 (magic) + 1 (version) + 3 (reserved)

  /**
   Package encrypted data with metadata in the standard format.

   - Parameters:
      - iv: The initialisation vector used for encryption
      - ciphertext: The encrypted data
      - tag: The authentication tag (for GCM mode)
   - Returns: Packaged data in the standard format
   */
  public static func packageEncryptedData(
    iv: [UInt8],
    ciphertext: [UInt8],
    tag: [UInt8]? = nil
  ) -> [UInt8] {
    var result = [UInt8]()

    // Add header
    result.append(contentsOf: magicBytes)
    result.append(formatVersion)
    result.append(contentsOf: [0, 0, 0]) // Reserved

    // Add IV
    result.append(contentsOf: iv)

    // Add ciphertext
    result.append(contentsOf: ciphertext)

    // Add tag if present
    if let tag {
      result.append(contentsOf: tag)
    }

    return result
  }

  /**
   Unpack encrypted data from the standard format.

   - Parameter data: Packaged data in the standard format
   - Returns: Tuple containing IV, ciphertext, and optional tag, or nil if format is invalid
   */
  public static func unpackEncryptedData(
    data: [UInt8]
  ) -> (iv: [UInt8], ciphertext: [UInt8], tag: [UInt8]?)? {
    // Check minimum size
    let minSize = headerSize + ivSize
    guard data.count > minSize else {
      return nil
    }

    // Verify magic bytes
    for i in 0..<magicBytes.count {
      guard data[i] == magicBytes[i] else {
        return nil
      }
    }

    // Verify version
    let version = data[4]
    guard version == formatVersion else {
      return nil
    }

    // Extract IV
    let ivStart = headerSize
    let ivEnd = ivStart + ivSize
    let iv = Array(data[ivStart..<ivEnd])

    // If we have enough data for a tag, extract it and the ciphertext separately
    if data.count >= ivEnd + tagSize {
      let ciphertextStart = ivEnd
      let ciphertextEnd = data.count - tagSize
      let tagStart = ciphertextEnd

      let ciphertext = Array(data[ciphertextStart..<ciphertextEnd])
      let tag = Array(data[tagStart..<data.count])

      return (iv, ciphertext, tag)
    } else {
      // No tag, just ciphertext
      let ciphertext = Array(data[ivEnd..<data.count])
      return (iv, ciphertext, nil)
    }
  }

  /**
   Package encrypted data in secure format.

   - Parameters:
      - iv: The initialisation vector
      - ciphertext: The encrypted data
      - tag: The authentication tag (optional)
   - Returns: Packaged data as Data
   */
  public static func packageSecureData(
    iv: Data,
    ciphertext: Data,
    tag: Data? = nil
  ) -> Data {
    let ivBytes = [UInt8](iv)
    let ciphertextBytes = [UInt8](ciphertext)
    let tagBytes = tag.map { [UInt8]($0) }

    let packaged = packageEncryptedData(
      iv: ivBytes,
      ciphertext: ciphertextBytes,
      tag: tagBytes
    )

    return Data(packaged)
  }

  /**
   Unpack encrypted data from secure format.

   - Parameter data: The packaged encrypted data
   - Returns: Tuple containing IV, ciphertext, and optional tag as Data, or nil if format is invalid
   */
  public static func unpackSecureData(
    data: Data
  ) -> (iv: Data, ciphertext: Data, tag: Data?)? {
    let dataBytes = [UInt8](data)

    guard let unpacked = unpackEncryptedData(data: dataBytes) else {
      return nil
    }

    let iv = Data(unpacked.iv)
    let ciphertext = Data(unpacked.ciphertext)
    let tag = unpacked.tag.map { Data($0) }

    return (iv, ciphertext, tag)
  }
  
  /**
   Convert encrypted data to a format suitable for storage with metadata.
   
   - Parameters:
     - algorithm: The encryption algorithm used
     - iv: The initialisation vector
     - ciphertext: The encrypted data
     - tag: The authentication tag (if applicable)
   - Returns: A SecurityResultDTO containing the formatted data and metadata
   */
  public static func formatEncryptedDataForStorage(
    algorithm: EncryptionAlgorithm,
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
    
    // Create metadata
    var metadata = [String: String]()
    metadata["algorithm"] = algorithm.rawValue
    metadata["version"] = String(formatVersion)
    metadata["ivSize"] = String(iv.count)
    if let tag = tag {
      metadata["tagSize"] = String(tag.count)
    }
    
    // Create result using the success factory method with proper parameters
    return SecurityResultDTO.success(
      resultData: Data(packagedData),
      executionTimeMs: 0,  // No actual execution time available for this utility function
      metadata: metadata
    )
  }
  
  /**
   Extract encrypted data components from a stored format.
   
   - Parameter resultDTO: The SecurityResultDTO containing the encrypted data
   - Returns: Tuple containing algorithm, IV, ciphertext, and optional tag, or nil if format is invalid
   */
  public static func extractEncryptedDataFromStorage(
    resultDTO: SecurityResultDTO
  ) -> (algorithm: EncryptionAlgorithm, iv: [UInt8], ciphertext: [UInt8], tag: [UInt8]?)? {
    // Extract the algorithm
    guard let algorithmString = resultDTO.metadata?["algorithm"],
          let algorithm = EncryptionAlgorithm(rawValue: algorithmString) else {
      return nil
    }
    
    // Extract and decode the data
    guard let base64Data = resultDTO.resultData,
          let data = Data(base64Encoded: base64Data) else {
      return nil
    }
    
    // Unpack the data
    guard let unpacked = unpackEncryptedData(data: [UInt8](data)) else {
      return nil
    }
    
    return (algorithm, unpacked.iv, unpacked.ciphertext, unpacked.tag)
  }
}
