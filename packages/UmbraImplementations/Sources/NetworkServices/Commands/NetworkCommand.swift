import Foundation
import LoggingInterfaces
import LoggingTypes
import NetworkInterfaces

/**
 Base protocol for all network operation commands.

 This protocol defines the contract that all network command implementations
 must fulfil, following the command pattern to encapsulate network operations in
 discrete command objects with a consistent interface.
 */
public protocol NetworkCommand: Sendable {
  /// The type of result returned by this command when executed
  associatedtype ResultType: Sendable

  /**
   Executes the network operation.

   - Parameters:
      - context: The logging context for the operation
   - Returns: The result of the operation
   - Throws: NetworkError if the operation fails
   */
  func execute(context: LogContextDTO) async throws -> ResultType
}

/**
 Base class for network commands providing common functionality.

 This abstract base class provides shared functionality for all network commands,
 including access to the URLSession, standardised logging, and utility methods
 that are commonly needed across network operations.
 */
public class BaseNetworkCommand: @unchecked Sendable {
  /// The URLSession for making network requests
  let session: URLSession

  /// Default timeout interval for requests
  let defaultTimeoutInterval: Double

  /// Default cache policy for requests
  let defaultCachePolicy: CachePolicy

  /// Logging instance for network operations
  let logger: PrivacyAwareLoggingProtocol

  /// Statistics provider for collecting network metrics
  let statisticsProvider: NetworkStatisticsProvider?

  /**
   Initialises a new base network command.

   - Parameters:
      - session: URLSession to use for network requests
      - defaultTimeoutInterval: Default timeout interval for requests
      - defaultCachePolicy: Default cache policy for requests
      - logger: Logger instance for network operations
      - statisticsProvider: Optional provider for collecting network metrics
   */
  public init(
    session: URLSession,
    defaultTimeoutInterval: Double=60.0,
    defaultCachePolicy: CachePolicy = .useProtocolCachePolicy,
    logger: PrivacyAwareLoggingProtocol,
    statisticsProvider: NetworkStatisticsProvider?=nil
  ) {
    self.session=session
    self.defaultTimeoutInterval=defaultTimeoutInterval
    self.defaultCachePolicy=defaultCachePolicy
    self.logger=logger
    self.statisticsProvider=statisticsProvider
  }

  /**
   Creates a logging context with standardised metadata.

   - Parameters:
      - operation: The name of the operation
      - additionalMetadata: Additional metadata for the log context
   - Returns: A configured network log context
   */
  func createLogContext(
    operation: String,
    additionalMetadata: [String: (value: String, privacyLevel: PrivacyLevel)]=[:]
  ) -> NetworkLogContext {
    // Create a base log context
    var context=NetworkLogContext(
      operation: operation,
      source: "NetworkService"
    )

    // Add additional metadata with specified privacy levels
    for (key, value) in additionalMetadata {
      switch value.privacyLevel {
        case .public:
          context=context.withPublic(key: key, value: value.value)
        case .protected:
          context=context.withProtected(key: key, value: value.value)
        case .private:
          context=context.withPrivate(key: key, value: value.value)
        case .sensitive, .hash, .never, .auto:
          // For other privacy levels, default to private
          context=context.withPrivate(key: key, value: value.value)
      }
    }

    return context
  }

  /**
   Constructs a URL from a NetworkRequestProtocol.

   - Parameter request: The network request
   - Returns: Constructed URL with query parameters, or nil if URL is invalid
   */
  func constructURL(from request: NetworkRequestProtocol) -> URL? {
    guard var urlComponents=URLComponents(string: request.urlString) else {
      return nil
    }

    // Add query parameters if any
    if !request.queryParameters.isEmpty {
      urlComponents.queryItems=request.queryParameters.map { key, value in
        URLQueryItem(name: key, value: value)
      }
    }

    return urlComponents.url
  }

  /**
   Creates a URLRequest from a NetworkRequestProtocol.

   - Parameter request: The network request
   - Returns: The result of the operation
   - Throws: NetworkError if URL construction fails
   */
  func createURLRequest(from request: NetworkRequestProtocol) throws -> URLRequest {
    guard let url=constructURL(from: request) else {
      throw NetworkError.invalidURL(request.urlString)
    }

    // Create and configure the URLRequest
    var urlRequest=URLRequest(
      url: url,
      cachePolicy: URLRequest
        .CachePolicy(rawValue: UInt(request.cachePolicy.hashValue)) ?? .useProtocolCachePolicy,
      timeoutInterval: request.timeoutInterval
    )

    // Set method
    urlRequest.httpMethod=request.method.rawValue

    // Set headers
    for (key, value) in request.headers {
      urlRequest.setValue(value, forHTTPHeaderField: key)
    }

    // Set body if applicable
    if let body=request.body {
      try setRequestBody(body, for: &urlRequest)
    }

    return urlRequest
  }

  /**
   Sets the request body for a URLRequest.

   - Parameters:
      - body: The request body to set
      - urlRequest: URLRequest to modify
   - Throws: NetworkError if body preparation fails
   */
  func setRequestBody(_ body: RequestBody, for urlRequest: inout URLRequest) throws {
    switch body {
      case let .json(encodable):
        let encoder=JSONEncoder()
        do {
          let jsonData=try encoder.encode(encodable)
          urlRequest.httpBody=jsonData
          urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } catch {
          throw NetworkError.encodingFailed(reason: "Failed to encode JSON body")
        }

      case let .form(parameters):
        var components=URLComponents()
        components.queryItems=parameters.map { key, value in
          URLQueryItem(name: key, value: value)
        }

        if let encodedData=components.query?.data(using: .utf8) {
          urlRequest.httpBody=encodedData
          urlRequest.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
          )
        }

      case let .data(bytes):
        urlRequest.httpBody=Data(bytes)
        // Content-Type is not set by default for raw data
        // The caller should set the appropriate Content-Type header

      case let .multipart(boundary, parts):
        let multipartBody=createMultipartBody(items: parts, boundary: boundary)
        urlRequest.httpBody=multipartBody
        urlRequest.setValue(
          "multipart/form-data; boundary=\(boundary)",
          forHTTPHeaderField: "Content-Type"
        )

      case .empty:
        // No body to set
        break
    }
  }

  /**
   Creates a multipart form body from the provided items.

   - Parameters:
      - items: Array of multipart form data items
      - boundary: The boundary string to use for separating form parts
   - Returns: Data containing the complete multipart form body
   */
  func createMultipartBody(items: [MultipartFormData], boundary: String) -> Data {
    var body=Data()

    for item in items {
      // Add boundary
      body.append("--\(boundary)\r\n".data(using: .utf8)!)

      // Add Content-Disposition header
      var header="Content-Disposition: form-data; name=\"\(item.name)\""
      if let filename=item.filename {
        header += "; filename=\"\(filename)\""
      }
      header += "\r\n"
      body.append(header.data(using: .utf8)!)

      // Add Content-Type header
      body.append("Content-Type: \(item.contentType)\r\n\r\n".data(using: .utf8)!)

      // Add data
      body.append(Data(item.data))

      // Add line break
      body.append("\r\n".data(using: .utf8)!)
    }

    // Add closing boundary
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)

    return body
  }

  /**
   Estimates the size of a request in bytes.

   - Parameter request: URLRequest to estimate
   - Returns: Estimated size in bytes
   */
  func estimateRequestSize(_ request: URLRequest) -> Int {
    var size=0

    // Method line: GET /path HTTP/1.1
    if let method=request.httpMethod, let url=request.url {
      let methodLine="\(method) \(url.path) HTTP/1.1"
      size += methodLine.utf8.count
    }

    // Headers
    if let headers=request.allHTTPHeaderFields {
      for (key, value) in headers {
        size += key.utf8.count + value.utf8.count + 4 // +4 for ": " and "\r\n"
      }
    }

    // Separator between headers and body
    size += 2 // "\r\n"

    // Body
    if let body=request.httpBody {
      size += body.count
    }

    return size
  }
}
