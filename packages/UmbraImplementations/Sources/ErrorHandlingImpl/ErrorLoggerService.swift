import ErrorCoreTypes
import ErrorHandlingInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # ErrorLoggerService

 Implementation of the ErrorLoggingProtocol that bridges errors with the logging system.

 This service provides structured error logging capabilities using the Alpha Dot Five
 logging system, preserving British spelling in documentation.
 */
public actor ErrorLoggerService: ErrorLoggingProtocol {
  // MARK: - Properties

  private let logger: LoggingProtocol

  // MARK: - Initialisation

  /**
   Initialises a new ErrorLoggerService with the provided logger.

   - Parameter logger: The underlying logger to use
   */
  public init(logger: LoggingProtocol) {
    self.logger=logger
  }

  // MARK: - ErrorLoggingProtocol Implementation

  /**
   Logs an error with the appropriate level and context.

   - Parameters:
      - error: The error to log
      - level: The severity level for logging this error
      - context: Optional contextual information about the error
   */
  public func logError(
    _ error: some Error,
    level: ErrorLogLevel,
    context: ErrorContext?
  ) async {
    // Create metadata from the error
    var metadata=LoggingTypes.LogMetadata()
    metadata["errorType"]=String(describing: type(of: error))
    metadata["errorMessage"]=error.localizedDescription

    // Add domain information if available
    if let domainError=error as? any ErrorDomainProtocol {
      metadata["errorDomain"]=String(describing: type(of: domainError).domain)
      metadata["errorCode"]="\(domainError.code)"
    }

    // Add context metadata if available
    if let context {
      for (key, value) in context.metadata {
        metadata[key]=value
      }
    }

    // Log with the appropriate level
    let message="[\(level.rawValue.uppercased())] \(error.localizedDescription)"
    let source=context?.source.description ?? "ErrorLoggerService"

    switch level {
      case .debug:
        await logger.debug(message, metadata: metadata, source: source)
      case .info:
        await logger.info(message, metadata: metadata, source: source)
      case .warning:
        await logger.warning(message, metadata: metadata, source: source)
      case .error, .critical:
        await logger.error(message, metadata: metadata, source: source)
    }
  }

  /**
   Logs an error with debug level.

   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
   */
  public func debug(_ error: some Error, context: ErrorContext?) async {
    await logError(error, level: .debug, context: context)
  }

  /**
   Logs an error with info level.

   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
   */
  public func info(_ error: some Error, context: ErrorContext?) async {
    await logError(error, level: .info, context: context)
  }

  /**
   Logs an error with warning level.

   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
   */
  public func warning(_ error: some Error, context: ErrorContext?) async {
    await logError(error, level: .warning, context: context)
  }

  /**
   Logs an error with error level.

   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
   */
  public func error(_ error: some Error, context: ErrorContext?) async {
    await logError(error, level: .error, context: context)
  }
}
