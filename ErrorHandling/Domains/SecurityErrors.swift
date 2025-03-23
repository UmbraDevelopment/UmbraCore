import Foundation
import ErrorHandlingInterfaces

extension UmbraErrors {
    /// Security error domain
    public enum Security {
        /// Core security errors related to authentication, authorisation, encryption, etc.
        public enum Core: Error, UmbraError {
            // Authentication errors
            case authenticationFailed(reason: String)
            case invalidToken(reason: String)
            case accessDenied(reason: String)
            
            // Encryption errors
            case encryptionFailed(reason: String)
            case decryptionFailed(reason: String)
            case integrityCheckFailed(reason: String)
            
            // Key management errors
            case keyGenerationFailed(reason: String)
            case keyDerivationFailed(reason: String)
            case keyRetrievalFailed(reason: String)
            
            // MARK: - UmbraError Protocol Implementation
            
            public var domain: String {
                return "UmbraErrors.Security.Core"
            }
            
            public var code: String {
                let intCode: Int
                switch self {
                case .authenticationFailed: intCode = 1001
                case .invalidToken: intCode = 1002
                case .accessDenied: intCode = 1003
                case .encryptionFailed: intCode = 1011
                case .decryptionFailed: intCode = 1012
                case .integrityCheckFailed: intCode = 1013
                case .keyGenerationFailed: intCode = 1021
                case .keyDerivationFailed: intCode = 1022
                case .keyRetrievalFailed: intCode = 1023
                }
                return String(intCode)
            }
            
            public var errorDescription: String {
                switch self {
                case let .authenticationFailed(reason):
                    return "Authentication failed: \(reason)"
                case let .invalidToken(reason):
                    return "Invalid token: \(reason)"
                case let .accessDenied(reason):
                    return "Access denied: \(reason)"
                case let .encryptionFailed(reason):
                    return "Encryption failed: \(reason)"
                case let .decryptionFailed(reason):
                    return "Decryption failed: \(reason)"
                case let .integrityCheckFailed(reason):
                    return "Integrity check failed: \(reason)"
                case let .keyGenerationFailed(reason):
                    return "Key generation failed: \(reason)"
                case let .keyDerivationFailed(reason):
                    return "Key derivation failed: \(reason)"
                case let .keyRetrievalFailed(reason):
                    return "Key retrieval failed: \(reason)"
                }
            }
            
            public var description: String {
                return errorDescription
            }
            
            public var source: ErrorSource? {
                return nil
            }
            
            public var underlyingError: Error? {
                return nil
            }
            
            public var context: ErrorContext {
                return ErrorContext(
                    source: domain,
                    operation: "security_operation",
                    details: errorDescription
                )
            }
            
            public var errorDomain: String {
                return domain
            }
            
            public var errorCode: Int {
                return Int(code) ?? 0
            }
            
            public func with(context: ErrorContext) -> Self {
                // Since these are enum cases, simply return self
                return self
            }
            
            public func with(underlyingError: Error) -> Self {
                // Since these are enum cases, simply return self
                return self
            }
            
            public func with(source: ErrorSource) -> Self {
                // Since these are enum cases, simply return self
                return self
            }
        }
    }
}
