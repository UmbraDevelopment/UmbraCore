import Foundation
import UmbraErrors
import CoreSecurityTypes

/**
 # KeyMetadataError
 
 Represents errors that can occur during key metadata operations.
 These errors provide detailed information about what went wrong during
 key metadata creation, storage, retrieval, or manipulation operations.
 
 Each error case includes detailed information to aid in diagnosis and resolution.
 */
public enum KeyMetadataError: Error, Sendable, Equatable {
    /// The key was not found with the specified identifier
    case keyNotFound(identifier: String)
    
    /// The key already exists with the specified identifier
    case keyAlreadyExists(identifier: String)
    
    /// The key data is invalid or corrupted
    case invalidKeyData(details: String)
    
    /// The key storage operation failed
    case keyStorageError(details: String)
    
    /// The key metadata storage operation failed
    case metadataError(details: String)
    
    /// A general key management error
    case keyManagementError(details: String)
    
    /**
     Converts this domain-specific error to a standardised SecurityProtocolError.
     
     - Returns: The equivalent SecurityProtocolError
     */
    public func toStandardError() -> SecurityProtocolError {
        switch self {
        case .keyNotFound(let identifier):
            return .operationFailed("Key not found: \(identifier)")
        case .keyAlreadyExists(let identifier):
            return .operationFailed("Key already exists: \(identifier)")
        case .invalidKeyData(let details):
            return .operationFailed("Invalid key data: \(details)")
        case .keyStorageError(let details), .metadataError(let details), .keyManagementError(let details):
            return .operationFailed(reason: details)
        }
    }
}
