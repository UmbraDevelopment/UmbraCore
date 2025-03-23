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
            
            // Security operation errors
            case operationFailed(reason: String)
            case invalidParameter(name: String, reason: String)
            case internalError(description: String)
            
            // Key and certificate errors
            case invalidKey(reason: String)
            case invalidCertificate(reason: String)
            case invalidSignature(reason: String)
            case invalidContext(reason: String)
            
            // Authorization errors
            case missingEntitlement(reason: String)
            case notAuthorized(reason: String)
            
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
                case .operationFailed: intCode = 1004
                case .invalidParameter: intCode = 1005
                case .internalError: intCode = 1006
                case .invalidKey: intCode = 1007
                case .invalidCertificate: intCode = 1008
                case .invalidSignature: intCode = 1009
                case .invalidContext: intCode = 1010
                case .missingEntitlement: intCode = 1011
                case .notAuthorized: intCode = 1012
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
                case let .operationFailed(reason):
                    return "Operation failed: \(reason)"
                case let .invalidParameter(name, reason):
                    return "Invalid parameter '\(name)': \(reason)"
                case let .internalError(description):
                    return "Internal error: \(description)"
                case let .invalidKey(reason):
                    return "Invalid key: \(reason)"
                case let .invalidCertificate(reason):
                    return "Invalid certificate: \(reason)"
                case let .invalidSignature(reason):
                    return "Invalid signature: \(reason)"
                case let .invalidContext(reason):
                    return "Invalid context: \(reason)"
                case let .missingEntitlement(reason):
                    return "Missing entitlement: \(reason)"
                case let .notAuthorized(reason):
                    return "Not authorized: \(reason)"
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
