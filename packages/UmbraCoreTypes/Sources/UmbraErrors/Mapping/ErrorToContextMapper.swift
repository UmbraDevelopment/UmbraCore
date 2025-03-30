import Foundation
import UmbraErrorsCore
import UmbraErrorsDomains

/**
 # ErrorToContextMapper
 
 A utility for mapping domain-specific errors to standardised error contexts 
 for consistent logging and reporting across the Umbra system.
 
 This follows the Alpha Dot Five architecture with:
 - Proper British spelling in documentation
 - Consistent domain-specific error treatment
 - Structured context information
 
 ## Usage Example
 
 ```swift
 // Convert a SecurityErrorDomain error to an ErrorContext
 let securityError = SecurityErrorDomain.encryptionFailed
 let context = ErrorToContextMapper.mapToContext(
     domainError: securityError,
     additionalInfo: ["keyId": "user-master-key"]
 )
 
 // Log with the context
 await errorLogger.logWithContext(error, context: context)
 ```
 */
public enum ErrorToContextMapper {
    /**
     Maps a domain-specific error to a standardised ErrorContext.
     
     - Parameters:
        - domainError: The domain-specific error enum case
        - additionalInfo: Optional dictionary of additional context information
        - severity: Optional override for the default severity
        
     - Returns: A populated ErrorContext with domain, operation, and details
     */
    public static func mapToContext<T: RawRepresentable>(
        domainError: T,
        additionalInfo: [String: String]? = nil,
        severity: ErrorSeverity? = nil
    ) -> ErrorContext where T.RawValue == String {
        // Get the domain from the error type if it's one of our domain types
        var domain = "Unknown"
        var defaultSeverity = ErrorSeverity.error
        var localizedDescription: String?
        
        // Handle known domain types
        if let securityError = domainError as? SecurityErrorDomain {
            domain = SecurityErrorDomain.domain
            defaultSeverity = securityError.defaultSeverity
            localizedDescription = securityError.localizedDescription
        } else if let keychainError = domainError as? KeychainErrorDomain {
            domain = KeychainErrorDomain.domain
            defaultSeverity = keychainError.defaultSeverity
            localizedDescription = keychainError.localizedDescription
        }
        // Note: Additional domain types like CryptoErrorDomain and RepositoryErrorDomain 
        // will be added in future updates as they become available
        
        // Create context dictionary
        var contextDict: [String: Any] = [
            "domain": domain,
            "code": String(describing: domainError.rawValue),
            "severity": severity ?? defaultSeverity
        ]
        
        // Add the localised description if available
        if let description = localizedDescription {
            contextDict["message"] = description
        } else {
            // Use a generic message based on the raw value
            contextDict["message"] = "Error occurred: \(domainError.rawValue)"
        }
        
        // Add any additional context information
        if let info = additionalInfo {
            for (key, value) in info {
                contextDict[key] = value
            }
        }
        
        // Create the ErrorContext with the prepared dictionary
        return ErrorContext(contextDict, 
                           source: domain, 
                           operation: "domain_error",
                           details: localizedDescription)
    }
    
    /**
     Maps a standard Error to an ErrorContext with best-effort domain detection.
     
     - Parameters:
        - error: Any Error type
        - additionalInfo: Optional dictionary of additional context information
        - severity: Optional override for the default severity
        
     - Returns: A populated ErrorContext
     */
    public static func mapToContext(
        error: Error,
        additionalInfo: [String: String]? = nil,
        severity: ErrorSeverity? = nil
    ) -> ErrorContext {
        // First check if it can be mapped to a specific domain error
        
        // Cast to enums for specific domain types will be extended
        // as more domain types become available
        
        // The enum types themselves need specific Error protocol conformance
        // before direct casting will succeed, but we can check for specific
        // enum types that conform to Error through protocol extension
        
        // Create the context dictionary
        var contextDict: [String: Any] = [:]
        
        // For NSError, try to extract common properties
        let nsError = error as NSError // This cast always succeeds
        contextDict["domain"] = nsError.domain
        contextDict["code"] = nsError.code
        contextDict["message"] = nsError.localizedDescription
        contextDict["severity"] = severity ?? ErrorSeverity.error
        
        // Add userInfo contents as details
        for (key, value) in nsError.userInfo {
            if let stringValue = value as? String {
                contextDict[key.description] = stringValue
            } else if let describable = value as? CustomStringConvertible {
                contextDict[key.description] = describable.description
            }
        }
        
        // Add any additional info
        if let info = additionalInfo {
            for (key, value) in info {
                contextDict[key] = value
            }
        }
        
        return ErrorContext(contextDict, 
                           source: nsError.domain, 
                           operation: nil,
                           details: nsError.localizedDescription,
                           underlyingError: error)
    }
}
