import Foundation
import LoggingTypes
import APIInterfaces
import UmbraErrors

/**
 * Configuration options for API operations
 *
 * This type provides a consistent way to configure how API operations are executed,
 * following the Alpha Dot Five architecture principles of strong typing and privacy by design.
 */
public struct APIConfigurationOptions: Sendable, Equatable {
    /// Standard options for most operations
    public static let standard = APIConfigurationOptions()
    
    /// Default timeout in seconds
    public static let defaultTimeout = 60
    
    /// Timeout in seconds (nil means no timeout)
    public let timeout: Int?
    
    /// Whether to retry failed operations
    public let retryEnabled: Bool
    
    /// Maximum number of retry attempts
    public let maxRetries: Int
    
    /// Priority level for the operation
    public let priority: APIOperationPriority
    
    /// Whether to use cached responses if available
    public let useCache: Bool
    
    /// Authentication level required for this operation
    public let authLevel: APIAuthenticationLevel
    
    /**
     * Creates a new set of API configuration options
     *
     * - Parameters:
     *   - timeout: Timeout in seconds (nil means no timeout)
     *   - retryEnabled: Whether to retry failed operations
     *   - maxRetries: Maximum number of retry attempts
     *   - priority: Priority level for the operation
     *   - useCache: Whether to use cached responses if available
     *   - authLevel: Authentication level required for this operation
     */
    public init(
        timeout: Int? = defaultTimeout,
        retryEnabled: Bool = true,
        maxRetries: Int = 3,
        priority: APIOperationPriority = .normal,
        useCache: Bool = true,
        authLevel: APIAuthenticationLevel = .authenticated
    ) {
        self.timeout = timeout
        self.retryEnabled = retryEnabled
        self.maxRetries = maxRetries
        self.priority = priority
        self.useCache = useCache
        self.authLevel = authLevel
    }
}

/**
 * Priority levels for API operations
 *
 * Defines the priority with which API operations should be executed.
 */
public enum APIOperationPriority: Int, Sendable, Equatable, Comparable {
    case low = 0
    case normal = 50
    case high = 100
    case critical = 200
    
    public static func < (lhs: APIOperationPriority, rhs: APIOperationPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/**
 * Authentication levels for API operations
 *
 * Defines the required authentication level for API operations.
 */
public enum APIAuthenticationLevel: Int, Sendable, Equatable, Comparable {
    case none = 0
    case basic = 10
    case authenticated = 50
    case elevated = 100
    
    public static func < (lhs: APIAuthenticationLevel, rhs: APIAuthenticationLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
