import Foundation
import LoggingInterfaces
import LoggingTypes
import NetworkInterfaces

/**
 Command for performing a network request and decoding the response.

 This command encapsulates the logic for performing a network request and
 decoding the response data into a specific type, following the command pattern architecture.
 */
public class PerformRequestAndDecodeCommand<T: Decodable & Sendable>: BaseNetworkCommand,
NetworkCommand {
  /// The result type for this command
  public typealias ResultType=T

  /// The network request to perform
  private let request: NetworkRequestProtocol

  /// The type to decode the response as
  private let decodableType: T.Type

  /// Task identifier for tracking active requests
  private let taskID: UUID = .init()

  /**
   Initialises a new perform request and decode command.

   - Parameters:
      - request: The network request to perform
      - decodableType: The type to decode the response as
      - session: URLSession to use for network requests
      - defaultTimeoutInterval: Default timeout interval for requests
      - defaultCachePolicy: Default cache policy for requests
      - logger: Logger instance for network operations
      - statisticsProvider: Optional provider for collecting network metrics
   */
  public init(
    request: NetworkRequestProtocol,
    decodableType: T.Type,
    session: URLSession,
    defaultTimeoutInterval: Double=60.0,
    defaultCachePolicy: CachePolicy = .useProtocolCachePolicy,
    logger: PrivacyAwareLoggingProtocol,
    statisticsProvider: NetworkStatisticsProvider?=nil
  ) {
    self.request=request
    self.decodableType=decodableType

    super.init(
      session: session,
      defaultTimeoutInterval: defaultTimeoutInterval,
      defaultCachePolicy: defaultCachePolicy,
      logger: logger,
      statisticsProvider: statisticsProvider
    )
  }

  /**
   Executes the network request and decode command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: The decoded response object
   - Throws: NetworkError if the operation fails
   */
  public func execute(context: LogContextDTO) async throws -> T {
    // Create context for this specific operation
    let operationContext=createLogContext(
      operation: "performRequestAndDecode",
      additionalMetadata: [
        "method": (value: request.method.rawValue, privacyLevel: .public),
        "url": (value: request.urlString, privacyLevel: .public),
        "decodingType": (value: String(describing: T.self), privacyLevel: .public),
        "taskID": (value: taskID.uuidString, privacyLevel: .public)
      ]
    )

    // Log operation start
    await logger.log(.info, "Starting network request with decoding", context: operationContext)

    // Create and execute the perform request command
    let performRequestCommand=PerformRequestCommand(
      request: request,
      session: session,
      defaultTimeoutInterval: defaultTimeoutInterval,
      defaultCachePolicy: defaultCachePolicy,
      logger: logger,
      statisticsProvider: statisticsProvider
    )

    // Execute the request and get the response
    let response=try await performRequestCommand.execute(context: context)

    // Decode the response
    do {
      // Create a decoder
      let decoder=JSONDecoder()

      // Try to decode the response data
      let decodedObject=try decoder.decode(decodableType, from: response.data)

      // Log successful decoding
      await logger.log(
        .info,
        "Successfully decoded response as \(String(describing: T.self))",
        context: operationContext
      )

      return decodedObject

    } catch {
      // Log decoding error
      let errorContext=createLogContext(
        operation: "decodeResponse",
        additionalMetadata: [
          "method": (value: request.method.rawValue, privacyLevel: .public),
          "url": (value: request.urlString, privacyLevel: .public),
          "decodingType": (value: String(describing: T.self), privacyLevel: .public),
          "errorDescription": (value: error.localizedDescription, privacyLevel: .public),
          "taskID": (value: taskID.uuidString, privacyLevel: .public)
        ]
      )

      await logger.log(.error, "Failed to decode response", context: errorContext)

      // If response data is available, include a sample in debug logs
      // but limit it to a reasonable size to avoid exposing sensitive data
      if !response.data.isEmpty {
        var dataPreview=""
        if let jsonString=String(data: response.data.prefix(200), encoding: .utf8) {
          dataPreview=jsonString + (response.data.count > 200 ? "..." : "")
        } else {
          dataPreview="[Binary data, \(response.data.count) bytes]"
        }

        let dataContext=errorContext.withPrivate(key: "responsePreview", value: dataPreview)
        await logger.log(.debug, "Response data preview", context: dataContext)
      }

      throw NetworkError.decodingFailed
    }
  }
}
