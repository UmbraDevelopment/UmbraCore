import Foundation

/**
 Defines types of security keys used in the system.
 
 This enumeration represents the different types of cryptographic keys
 that can be generated and managed by the security subsystem.
 */
public enum SecurityKeyType: String, Sendable, Codable, Equatable, CaseIterable {
    /// AES-128 encryption key
    case aes128 = "AES-128"
    
    /// AES-256 encryption key
    case aes256 = "AES-256"
    
    /// HMAC SHA-256 authentication key
    case hmacSHA256 = "HMAC-SHA256"
    
    /// Returns the key length in bytes
    public var keyLength: Int {
        switch self {
        case .aes128:
            return 16 // 128 bits = 16 bytes
        case .aes256:
            return 32 // 256 bits = 32 bytes
        case .hmacSHA256:
            return 32 // 256 bits = 32 bytes
        }
    }
    
    /// Returns a human-readable description of the key type
    public var localizedDescription: String {
        switch self {
        case .aes128:
            return "AES-128 Encryption Key"
        case .aes256:
            return "AES-256 Encryption Key"
        case .hmacSHA256:
            return "HMAC-SHA256 Authentication Key"
        }
    }
}
