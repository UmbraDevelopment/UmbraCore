import Foundation
import ErrorHandlingInterfaces

extension UmbraErrors.Security {
    /// Protocol-friendly security errors without Foundation dependencies
    public enum Protocols: Error, UmbraError {
        // Basic error types for cross-process boundary
        case invalidInput(String)
        case operationFailed(String)
        case timeout(String)
        case notFound(String)
        case notAvailable(String)
        case invalidState(String)
        case randomGenerationFailed(String)
        case notImplemented(String)
        
        // MARK: - UmbraError Protocol Implementation
        
        public var domain: String {
            return "UmbraErrors.Security.Protocols"
        }
        
        public var code: String {
            let intCode: Int
            switch self {
            case .invalidInput: intCode = 2001
            case .operationFailed: intCode = 2002
            case .timeout: intCode = 2003
            case .notFound: intCode = 2004
            case .notAvailable: intCode = 2005
            case .invalidState: intCode = 2006
            case .randomGenerationFailed: intCode = 2007
            case .notImplemented: intCode = 2008
            }
            return String(intCode)
        }
        
        public var errorDescription: String {
            switch self {
            case let .invalidInput(message):
                return "Invalid input: \(message)"
            case let .operationFailed(message):
                return "Operation failed: \(message)"
            case let .timeout(message):
                return "Timeout: \(message)"
            case let .notFound(message):
                return "Not found: \(message)"
            case let .notAvailable(message):
                return "Not available: \(message)"
            case let .invalidState(message):
                return "Invalid state: \(message)"
            case let .randomGenerationFailed(message):
                return "Random generation failed: \(message)"
            case let .notImplemented(message):
                return "Not implemented: \(message)"
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
                operation: "security_protocol_operation",
                details: errorDescription
            )
        }
        
        public func with(context: ErrorContext) -> Self {
            return self
        }
        
        public func with(underlyingError: Error) -> Self {
            return self
        }
        
        public func with(source: ErrorSource) -> Self {
            return self
        }
    }
}
