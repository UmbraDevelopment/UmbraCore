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
  
  /// Registry of recovery strategies
  private var recoveryRegistry: [String: Any] = [:]

  /**
   Initialises a new error handler.

   - Parameter logger: The logger to use for error reporting
   */
  public init(logger: PrivacyAwareLoggingProtocol) {
    self.errorLogger = ErrorLogger(logger: logger)
  }

  /**
   Handles an error according to the implementation's strategy.

   This method takes appropriate action to process the error, including
   logging, recovery attempts, and monitoring as specified in the options.

   - Parameters:
      - error: The error to handle
      - options: Configuration options for error handling
   */
  public func handle(
    _ error: some Error,
    options: ErrorHandlingOptions?
  ) async {
    // Get options with defaults if not provided
    let effectiveOptions = options ?? .standard
    
    // Create basic metadata from options
    var metadata: [String: String] = effectiveOptions.additionalMetadata
    
    // Add stack trace if requested
    if effectiveOptions.includeStackTrace {
      // Capture current stack trace if available
      if let stackTrace = Thread.callStackSymbols.joined(separator: "\n") {
        metadata["stackTrace"] = stackTrace
      }
    }
    
    // Log the error with appropriate privacy level
    await errorLogger.logError(
      error,
      level: mapErrorToLogLevel(error),
      privacyLevel: effectiveOptions.privacyLevel,
      metadata: metadata
    )
    
    // Handle user notification if requested
    if effectiveOptions.notifyUser {
      // Code to notify user would go here
      // This could involve posting a notification or other UI feedback
    }
    
    // Report to monitoring systems if requested
    if effectiveOptions.reportToMonitoring {
      // Code to report to monitoring systems would go here
      // This could involve sending to analytics, crash reporting, etc.
    }
    
    // Attempt recovery if requested (implementation would depend on registered strategies)
    if effectiveOptions.attemptRecovery {
      // Attempt generic recovery based on error type
      // Specific recovery logic would be implemented here
    }
  }

  /**
   Handles an error with a context.

   This method extracts metadata from the context and applies privacy
   controls based on the context's domain.

   - Parameters:
      - error: The error to handle
      - context: Contextual information about the error
      - options: Configuration options for error handling
   */
  public func handle(
    _ error: some Error,
    context: ErrorContext,
    options: ErrorHandlingOptions?
  ) async {
    // Get options with defaults if not provided
    let effectiveOptions = options ?? .standard
    
    // Create combined metadata from context and options
    var metadata: [String: String] = effectiveOptions.additionalMetadata
    
    // Add context metadata, prioritising context values in case of conflicts
    for (key, value) in context.metadata {
      metadata[key] = value
    }
    
    // Add source information from context
    metadata["source"] = context.source.description
    
    // Add domain information from context if available
    if let domain = context.domain {
      metadata["domain"] = domain.description
    }
    
    // Determine privacy level based on context and options
    let effectivePrivacyLevel = determinePrivacyLevel(
      from: context,
      baseLevel: effectiveOptions.privacyLevel
    )
    
    // Log the error with enhanced context
    await errorLogger.logError(
      error,
      level: mapErrorToLogLevel(error),
      privacyLevel: effectivePrivacyLevel,
      metadata: metadata
    )
    
    // Additional context-specific handling
    if let domain = context.domain {
      // Domain-specific handling could be implemented here
      // For example, different notification strategies per domain
    }
    
    // Handle user notification if requested
    if effectiveOptions.notifyUser {
      // Context-aware user notification would go here
    }
    
    // Report to monitoring systems if requested
    if effectiveOptions.reportToMonitoring {
      // Context-aware monitoring reporting would go here
    }
    
    // Attempt recovery if requested
    if effectiveOptions.attemptRecovery {
      // Context-aware recovery strategy selection would go here
    }
  }
  
  /**
   Handles an error with recovery options.
   
   This method attempts to recover from the error using the provided 
   recovery strategies in order. It returns a result indicating whether
   recovery was successful and the recovery outcome.
   
   - Parameters:
      - error: The error to handle
      - context: Contextual information about the error
      - recoveryStrategies: Ordered list of recovery strategies to attempt
      - options: Configuration options for error handling
   
   - Returns: Result indicating whether recovery was successful and the recovery outcome
   */
  public func handleWithRecovery<E: Error, Outcome>(
    _ error: E,
    context: ErrorContext,
    recoveryStrategies: [ErrorRecoveryStrategy<E, Outcome>],
    options: ErrorHandlingOptions?
  ) async -> ErrorRecoveryResult<Outcome> {
    // Get options with defaults if not provided
    let effectiveOptions = options ?? .standard
    
    // Log the error first
    await handle(error, context: context, options: effectiveOptions)
    
    // If recovery is disabled, return not attempted
    if !effectiveOptions.attemptRecovery {
      return .notAttempted
    }
    
    // No strategies provided, return not attempted
    if recoveryStrategies.isEmpty {
      return .notAttempted
    }
    
    // Try each recovery strategy in order
    for (index, strategy) in recoveryStrategies.enumerated() {
      do {
        // Log that we're attempting a recovery strategy
        await errorLogger.info(
          "Attempting recovery strategy \(index + 1)/\(recoveryStrategies.count): \(strategy.description)",
          metadata: ["errorType": String(describing: type(of: error))]
        )
        
        // Apply the recovery strategy
        if let outcome = await strategy.action(error, context) {
          // Log success
          await errorLogger.info(
            "Recovery successful using strategy: \(strategy.description)",
            metadata: ["errorType": String(describing: type(of: error))]
          )
          return .recovered(outcome)
        }
      } catch {
        // Log failure of this strategy, but continue to the next one
        await errorLogger.warning(
          "Recovery strategy failed: \(strategy.description)",
          metadata: ["errorType": String(describing: type(of: error)), "recoveryError": String(describing: error)]
        )
      }
    }
    
    // All strategies failed or returned nil
    return .failed(error)
  }
  
  // MARK: - Private Helper Methods
  
  /**
   Determines the appropriate log level for an error.
   
   Maps different error types to appropriate log levels based on severity.
   
   - Parameter error: The error to map
   - Returns: The appropriate log level
   */
  private func mapErrorToLogLevel(_ error: Error) -> ErrorLogLevel {
    // Determine log level based on error type or severity
    if let domainError = error as? ErrorDomainProtocol {
      switch domainError.severity {
      case .low:
        return .info
      case .medium:
        return .warning
      case .high:
        return .error
      case .critical:
        return .critical
      }
    }
    
    // Default mapping for standard errors
    return .error
  }
  
  /**
   Determines the effective privacy level based on context.
   
   - Parameters:
     - context: The error context
     - baseLevel: The base privacy level from options
   
   - Returns: The effective privacy level to use
   */
  private func determinePrivacyLevel(
    from context: ErrorContext,
    baseLevel: ErrorPrivacyLevel
  ) -> ErrorPrivacyLevel {
    // If the context has specific privacy requirements, prioritise those
    if let domain = context.domain {
      // This could be expanded to have domain-specific privacy rules
      if domain.description.contains("Security") || 
         domain.description.contains("Crypto") ||
         domain.description.contains("Authentication") {
        // Security domains get enhanced privacy by default
        return baseLevel < .enhanced ? .enhanced : baseLevel
      }
    }
    
    // Otherwise use the base level
    return baseLevel
  }
}
