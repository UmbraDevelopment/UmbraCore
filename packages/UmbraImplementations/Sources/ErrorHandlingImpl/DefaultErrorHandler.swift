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

  private let logger: LoggingProtocol

  // MARK: - Initialisation

  /**
   Initialises a new DefaultErrorHandler.

   - Parameter logger: The logger to use for error logging
   */
  public init(logger: LoggingProtocol) {
    self.logger=logger
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
    // Create log metadata
    var logMetadata=LoggingTypes.LogMetadata()

    // Add error information
    logMetadata["errorType"]=String(describing: type(of: error))
    logMetadata["errorMessage"]=error.localizedDescription

    // Add domain information if available
    if let domainError=error as? any ErrorDomainProtocol {
      logMetadata["errorDomain"]=String(describing: type(of: domainError).domain)
      logMetadata["errorCode"]="\(domainError.code)"
    }

    // Add user metadata
    for (key, value) in metadata {
      logMetadata[key]=value
    }

    // Log the error
    await logger.error(
      "Error encountered: \(error.localizedDescription)",
      metadata: logMetadata,
      source: source ?? "DefaultErrorHandler"
    )

    // Handle specific error types differently if needed
    if let _=error as? any ErrorDomainProtocol {
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
    let source=context.source.description
    await handle(error, source: source, metadata: context.metadata)
  }
}
