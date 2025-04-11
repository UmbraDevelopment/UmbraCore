import Foundation
import LoggingInterfaces
import NetworkInterfaces

/**
 Factory for creating network command objects.

 This factory is responsible for creating specific command objects that encapsulate
 the logic for each network operation, following the command pattern architecture.
 */
public struct NetworkCommandFactory {
  /// The URLSession for making network requests
  private let session: URLSession

  /// Default timeout interval for requests
  private let defaultTimeoutInterval: Double

  /// Default cache policy for requests
  private let defaultCachePolicy: CachePolicy

  /// Logging instance for network operations
  private let logger: PrivacyAwareLoggingProtocol

  /// Statistics provider for collecting network metrics
  private let statisticsProvider: NetworkStatisticsProvider?

  /**
   Initialises a new network command factory.

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
   Creates a command for performing a network request.

   - Parameter request: The network request to perform
   - Returns: A configured perform request command
   */
  public func createPerformRequestCommand(
    request: NetworkRequestProtocol
  ) -> PerformRequestCommand {
    PerformRequestCommand(
      request: request,
      session: session,
      defaultTimeoutInterval: defaultTimeoutInterval,
      defaultCachePolicy: defaultCachePolicy,
      logger: logger,
      statisticsProvider: statisticsProvider
    )
  }

  /**
   Creates a command for performing a network request and decoding the response.

   - Parameters:
      - request: The network request to perform
      - type: The type to decode the response as
   - Returns: A configured perform request and decode command
   */
  public func createPerformRequestAndDecodeCommand<T: Decodable & Sendable>(
    request: NetworkRequestProtocol,
    as type: T.Type
  ) -> PerformRequestAndDecodeCommand<T> {
    PerformRequestAndDecodeCommand(
      request: request,
      decodableType: type,
      session: session,
      defaultTimeoutInterval: defaultTimeoutInterval,
      defaultCachePolicy: defaultCachePolicy,
      logger: logger,
      statisticsProvider: statisticsProvider
    )
  }

  /**
   Creates a command for uploading data.

   - Parameters:
      - request: The network request to perform
      - progressHandler: Optional callback for progress updates
   - Returns: A configured upload data command
   */
  public func createUploadDataCommand(
    request: NetworkRequestProtocol,
    progressHandler: (@Sendable (Double) -> Void)?=nil
  ) -> UploadDataCommand {
    UploadDataCommand(
      request: request,
      progressHandler: progressHandler,
      session: session,
      defaultTimeoutInterval: defaultTimeoutInterval,
      defaultCachePolicy: defaultCachePolicy,
      logger: logger,
      statisticsProvider: statisticsProvider
    )
  }

  /**
   Creates a command for downloading data.

   - Parameters:
      - request: The network request to perform
      - progressHandler: Optional callback for progress updates
   - Returns: A configured download data command
   */
  public func createDownloadDataCommand(
    request: NetworkRequestProtocol,
    progressHandler: (@Sendable (Double) -> Void)?=nil
  ) -> DownloadDataCommand {
    DownloadDataCommand(
      request: request,
      progressHandler: progressHandler,
      session: session,
      defaultTimeoutInterval: defaultTimeoutInterval,
      defaultCachePolicy: defaultCachePolicy,
      logger: logger,
      statisticsProvider: statisticsProvider
    )
  }
}
