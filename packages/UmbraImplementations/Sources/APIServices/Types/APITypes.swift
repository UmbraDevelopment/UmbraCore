import Foundation
import LoggingTypes
import APIInterfaces
import UmbraErrors

/// Options for API execution, following the Alpha Dot Five architecture
public struct APIExecutionOptions: Sendable, Equatable {
    /// Standard options for most operations
    public static let standard = APIExecutionOptions()
    
    /// Default timeout in seconds
    public static let defaultTimeout = 60
    
    /// Timeout in seconds (nil means no timeout)
    public let timeout: Int?
    
    /// Whether to retry failed operations
    public let retryEnabled: Bool
    
    /// Maximum number of retry attempts
    public let maxRetries: Int
    
    /// Priority level for the operation
    public let priority: APIPriority
    
    /// Whether to use cached responses if available
    public let useCache: Bool
    
    /// Authentication level required for this operation
    public let authLevel: APIAuthLevel
    
    /// Creates a new set of API execution options
    ///
    /// - Parameters:
    ///   - timeout: Timeout in seconds (nil means no timeout)
    ///   - retryEnabled: Whether to retry failed operations
    ///   - maxRetries: Maximum number of retry attempts
    ///   - priority: Priority level for the operation
    ///   - useCache: Whether to use cached responses if available
    ///   - authLevel: Authentication level required for this operation
    public init(
        timeout: Int? = defaultTimeout,
        retryEnabled: Bool = true,
        maxRetries: Int = 3,
        priority: APIPriority = .normal,
        useCache: Bool = true,
        authLevel: APIAuthLevel = .authenticated
    ) {
        self.timeout = timeout
        self.retryEnabled = retryEnabled
        self.maxRetries = maxRetries
        self.priority = priority
        self.useCache = useCache
        self.authLevel = authLevel
    }
}

/// Priority levels for API operations
public enum APIPriority: Int, Sendable, Equatable, Comparable {
    case low = 0
    case normal = 50
    case high = 100
    case critical = 200
    
    public static func < (lhs: APIPriority, rhs: APIPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Authentication levels for API operations
public enum APIAuthLevel: Int, Sendable, Equatable, Comparable {
    case none = 0
    case basic = 10
    case authenticated = 50
    case elevated = 100
    
    public static func < (lhs: APIAuthLevel, rhs: APIAuthLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Result type for API operations, providing either a success value or an error
public enum APIResult<Value: Sendable>: Sendable {
    case success(Value)
    case failure(APIError)
    
    /// Returns the success value or throws the failure error
    public func get() throws -> Value {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Maps a successful result to a new value using the provided closure
    public func map<NewValue: Sendable>(_ transform: (Value) -> NewValue) -> APIResult<NewValue> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Determines if the result is a success
    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    /// Determines if the result is a failure
    public var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }
}
