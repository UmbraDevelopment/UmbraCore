import Foundation
import LoggingInterfaces
import LoggingTypes
import NetworkInterfaces

/// Implementation of NetworkServiceProtocol that provides actual network functionality
/// using URLSession while maintaining protocol boundaries.
///
/// This implementation follows the Alpha Dot Five architecture principles by:
/// 1. Using actor isolation for thread safety
/// 2. Implementing privacy-aware logging with appropriate data classification
/// 3. Using proper British spelling in documentation
/// 4. Providing comprehensive error handling with privacy controls
/// 5. Using command pattern for improved maintainability and testability
public actor NetworkServiceImpl: NetworkServiceProtocol {
  // MARK: - Private Properties

  /// The underlying URLSession for making network requests
  private let session: URLSession

  /// Default timeout interval for requests
  private let defaultTimeoutInterval: Double

  /// Default cache policy for requests
  private let defaultCachePolicy: CachePolicy

  /// Logging instance for network operations
  private let logger: PrivacyAwareLoggingProtocol

  /// Dictionary of active tasks and their associated requests
  private var activeTasks: [UUID: URLSessionTask]=[:]

  /// Statistics provider for collecting network metrics
  private let statisticsProvider: NetworkStatisticsProvider?

  /// Factory for creating network commands
  private let commandFactory: NetworkCommandFactory

  // MARK: - Initialisation

  /// Initialise a NetworkServiceImpl
  /// - Parameters:
  ///   - session: URLSession to use for network requests
  ///   - defaultTimeoutInterval: Default timeout interval for requests
  ///   - defaultCachePolicy: Default cache policy for requests
  ///   - logger: Logger instance for network operations
  ///   - statisticsProvider: Optional provider for collecting network metrics
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

    // Create the command factory
    commandFactory=NetworkCommandFactory(
      session: session,
      defaultTimeoutInterval: defaultTimeoutInterval,
      defaultCachePolicy: defaultCachePolicy,
      logger: logger,
      statisticsProvider: statisticsProvider
    )
  }

  /// Initialise a NetworkServiceImpl with default configuration
  /// - Parameters:
  ///   - timeoutInterval: Timeout interval for requests
  ///   - cachePolicy: Default cache policy for requests
  ///   - enableMetrics: Whether to collect network metrics
  ///   - logger: Logger instance for network operations
  public init(
    timeoutInterval: Double=60.0,
    cachePolicy: CachePolicy = .useProtocolCachePolicy,
    enableMetrics: Bool=true,
    logger: PrivacyAwareLoggingProtocol
  ) {
    let sessionConfig=URLSessionConfiguration.default
    sessionConfig.timeoutIntervalForRequest=timeoutInterval
    sessionConfig.timeoutIntervalForResource=timeoutInterval * 2

    let session=URLSession(configuration: sessionConfig)

    // Create statistics provider if metrics are enabled
    let statsProvider: NetworkStatisticsProvider?=enableMetrics ? NetworkStatisticsProviderImpl() :
      nil

    self.session=session
    defaultTimeoutInterval=timeoutInterval
    defaultCachePolicy=cachePolicy
    self.logger=logger
    statisticsProvider=statsProvider

    // Create the command factory
    commandFactory=NetworkCommandFactory(
      session: session,
      defaultTimeoutInterval: timeoutInterval,
      defaultCachePolicy: cachePolicy,
      logger: logger,
      statisticsProvider: statsProvider
    )
  }

  // MARK: - NetworkServiceProtocol Implementation

  public func performRequest(_ request: NetworkRequestProtocol) async throws -> NetworkResponseDTO {
    // Create a log context for this operation
    let context=NetworkLogContext(
      operation: "performRequest",
      source: "NetworkService",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "method", value: request.method.rawValue)
        .withPublic(key: "url", value: request.urlString)
    )

    // Create the command using the factory
    let command=commandFactory.createPerformRequestCommand(request: request)

    // Execute the command
    return try await command.execute(context: context)
  }

  public func performRequestAndDecode<T: Decodable & Sendable>(
    _ request: NetworkRequestProtocol,
    as type: T.Type
  ) async throws -> T {
    // Create a log context for this operation
    let context=NetworkLogContext(
      operation: "performRequestAndDecode",
      source: "NetworkService",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "method", value: request.method.rawValue)
        .withPublic(key: "url", value: request.urlString)
        .withPublic(key: "decodingType", value: String(describing: T.self))
    )

    // Create the command using the factory
    let command=commandFactory.createPerformRequestAndDecodeCommand(
      request: request,
      as: type
    )

    // Execute the command
    return try await command.execute(context: context)
  }

  public func uploadData(
    _ request: NetworkRequestProtocol,
    progressHandler _: (@Sendable (Double) -> Void)? // Ensure @Sendable is inside the parenthesis
  ) async throws -> NetworkResponseDTO {
    // Create a log context for this operation
    let context=NetworkLogContext(
      operation: "uploadData",
      source: "NetworkService",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "method", value: request.method.rawValue)
        .withPublic(key: "url", value: request.urlString)
    )

    // Create the command using the factory
    let command=commandFactory.createUploadDataCommand(
      request: request,
      progressHandler: nil
    )

    // Execute the command
    return try await command.execute(context: context)
  }

  public func downloadData(
    _ request: NetworkRequestProtocol,
    progressHandler _: (@Sendable (Double) -> Void)? // Ensure @Sendable is inside the parenthesis
  ) async throws -> NetworkResponseDTO {
    // Create a log context for this operation
    let context=NetworkLogContext(
      operation: "downloadData",
      source: "NetworkService",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "method", value: request.method.rawValue)
        .withPublic(key: "url", value: request.urlString)
    )

    // Create the command using the factory
    let command=commandFactory.createDownloadDataCommand(
      request: request,
      progressHandler: nil
    )

    // Execute the command
    return try await command.execute(context: context)
  }

  public func isNetworkAvailable() async -> Bool {
    // This is a placeholder implementation
    // In a real implementation, this would use NWPathMonitor or similar
    // to determine network availability
    true
  }

  public func cancelAllRequests() async {
    let logContext=NetworkLogContext(
      operation: "cancelAllRequests",
      source: "NetworkService"
    )

    await logger.log(.info, "Cancelling all active network requests", context: logContext)

    // Iterate through active tasks and cancel them
    for (taskID, task) in activeTasks {
      task.cancel()

      // Log cancellation
      await logger.log(
        .debug,
        "Cancelled request",
        context: logContext.withPublic(key: "taskID", value: taskID.uuidString)
      )
    }

    // Clear the active tasks dictionary
    activeTasks.removeAll()

    await logger.log(
      .info,
      "Cancelled all active network requests",
      context: logContext
    )
  }

  public func cancelRequest(_ request: NetworkRequestProtocol) async {
    let logContext=NetworkLogContext(
      operation: "cancelRequest",
      source: "NetworkService",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "url", value: request.urlString)
        .withPublic(key: "action", value: "cancelRequest")
    )

    await logger.debug("Attempting to cancel request to \(request.urlString)", context: logContext)
    // Find the task associated with this request and cancel it
    for (id, task) in activeTasks {
      // Cancel just the first matching request we find
      // A more sophisticated implementation would track exact request matches
      if task.originalRequest?.url?.absoluteString == request.urlString {
        await logger.info("Cancelling request to \(request.urlString)", context: logContext)
        task.cancel()
        activeTasks.removeValue(forKey: id)
        break
      }
    }
  }

  // MARK: - Private Helper Methods

  /// Construct a URL from a NetworkRequestProtocol
  private func constructURL(from request: NetworkRequestProtocol) async -> URL? {
    guard var urlComponents=URLComponents(string: request.urlString) else {
      let errorContext=NetworkLogContext(
        operation: "constructURL",
        source: "NetworkService",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "urlString", value: request.urlString)
      )

      await logger.error(
        "Failed to create URLComponents from \(request.urlString)",
        context: errorContext
      )
      return nil
    }

    // Add query parameters if any
    if !request.queryParameters.isEmpty {
      let queryItems=request.queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
      urlComponents.queryItems=(urlComponents.queryItems ?? []) + queryItems
    }

    return urlComponents.url
  }

  /// Construct a URLRequest from a NetworkRequestProtocol
  private func constructURLRequest(
    from request: NetworkRequestProtocol,
    url: URL
  ) async throws -> URLRequest {
    var urlRequest=URLRequest(url: url)

    // Set HTTP method
    urlRequest.httpMethod=request.method.rawValue

    // Set headers
    for (key, value) in request.headers {
      urlRequest.setValue(value, forHTTPHeaderField: key)
    }

    // Set timeout and cache policy
    urlRequest.timeoutInterval=request.timeoutInterval
    urlRequest.cachePolicy=mapCachePolicy(request.cachePolicy)

    // Set body if present
    if let body=request.body {
      try await setRequestBody(body, for: &urlRequest)
    }

    return urlRequest
  }

  /// Set the body data for a URLRequest
  private func setRequestBody(_ body: RequestBody, for urlRequest: inout URLRequest) async throws {
    switch body {
      case let .json(encodable):
        // Convert Encodable to Data
        let encoder=JSONEncoder()
        let jsonData=try encoder.encode(AnyEncodable(encodable))
        urlRequest.httpBody=jsonData
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
          urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

      case let .data(bytes):
        // Set raw data
        urlRequest.httpBody=Data(bytes)

      case let .form(parameters):
        // Form URL encoded data
        var components=URLComponents()
        components.queryItems=parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        let formString=components.percentEncodedQuery ?? ""
        urlRequest.httpBody=formString.data(using: .utf8)
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
          urlRequest.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
          )
        }

      case let .multipart(boundary, parts):
        // Multipart form data
        var bodyData=Data()

        for part in parts {
          bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)

          if let filename=part.filename {
            bodyData
              .append(
                "Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(filename)\"\r\n"
                  .data(using: .utf8)!
              )
          } else {
            bodyData
              .append(
                "Content-Disposition: form-data; name=\"\(part.name)\"\r\n"
                  .data(using: .utf8)!
              )
          }

          bodyData.append("Content-Type: \(part.contentType)\r\n\r\n".data(using: .utf8)!)
          bodyData.append(Data(part.data))
          bodyData.append("\r\n".data(using: .utf8)!)
        }

        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)

        urlRequest.httpBody=bodyData
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
          urlRequest.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
          )
        }

      case .empty:
        // No body to set
        break
    }
  }

  /// Map CachePolicy to URLRequest.CachePolicy
  private func mapCachePolicy(_ cachePolicy: CachePolicy) -> URLRequest.CachePolicy {
    switch cachePolicy {
      case .useProtocolCachePolicy:
        .useProtocolCachePolicy
      case .reloadIgnoringLocalCache:
        .reloadIgnoringLocalCacheData
      case .returnCacheDataElseLoad:
        .returnCacheDataElseLoad
      case .returnCacheDataDontLoad:
        .returnCacheDataDontLoad
    }
  }

  /// Map URLError to NetworkError
  private func mapURLErrorToNetworkError(_ error: URLError) -> NetworkError {
    switch error.code {
      case .badURL:
        .invalidURL(error.failingURL?.absoluteString ?? "Unknown URL")
      case .timedOut:
        .timeout(seconds: defaultTimeoutInterval)
      case .cannotFindHost:
        .hostNotFound(hostname: error.failingURL?.absoluteString ?? "Unknown host")
      case .cannotConnectToHost:
        .connectionFailed(reason: error.localizedDescription)
      case .networkConnectionLost:
        .connectionFailed(reason: "Network connection lost")
      case .notConnectedToInternet:
        .networkUnavailable
      case .cancelled:
        .cancelled
      case .badServerResponse:
        .serverError(statusCode: 0, message: "Bad server response")
      case .secureConnectionFailed:
        .secureConnectionFailed(reason: error.localizedDescription)
      case .resourceUnavailable:
        .resourceNotFound(path: error.failingURL?.absoluteString ?? "Unknown resource")
      case .dataNotAllowed:
        .networkUnavailable
      default:
        .unknown(message: error.localizedDescription)
    }
  }

  /// Record network statistics
  private func recordStatistics(
    response: NetworkResponseDTO,
    requestSizeBytes: Int64,
    responseSizeBytes: Int64,
    durationMs: Double
  ) async {
    await statisticsProvider?.recordRequest(
      response: response,
      requestSizeBytes: requestSizeBytes,
      responseSizeBytes: responseSizeBytes,
      durationMs: durationMs
    )
  }

  /// Estimate the size of a request in bytes
  private func estimateRequestSize(_ request: URLRequest) -> Int {
    var size=0

    // Method line: GET /path HTTP/1.1
    if let method=request.httpMethod, let url=request.url {
      size += method.count + url.absoluteString.count + 12
    }

    // Headers
    for (key, value) in request.allHTTPHeaderFields ?? [:] {
      size += key.count + value.count + 4 // key: value\r\n
    }

    // Body
    if let bodyData=request.httpBody {
      size += bodyData.count
    }

    // HTTP separator
    size += 4 // \r\n\r\n

    return size
  }
}

// MARK: - AnyEncodable Helper

/// A type-erasing wrapper for any Encodable value
private struct AnyEncodable: Encodable {
  private let encodable: Encodable

  init(_ encodable: Encodable) {
    self.encodable=encodable
  }

  func encode(to encoder: Encoder) throws {
    try encodable.encode(to: encoder)
  }
}
