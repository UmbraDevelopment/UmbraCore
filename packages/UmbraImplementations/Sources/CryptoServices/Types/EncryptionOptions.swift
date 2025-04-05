import CoreSecurityTypes
import CryptoTypes
import Foundation

/// Defines the algorithms available for encryption operations
public enum EncryptionAlgorithm: String, Sendable, Equatable, CaseIterable {
  /// AES 256-bit in CBC (Cipher Block Chaining) mode
  case aes256CBC

  /// AES 256-bit in GCM (Galois/Counter Mode) for authenticated encryption
  case aes256GCM
}

/**
 Options for encryption operations in the crypto services.
 
 These options control the algorithm, mode, and additional parameters used for encryption.
 */
public struct EncryptionOptions: Sendable {
  /// The encryption algorithm to use
  public let algorithm: CoreSecurityTypes.EncryptionAlgorithm
  
  /// Optional authenticated data for authenticated encryption modes
  public let authenticatedData: [UInt8]?
  
  /// Padding mode to use for block ciphers
  public let padding: PaddingMode?
  
  /**
   Creates a new instance with the specified options
   
   - Parameters:
     - algorithm: The encryption algorithm to use
     - authenticatedData: Optional authenticated data for authenticated modes
     - padding: Optional padding mode to use
   */
  public init(
    algorithm: CoreSecurityTypes.EncryptionAlgorithm = .aes256CBC,
    authenticatedData: [UInt8]?=nil,
    padding: PaddingMode? = .pkcs7
  ) {
    self.algorithm=algorithm
    self.authenticatedData=authenticatedData
    self.padding=padding
  }
}
