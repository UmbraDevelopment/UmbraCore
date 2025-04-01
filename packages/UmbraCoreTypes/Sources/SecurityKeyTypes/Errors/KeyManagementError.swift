import Foundation

/**
 Error type for key management operations.

 This error type follows the Alpha Dot Five architecture pattern for domain-specific errors
 with detailed information and proper Sendable conformance for actor isolation.
 */
public enum KeyManagementError: Error, Equatable, Sendable {
    /// Key not found with the specified identifier
    case keyNotFound(identifier: String)
    
    /// Key creation failed
    case keyCreationFailed(reason: String)
    
    /// Key storage failed
    case keyStorageFailed(reason: String)
    
    /// Invalid input provided to operation
    case invalidInput(details: String)
    
    /// Key rotation failed
    case keyRotationFailed(reason: String)
    
    /// Key management operation failed
    case keyManagementError(details: String)
    
    /// Creates a human-readable description of the error
    public var localizedDescription: String {
        switch self {
            case let .keyNotFound(identifier):
                "Key not found with identifier: \(identifier)"
            case let .keyCreationFailed(reason):
                "Key creation failed: \(reason)"
            case let .keyStorageFailed(reason):
                "Key storage failed: \(reason)"
            case let .invalidInput(details):
                "Invalid input: \(details)"
            case let .keyRotationFailed(reason):
                "Key rotation failed: \(reason)"
            case let .keyManagementError(details):
                "Key management error: \(details)"
        }
    }
    
    /// Returns an error code for this error
    public var errorCode: String {
        switch self {
            case .keyNotFound: "KM001"
            case .keyCreationFailed: "KM002"
            case .keyStorageFailed: "KM003"
            case .invalidInput: "KM004"
            case .keyRotationFailed: "KM005"
            case .keyManagementError: "KM006"
        }
    }
}
