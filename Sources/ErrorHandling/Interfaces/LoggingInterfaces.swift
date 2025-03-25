import Foundation
import UmbraErrorsCore

/// Protocol defining a destination for error logs
public protocol LogDestination: Sendable {
  /// Configure the log destination
  /// - Parameter configuration: Configuration settings for the destination
  func configure(with configuration: [String: Any])

  /// Write a log message to the destination
  /// - Parameters:
  ///   - message: The message to log
  ///   - severity: The severity level of the message
  ///   - metadata: Additional contextual information
  func write(message: String, severity: UmbraErrorsCore.ErrorSeverity, metadata: [String: Any]?)
}

/// Service interface for error logging
public protocol ErrorLoggingService: ErrorLoggingProtocol {
  /// Log an error with a specific severity level
  /// - Parameters:
  ///   - error: The error to log
  ///   - severity: The severity level
  func log(_ error: Error, withSeverity severity: UmbraErrorsCore.ErrorSeverity)

  /// Configure the logging service with destinations
  /// - Parameter destinations: The logging destinations to use
  func configure(destinations: [LogDestination])
}

/// Default implementation for converting UmbraErrors to general Error logging
extension ErrorLoggingService {
  public func log(error: some UmbraError, severity: UmbraErrorsCore.ErrorSeverity) {
    log(error, withSeverity: severity)
  }
}
