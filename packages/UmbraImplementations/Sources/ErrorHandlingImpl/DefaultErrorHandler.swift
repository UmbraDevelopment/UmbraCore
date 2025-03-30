import ErrorCoreTypes
import ErrorHandlingInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # DefaultErrorHandler
 
 Default implementation of the ErrorHandlerProtocol that handles
 errors according to the Alpha Dot Five architecture principles of
 privacy-aware error handling, structured logging, and actor-based
 concurrency.
 
 This handler ensures errors are properly logged with appropriate
 privacy controls, categorised by domain, and processed for analysis.
 */
public actor DefaultErrorHandler: ErrorHandlerProtocol {
  /// Logger for error reporting
  private let errorLogger: ErrorLogger
  
  /**
   Initialises a new error handler.
   
   - Parameter logger: The logger to use for error reporting
   */
  public init(logger: LoggingProtocol) {
    self.errorLogger = ErrorLogger(logger: logger)
  }
  
  /**
   Handles an error with additional source information and metadata.
   
   - Parameters:
      - error: The error to handle
      - source: Source identifier for the error
      - metadata: Additional contextual information
   */
  public func handle<E: Error>(
    _ error: E,
    source: String?,
    metadata: [String: String]
  ) async {
    // Log the error using our structured, privacy-aware logger
    await errorLogger.logError(
      error,
      source: source,
      metadata: metadata
    )

    // Handle specific error types differently if needed
    if let _ = error as? any ErrorDomainProtocol {
      // Special handling for domain errors could be added here
    }

    // Additional error handling logic could be added here
  }

  /**
   Handles an error with a context.

   This is a convenience method that extracts source and metadata from the context.

   - Parameters:
      - error: The error to handle
      - context: Contextual information about the error
   */
  public func handle<E: Error>(
    _ error: E,
    context: ErrorContext
  ) async {
    // Convert context to metadata dictionary
    var metadata: [String: String] = [:]
    for (key, value) in context.metadata {
      metadata[key] = value
    }
    
    // Convert ErrorSource to String
    let sourceString = context.source.description
    
    // Log the error using our structured, privacy-aware logger
    await errorLogger.logError(
      error,
      source: sourceString,
      metadata: metadata
    )

    // Additional context-specific handling could be added here
  }
}
