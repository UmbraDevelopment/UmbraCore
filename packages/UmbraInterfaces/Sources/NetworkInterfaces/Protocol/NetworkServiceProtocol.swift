/// Protocol defining the core functionality for network operations.
/// This protocol is foundation-independent and provides a clean interface for network
/// communication.
public protocol NetworkServiceProtocol: Sendable {
  /// Performs a network request and returns the response
  /// - Parameter request: The request to perform
  /// - Returns: A NetworkResponseDTO containing the result
  func performRequest(_ request: NetworkRequestProtocol) async throws -> NetworkResponseDTO

  /// Performs a network request and decodes the response to a specific type
  /// - Parameters:
  ///   - request: The request to perform
  ///   - type: The type to decode the response to
  /// - Returns: The decoded response data
  func performRequestAndDecode<T: Decodable>(
    _ request: NetworkRequestProtocol,
    as type: T.Type
  ) async throws -> T

  /// Uploads data to a server
  /// - Parameters:
  ///   - request: The request containing the upload configuration
  ///   - progressHandler: Optional handler for monitoring upload progress
  /// - Returns: A NetworkResponseDTO containing the result
  func uploadData(
    _ request: NetworkRequestProtocol,
    progressHandler: (@Sendable (Double) -> Void)?
  ) async throws -> NetworkResponseDTO

  /// Downloads data from a server
  /// - Parameters:
  ///   - request: The request containing the download configuration
  ///   - progressHandler: Optional handler for monitoring download progress
  /// - Returns: A NetworkResponseDTO containing the result
  func downloadData(
    _ request: NetworkRequestProtocol,
    progressHandler: (@Sendable (Double) -> Void)?
  ) async throws -> NetworkResponseDTO

  /// Checks if the network is currently available
  /// - Returns: True if the network is available, false otherwise
  func isNetworkAvailable() async -> Bool

  /// Cancels all ongoing network requests
  func cancelAllRequests() async

  /// Cancels a specific network request
  /// - Parameter request: The request to cancel
  func cancelRequest(_ request: NetworkRequestProtocol) async
}

/// Extension providing additional functionality for NetworkServiceProtocol
extension NetworkServiceProtocol {
  /// Performs a network request with retry capability
  /// - Parameters:
  ///   - request: The request to perform
  ///   - retries: Number of retry attempts
  ///   - delay: Delay between retries in seconds
  /// - Returns: A NetworkResponseDTO containing the result
  public func performRequestWithRetry(
    _ request: NetworkRequestProtocol,
    retries: Int,
    delay: Double
  ) async throws -> NetworkResponseDTO {
    var attempts=0
    var lastError: Error?

    while attempts <= retries {
      do {
        return try await performRequest(request)
      } catch {
        lastError=error
        attempts += 1

        if attempts <= retries {
          try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
      }
    }

    if let error=lastError as? NetworkError {
      throw error
    } else if let error=lastError {
      throw NetworkError.unknown(message: error.localizedDescription)
    } else {
      throw NetworkError.unknown(message: "Unknown error occurred during retry")
    }
  }

  /// Performs a simple GET request to the specified URL
  /// - Parameter urlString: The URL to request
  /// - Returns: A NetworkResponseDTO containing the result
  public func get(_ urlString: String) async throws -> NetworkResponseDTO {
    let request=SimpleNetworkRequest(urlString: urlString, method: .get)
    return try await performRequest(request)
  }

  /// Performs a simple POST request to the specified URL with the provided body
  /// - Parameters:
  ///   - urlString: The URL to request
  ///   - body: The body data to send
  /// - Returns: A NetworkResponseDTO containing the result
  public func post(_ urlString: String, body: RequestBody) async throws -> NetworkResponseDTO {
    let request=SimpleNetworkRequest(urlString: urlString, method: .post, body: body)
    return try await performRequest(request)
  }
}

/// A simple implementation of NetworkRequestProtocol for convenience methods
private struct SimpleNetworkRequest: NetworkRequestProtocol {
  let urlString: String
  let method: HTTPMethod
  let headers: [String: String]
  let queryParameters: [String: String]
  let body: RequestBody?
  let cachePolicy: CachePolicy
  let timeoutInterval: Double

  init(
    urlString: String,
    method: HTTPMethod,
    headers: [String: String]=[:],
    queryParameters: [String: String]=[:],
    body: RequestBody?=nil,
    cachePolicy: CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: Double=60.0
  ) {
    self.urlString=urlString
    self.method=method
    self.headers=headers
    self.queryParameters=queryParameters
    self.body=body
    self.cachePolicy=cachePolicy
    self.timeoutInterval=timeoutInterval
  }
}
