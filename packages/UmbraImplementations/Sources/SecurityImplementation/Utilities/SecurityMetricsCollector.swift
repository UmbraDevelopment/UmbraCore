import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes

/**
 # Security Metrics Collector

 Centralises performance tracking for security operations.
 This utility provides consistent measurement, logging,
 and reporting of performance metrics across the security implementation.

 ## Benefits

 - Ensures consistent performance monitoring across all security services
 - Provides standardised metric logging with appropriate context
 - Maintains historical performance data for analysis

 ## Privacy-Aware Logging

 Implements privacy-aware metrics collection through SecureLoggerActor, ensuring
 that all performance metrics are properly tagged with privacy levels according to
 the Alpha Dot Five architecture principles.
 */
final class SecurityMetricsCollector {
  /**
   The logger instance for recording general metrics
   */
  private let logger: LoggingInterfaces.LoggingProtocol

  /**
   The secure logger for privacy-aware logging of metrics

   This logger ensures proper privacy tagging for all security metrics
   in accordance with Alpha Dot Five architecture principles.
   */
  private let secureLogger: SecureLoggerActor

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
   Initialises the metrics collector with loggers

   - Parameters:
       - logger: The logging service to use for general metrics recording
       - secureLogger: The secure logger for privacy-aware metrics collection (optional)
   */
  init(
    logger: LoggingInterfaces.LoggingProtocol,
    secureLogger: SecureLoggerActor?=nil
  ) {
    self.logger=logger
    self.secureLogger=secureLogger ?? SecureLoggerActor(
      subsystem: "com.umbra.security",
      category: "SecurityMetrics",
      includeTimestamps: true
    )
  }

  /**
   Records the completion of a security operation with privacy controls

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

    // Prepare privacy-tagged metadata for secure logger
    var secureMetadata: [String: PrivacyTaggedValue]=[
      "operationId": PrivacyTaggedValue(value: operationID, privacyLevel: .public),
      "operation": PrivacyTaggedValue(value: operation.rawValue, privacyLevel: .public),
      "durationMs": PrivacyTaggedValue(value: Int(duration), privacyLevel: .public),
      "success": PrivacyTaggedValue(value: success, privacyLevel: .public)
    ]

    // Add additional metadata with privacy tagging
    for (key, value) in additionalMetadata {
      // Determine privacy level based on key name
      let privacyLevel=determinePrivacyLevel(for: key)
      secureMetadata[key]=PrivacyTaggedValue(value: value, privacyLevel: privacyLevel)
    }

    // Add historical performance with privacy tagging
    if let avgDuration=averagePerformance(for: operation) {
      secureMetadata["avgDurationMs"]=PrivacyTaggedValue(value: Int(avgDuration),
                                                         privacyLevel: .public)
    }

    // Log with secure logger for enhanced privacy awareness
    let status: SecurityEventStatus=success ? .success : .warning
    await secureLogger.securityEvent(
      action: "MetricsCollection",
      status: status,
      subject: nil,
      resource: nil,
      additionalMetadata: secureMetadata
    )
  }

  /**
   Records a significant performance anomaly with privacy controls

   - Parameters:
       - operation: The operation type
       - duration: Duration of the operation in milliseconds
       - threshold: The threshold that was exceeded
       - context: Additional contextual information
   */
  func recordPerformanceAnomaly(
    operation: SecurityOperation,
    duration: Double,
    threshold: Double,
    context: [String: String]=[:]
  ) async {
    // Create anomaly metadata
    var anomalyMetadata: LoggingInterfaces.LogMetadata=[
      "operation": operation.rawValue,
      "durationMs": String(format: "%.2f", duration),
      "thresholdMs": String(format: "%.2f", threshold),
      "exceededBy": String(format: "%.1f%%", (duration - threshold) / threshold * 100)
    ]

    // Add context information
    for (key, value) in context {
      anomalyMetadata[key]=value
    }

    // Log the anomaly
    await logger.warning(
      "Performance anomaly detected in \(operation.description)",
      metadata: anomalyMetadata
    )

    // Prepare privacy-tagged metadata for secure logger
    var secureMetadata: [String: PrivacyTaggedValue]=[
      "operation": PrivacyTaggedValue(value: operation.rawValue, privacyLevel: .public),
      "durationMs": PrivacyTaggedValue(value: Int(duration), privacyLevel: .public),
      "thresholdMs": PrivacyTaggedValue(value: Int(threshold), privacyLevel: .public),
      "exceededBy": PrivacyTaggedValue(value: String(format: "%.1f%%",
                                                     (duration - threshold) / threshold * 100),
                                       privacyLevel: .public)
    ]

    // Add context with privacy tagging
    for (key, value) in context {
      // Determine privacy level based on key name
      let privacyLevel=determinePrivacyLevel(for: key)
      secureMetadata[key]=PrivacyTaggedValue(value: value, privacyLevel: privacyLevel)
    }

    // Log with secure logger for enhanced privacy awareness
    await secureLogger.securityEvent(
      action: "PerformanceAnomaly",
      status: .warning,
      subject: nil,
      resource: nil,
      additionalMetadata: secureMetadata
    )
  }

  /**
   Stores a performance metric in the history collection

   - Parameters:
       - operation: The operation type
       - duration: Duration of the operation in milliseconds
   */
  private func storePerformanceMetric(operation: SecurityOperation, duration: Double) {
    let key=operation.rawValue

    // Create entry if it doesn't exist
    if performanceHistory[key] == nil {
      performanceHistory[key]=[]
    }

    // Add the new measurement
    performanceHistory[key]?.append(duration)

    // Trim history if it exceeds the limit
    if let history=performanceHistory[key], history.count > historyLimit {
      performanceHistory[key]=Array(history.suffix(historyLimit))
    }
  }

  /**
   Calculates the average performance for a specific operation type

   - Parameter operation: The operation type
   - Returns: Average duration in milliseconds, or nil if no history
   */
  private func averagePerformance(for operation: SecurityOperation) -> Double? {
    let key=operation.rawValue

    guard let history=performanceHistory[key], !history.isEmpty else {
      return nil
    }

    let sum=history.reduce(0, +)
    return sum / Double(history.count)
  }

  /**
   Determines the appropriate privacy level for a metadata key

   - Parameter key: The metadata key to evaluate
   - Returns: The appropriate privacy level for the key
   */
  private func determinePrivacyLevel(for key: String) -> PrivacyLevel {
    // Keys that may contain sensitive information
    let sensitiveKeyPatterns=[
      "token", "key", "password", "secret", "credential", "auth",
      "identity", "user", "account", "certificate", "private"
    ]

    // Keys that may contain restricted information
    let restrictedKeyPatterns=[
      "error", "exception", "failure", "id", "session", "context",
      "request", "content", "message"
    ]

    // Check if any sensitive patterns match
    for pattern in sensitiveKeyPatterns {
      if key.lowercased().contains(pattern) {
        return .sensitive
      }
    }

    // Check if any restricted patterns match
    for pattern in restrictedKeyPatterns {
      if key.lowercased().contains(pattern) {
        return .restricted
      }
    }

    // Default to public for metrics
    return .public
  }
}
