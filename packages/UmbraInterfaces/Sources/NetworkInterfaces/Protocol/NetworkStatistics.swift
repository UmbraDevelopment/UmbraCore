import Foundation

/// NetworkStatistics represents the collected metrics for network operations.
/// This provides insights into network performance and reliability without Foundation dependencies.
public struct NetworkStatistics: Sendable, Hashable {
  /// Total number of requests performed
  public let totalRequests: Int

  /// Number of successful requests
  public let successfulRequests: Int

  /// Number of failed requests
  public let failedRequests: Int

  /// Total bytes sent
  public let bytesSent: Int64

  /// Total bytes received
  public let bytesReceived: Int64

  /// Average response time in milliseconds
  public let averageResponseTimeMs: Double

  /// A map of status code occurrences
  public let statusCodeDistribution: [Int: Int]

  /// A map of error type occurrences
  public let errorTypeDistribution: [String: Int]

  /// A timestamp for when these statistics were collected
  public let collectionTimestamp: Int64 // UNIX timestamp in milliseconds

  /// Create a new NetworkStatistics instance
  /// - Parameters:
  ///   - totalRequests: Total number of requests performed
  ///   - successfulRequests: Number of successful requests
  ///   - failedRequests: Number of failed requests
  ///   - bytesSent: Total bytes sent
  ///   - bytesReceived: Total bytes received
  ///   - averageResponseTimeMs: Average response time in milliseconds
  ///   - statusCodeDistribution: A map of status code occurrences
  ///   - errorTypeDistribution: A map of error type occurrences
  ///   - collectionTimestamp: Timestamp in milliseconds since UNIX epoch
  public init(
    totalRequests: Int,
    successfulRequests: Int,
    failedRequests: Int,
    bytesSent: Int64,
    bytesReceived: Int64,
    averageResponseTimeMs: Double,
    statusCodeDistribution: [Int: Int],
    errorTypeDistribution: [String: Int],
    collectionTimestamp: Int64
  ) {
    self.totalRequests=totalRequests
    self.successfulRequests=successfulRequests
    self.failedRequests=failedRequests
    self.bytesSent=bytesSent
    self.bytesReceived=bytesReceived
    self.averageResponseTimeMs=averageResponseTimeMs
    self.statusCodeDistribution=statusCodeDistribution
    self.errorTypeDistribution=errorTypeDistribution
    self.collectionTimestamp=collectionTimestamp
  }

  /// Creates an empty statistics object
  public static var empty: NetworkStatistics {
    NetworkStatistics(
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      bytesSent: 0,
      bytesReceived: 0,
      averageResponseTimeMs: 0,
      statusCodeDistribution: [:],
      errorTypeDistribution: [:],
      collectionTimestamp: currentTimestampMs()
    )
  }

  /// Get the current time in milliseconds since UNIX epoch
  private static func currentTimestampMs() -> Int64 {
    let timeInSeconds=Double(Date().timeIntervalSince1970)
    return Int64(timeInSeconds * 1000)
  }
}

/// Protocol for services that provide network statistics
public protocol NetworkStatisticsProvider: Sendable {
  /// Get the current network statistics
  /// - Returns: The current network statistics
  func getStatistics() async -> NetworkStatistics

  /// Reset the network statistics to initial values
  func resetStatistics() async

  /// Add a completed request to the statistics
  /// - Parameters:
  ///   - response: The response received
  ///   - requestSizeBytes: Size of the request in bytes
  ///   - responseSizeBytes: Size of the response in bytes
  ///   - durationMs: Duration of the request in milliseconds
  func recordRequest(
    response: NetworkResponseDTO,
    requestSizeBytes: Int64,
    responseSizeBytes: Int64,
    durationMs: Double
  ) async
}
