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
      case let .invalidURL(url):
        "Invalid URL: \(url)"
      case let .timeout(seconds):
        "Request timed out after \(seconds) seconds"
      case let .serverError(statusCode, message):
        "Server error (\(statusCode)): \(message)"
      case .noData:
        "No data received from server"
      case let .dataProcessingFailed(reason):
        "Data processing failed: \(reason)"
      case let .connectionFailed(reason):
        "Connection failed: \(reason)"
      case let .authenticationFailed(reason):
        "Authentication failed: \(reason)"
      case .networkUnavailable:
        "Network is unavailable"
      case .cancelled:
        "Request was cancelled"
      case let .unknown(message):
        "Unknown error: \(message)"
      case let .internalError(message):
        "Internal error: \(message)"
      case let .decodingFailed(reason):
        "Decoding failed: \(reason)"
      case let .encodingFailed(reason):
        "Encoding failed: \(reason)"
      case .requiresConnection:
        "Operation requires an active network connection"
      case let .secureConnectionFailed(reason):
        "Secure connection failed: \(reason)"
      case let .invalidParameters(reason):
        "Invalid parameters: \(reason)"
      case let .hostNotFound(hostname):
        "Host not found: \(hostname)"
      case let .tooManyRedirects(count):
        "Too many redirects (\(count))"
      case let .resourceNotFound(path):
        "Resource not found: \(path)"
    }
  }
}
