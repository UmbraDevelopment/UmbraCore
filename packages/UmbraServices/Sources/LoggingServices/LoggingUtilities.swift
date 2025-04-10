import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Utilities for logging services.

 This file provides helper functions for working with logging services,
 including conversions between different logger types.
 */
public enum LoggingServices {
  /**
   Creates a wrapper that converts a LoggingActor to LoggingProtocol.

   - Parameter logger: The logging actor to wrap
   - Returns: A LoggingProtocol instance that delegates to the actor
   */
  public static func createLoggingWrapper(logger: LoggingActor) async -> LoggingProtocol {
    ActorLogger(loggingActor: logger, defaultSource: "Security")
  }

  /**
   Creates a secure logger for privacy-aware logging.

   - Parameters:
      - subsystem: The subsystem identifier
      - category: The category for logs
      - includeTimestamps: Whether to include timestamps in log output
   - Returns: A privacy-aware logger for secure operations
   */
  public static func createSecureLogger(
    subsystem: String,
    category: String,
    includeTimestamps _: Bool=true
  ) async -> LoggingProtocol {
    // Create a privacy-aware logger with production settings
    await LoggerFactory.createPrivacyAwareLogger(
      source: "\(subsystem).\(category)",
      minimumLogLevel: .info,
      privacyFilterEnabled: true
    )
  }
}
