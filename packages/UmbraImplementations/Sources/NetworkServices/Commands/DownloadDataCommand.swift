import Foundation
import LoggingInterfaces
import LoggingTypes
import NetworkInterfaces

/**
 Command for downloading data via a network request.

 This command encapsulates the logic for downloading data and tracking progress,
 following the command pattern architecture.
 */
public class DownloadDataCommand: BaseNetworkCommand, NetworkCommand {
  /// The result type for this command
  public typealias ResultType=NetworkResponseDTO

  /// The network request to perform
  private let request: NetworkRequestProtocol

  /// Progress handler callback
  private let progressHandler: (@Sendable (Double) -> Void)?

  /// Task identifier for tracking active requests
  private let taskID: UUID = .init()

  /**
   Initialises a new download data command.

   - Parameters:
      - request: The network request to perform
      - progressHandler: Optional callback for progress updates
      - session: URLSession to use for network requests
      - defaultTimeoutInterval: Default timeout interval for requests
      - defaultCachePolicy: Default cache policy for requests
      - logger: Logger instance for network operations
      - statisticsProvider: Optional provider for collecting network metrics
   */
  public init(
    request: NetworkRequestProtocol,
    progressHandler: (@Sendable (Double) -> Void)?,
    session: URLSession,
    defaultTimeoutInterval: Double=60.0,
    defaultCachePolicy: CachePolicy = .useProtocolCachePolicy,
    logger: PrivacyAwareLoggingProtocol,
    statisticsProvider: NetworkStatisticsProvider?=nil
  ) {
    self.request=request
    self.progressHandler=progressHandler

    super.init(
      session: session,
      defaultTimeoutInterval: defaultTimeoutInterval,
      defaultCachePolicy: defaultCachePolicy,
      logger: logger,
      statisticsProvider: statisticsProvider
    )
  }

  /**
   Executes the download data command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: The network response
   - Throws: NetworkError if the operation fails
   */
  public func execute(context _: LogContextDTO) async throws -> NetworkResponseDTO {
    let startTime=Date().timeIntervalSince1970 * 1000
    var requestSizeBytes: Int64=0
    var responseSizeBytes: Int64=0

    // Create the URLRequest
    let urlRequest: URLRequest
    do {
      urlRequest=try createURLRequest(from: request)
      requestSizeBytes=Int64(estimateRequestSize(urlRequest))
    } catch {
      // Log URL creation failure
      let errorContext=createLogContext(
        operation: "downloadData",
        additionalMetadata: [
          "urlString": (value: request.urlString, privacyLevel: .public),
          "error": (value: error.localizedDescription, privacyLevel: .public)
        ]
      )
      await logger.log(.error, "Failed to create URL from request", context: errorContext)
      throw error is NetworkError ? error : NetworkError.invalidURL(request.urlString)
    }

    // Create request log context
    let requestContext=createLogContext(
      operation: "downloadData",
      additionalMetadata: [
        "method": (value: request.method.rawValue, privacyLevel: .public),
        "url": (value: request.urlString, privacyLevel: .public),
        "taskID": (value: taskID.uuidString, privacyLevel: .public)
      ]
    )

    // Log request start
    await logger.log(.info, "Starting download request", context: requestContext)

    do {
      // Perform the download request using a data task (for simplicity)
      // In a real implementation, this would use URLSession's downloadTask methods
      let (data, urlResponse)=try await session.data(for: urlRequest)

      // Process the response
      guard let httpResponse=urlResponse as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
      }

      // Calculate response size
      responseSizeBytes=Int64(data.count)

      // Calculate elapsed time
      let endTime=Date().timeIntervalSince1970 * 1000
      let durationMs=endTime - startTime

      // Create success context
      let successContext=createLogContext(
        operation: "downloadData",
        additionalMetadata: [
          "method": (value: request.method.rawValue, privacyLevel: .public),
          "url": (value: request.urlString, privacyLevel: .public),
          "statusCode": (value: String(httpResponse.statusCode), privacyLevel: .public),
          "durationMs": (value: String(format: "%.2f", durationMs), privacyLevel: .public),
          "requestSizeBytes": (value: String(requestSizeBytes), privacyLevel: .public),
          "responseSizeBytes": (value: String(responseSizeBytes), privacyLevel: .public),
          "taskID": (value: taskID.uuidString, privacyLevel: .public)
        ]
      )

      // Log success
      await logger.log(.info, "Download completed successfully", context: successContext)

      // Update statistics if available
      await statisticsProvider?.recordRequest(
        url: request.urlString,
        method: request.method.rawValue,
        statusCode: httpResponse.statusCode,
        requestSizeBytes: requestSizeBytes,
        responseSizeBytes: responseSizeBytes,
        durationMs: durationMs
      )

      // Check status code for error responses
      if httpResponse.statusCode >= 400 {
        throw NetworkError.httpError(
          statusCode: httpResponse.statusCode,
          data: data
        )
      }

      // Return a successful response
      // Create and return the response
      return NetworkResponseDTO(
        data: data,
        statusCode: httpResponse.statusCode,
        headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
        url: httpResponse.url
      )

    } catch let error as URLError {
      // Handle URLError
      let endTime=Date().timeIntervalSince1970 * 1000
      let durationMs=endTime - startTime

      let errorContext=createLogContext(
        operation: "downloadData",
        additionalMetadata: [
          "method": (value: request.method.rawValue, privacyLevel: .public),
          "url": (value: request.urlString, privacyLevel: .public),
          "errorCode": (value: String(error.code.rawValue), privacyLevel: .public),
          "errorDescription": (value: error.localizedDescription, privacyLevel: .public),
          "durationMs": (value: String(format: "%.2f", durationMs), privacyLevel: .public),
          "taskID": (value: taskID.uuidString, privacyLevel: .public)
        ]
      )

      await logger.log(.error, "Download failed with URLError", context: errorContext)

      // Update error statistics
      await statisticsProvider?.recordError(
        url: request.urlString,
        method: request.method.rawValue,
        errorCode: String(error.code.rawValue),
        durationMs: durationMs
      )

      // Map URLError to NetworkError
      let networkError: NetworkError=switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
          .noConnection
        case .timedOut:
          .timeout
        case .cancelled:
          .cancelled
        default:
          .urlError(error)
      }

      throw networkError

    } catch let error as NetworkError {
      // Already a NetworkError, propagate it
      let endTime=Date().timeIntervalSince1970 * 1000
      let durationMs=endTime - startTime

      let errorContext=createLogContext(
        operation: "downloadData",
        additionalMetadata: [
          "method": (value: request.method.rawValue, privacyLevel: .public),
          "url": (value: request.urlString, privacyLevel: .public),
          "errorDescription": (value: error.localizedDescription, privacyLevel: .public),
          "durationMs": (value: String(format: "%.2f", durationMs), privacyLevel: .public),
          "taskID": (value: taskID.uuidString, privacyLevel: .public)
        ]
      )

      await logger.log(.error, "Download failed with NetworkError", context: errorContext)

      // Update error statistics
      await statisticsProvider?.recordError(
        url: request.urlString,
        method: request.method.rawValue,
        errorCode: String(describing: error),
        durationMs: durationMs
      )

      throw error

    } catch {
      // Handle any other errors
      let endTime=Date().timeIntervalSince1970 * 1000
      let durationMs=endTime - startTime

      let errorContext=createLogContext(
        operation: "downloadData",
        additionalMetadata: [
          "method": (value: request.method.rawValue, privacyLevel: .public),
          "url": (value: request.urlString, privacyLevel: .public),
          "errorDescription": (value: error.localizedDescription, privacyLevel: .public),
          "durationMs": (value: String(format: "%.2f", durationMs), privacyLevel: .public),
          "taskID": (value: taskID.uuidString, privacyLevel: .public)
        ]
      )

      await logger.log(.error, "Download failed with unexpected error", context: errorContext)

      // Update error statistics
      await statisticsProvider?.recordError(
        url: request.urlString,
        method: request.method.rawValue,
        errorCode: "unknown",
        durationMs: durationMs
      )

      throw NetworkError.unknown(error.localizedDescription)
    }
  }
}
