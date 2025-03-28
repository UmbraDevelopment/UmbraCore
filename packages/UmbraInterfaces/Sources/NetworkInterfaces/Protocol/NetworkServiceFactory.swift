/// Protocol defining a factory for creating network service instances.
/// This provides a standard way to instantiate network services with various configurations.
public protocol NetworkServiceFactoryProtocol: Sendable {
    /// Creates a default network service
    /// - Returns: A NetworkServiceProtocol implementation
    func createDefaultService() -> any NetworkServiceProtocol
    
    /// Creates a network service with custom configuration
    /// - Parameters:
    ///   - timeoutInterval: Timeout interval in seconds
    ///   - cachePolicy: Default cache policy for requests
    ///   - enableMetrics: Whether to collect performance metrics
    /// - Returns: A NetworkServiceProtocol implementation with the specified configuration
    func createService(
        timeoutInterval: Double,
        cachePolicy: CachePolicy,
        enableMetrics: Bool
    ) -> any NetworkServiceProtocol
    
    /// Creates a network service with authentication
    /// - Parameters:
    ///   - authenticationType: Type of authentication to use
    ///   - credentials: Authentication credentials
    ///   - timeoutInterval: Timeout interval in seconds
    /// - Returns: A NetworkServiceProtocol implementation with authentication capabilities
    func createAuthenticatedService(
        authenticationType: AuthenticationType,
        credentials: AuthCredentials,
        timeoutInterval: Double
    ) -> any NetworkServiceProtocol
}

/// Types of authentication supported by network services
public enum AuthenticationType: Sendable {
    /// Basic HTTP authentication
    case basic
    
    /// Bearer token authentication
    case bearer
    
    /// OAuth 2.0 authentication
    case oauth2
    
    /// Custom authentication method
    case custom(String)
}

/// Authentication credentials for network services
public struct AuthCredentials: Sendable, Hashable {
    /// Username for authentication
    public let username: String?
    
    /// Password for authentication
    public let password: String?
    
    /// Token for authentication
    public let token: String?
    
    /// Additional parameters for authentication
    public let additionalParameters: [String: String]
    
    /// Create basic credentials with username and password
    /// - Parameters:
    ///   - username: The username
    ///   - password: The password
    /// - Returns: AuthCredentials with username and password
    public static func basic(username: String, password: String) -> AuthCredentials {
        AuthCredentials(
            username: username,
            password: password,
            token: nil,
            additionalParameters: [:]
        )
    }
    
    /// Create token-based credentials
    /// - Parameter token: The authentication token
    /// - Returns: AuthCredentials with token
    public static func token(_ token: String) -> AuthCredentials {
        AuthCredentials(
            username: nil,
            password: nil,
            token: token,
            additionalParameters: [:]
        )
    }
    
    /// Create customised credentials
    /// - Parameters:
    ///   - username: Optional username
    ///   - password: Optional password
    ///   - token: Optional token
    ///   - additionalParameters: Additional parameters for authentication
    /// - Returns: AuthCredentials with the specified values
    public static func custom(
        username: String? = nil,
        password: String? = nil,
        token: String? = nil,
        additionalParameters: [String: String] = [:]
    ) -> AuthCredentials {
        AuthCredentials(
            username: username,
            password: password,
            token: token,
            additionalParameters: additionalParameters
        )
    }
    
    /// Initialiser for AuthCredentials
    /// - Parameters:
    ///   - username: Optional username
    ///   - password: Optional password
    ///   - token: Optional token
    ///   - additionalParameters: Additional parameters for authentication
    public init(
        username: String? = nil,
        password: String? = nil,
        token: String? = nil,
        additionalParameters: [String: String] = [:]
    ) {
        self.username = username
        self.password = password
        self.token = token
        self.additionalParameters = additionalParameters
    }
}
