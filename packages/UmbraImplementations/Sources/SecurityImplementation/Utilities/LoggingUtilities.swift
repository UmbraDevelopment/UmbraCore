import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes

/**
 Utilities for logging services specific to the security implementation.

 This file provides helper functions for working with logging services
 within the security implementation module.
 */
public enum SecurityLoggingUtilities {
  /**
   Creates a wrapper that converts a LoggingServiceActor to LoggingProtocol.

   - Parameter logger: The logging service actor to wrap
   - Returns: A LoggingProtocol instance that delegates to the actor
   */
  public static func createLoggingWrapper(logger: LoggingServiceActor) async -> LoggingProtocol {
    // Create a basic logger that wraps the logging service actor
    StandardLogger(source: "Security") { message, level, metadata in
      // Convert LogLevel to UmbraLogLevel and use the correct parameter labels
      let umbraLevel: LoggingTypes.UmbraLogLevel = level == .debug ? .debug : 
                                                   level == .info ? .info :
                                                   level == .warning ? .warning :
                                                   level == .error ? .error : .critical
      
      await logger.log(
        level: umbraLevel,
        message: message,
        metadata: metadata == nil ? nil : LogMetadataDTOCollection()
      )
    }
  }

  /**
   Creates a secure logger for privacy-aware logging.

   - Parameters:
      - subsystem: The subsystem identifier
      - category: The category for logs
   - Returns: A privacy-aware logger for secure operations
   */
  public static func createSecureLogger(
    subsystem: String,
    category: String
  ) async -> LoggingProtocol {
    // Create a privacy-aware logger with production settings
    let logger = await LoggingServiceFactory.shared.createService(
      minimumLevel: .info
    )
    
    // Wrap it in our protocol adapter
    return await createLoggingWrapper(logger: logger)
  }
}

/**
 A simple logger implementation that delegates to a closure.
 This allows us to bridge between different logger implementations.
 */
private actor StandardLogger: LoggingProtocol {
  private let source: String
  private let logHandler: (String, LogLevel, PrivacyMetadata?) async -> Void
  
  // Add the required loggingActor property
  public var loggingActor: LoggingActor {
    // Create a basic implementation with empty destinations
    LoggingActor(destinations: [], minimumLogLevel: .info)
  }
  
  // Add the required log method that uses LogContextDTO
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    // Simply forward to the appropriate log level methods with the raw message
    switch level {
    case .debug:
      await logHandler(message, .debug, nil)
    case .info:
      await logHandler(message, .info, nil)
    case .warning:
      await logHandler(message, .warning, nil)
    case .error:
      await logHandler(message, .error, nil)
    case .critical:
      await logHandler(message, .critical, nil)
    case .trace:
      await logHandler(message, .debug, nil) // Map trace to debug as a fallback
    }
  }

  init(source: String, logHandler: @escaping (String, LogLevel, PrivacyMetadata?) async -> Void) {
    self.source = source
    self.logHandler = logHandler
  }

  public func debug(_ message: String, metadata: PrivacyMetadata?, source _: String) async {
    await logHandler(message, .debug, metadata)
  }

  public func info(_ message: String, metadata: PrivacyMetadata?, source _: String) async {
    await logHandler(message, .info, metadata)
  }

  public func warning(_ message: String, metadata: PrivacyMetadata?, source _: String) async {
    await logHandler(message, .warning, metadata)
  }

  public func error(_ message: String, metadata: PrivacyMetadata?, source _: String) async {
    await logHandler(message, .error, metadata)
  }

  public func critical(_ message: String, metadata: PrivacyMetadata?, source _: String) async {
    await logHandler(message, .critical, metadata)
  }
}
