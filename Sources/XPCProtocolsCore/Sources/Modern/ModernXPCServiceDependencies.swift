import Foundation

/// Type-erased logger protocol that can be used with any logger implementation
public protocol SendableLogger: Sendable {
    /// Log a message
    func log(level: String, message: String, metadata: [String: String]?)
}

/// Dependencies for the ModernXPCService
///
/// This protocol defines the dependencies required by the ModernXPCService.
/// It allows for dependency injection and easier testing.
public protocol ModernXPCServiceDependencies: Sendable {
    /// Logger for the service
    var logger: SendableLogger? { get }
    
    /// Configuration for the service
    var configuration: [String: String] { get }
    
    /// Whether to use secure storage
    var useSecureStorage: Bool { get }
}

/// Default implementation of ModernXPCServiceDependencies
public struct DefaultModernXPCServiceDependencies: ModernXPCServiceDependencies {
    /// Logger for the service
    public let logger: SendableLogger?
    
    /// Configuration for the service
    public let configuration: [String: String]
    
    /// Whether to use secure storage
    public let useSecureStorage: Bool
    
    /// Create a new default dependencies object
    /// - Parameters:
    ///   - logger: Logger for the service
    ///   - configuration: Configuration for the service
    ///   - useSecureStorage: Whether to use secure storage
    public init(
        logger: SendableLogger? = nil,
        configuration: [String: String] = [:],
        useSecureStorage: Bool = true
    ) {
        self.logger = logger
        self.configuration = configuration
        self.useSecureStorage = useSecureStorage
    }
}

/// Mock implementation of ModernXPCServiceDependencies for testing
public struct MockModernXPCServiceDependencies: ModernXPCServiceDependencies {
    /// Logger for the service
    public let logger: SendableLogger?
    
    /// Configuration for the service
    public let configuration: [String: String]
    
    /// Whether to use secure storage
    public let useSecureStorage: Bool
    
    /// Create a new mock dependencies object
    /// - Parameters:
    ///   - logger: Logger for the service
    ///   - configuration: Configuration for the service
    ///   - useSecureStorage: Whether to use secure storage
    public init(
        logger: SendableLogger? = nil,
        configuration: [String: String] = ["environment": "test"],
        useSecureStorage: Bool = false
    ) {
        self.logger = logger
        self.configuration = configuration
        self.useSecureStorage = useSecureStorage
    }
}
