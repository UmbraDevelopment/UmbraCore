import UmbraCoreTypes

/// FoundationIndependent representation of a network request.
/// This data transfer object encapsulates network request information
/// without using any Foundation types.
public struct NetworkRequestDTO: Sendable, Equatable {
  // MARK: - Types

  /// The HTTP method for the request
  public enum HTTPMethod: String, Sendable, Equatable {
    case get="GET"
    case post="POST"
    case put="PUT"
    case delete="DELETE"
    case head="HEAD"
    case options="OPTIONS"
    case patch="PATCH"
  }

  /// Authentication type for the request
  public enum AuthType: Sendable, Equatable {
    /// No authentication
    case none
    /// Basic authentication with username and password
    case basic(username: String, password: String)
    /// Bearer token authentication
    case bearer(token: String)
    /// API key authentication
    case apiKey(key: String, paramName: String, inHeader: Bool)
    /// Custom authentication with headers
    case custom(headers: [String: String])
  }

  // MARK: - Properties

  /// Unique identifier for the request
  public let id: String

  /// The URL for the request as a string
  public let urlString: String

  /// The HTTP method to use
  public let method: HTTPMethod

  /// Headers to send with the request
  public let headers: [String: String]

  /// Query parameters for the request
  public let queryParams: [String: String]

  /// Body data as bytes (for POST, PUT, etc.)
  public let bodyData: [UInt8]?

  /// Timeout interval in seconds
  public let timeoutInterval: Double

  /// Authentication configuration
  public let authentication: AuthType

  /// Whether to use caching
  public let useCache: Bool

  /// Whether to follow redirects
  public let followRedirects: Bool

  /// Creation time as Unix timestamp in seconds
  public let createdAt: UInt64

  /// Additional metadata for the request
  public let metadata: [String: String]

  // MARK: - Initializers

  /// Full initializer with all request properties
  /// - Parameters:
  ///   - id: Unique identifier for the request
  ///   - urlString: The URL for the request as a string
  ///   - method: The HTTP method to use
  ///   - headers: Headers to send with the request
  ///   - queryParams: Query parameters for the request
  ///   - bodyData: Body data as bytes
  ///   - timeoutInterval: Timeout interval in seconds
  ///   - authentication: Authentication configuration
  ///   - useCache: Whether to use caching
  ///   - followRedirects: Whether to follow redirects
  ///   - createdAt: Creation time as Unix timestamp
  ///   - metadata: Additional metadata
  public init(
    id: String,
    urlString: String,
    method: HTTPMethod = .get,
    headers: [String: String]=[:],
    queryParams: [String: String]=[:],
    bodyData: [UInt8]?=nil,
    timeoutInterval: Double=60.0,
    authentication: AuthType = .none,
    useCache: Bool=true,
    followRedirects: Bool=true,
    createdAt: UInt64,
    metadata: [String: String]=[:]
  ) {
    self.id=id
    self.urlString=urlString
    self.method=method
    self.headers=headers
    self.queryParams=queryParams
    self.bodyData=bodyData
    self.timeoutInterval=max(1.0, timeoutInterval) // Ensure timeout is at least 1 second
    self.authentication=authentication
    self.useCache=useCache
    self.followRedirects=followRedirects
    self.createdAt=createdAt
    self.metadata=metadata
  }

  // MARK: - Factory Methods

  /// Create a GET request
  /// - Parameters:
  ///   - id: Unique identifier for the request
  ///   - urlString: The URL for the request as a string
  ///   - queryParams: Query parameters for the request
  ///   - headers: Headers to send with the request
  ///   - authentication: Authentication configuration
  ///   - createdAt: Creation time as Unix timestamp
  /// - Returns: A NetworkRequestDTO configured for a GET request
  public static func get(
    id: String,
    urlString: String,
    queryParams: [String: String]=[:],
    headers: [String: String]=[:],
    authentication: AuthType = .none,
    createdAt: UInt64
  ) -> NetworkRequestDTO {
    NetworkRequestDTO(
      id: id,
      urlString: urlString,
      method: .get,
      headers: headers,
      queryParams: queryParams,
      authentication: authentication,
      createdAt: createdAt
    )
  }

  /// Create a POST request
  /// - Parameters:
  ///   - id: Unique identifier for the request
  ///   - urlString: The URL for the request as a string
  ///   - bodyData: Body data as bytes
  ///   - headers: Headers to send with the request
  ///   - authentication: Authentication configuration
  ///   - createdAt: Creation time as Unix timestamp
  /// - Returns: A NetworkRequestDTO configured for a POST request
  public static func post(
    id: String,
    urlString: String,
    bodyData: [UInt8]?,
    headers: [String: String]=[:],
    authentication: AuthType = .none,
    createdAt: UInt64
  ) -> NetworkRequestDTO {
    NetworkRequestDTO(
      id: id,
      urlString: urlString,
      method: .post,
      headers: headers,
      bodyData: bodyData,
      authentication: authentication,
      createdAt: createdAt
    )
  }

  /// Create a request with basic authentication
  /// - Parameters:
  ///   - id: Unique identifier for the request
  ///   - urlString: The URL for the request as a string
  ///   - method: The HTTP method to use
  ///   - username: Username for basic authentication
  ///   - password: Password for basic authentication
  ///   - createdAt: Creation time as Unix timestamp
  /// - Returns: A NetworkRequestDTO with basic authentication
  public static func withBasicAuth(
    id: String,
    urlString: String,
    method: HTTPMethod = .get,
    username: String,
    password: String,
    createdAt: UInt64
  ) -> NetworkRequestDTO {
    NetworkRequestDTO(
      id: id,
      urlString: urlString,
      method: method,
      authentication: .basic(username: username, password: password),
      createdAt: createdAt
    )
  }

  /// Create a request with bearer token authentication
  /// - Parameters:
  ///   - id: Unique identifier for the request
  ///   - urlString: The URL for the request as a string
  ///   - method: The HTTP method to use
  ///   - token: Bearer token for authentication
  ///   - createdAt: Creation time as Unix timestamp
  /// - Returns: A NetworkRequestDTO with bearer token authentication
  public static func withBearerToken(
    id: String,
    urlString: String,
    method: HTTPMethod = .get,
    token: String,
    createdAt: UInt64
  ) -> NetworkRequestDTO {
    NetworkRequestDTO(
      id: id,
      urlString: urlString,
      method: method,
      authentication: .bearer(token: token),
      createdAt: createdAt
    )
  }

  // MARK: - Computed Properties

  /// Whether this is a read-only request (GET or HEAD)
  public var isReadOnly: Bool {
    method == .get || method == .head
  }

  /// Whether this request has a body
  public var hasBody: Bool {
    bodyData != nil && !bodyData!.isEmpty
  }

  /// The size of the body data in bytes
  public var bodySize: Int {
    bodyData?.count ?? 0
  }

  // MARK: - Utility Methods

  /// Create a copy of this request with updated headers
  /// - Parameter newHeaders: The headers to add or update
  /// - Returns: A new NetworkRequestDTO with updated headers
  public func withUpdatedHeaders(_ newHeaders: [String: String]) -> NetworkRequestDTO {
    var updatedHeaders=headers
    for (key, value) in newHeaders {
      updatedHeaders[key]=value
    }

    return NetworkRequestDTO(
      id: id,
      urlString: urlString,
      method: method,
      headers: updatedHeaders,
      queryParams: queryParams,
      bodyData: bodyData,
      timeoutInterval: timeoutInterval,
      authentication: authentication,
      useCache: useCache,
      followRedirects: followRedirects,
      createdAt: createdAt,
      metadata: metadata
    )
  }

  /// Create a copy of this request with updated query parameters
  /// - Parameter newParams: The query parameters to add or update
  /// - Returns: A new NetworkRequestDTO with updated query parameters
  public func withUpdatedQueryParams(_ newParams: [String: String]) -> NetworkRequestDTO {
    var updatedParams=queryParams
    for (key, value) in newParams {
      updatedParams[key]=value
    }

    return NetworkRequestDTO(
      id: id,
      urlString: urlString,
      method: method,
      headers: headers,
      queryParams: updatedParams,
      bodyData: bodyData,
      timeoutInterval: timeoutInterval,
      authentication: authentication,
      useCache: useCache,
      followRedirects: followRedirects,
      createdAt: createdAt,
      metadata: metadata
    )
  }

  /// Create a copy of this request with updated body data
  /// - Parameter newBodyData: The new body data
  /// - Returns: A new NetworkRequestDTO with updated body data
  public func withBodyData(_ newBodyData: [UInt8]?) -> NetworkRequestDTO {
    NetworkRequestDTO(
      id: id,
      urlString: urlString,
      method: method,
      headers: headers,
      queryParams: queryParams,
      bodyData: newBodyData,
      timeoutInterval: timeoutInterval,
      authentication: authentication,
      useCache: useCache,
      followRedirects: followRedirects,
      createdAt: createdAt,
      metadata: metadata
    )
  }

  /// Create a copy of this request with updated authentication
  /// - Parameter newAuth: The new authentication configuration
  /// - Returns: A new NetworkRequestDTO with updated authentication
  public func withAuthentication(_ newAuth: AuthType) -> NetworkRequestDTO {
    NetworkRequestDTO(
      id: id,
      urlString: urlString,
      method: method,
      headers: headers,
      queryParams: queryParams,
      bodyData: bodyData,
      timeoutInterval: timeoutInterval,
      authentication: newAuth,
      useCache: useCache,
      followRedirects: followRedirects,
      createdAt: createdAt,
      metadata: metadata
    )
  }

  /// Create a copy of this request with updated metadata
  /// - Parameter additionalMetadata: The metadata to add or update
  /// - Returns: A new NetworkRequestDTO with updated metadata
  public func withUpdatedMetadata(_ additionalMetadata: [String: String]) -> NetworkRequestDTO {
    var newMetadata=metadata
    for (key, value) in additionalMetadata {
      newMetadata[key]=value
    }

    return NetworkRequestDTO(
      id: id,
      urlString: urlString,
      method: method,
      headers: headers,
      queryParams: queryParams,
      bodyData: bodyData,
      timeoutInterval: timeoutInterval,
      authentication: authentication,
      useCache: useCache,
      followRedirects: followRedirects,
      createdAt: createdAt,
      metadata: newMetadata
    )
  }
}
