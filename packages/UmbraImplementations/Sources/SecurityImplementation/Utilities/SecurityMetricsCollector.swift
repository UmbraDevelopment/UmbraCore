import Foundation
import LoggingTypes
import CoreSecurityTypes
import LoggingInterfaces
import LoggingServices

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
   
   Maps operation types to a list of recent durations in milliseconds
   */
  private var performanceHistory: [String: [Double]] = [:]
  
  /**
   Maximum number of historical performance records to keep per operation
   */
  private let maxHistoryEntries = 10
  
  /**
   Threshold for performance anomaly detection (percentage above average)
   */
  private let anomalyThresholdPercent = 200.0
  
  /**
   Creates a new security metrics collector
   
   - Parameters:
     - logger: The logger to use for general metrics
     - secureLogger: The secure logger to use for privacy-aware metrics
   */
  init(
    logger: LoggingInterfaces.LoggingProtocol,
    secureLogger: SecureLoggerActor
  ) {
    self.logger = logger
    self.secureLogger = secureLogger
  }
  
  /**
   Records performance metrics for a security operation
   
   - Parameters:
     - operation: The type of security operation
     - durationMs: The duration of the operation in milliseconds
     - success: Whether the operation was successful
     - additionalMetadata: Additional metadata to include in the log
   */
  func recordMetrics(
    operation: CoreSecurityTypes.SecurityOperation,
    durationMs: Double,
    success: Bool,
    additionalMetadata: [String: String] = [:]
  ) async {
    // Update performance history
    updatePerformanceHistory(operation: operation.description, duration: durationMs)
    
    // Check for performance anomalies
    if let avgDuration = averagePerformance(for: operation.description),
       durationMs > avgDuration * (1 + anomalyThresholdPercent / 100) {
      await logPerformanceAnomaly(
        operation: operation,
        duration: durationMs,
        average: avgDuration
      )
    }
    
    // Create context for logging
    let context = SecurityMetricsContext(
      operation: operation.description,
      durationMs: String(format: "%.2f", durationMs),
      success: success ? "true" : "false"
    )
    
    // Add any additional metadata
    var enhancedContext = context
    for (key, value) in additionalMetadata {
      enhancedContext = enhancedContext.adding(key: key, value: value, privacyLevel: .public)
    }
    
    // Add historical performance if available
    if let avgDuration = averagePerformance(for: operation.description) {
      enhancedContext = enhancedContext.adding(
        key: "avgDurationMs", 
        value: String(format: "%.2f", avgDuration), 
        privacyLevel: .public
      )
    }
    
    // Log the metrics with appropriate level based on success
    if success {
      await logger.info("Security operation metrics: \(operation.description)", context: enhancedContext)
    } else {
      await logger.warning("Failed security operation metrics: \(operation.description)", context: enhancedContext)
    }
    
    // Also log to secure logger with privacy tags
    await secureLogger.securityEvent(
      action: "MetricsCollection",
      status: success ? .success : .failed,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operation": PrivacyTaggedValue(value: .string(operation.description), privacyLevel: .public),
        "durationMs": PrivacyTaggedValue(value: .number(String(format: "%.2f", durationMs)), privacyLevel: .public),
        "success": PrivacyTaggedValue(value: .bool(success), privacyLevel: .public)
      ]
    )
  }
  
  /**
   Updates the performance history for an operation
   
   - Parameters:
     - operation: The operation type
     - duration: The duration in milliseconds
   */
  private func updatePerformanceHistory(
    operation: String,
    duration: Double
  ) {
    // Initialize history array if needed
    if performanceHistory[operation] == nil {
      performanceHistory[operation] = []
    }
    
    // Add new duration
    performanceHistory[operation]?.append(duration)
    
    // Trim history if needed
    if let history = performanceHistory[operation],
       history.count > maxHistoryEntries {
      performanceHistory[operation] = Array(history.suffix(maxHistoryEntries))
    }
  }
  
  /**
   Calculates the average performance for an operation
   
   - Parameter operation: The operation type
   - Returns: The average duration in milliseconds, or nil if no history
   */
  private func averagePerformance(for operation: String) -> Double? {
    guard let history = performanceHistory[operation], !history.isEmpty else {
      return nil
    }
    
    let sum = history.reduce(0, +)
    return sum / Double(history.count)
  }
  
  /**
   Logs a performance anomaly
   
   - Parameters:
     - operation: The operation that experienced the anomaly
     - duration: The anomalous duration
     - average: The average duration for comparison
   */
  private func logPerformanceAnomaly(
    operation: CoreSecurityTypes.SecurityOperation,
    duration: Double,
    average: Double
  ) async {
    // Calculate percentage above average
    let percentAboveAvg = ((duration / average) - 1.0) * 100.0
    
    // Create context for anomaly logging
    let anomalyContext = SecurityMetricsContext(
      operation: operation.description,
      durationMs: String(format: "%.2f", duration),
      percentAboveAverage: String(format: "%.1f", percentAboveAvg),
      averageDurationMs: String(format: "%.2f", average)
    )
    
    // Log the anomaly
    await logger.warning("Performance anomaly detected in \(operation.description)", context: anomalyContext)
    
    // Prepare privacy-tagged metadata for secure logger
    await secureLogger.securityEvent(
      action: "PerformanceAnomaly",
      status: .warning,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operation": PrivacyTaggedValue(value: .string(operation.description), privacyLevel: .public),
        "durationMs": PrivacyTaggedValue(value: .number(String(format: "%.2f", duration)), privacyLevel: .public),
        "percentAboveAvg": PrivacyTaggedValue(value: .number(String(format: "%.1f", percentAboveAvg)), privacyLevel: .public),
        "avgDurationMs": PrivacyTaggedValue(value: .number(String(format: "%.2f", average)), privacyLevel: .public)
      ]
    )
  }
  
  /**
   Determines the appropriate privacy level for a metadata key
   
   - Parameter key: The metadata key
   - Returns: The appropriate privacy level
   */
  private func privacyLevelForKey(_ key: String) -> LogPrivacyLevel {
    // Keys that might contain sensitive information
    let sensitiveKeyPatterns = [
      "token", "key", "secret", "password", "credential", "auth"
    ]
    
    // Keys that might contain private but not sensitive information
    let privateKeyPatterns = [
      "user", "account", "email", "phone", "address", "name", "id"
    ]
    
    // Check for sensitive patterns first
    for pattern in sensitiveKeyPatterns {
      if key.lowercased().contains(pattern) {
        return .sensitive
      }
    }
    
    // Then check for private patterns
    for pattern in privateKeyPatterns {
      if key.lowercased().contains(pattern) {
        return .private
      }
    }
    
    // Default to public
    return .public
  }
}
