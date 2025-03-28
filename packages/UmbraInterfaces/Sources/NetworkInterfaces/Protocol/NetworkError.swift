/// NetworkError defines all possible error conditions that can occur during network operations.
/// This is a self-contained error type that doesn't depend on UmbraErrors or Foundation errors.
public enum NetworkError: Error, Hashable, Sendable {
    /// The specified URL was invalid or malformed
    case invalidURL(String)
    
    /// Request timed out after waiting for a response
    case timeout(seconds: Double)
    
    /// Server returned an error status code
    case serverError(statusCode: Int, message: String)
    
    /// No data was returned from the server
    case noData
    
    /// Received data could not be processed
    case dataProcessingFailed(reason: String)
    
    /// The server could not be reached
    case connectionFailed(reason: String)
    
    /// Authentication with the server failed
    case authenticationFailed(reason: String)
    
    /// Network currently unavailable (offline)
    case networkUnavailable
    
    /// A request was cancelled
    case cancelled
    
    /// An error occurred but the specific cause is unknown
    case unknown(message: String)
    
    /// Internal error that doesn't fit other categories
    case internalError(message: String)
    
    /// The response couldn't be decoded
    case decodingFailed(reason: String)
    
    /// The request couldn't be encoded
    case encodingFailed(reason: String)
    
    /// The operation requires an active network connection
    case requiresConnection
    
    /// TLS/SSL error occurred during the connection
    case secureConnectionFailed(reason: String)
    
    /// Request has invalid parameters
    case invalidParameters(reason: String)
    
    /// Host name could not be resolved
    case hostNotFound(hostname: String)
    
    /// Redirection limit was exceeded
    case tooManyRedirects(count: Int)
    
    /// A resource required by the request was not found
    case resourceNotFound(path: String)
}

// MARK: - CustomStringConvertible
extension NetworkError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .timeout(let seconds):
            return "Request timed out after \(seconds) seconds"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .noData:
            return "No data received from server"
        case .dataProcessingFailed(let reason):
            return "Data processing failed: \(reason)"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .networkUnavailable:
            return "Network is unavailable"
        case .cancelled:
            return "Request was cancelled"
        case .unknown(let message):
            return "Unknown error: \(message)"
        case .internalError(let message):
            return "Internal error: \(message)"
        case .decodingFailed(let reason):
            return "Decoding failed: \(reason)"
        case .encodingFailed(let reason):
            return "Encoding failed: \(reason)"
        case .requiresConnection:
            return "Operation requires an active network connection"
        case .secureConnectionFailed(let reason):
            return "Secure connection failed: \(reason)"
        case .invalidParameters(let reason):
            return "Invalid parameters: \(reason)"
        case .hostNotFound(let hostname):
            return "Host not found: \(hostname)"
        case .tooManyRedirects(let count):
            return "Too many redirects (\(count))"
        case .resourceNotFound(let path):
            return "Resource not found: \(path)"
        }
    }
}
