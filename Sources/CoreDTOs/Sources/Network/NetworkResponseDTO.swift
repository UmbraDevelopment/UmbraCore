import UmbraCoreTypes

/// FoundationIndependent representation of a network response.
/// This data transfer object encapsulates network response information
/// without using any Foundation types.
public struct NetworkResponseDTO: Sendable, Equatable {
  // MARK: - Properties

  /// The ID of the request that this is a response to
  public let requestID: String

  /// HTTP status code
  public let statusCode: Int

  /// HTTP status message
  public let statusMessage: String

  /// Response headers
  public let headers: [String: String]

  /// Response body data as bytes
  public let bodyData: [UInt8]

  /// Mime type of the response
  public let mimeType: String?

  /// Character encoding of the response
  public let textEncodingName: String?

  /// Whether the response was loaded from cache
  public let isFromCache: Bool

  /// Duration of the network operation in seconds
  public let duration: Double

  /// Timestamp when the response was received (Unix timestamp in seconds)
  public let timestamp: UInt64

  /// Additional metadata for the response
  public let metadata: [String: String]

  // MARK: - Initializers

  /// Full initializer with all response properties
  /// - Parameters:
  ///   - requestId: The ID of the request that this is a response to
  ///   - statusCode: HTTP status code
  ///   - statusMessage: HTTP status message
  ///   - headers: Response headers
  ///   - bodyData: Response body data as bytes
  ///   - mimeType: Mime type of the response
  ///   - textEncodingName: Character encoding of the response
  ///   - isFromCache: Whether the response was loaded from cache
  ///   - duration: Duration of the network operation in seconds
  ///   - timestamp: Timestamp when the response was received
  ///   - metadata: Additional metadata
  public init(
    requestID: String,
    statusCode: Int,
    statusMessage: String,
    headers: [String: String]=[:],
    bodyData: [UInt8]=[],
    mimeType: String?=nil,
    textEncodingName: String?=nil,
    isFromCache: Bool=false,
    duration: Double=0.0,
    timestamp: UInt64,
    metadata: [String: String]=[:]
  ) {
    self.requestID=requestID
    self.statusCode=statusCode
    self.statusMessage=statusMessage
    self.headers=headers
    self.bodyData=bodyData
    self.mimeType=mimeType
    self.textEncodingName=textEncodingName
    self.isFromCache=isFromCache
    self.duration=max(0.0, duration)
    self.timestamp=timestamp
    self.metadata=metadata
  }

  // MARK: - Factory Methods

  /// Create a successful response
  /// - Parameters:
  ///   - requestId: The ID of the request that this is a response to
  ///   - bodyData: Response body data as bytes
  ///   - headers: Response headers
  ///   - mimeType: Mime type of the response
  ///   - duration: Duration of the network operation in seconds
  ///   - timestamp: Timestamp when the response was received
  /// - Returns: A NetworkResponseDTO with HTTP 200 status
  public static func success(
    requestID: String,
    bodyData: [UInt8]=[],
    headers: [String: String]=[:],
    mimeType: String?=nil,
    duration: Double=0.0,
    timestamp: UInt64
  ) -> NetworkResponseDTO {
    NetworkResponseDTO(
      requestID: requestID,
      statusCode: 200,
      statusMessage: "OK",
      headers: headers,
      bodyData: bodyData,
      mimeType: mimeType,
      duration: duration,
      timestamp: timestamp
    )
  }

  /// Create an error response
  /// - Parameters:
  ///   - requestId: The ID of the request that this is a response to
  ///   - statusCode: HTTP status code
  ///   - statusMessage: HTTP status message
  ///   - errorData: Optional error data as bytes
  ///   - duration: Duration of the network operation in seconds
  ///   - timestamp: Timestamp when the response was received
  /// - Returns: A NetworkResponseDTO with error status
  public static func error(
    requestID: String,
    statusCode: Int,
    statusMessage: String,
    errorData: [UInt8]=[],
    duration: Double=0.0,
    timestamp: UInt64
  ) -> NetworkResponseDTO {
    NetworkResponseDTO(
      requestID: requestID,
      statusCode: statusCode,
      statusMessage: statusMessage,
      bodyData: errorData,
      duration: duration,
      timestamp: timestamp,
      metadata: ["error": "true"]
    )
  }

  /// Create a network failure response (not a HTTP error)
  /// - Parameters:
  ///   - requestId: The ID of the request that this is a response to
  ///   - errorMessage: Description of the network error
  ///   - duration: Duration of the network operation in seconds
  ///   - timestamp: Timestamp when the failure occurred
  /// - Returns: A NetworkResponseDTO representing a network failure
  public static func networkFailure(
    requestID: String,
    errorMessage: String,
    duration: Double=0.0,
    timestamp: UInt64
  ) -> NetworkResponseDTO {
    NetworkResponseDTO(
      requestID: requestID,
      statusCode: -1,
      statusMessage: errorMessage,
      duration: duration,
      timestamp: timestamp,
      metadata: ["error": "true", "networkError": "true"]
    )
  }

  // MARK: - Computed Properties

  /// Whether the response represents a successful HTTP status (200-299)
  public var isSuccess: Bool {
    statusCode >= 200 && statusCode < 300
  }

  /// Whether the response represents a client error (400-499)
  public var isClientError: Bool {
    statusCode >= 400 && statusCode < 500
  }

  /// Whether the response represents a server error (500-599)
  public var isServerError: Bool {
    statusCode >= 500 && statusCode < 600
  }

  /// Whether the response represents any kind of error
  public var isError: Bool {
    statusCode < 0 || statusCode >= 400
  }

  /// Size of the response body in bytes
  public var bodySize: Int {
    bodyData.count
  }

  // MARK: - Utility Methods

  /// Attempts to convert the body data to a UTF-8 string
  /// - Returns: Body data as a UTF-8 string, or nil if conversion fails
  public func bodyAsUTF8String() -> String? {
    guard !bodyData.isEmpty else { return nil }

    // Use native Swift String initializer with byte array
    return String(bytes: bodyData, encoding: .utf8)
  }

  /// Get a header value by name
  /// - Parameter name: Header name (case-insensitive)
  /// - Returns: Header value, or nil if not found
  public func getHeader(_ name: String) -> String? {
    // Headers are often case-insensitive, so we'll check in a case-insensitive way
    let lowercaseName=name.lowercased()

    for (key, value) in headers {
      if key.lowercased() == lowercaseName {
        return value
      }
    }

    return nil
  }

  /// Create a copy of this response with updated metadata
  /// - Parameter additionalMetadata: The metadata to add or update
  /// - Returns: A new NetworkResponseDTO with updated metadata
  public func withUpdatedMetadata(_ additionalMetadata: [String: String]) -> NetworkResponseDTO {
    var newMetadata=metadata
    for (key, value) in additionalMetadata {
      newMetadata[key]=value
    }

    return NetworkResponseDTO(
      requestID: requestID,
      statusCode: statusCode,
      statusMessage: statusMessage,
      headers: headers,
      bodyData: bodyData,
      mimeType: mimeType,
      textEncodingName: textEncodingName,
      isFromCache: isFromCache,
      duration: duration,
      timestamp: timestamp,
      metadata: newMetadata
    )
  }
}
