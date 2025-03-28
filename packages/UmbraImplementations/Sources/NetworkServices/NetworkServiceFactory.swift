import CoreDTOs
import Foundation
import NetworkInterfaces

/// Factory for creating NetworkService instances
public enum NetworkServiceFactory {
    /// Create a default NetworkService implementation
    /// - Returns: A configured NetworkServiceProtocol instance
    public static func createDefault() -> NetworkServiceProtocol {
        NetworkServiceImpl.createDefault()
    }

    /// Create a NetworkService with custom configuration
    /// - Parameters:
    ///   - timeout: Timeout interval for requests in seconds
    ///   - cachePolicy: URL cache policy to use
    ///   - allowsCellularAccess: Whether to allow cellular access
    /// - Returns: A configured NetworkServiceProtocol instance
    public static func createWithConfiguration(
        timeout: Double = 60.0,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        allowsCellularAccess: Bool = true
    ) -> NetworkServiceProtocol {
        NetworkServiceImpl.createWithConfiguration(
            timeout: timeout,
            cachePolicy: Int(cachePolicy.rawValue),
            allowsCellularAccess: allowsCellularAccess
        )
    }

    /// Create a NetworkService with authentication
    /// - Parameters:
    ///   - authType: The type of authentication to use
    ///   - timeout: Timeout interval for requests in seconds
    /// - Returns: A configured NetworkServiceProtocol instance
    public static func createWithAuthentication(
        authType: NetworkRequestDTO.AuthType,
        timeout: Double = 60.0
    ) -> NetworkServiceProtocol {
        NetworkServiceImpl.createWithAuthentication(
            authType: authType,
            timeout: timeout
        )
    }
}
