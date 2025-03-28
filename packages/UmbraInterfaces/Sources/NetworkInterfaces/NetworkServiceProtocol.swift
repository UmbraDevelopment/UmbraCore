import CoreDTOs
import Foundation

/// A protocol defining a Foundation-independent interface for network operations
public protocol NetworkServiceProtocol: Sendable {
    /// Send a network request asynchronously
    /// - Parameter request: The request to send
    /// - Returns: A result containing either the response or an error
    func sendRequest(_ request: NetworkRequestDTO) async -> OperationResultDTO<NetworkResponseDTO>

    /// Download data from a URL
    /// - Parameters:
    ///   - urlString: The URL string to download from
    ///   - headers: Optional headers for the request
    /// - Returns: A result containing either the downloaded data or an error
    func downloadData(from urlString: String, headers: [String: String]?) async
        -> OperationResultDTO<[UInt8]>

    /// Download data with progress reporting
    /// - Parameters:
    ///   - urlString: The URL string to download from
    ///   - headers: Optional headers for the request
    ///   - progressHandler: A closure that will be called periodically with download progress
    /// - Returns: A result containing either the downloaded data or an error
    func downloadData(
        from urlString: String,
        headers: [String: String]?,
        progressHandler: @escaping (Double) -> Void
    ) async -> OperationResultDTO<[UInt8]>

    /// Upload data to a URL
    /// - Parameters:
    ///   - data: The data to upload
    ///   - urlString: The URL string to upload to
    ///   - method: The HTTP method to use (default: POST)
    ///   - headers: Optional headers for the request
    /// - Returns: A result containing either the server response or an error
    func uploadData(
        _ data: [UInt8],
        to urlString: String,
        method: NetworkRequestDTO.HTTPMethod,
        headers: [String: String]?
    ) async -> OperationResultDTO<NetworkResponseDTO>

    /// Upload data with progress reporting
    /// - Parameters:
    ///   - data: The data to upload
    ///   - urlString: The URL string to upload to
    ///   - method: The HTTP method to use (default: POST)
    ///   - headers: Optional headers for the request
    ///   - progressHandler: A closure that will be called periodically with upload progress
    /// - Returns: A result containing either the server response or an error
    func uploadData(
        _ data: [UInt8],
        to urlString: String,
        method: NetworkRequestDTO.HTTPMethod,
        headers: [String: String]?,
        progressHandler: @escaping (Double) -> Void
    ) async -> OperationResultDTO<NetworkResponseDTO>

    /// Checks if a URL is reachable
    /// - Parameter urlString: The URL string to check
    /// - Returns: A result containing either a boolean indicating reachability or an error
    func isReachable(urlString: String) async -> OperationResultDTO<Bool>
    
    /// Creates a configured instance with default settings
    /// - Returns: A network service instance with default configuration
    static func createDefault() -> Self
    
    /// Creates a configured instance with custom timeout and policies
    /// - Parameters:
    ///   - timeout: Timeout interval for requests in seconds
    ///   - cachePolicy: Cache policy to use for requests
    ///   - allowsCellularAccess: Whether to allow cellular network access
    /// - Returns: A network service instance with custom configuration
    static func createWithConfiguration(
        timeout: Double,
        cachePolicy: Int,
        allowsCellularAccess: Bool
    ) -> Self
    
    /// Creates a configured instance with authentication
    /// - Parameters:
    ///   - authType: The type of authentication to use
    ///   - timeout: Timeout interval for requests in seconds
    /// - Returns: A network service instance with authentication configured
    static func createWithAuthentication(
        authType: NetworkRequestDTO.AuthType,
        timeout: Double
    ) -> Self
}

/// Errors that can occur during network operations
public enum NetworkError: Int32, Error, Equatable, CaseIterable {
    /// The URL was invalid or malformed
    case invalidURL = 1001
    
    /// Could not connect to the server
    case connectionFailed = 1002
    
    /// The server response was invalid or could not be parsed
    case invalidResponse = 1003
    
    /// The request timed out
    case timeout = 1004
    
    /// Authentication failed
    case authenticationFailed = 1005
    
    /// The requested resource was not found (HTTP 404)
    case notFound = 1006
    
    /// The server refused the request (HTTP 4xx other than 404)
    case clientError = 1007
    
    /// The server encountered an error (HTTP 5xx)
    case serverError = 1008
    
    /// An unexpected error occurred
    case unknown = 1009
    
    /// Convert an HTTP status code to an appropriate NetworkError
    /// - Parameter statusCode: The HTTP status code
    /// - Returns: The corresponding NetworkError
    public static func from(statusCode: Int) -> NetworkError {
        switch statusCode {
        case 404:
            return .notFound
        case 400...499:
            return .clientError
        case 500...599:
            return .serverError
        default:
            return .unknown
        }
    }
}

/// Extension providing convenience methods for working with NetworkError
public extension NetworkError {
    /// Converts NetworkError to a user-friendly message
    /// - Returns: A string describing the error in user-friendly terms
    func localizedDescription() -> String {
        switch self {
        case .invalidURL:
            return "The URL is invalid or malformed."
        case .connectionFailed:
            return "Could not connect to the server. Please check your network connection."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .timeout:
            return "The request timed out. Please try again later."
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials."
        case .notFound:
            return "The requested resource was not found."
        case .clientError:
            return "Client error occurred. The server refused the request."
        case .serverError:
            return "Server error occurred. Please try again later."
        case .unknown:
            return "An unexpected error occurred."
        }
    }
}
