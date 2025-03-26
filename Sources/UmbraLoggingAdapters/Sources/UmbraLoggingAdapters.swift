/// UmbraLoggingAdapters
///
/// This module provides adapter implementations for the UmbraLogging interfaces.
/// It contains the concrete implementations of the logging system that delegate
/// to the underlying logging frameworks via the LoggingWrapper module.
///
/// The adapter pattern used here helps maintain clean separation between the
/// logging interfaces defined in UmbraLogging and their implementations.
import Foundation
import LoggingWrapper
import LoggingWrapperInterfaces
import UmbraLogging
import Adapters

/// Facade for UmbraLoggingAdapters module
public enum UmbraLoggingAdapters {
  /// Create a new instance of the logger implementation
  /// - Returns: A logger instance conforming to LoggingProtocol
  public static func createLogger() -> LoggingProtocol {
    LoggerImplementation.shared
  }

  /// Create a new logger with a specific configuration
  /// - Parameter destinations: Array of log destinations (must be Sendable types)
  /// - Returns: A logger instance conforming to LoggingProtocol
  public static func createLoggerWithDestinations(_ destinations: [some Sendable])
  -> LoggingProtocol {
    // Use a dedicated initialiser method that properly isolates the destinations
    // This ensures thread safety for Swift 6 compatibility
    LoggerImplementation.withDestinations(destinations)
  }
}
