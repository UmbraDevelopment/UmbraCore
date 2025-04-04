import Foundation
import UmbraErrors
import SecurityCoreInterfaces
import DomainSecurityTypes
import CoreSecurityTypes

/**
 # KeyManagementError
 
 Domain-specific error type for key management operations.
 
 This error type follows the Alpha Dot Five architecture standards:
 - Uses standardised error patterns
 - Provides detailed error information
 - Conforms to standard error protocols
 - Uses British spelling in documentation
 
 It provides a direct mapping to UmbraErrors.Security.KeyManagement
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
     Converts to the standard UmbraErrors type.
     
     This allows for consistent error handling across modules while
     maintaining the rich domain-specific information.
     
     - Returns: The equivalent UmbraErrors.Security.KeyManagement error
     */
    public func toStandardError() -> UmbraErrors.Security.KeyManagement {
        switch self {
        case .keyNotFound(let identifier):
            return .keyNotFound(identifier: identifier)
        case .invalidInput(let details):
            return .invalidInput(details: details)
        case .keyManagementError(let details):
            return .generalError(details: details)
        case .keyFormatError(let details):
            return .keyFormatError(details: details)
        case .storageError(let details):
            return .storageError(details: details)
        case .accessError(let details):
            return .accessError(details: details)
        case .keyInaccessible(let details):
            return .keyInaccessible(details: details)
        }
    }
    
    /**
     Creates a KeyManagementError from a standard UmbraErrors type.
     
     - Parameter standardError: The standard error to convert
     - Returns: The equivalent KeyManagementError
     */
    public static func fromStandardError(_ standardError: UmbraErrors.Security.KeyManagement) -> KeyManagementError {
        switch standardError {
        case .keyNotFound(let identifier):
            return .keyNotFound(identifier: identifier)
        case .invalidInput(let details):
            return .invalidInput(details: details)
        case .generalError(let details):
            return .keyManagementError(details: details)
        case .keyFormatError(let details):
            return .keyFormatError(details: details)
        case .storageError(let details):
            return .storageError(details: details)
        case .accessError(let details):
            return .accessError(details: details)
        case .keyInaccessible(let details):
            return .keyInaccessible(details: details)
        }
    }
}

// MARK: - Protocol Extensions

/**
 Extension to make DefaultKeyGenerator initialiser public
 */
extension KeyGenerator where Self == DefaultKeyGenerator {
    /**
     Creates a new default key generator instance
     
     This factory method allows using DefaultKeyGenerator in public APIs
     and default parameter values.
     */
    public static func createDefault() -> DefaultKeyGenerator {
        return DefaultKeyGenerator()
    }
}

/**
 Protocol extension for KeyStorage to ensure interface compliance
 */
public extension KeyStorage {
    /**
     Gets all key identifiers stored in this key storage
     
     - Returns: An array of string identifiers
     - Throws: If retrieval fails
     */
    func getAllIdentifiers() async throws -> [String] {
        var identifiers: [String] = []
        let keys = try await getAllKeys()
        for (identifier, _) in keys {
            identifiers.append(identifier)
        }
        return identifiers
    }
    
    /**
     Gets all keys with their identifiers
     
     - Returns: A dictionary mapping identifiers to keys
     - Throws: If retrieval fails
     */
    func getAllKeys() async throws -> [String: [UInt8]] {
        // Default implementation, can be overridden by concrete types
        // This is a potentially expensive operation that should be optimised
        // in production implementations
        var result: [String: [UInt8]] = [:]
        
        // This is a placeholder implementation and would need to be
        // implemented properly in concrete types
        return result
    }
}

// MARK: - Error Mapping

/**
 Maps between KeyManagementError and SecurityProtocolError
 
 This enables the KeyManagementActor to conform to the KeyManagementProtocol
 while using domain-specific error types internally.
 */
public extension Result where Failure == KeyManagementError {
    /**
     Converts a Result with KeyManagementError to one with SecurityProtocolError
     
     - Returns: A new Result with the mapped error type
     */
    func mapToProtocolError() -> Result<Success, SecurityProtocolError> {
        self.mapError { error in
            switch error {
            case .keyNotFound(let identifier):
                return SecurityProtocolError.keyNotFound(identifier: identifier)
            case .invalidInput(let details):
                return SecurityProtocolError.invalidInput(details: details)
            case .keyManagementError(let details):
                return SecurityProtocolError.generalError(details: details)
            case .keyFormatError(let details):
                return SecurityProtocolError.formatError(details: details)
            case .storageError(let details):
                return SecurityProtocolError.storageError(details: details)
            case .accessError(let details):
                return SecurityProtocolError.accessError(details: details)
            case .keyInaccessible(let details):
                return SecurityProtocolError.generalError(details: "Key inaccessible: \(details)")
            }
        }
    }
}

public extension Result where Failure == SecurityProtocolError {
    /**
     Converts a Result with SecurityProtocolError to one with KeyManagementError
     
     - Returns: A new Result with the mapped error type
     */
    func mapToKeyManagementError() -> Result<Success, KeyManagementError> {
        self.mapError { error in
            switch error {
            case .keyNotFound(let identifier):
                return KeyManagementError.keyNotFound(identifier: identifier)
            case .invalidInput(let details):
                return KeyManagementError.invalidInput(details: details)
            case .generalError(let details):
                return KeyManagementError.keyManagementError(details: details)
            case .formatError(let details):
                return KeyManagementError.keyFormatError(details: details)
            case .storageError(let details):
                return KeyManagementError.storageError(details: details)
            case .accessError(let details):
                return KeyManagementError.accessError(details: details)
            }
        }
    }
}
