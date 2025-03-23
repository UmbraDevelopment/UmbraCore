import Foundation
import ErrorHandlingInterfaces

extension UmbraErrors {
    /// Crypto error domain
    public enum Crypto {
        /// Core cryptographic errors
        public enum Core: Error, UmbraError {
            // Cryptographic operation errors
            case operationFailed(reason: String)
            case invalidAlgorithm(name: String)
            case invalidKey(reason: String)
            case invalidData(reason: String)
            
            // Hash errors
            case hashingFailed(reason: String)
            case signatureVerificationFailed(reason: String)
            
            // MARK: - UmbraError Protocol Implementation
            
            public var domain: String {
                return "UmbraErrors.Crypto.Core"
            }
            
            public var code: String {
                let intCode: Int
                switch self {
                case .operationFailed: intCode = 2001
                case .invalidAlgorithm: intCode = 2002
                case .invalidKey: intCode = 2003
                case .invalidData: intCode = 2004
                case .hashingFailed: intCode = 2011
                case .signatureVerificationFailed: intCode = 2012
                }
                return String(intCode)
            }
            
            public var errorDescription: String {
                switch self {
                case let .operationFailed(reason):
                    return "Crypto operation failed: \(reason)"
                case let .invalidAlgorithm(name):
                    return "Invalid crypto algorithm: \(name)"
                case let .invalidKey(reason):
                    return "Invalid crypto key: \(reason)"
                case let .invalidData(reason):
                    return "Invalid crypto data: \(reason)"
                case let .hashingFailed(reason):
                    return "Hashing operation failed: \(reason)"
                case let .signatureVerificationFailed(reason):
                    return "Signature verification failed: \(reason)"
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
                    operation: "crypto_operation",
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
