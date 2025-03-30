import ErrorCoreTypes
import ErrorHandlingInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # DefaultErrorHandler

 Default implementation of the ErrorHandlerProtocol.

 This implementation logs errors and provides basic error handling
 functionality. It follows the Alpha Dot Five architecture by providing
 a concrete implementation of an interface with proper British spelling
 in documentation.
 */
public actor DefaultErrorHandler: ErrorHandlerProtocol {
  // MARK: - Properties

  /// The logger to use for error logging
  private let logger: LoggingProtocol
  
  /// Domain-specific logger for error handling
  private let errorLogger: ErrorLogger

  // MARK: - Initialisation

  /**
   Initialises a new DefaultErrorHandler.

   - Parameter logger: The logger to use for error logging
   */
  public init(logger: LoggingProtocol) {
    self.logger = logger
    self.errorLogger = ErrorLogger(logger: logger)
  }

  // MARK: - ErrorHandlerProtocol Implementation

  /**
   Handles an error according to the implementation's strategy.

   This method logs the error with appropriate metadata and takes
   appropriate action based on error type.

   - Parameters:
      - error: The error to handle
      - source: Optional string identifying the error source
      - metadata: Additional contextual information about the error
   */
  public func handle(
    _ error: some Error,
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
  public func handle(
    _ error: some Error,
    context: ErrorContext
  ) async {
    // Convert context to metadata dictionary
    var metadata: [String: String] = [:]
    for (key, value) in context.metadata {
      metadata[key] = value
    }
    
    // Log the error using our structured, privacy-aware logger
    await errorLogger.logError(
      error,
      source: context.source,
      metadata: metadata
    )

    // Additional error handling logic could be added here
  }
}
