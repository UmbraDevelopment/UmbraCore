import Foundation

/**
 Defines the padding modes available for block cipher operations.
 
 Block ciphers operate on fixed-size blocks of data. Padding is needed
 when the data to be encrypted is not an exact multiple of the block size.
 */
public enum PaddingMode: String, Sendable, Equatable, CaseIterable {
  /// PKCS#7 padding (RFC 5652)
  case pkcs7
  
  /// No padding - data must be an exact multiple of the block size
  case none
  
  /// Zero padding - fill with zeros
  case zero
  
  /// Description of the padding mode
  public var description: String {
    switch self {
      case .pkcs7:
        return "PKCS#7 Padding"
      case .none:
        return "No Padding"
      case .zero:
        return "Zero Padding"
    }
  }
}
