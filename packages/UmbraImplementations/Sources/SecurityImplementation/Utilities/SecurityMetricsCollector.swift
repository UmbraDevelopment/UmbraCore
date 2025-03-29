import Foundation
import LoggingInterfaces
import SecurityCoreTypes

/**
 # Security Metrics Collector

 Centralises performance tracking for security operations.
 This utility provides consistent measurement, logging,
 and reporting of performance metrics across the security implementation.

 ## Benefits

 - Ensures consistent performance monitoring across all security services
 - Provides standardised metric logging with appropriate context
 - Maintains historical performance data for analysis
 */
final class SecurityMetricsCollector {
  /**
   The logger instance for recording metrics
   */
  private let logger: LoggingInterfaces.LoggingProtocol

  /**
   Performance history for recent operations

   Maps operation types to arrays of performance measurements
   */
  private var performanceHistory: [String: [Double]]=[:]

  /**
   Maximum number of historical measurements to keep per operation type
   */
  private let historyLimit=100

  /**
   Initialises the metrics collector with a logger

   - Parameter logger: The logging service to use for metrics recording
   */
  init(logger: LoggingInterfaces.LoggingProtocol) {
    self.logger=logger
  }

  /**
   Records the completion of a security operation

   - Parameters:
       - operation: The operation type
       - operationID: Unique identifier for the operation
       - startTime: Time when the operation started
       - success: Whether the operation was successful
       - additionalMetadata: Optional additional context information
   */
  func recordOperationCompletion(
    operation: SecurityOperation,
    operationID: String,
    startTime: Date,
    success: Bool,
    additionalMetadata: [String: String]=[:]
  ) async {
    // Calculate duration for performance metrics
    let duration=Date().timeIntervalSince(startTime) * 1000

    // Store in performance history
    storePerformanceMetric(operation: operation, duration: duration)

    // Create base metadata for logging
    var metricMetadata: LoggingInterfaces.LogMetadata=[
      "operationId": operationID,
      "operation": operation.rawValue,
      "durationMs": String(format: "%.2f", duration),
      "success": "\(success)",
      "timestamp": "\(Date())"
    ]

    // Add any additional metadata
    for (key, value) in additionalMetadata {
      metricMetadata[key]=value
    }

    // Add historical performance if available
    if let avgDuration=averagePerformance(for: operation) {
      metricMetadata["avgDurationMs"]=String(format: "%.2f", avgDuration)
    }

    // Log the metrics with appropriate level based on success
    if success {
      await logger.info(
        "Security operation metrics: \(operation.description)",
        metadata: metricMetadata
      )
    } else {
      await logger.warning(
        "Failed security operation metrics: \(operation.description)",
        metadata: metricMetadata
      )
    }
  }

  /**
   Stores a performance measurement in the history

   - Parameters:
       - operation: The operation type
       - duration: Duration in milliseconds
   */
  private func storePerformanceMetric(operation: SecurityOperation, duration: Double) {
    let key=operation.rawValue

    // Create array if it doesn't exist
    if performanceHistory[key] == nil {
      performanceHistory[key]=[]
    }

    // Add new measurement
    performanceHistory[key]?.append(duration)

    // Trim history if it exceeds the limit
    if let history=performanceHistory[key], history.count > historyLimit {
      performanceHistory[key]=Array(history.suffix(historyLimit))
    }
  }

  /**
   Calculates the average performance for an operation type

   - Parameter operation: The operation type
   - Returns: Average duration in milliseconds, or nil if no history exists
   */
  private func averagePerformance(for operation: SecurityOperation) -> Double? {
    guard let history=performanceHistory[operation.rawValue], !history.isEmpty else {
      return nil
    }

    let sum=history.reduce(0, +)
    return sum / Double(history.count)
  }

  /**
   Retrieves performance statistics for an operation type

   - Parameter operation: The operation type
   - Returns: Statistics including min, max, average, and count
   */
  func performanceStats(for operation: SecurityOperation) -> PerformanceStats? {
    guard let history=performanceHistory[operation.rawValue], !history.isEmpty else {
      return nil
    }

    return PerformanceStats(
      min: history.min() ?? 0,
      max: history.max() ?? 0,
      average: history.reduce(0, +) / Double(history.count),
      count: history.count
    )
  }

  /**
   Performance statistics structure

   Contains summary statistics for operation performance
   */
  struct PerformanceStats {
    let min: Double
    let max: Double
    let average: Double
    let count: Int
  }
}
