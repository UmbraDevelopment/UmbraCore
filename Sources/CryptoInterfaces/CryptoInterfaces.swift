import Foundation
import UmbraCoreTypes

/// Protocol that defines cryptographic operations while maintaining independence from specific implementations.
/// This acts as a bridge between CryptoSwift and foundation-independent implementations.
public protocol CryptoOperationProvider {
    /// Create a secure byte array from the given data
    /// - Parameter data: The data to convert
    /// - Returns: Secure bytes
    func createSecureBytes(from data: Data) -> SecureBytes
    
    /// Generate a random secure byte array of the specified length
    /// - Parameter length: The length of the secure byte array to generate
    /// - Returns: Secure bytes containing random data
    func generateRandomSecureBytes(length: Int) -> SecureBytes
    
    /// Hash the provided bytes using the specified algorithm
    /// - Parameters:
    ///   - bytes: The bytes to hash
    ///   - algorithm: The hashing algorithm to use
    /// - Returns: The resulting hash as secure bytes
    func hashBytes(_ bytes: SecureBytes, algorithm: String) -> SecureBytes
}

/// Common cryptographic operation types that can be shared across implementation boundaries
public enum CryptoOperation {
    case hash
    case encrypt
    case decrypt
    case sign
    case verify
}

/// Status of a cryptographic operation
public enum CryptoOperationStatus {
    case success
    case failure(reason: String)
    case unsupported
}
