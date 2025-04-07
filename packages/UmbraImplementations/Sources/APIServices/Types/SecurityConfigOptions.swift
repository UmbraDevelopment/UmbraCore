import Foundation
import LoggingTypes
import APIInterfaces
import UmbraErrors

/// Configuration options for security operations in the API Services module
///
/// This type follows the Alpha Dot Five architecture principles of strong typing
/// and clear, explicit interfaces to support privacy by design.
public struct SecurityConfigOptions: Sendable, Equatable, Codable {
    /// Default encryption strength (256 bits)
    public static let defaultEncryptionStrength = 256
    
    /// Default options for most security operations
    public static let standard = SecurityConfigOptions()
    
    /// Encryption strength in bits (128, 192, 256)
    public let encryptionStrength: Int
    
    /// Whether to use authenticated encryption
    public let useAuthenticatedEncryption: Bool
    
    /// Whether to use hardware acceleration when available
    public let useHardwareAcceleration: Bool
    
    /// Password iteration count for key derivation
    public let iterationCount: Int
    
    /// Whether to use platform-specific cryptography implementations
    public let usePlatformCrypto: Bool
    
    /// Creates a new set of security configuration options
    ///
    /// - Parameters:
    ///   - encryptionStrength: Encryption strength in bits (128, 192, 256)
    ///   - useAuthenticatedEncryption: Whether to use authenticated encryption
    ///   - useHardwareAcceleration: Whether to use hardware acceleration when available
    ///   - iterationCount: Password iteration count for key derivation
    ///   - usePlatformCrypto: Whether to use platform-specific cryptography implementations
    public init(
        encryptionStrength: Int = defaultEncryptionStrength,
        useAuthenticatedEncryption: Bool = true,
        useHardwareAcceleration: Bool = true,
        iterationCount: Int = 10000,
        usePlatformCrypto: Bool = true
    ) {
        self.encryptionStrength = encryptionStrength
        self.useAuthenticatedEncryption = useAuthenticatedEncryption
        self.useHardwareAcceleration = useHardwareAcceleration
        self.iterationCount = iterationCount
        self.usePlatformCrypto = usePlatformCrypto
    }
}
