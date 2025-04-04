import Foundation
import UmbraErrors
import SecurityCoreInterfaces
import DomainSecurityTypes
import CoreSecurityTypes
import SecurityKeyTypes

/**
 Protocol for generating cryptographic keys.
 
 This protocol defines the interface for key generation operations
 within the security subsystem.
 */
public protocol KeyGenerator: Sendable {
    /**
     Generates a new cryptographic key.
     
     - Returns: A new cryptographic key as a byte array
     - Throws: If key generation fails
     */
    func generateKey() async throws -> [UInt8]
}

/**
 # KeyManagementError
 
 Domain-specific error type for key management operations.
 
 This error type follows the Alpha Dot Five architecture standards:
 - Uses standardised error patterns
 - Provides detailed error information
 - Conforms to standard error protocols
 - Uses British spelling in documentation
 
 It provides a direct mapping to standard security error types
 while supporting additional contextual information.
 */
public enum KeyManagementError: Error, Sendable, Equatable {
    /// The key with the specified identifier was not found
    case keyNotFound(identifier: String)
    
    /// The input provided to the operation was invalid
    case invalidInput(details: String)
    
    /// A general key management error occurred
    case keyManagementError(details: String)
    
    /// Error converting between key formats
    case keyFormatError(details: String)
    
    /// Storage for the key failed
    case storageError(details: String)
    
    /// The key permission or access control failed
    case accessError(details: String)
    
    /// The key is not accessible due to security constraints
    case keyInaccessible(details: String)
}

// MARK: - Error Conversion

extension KeyManagementError {
    /**
     Converts to the standard error type.
     
     This allows for consistent error handling across modules while
     maintaining the rich domain-specific information.
     
     - Returns: The equivalent standard security error
     */
    public func toStandardError() -> SecurityProtocolError {
        switch self {
        case .keyNotFound(let identifier):
            return .operationFailed(reason: "Key not found: \(identifier)")
        case .invalidInput(let details):
            return .inputError("Invalid input: \(details)")
        case .keyManagementError(let details):
            return .operationFailed(reason: "Key management error: \(details)")
        case .keyFormatError(let details):
            return .invalidMessageFormat(details: "Invalid key format: \(details)")
        case .storageError(let details):
            return .operationFailed(reason: "Storage error: \(details)")
        case .accessError(let details):
            return .authenticationFailed(reason: "Access error: \(details)")
        case .keyInaccessible(let details):
            return .operationFailed(reason: "Key inaccessible: \(details)")
        }
    }
    
    /**
     Creates a KeyManagementError from a standard security error type.
     
     - Parameter standardError: The standard error to convert
     - Returns: The equivalent KeyManagementError
     */
    public static func fromStandardError(_ standardError: SecurityProtocolError) -> KeyManagementError {
        switch standardError {
        case .inputError(let message):
            return .invalidInput(details: message)
        case .invalidMessageFormat(let details):
            return .keyFormatError(details: details)
        case .authenticationFailed(let reason):
            return .accessError(details: reason)
        case .operationFailed(let reason):
            if reason.contains("Key not found") {
                let idParts = reason.components(separatedBy: "Key not found: ")
                let identifier = idParts.count > 1 ? idParts[1] : "unknown"
                return .keyNotFound(identifier: identifier)
            } else if reason.contains("Storage error") {
                return .storageError(details: reason)
            } else if reason.contains("Key inaccessible") {
                return .keyInaccessible(details: reason)
            } else {
                return .keyManagementError(details: reason)
            }
        default:
            return .keyManagementError(details: standardError.localizedDescription)
        }
    }
}

// MARK: - Protocol Extensions

/**
 Extension for DefaultKeyGenerator
 */
public struct DefaultKeyGenerator: KeyGenerator {
    /**
     Initialises a new DefaultKeyGenerator
     */
    public init() {}
    
    /**
     Generates a new cryptographic key using secure random bytes
     
     - Returns: A new cryptographic key as a byte array
     - Throws: If key generation fails
     */
    public func generateKey() async throws -> [UInt8] {
        // Generate a 32-byte (256-bit) key
        var keyData = [UInt8](repeating: 0, count: 32)
        
        // Use a secure random number generator
        let status = SecRandomCopyBytes(kSecRandomDefault, keyData.count, &keyData)
        
        if status != errSecSuccess {
            throw KeyManagementError.keyManagementError(details: "Failed to generate secure random bytes")
        }
        
        return keyData
    }
}
