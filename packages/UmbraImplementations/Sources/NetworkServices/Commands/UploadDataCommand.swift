import Foundation
import LoggingInterfaces
import LoggingTypes
import NetworkInterfaces

/**
 Command for uploading data to a network endpoint.

 This command encapsulates the logic for uploading data to a URL and
 processing the response, setting the appropriate request body and
 following the command pattern architecture.
 */
public class UploadDataCommand: BaseNetworkCommand, NetworkCommand, @unchecked Sendable {
  /// The result type for this command
  public typealias ResultType=NetworkResponseDTO

  /// The network request to perform
  private let request: NetworkRequestProtocol

  /// Progress handler callback
  private let progressHandler: (@Sendable (Double) -> Void)?

  /// Task identifier for tracking active requests
  private let taskID: UUID = .init()

  /**
   Initialises a new upload data command.

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
   Executes the upload data command.

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
        operation: "uploadData",
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
      operation: "uploadData",
      additionalMetadata: [
        "method": (value: request.method.rawValue, privacyLevel: .public),
        "url": (value: request.urlString, privacyLevel: .public),
        "taskID": (value: taskID.uuidString, privacyLevel: .public)
      ]
    )

    // Log request start
    await logger.log(.info, "Starting upload request", context: requestContext)

    do {
      // Extract the data to upload from the request body
      guard let body=request.body, case let .data(bytes)=body else {
        throw NetworkError.invalidParameters(reason: "Upload requests require a data body")
      }

      // Create the upload task
      let (data, urlResponse)=try await session.upload(for: urlRequest, from: Data(bytes))

      // Process the response
      guard let httpResponse=urlResponse as? HTTPURLResponse else {
        throw NetworkError.internalError(message: "Invalid response type received")
      }

      // Calculate response size
      responseSizeBytes=Int64(data.count)

      // Calculate elapsed time
      let endTime=Date().timeIntervalSince1970 * 1000
      let durationMs=endTime - startTime

      // Create success context
      let successContext=createLogContext(
        operation: "uploadData",
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
      await logger.log(.info, "Upload completed successfully", context: successContext)

      // Update statistics if available
      await statisticsProvider?.recordRequest(
        response: NetworkResponseDTO(
          statusCode: httpResponse.statusCode,
          headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
          data: [UInt8](data),
          isSuccess: true,
          error: nil
        ),
        requestSizeBytes: requestSizeBytes,
        responseSizeBytes: responseSizeBytes,
        durationMs: durationMs
      )

      // Check status code for error responses
      if httpResponse.statusCode >= 400 {
        throw NetworkError.serverError(
          statusCode: httpResponse.statusCode,
          message: String(data: data, encoding: .utf8) ?? "No error message provided"
        )
      }

      // Create and return the response
      return NetworkResponseDTO(
        statusCode: httpResponse.statusCode,
        headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
        data: [UInt8](data),
        isSuccess: true,
        error: nil
      )

    } catch let error as URLError {
      // Handle URLError
      let endTime=Date().timeIntervalSince1970 * 1000
      let durationMs=endTime - startTime

      let errorContext=createLogContext(
        operation: "uploadData",
        additionalMetadata: [
          "method": (value: request.method.rawValue, privacyLevel: .public),
          "url": (value: request.urlString, privacyLevel: .public),
          "errorCode": (value: String(error.code.rawValue), privacyLevel: .public),
          "errorDescription": (value: error.localizedDescription, privacyLevel: .public),
          "durationMs": (value: String(format: "%.2f", durationMs), privacyLevel: .public),
          "taskID": (value: taskID.uuidString, privacyLevel: .public)
        ]
      )

      await logger.log(.error, "Upload failed with URLError", context: errorContext)

      // Update error statistics
      await statisticsProvider?.recordRequest(
        response: NetworkResponseDTO(
          statusCode: 0,
          headers: [:],
          data: [],
          isSuccess: false,
          error: NetworkError.unknown(message: error.localizedDescription)
        ),
        requestSizeBytes: requestSizeBytes,
        responseSizeBytes: 0,
        durationMs: durationMs
      )

      // Map URLError to NetworkError
      let networkError: NetworkError=switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
          .networkUnavailable
        case .timedOut:
          .timeout(seconds: request.timeoutInterval)
        case .cancelled:
          .cancelled
        default:
          .connectionFailed(reason: error.localizedDescription)
      }

      throw networkError

    } catch let error as NetworkError {
      // Already a NetworkError, propagate it
      let endTime=Date().timeIntervalSince1970 * 1000
      let durationMs=endTime - startTime

      let errorContext=createLogContext(
        operation: "uploadData",
        additionalMetadata: [
          "method": (value: request.method.rawValue, privacyLevel: .public),
          "url": (value: request.urlString, privacyLevel: .public),
          "errorDescription": (value: error.localizedDescription, privacyLevel: .public),
          "durationMs": (value: String(format: "%.2f", durationMs), privacyLevel: .public),
          "taskID": (value: taskID.uuidString, privacyLevel: .public)
        ]
      )

      await logger.log(.error, "Upload failed with NetworkError", context: errorContext)

      // Update error statistics
      await statisticsProvider?.recordRequest(
        response: NetworkResponseDTO(
          statusCode: 0,
          headers: [:],
          data: [],
          isSuccess: false,
          error: error
        ),
        requestSizeBytes: requestSizeBytes,
        responseSizeBytes: 0,
        durationMs: durationMs
      )

      throw error

    } catch {
      // Handle any other errors
      let endTime=Date().timeIntervalSince1970 * 1000
      let durationMs=endTime - startTime

      let errorContext=createLogContext(
        operation: "uploadData",
        additionalMetadata: [
          "method": (value: request.method.rawValue, privacyLevel: .public),
          "url": (value: request.urlString, privacyLevel: .public),
          "errorDescription": (value: error.localizedDescription, privacyLevel: .public),
          "durationMs": (value: String(format: "%.2f", durationMs), privacyLevel: .public),
          "taskID": (value: taskID.uuidString, privacyLevel: .public)
        ]
      )

      await logger.log(.error, "Upload failed with unexpected error", context: errorContext)

      // Update error statistics
      await statisticsProvider?.recordRequest(
        response: NetworkResponseDTO(
          statusCode: 0,
          headers: [:],
          data: [],
          isSuccess: false,
          error: NetworkError.unknown(message: error.localizedDescription)
        ),
        requestSizeBytes: requestSizeBytes,
        responseSizeBytes: 0,
        durationMs: durationMs
      )

      throw NetworkError.unknown(message: error.localizedDescription)
    }
  }
}
