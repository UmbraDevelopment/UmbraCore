import Foundation
import UmbraErrorsCore

/// Domain identifier for keychain-related errors
public enum KeychainErrorDomain: String, CaseIterable, Sendable {
    /// Domain identifier
    public static let domain = "Keychain"
    
    // Access errors
    case accessDenied = "ACCESS_DENIED"
    case itemNotFound = "ITEM_NOT_FOUND"
    case duplicateItem = "DUPLICATE_ITEM"
    
    // Input validation errors
    case invalidParameter = "INVALID_PARAMETER"
    case missingParameter = "MISSING_PARAMETER"
    case invalidData = "INVALID_DATA"
    
    // Operation errors
    case storeFailed = "STORE_FAILED"
    case retrieveFailed = "RETRIEVE_FAILED"
    case updateFailed = "UPDATE_FAILED"
    case deleteFailed = "DELETE_FAILED"
    
    // Encoding/decoding errors
    case encodingFailed = "ENCODING_FAILED"
    case decodingFailed = "DECODING_FAILED"
    
    // Security errors
    case securityViolation = "SECURITY_VIOLATION"
    case maxRetryExceeded = "MAX_RETRY_EXCEEDED"
    
    // System errors
    case systemError = "SYSTEM_ERROR"
    case serviceUnavailable = "SERVICE_UNAVAILABLE"
    case interactionNotAllowed = "INTERACTION_NOT_ALLOWED"
    case userCancelled = "USER_CANCELLED"
    
    // Miscellaneous
    case unspecified = "UNSPECIFIED"
}

/// Extension to add more functionality to the keychain error domain
extension KeychainErrorDomain {
    /// Map to a standard error severity
    public var defaultSeverity: ErrorSeverity {
        switch self {
        case .invalidParameter, .missingParameter, .invalidData, .userCancelled:
            return .warning
            
        case .itemNotFound, .duplicateItem:
            return .info
            
        case .storeFailed, .retrieveFailed, .updateFailed, .deleteFailed,
             .encodingFailed, .decodingFailed, .maxRetryExceeded:
            return .error
            
        case .accessDenied, .securityViolation, .systemError, .serviceUnavailable:
            return .critical
            
        default:
            return .error
        }
    }
    
    /// Get a user-friendly description of the error
    /// All descriptions use British English spelling
    public var localizedDescription: String {
        switch self {
        case .accessDenied:
            return "Access to the keychain was denied"
            
        case .itemNotFound:
            return "The requested item was not found in the keychain"
            
        case .duplicateItem:
            return "An item with this identifier already exists in the keychain"
            
        case .invalidParameter:
            return "One or more parameters provided to the keychain are invalid"
            
        case .missingParameter:
            return "A required parameter is missing for this keychain operation"
            
        case .invalidData:
            return "The data provided for this keychain operation is invalid"
            
        case .storeFailed:
            return "Failed to store the item in the keychain"
            
        case .retrieveFailed:
            return "Failed to retrieve the item from the keychain"
            
        case .updateFailed:
            return "Failed to update the item in the keychain"
            
        case .deleteFailed:
            return "Failed to delete the item from the keychain"
            
        case .encodingFailed:
            return "Failed to encode the data for keychain storage"
            
        case .decodingFailed:
            return "Failed to decode the data retrieved from the keychain"
            
        case .securityViolation:
            return "A security violation occurred during the keychain operation"
            
        case .maxRetryExceeded:
            return "Maximum retry attempts exceeded for the keychain operation"
            
        case .systemError:
            return "A system error occurred while accessing the keychain"
            
        case .serviceUnavailable:
            return "The keychain service is currently unavailable"
            
        case .interactionNotAllowed:
            return "User interaction is not allowed for this keychain operation"
            
        case .userCancelled:
            return "The keychain operation was cancelled by the user"
            
        case .unspecified:
            return "An unspecified keychain error occurred"
        }
    }
    
    /// Map from system keychain error codes to our domain errors
    /// - Parameter status: The OSStatus from a keychain operation
    /// - Returns: The appropriate KeychainErrorDomain case
    public static func fromOSStatus(_ status: OSStatus) -> KeychainErrorDomain {
        switch status {
        case errSecDuplicateItem:
            return .duplicateItem
        case errSecItemNotFound:
            return .itemNotFound
        case errSecAuthFailed:
            return .accessDenied
        case errSecDecode:
            return .decodingFailed
        case errSecParam:
            return .invalidParameter
        case errSecAllocate:
            return .systemError
        case errSecInteractionNotAllowed:
            return .interactionNotAllowed
        case errSecUserCanceled:
            return .userCancelled
        case errSecNotAvailable:
            return .serviceUnavailable
        default:
            return .unspecified
        }
    }
}
