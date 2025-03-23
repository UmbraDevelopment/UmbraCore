import CoreDTOs
import Foundation

/// Factory for creating NetworkServiceDTOAdapter instances
public enum NetworkServiceDTOFactory {
  /// Create a default NetworkServiceDTOAdapter
  /// - Returns: A configured NetworkServiceDTOAdapter
  public static func createDefault() -> NetworkServiceDTOAdapter {
    NetworkServiceDTOAdapter()
  }

  /// Create a NetworkServiceDTOAdapter with custom configuration
  /// - Parameters:
  ///   - timeout: Timeout interval for requests in seconds
  ///   - cachePolicy: URL cache policy to use
  ///   - allowsCellularAccess: Whether to allow cellular access
  /// - Returns: A configured NetworkServiceDTOAdapter
  public static func createWithConfiguration(
    timeout: TimeInterval=60.0,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    allowsCellularAccess: Bool=true
  ) -> NetworkServiceDTOAdapter {
    let config=URLSessionConfiguration.default
    config.timeoutIntervalForRequest=timeout
    config.timeoutIntervalForResource=timeout * 2
    config.requestCachePolicy=cachePolicy
    config.allowsCellularAccess=allowsCellularAccess

    let session=URLSession(configuration: config)
    return NetworkServiceDTOAdapter(session: session)
  }

  /// Create a NetworkServiceDTOAdapter with authentication
  /// - Parameters:
  ///   - authType: The type of authentication to use
  ///   - timeout: Timeout interval for requests in seconds
  /// - Returns: A configured NetworkServiceDTOAdapter
  public static func createWithAuthentication(
    authType: NetworkRequestDTO.AuthType,
    timeout: TimeInterval=60.0
  ) -> NetworkServiceDTOAdapter {
    let config=URLSessionConfiguration.default
    config.timeoutIntervalForRequest=timeout
    config.timeoutIntervalForResource=timeout * 2

    // Configure auth headers
    var defaultHeaders=[String: String]()

    switch authType {
      case let .bearer(token):
        defaultHeaders["Authorization"]="Bearer \(token)"
      case let .basic(username, password):
        if let authData="\(username):\(password)".data(using: .utf8) {
          let base64Auth=authData.base64EncodedString()
          defaultHeaders["Authorization"]="Basic \(base64Auth)"
        }
      case let .apiKey(key, paramName, inHeader):
        if inHeader {
          defaultHeaders[paramName]=key
        }
      // For URL param API keys, these will need to be added on the request level
      case let .custom(headers):
        defaultHeaders=headers
      case .none:
        break
    }

    if !defaultHeaders.isEmpty {
      config.httpAdditionalHeaders=defaultHeaders
    }

    let session=URLSession(configuration: config)
    return NetworkServiceDTOAdapter(session: session)
  }
}
