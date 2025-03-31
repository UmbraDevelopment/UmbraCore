import CryptoTypes
import DomainSecurityTypes
import Foundation

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
public enum CryptoFormat {
  /// The current version of the crypto format
  public static let formatVersion: UInt8=1

  /// Format magic bytes for identification
  private static let magicBytes: [UInt8]=[0x55, 0x4D, 0x42, 0x52] // "UMBR" in hex

  /// Standard IV size for AES-GCM in bytes
  public static let ivSize=12

  /// Standard GCM authentication tag size in bytes
  public static let tagSize=16

  /// Header size for encrypted data (magic + version + reserved)
  private static let headerSize=8 // 4 (magic) + 1 (version) + 3 (reserved)

  /**
   Package encrypted data with metadata in the standard format.

   Format structure:
   - 4 bytes: Magic value "UMBR"
   - 1 byte: Format version
   - 3 bytes: Reserved for future use
   - 12 bytes: Initialisation vector
   - N bytes: Ciphertext
   - 16 bytes: Authentication tag (if GCM)

   - Parameters:
      - iv: The initialisation vector used for encryption
      - ciphertext: The encrypted data
      - tag: The authentication tag (for GCM mode)
   - Returns: Packaged data in the standard format
   */
  public static func packageEncryptedData(
    iv: [UInt8],
    ciphertext: [UInt8],
    tag: [UInt8]?=nil
  ) -> [UInt8] {
    var result=[UInt8]()

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

   - Parameter data: The packaged encrypted data
   - Returns: Tuple containing IV, ciphertext, and optional tag, or nil if format is invalid
   */
  public static func unpackEncryptedData(data: [UInt8])
  -> (iv: [UInt8], ciphertext: [UInt8], tag: [UInt8]?)? {
    // Check minimum size
    let minSize=headerSize + ivSize
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
    let version=data[4]
    guard version == formatVersion else {
      return nil
    }

    // Extract IV
    let ivStart=headerSize
    let ivEnd=ivStart + ivSize
    let iv=Array(data[ivStart..<ivEnd])

    // If we have enough data for a tag, extract it and the ciphertext separately
    if data.count >= ivEnd + tagSize {
      let ciphertextStart=ivEnd
      let ciphertextEnd=data.count - tagSize
      let tagStart=ciphertextEnd

      let ciphertext=Array(data[ciphertextStart..<ciphertextEnd])
      let tag=Array(data[tagStart..<data.count])

      return (iv, ciphertext, tag)
    } else {
      // No tag, just ciphertext
      let ciphertext=Array(data[ivEnd..<data.count])
      return (iv, ciphertext, nil)
    }
  }

  /**
   Package an encrypted SecureBytes instance.

   This is a convenience method that works with SecureBytes instead of raw byte arrays.

   - Parameters:
      - iv: The initialisation vector
      - ciphertext: The encrypted data
      - tag: The authentication tag (optional)
   - Returns: Packaged data as SecureBytes
   */
  public static func packageSecureBytes(
    iv: SecureBytes,
    ciphertext: SecureBytes,
    tag: SecureBytes?=nil
  ) -> SecureBytes {
    let ivBytes=iv.bytes()
    let ciphertextBytes=ciphertext.bytes()
    let tagBytes=tag?.bytes()

    let packaged=packageEncryptedData(
      iv: ivBytes,
      ciphertext: ciphertextBytes,
      tag: tagBytes
    )

    return SecureBytes(bytes: packaged)
  }

  /**
   Unpack an encrypted SecureBytes instance.

   This is a convenience method that works with SecureBytes instead of raw byte arrays.

   - Parameter data: The packaged encrypted data as SecureBytes
   - Returns: Tuple containing IV, ciphertext, and optional tag as SecureBytes, or nil if format is invalid
   */
  public static func unpackSecureBytes(data: SecureBytes)
  -> (iv: SecureBytes, ciphertext: SecureBytes, tag: SecureBytes?)? {
    let dataBytes=data.bytes()

    guard let unpacked=unpackEncryptedData(data: dataBytes) else {
      return nil
    }

    let iv=SecureBytes(bytes: unpacked.iv)
    let ciphertext=SecureBytes(bytes: unpacked.ciphertext)
    let tag=unpacked.tag.map { SecureBytes(bytes: $0) }

    return (iv, ciphertext, tag)
  }
}
