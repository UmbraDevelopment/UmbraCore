import Foundation

/**
 Padding modes for cryptographic operations.
 
 This enum defines the various padding modes that can be used with block ciphers
 in cryptographic operations. Different padding modes are appropriate for different
 use cases and security requirements.
 */
public enum PaddingMode: String, Sendable, Codable, CaseIterable {
    /// PKCS#7 padding (RFC 5652)
    case pkcs7
    
    /// No padding (data must be a multiple of the block size)
    case none
    
    /// Zero padding (pad with zeros)
    case zero
    
    /// ANSI X.923 padding (zeros with the last byte indicating the padding length)
    case ansiX923
    
    /// ISO/IEC 7816-4 padding (0x80 followed by zeros)
    case iso7816_4
}
