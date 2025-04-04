import CoreSecurityTypes
import Foundation

/**
 Configuration options for the CryptoService implementation.
 
 These options control general behaviour of the crypto service and cryptographic parameters.
 */
public struct CryptoServiceOptions: Sendable, Equatable {
    /// Whether to log operations (for debugging only)
    public let enableLogging: Bool
    
    /// Default iteration count for PBKDF2 key derivation
    public let defaultIterations: Int
    
    /// Preferred key size for AES encryption in bytes
    public let preferredKeySize: Int
    
    /// Size of initialisation vector in bytes
    public let ivSize: Int
    
    /// Creates a new CryptoServiceOptions instance with the specified parameters
    ///
    /// - Parameters:
    ///   - enableLogging: Whether to log operations (defaults to false)
    ///   - defaultIterations: Iteration count for PBKDF2 (default: 10000)
    ///   - preferredKeySize: Preferred key size in bytes (default: 32 for AES-256)
    ///   - ivSize: Size of initialisation vector in bytes (default: 12)
    public init(
        enableLogging: Bool = false,
        defaultIterations: Int = 10000,
        preferredKeySize: Int = 32,
        ivSize: Int = 12
    ) {
        self.enableLogging = enableLogging
        self.defaultIterations = defaultIterations
        self.preferredKeySize = preferredKeySize
        self.ivSize = ivSize
    }
    
    /// Default options suitable for most applications
    public static let `default` = CryptoServiceOptions()
    
    /// High security options with increased iteration count
    public static let highSecurity = CryptoServiceOptions(
        enableLogging: false,
        defaultIterations: 100_000,
        preferredKeySize: 32,
        ivSize: 16
    )
}
