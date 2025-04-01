import ErrorCoreTypes
import ErrorHandlingInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import UmbraErrors

/**
 # Default Error Handler Implementation
 
 A thread-safe error handler implementation that provides centralised
 error handling capabilities following the Alpha Dot Five architecture
 principles.
 
 This implementation supports:
 - Privacy-aware error logging
 - Error recovery with customisable strategies
 - Consistent error handling across the application
 */
public actor DefaultErrorHandler: ErrorHandlerProtocol {
  /// Logger for error reporting
  private let errorLogger: ErrorLogger
  
  /// Registry for type-erased recovery strategies
  private var recoveryRegistry: [String: [AnyErrorRecoveryStrategy]] = [:]
  
  // MARK: - Type Erasure for Recovery Strategies
  
  /// Protocol to erase the generic types of ErrorRecoveryStrategy
  private protocol AnyErrorRecoveryStrategy {
    /// Attempts to execute the recovery action with type-erased input/output.
    /// The implementation should attempt to cast the error and context to the expected types.
    func attemptAction(error: Any, context: ErrorContext) async -> Any?
    
    /// The specific error type this strategy handles.
    var errorType: Any.Type { get }
  }
  
  /// Wrapper to hold a concrete strategy and conform to AnyErrorRecoveryStrategy
  private struct RecoveryStrategyWrapper<E: Error, Outcome>: AnyErrorRecoveryStrategy {
    let concreteStrategy: ErrorRecoveryStrategy<E, Outcome>
    
    var errorType: Any.Type { E.self }
    
    func attemptAction(error: Any, context: ErrorContext) async -> Any? {
      // Attempt to cast the provided error to the type this strategy expects
      guard let typedError = error as? E else {
        return nil // Type mismatch
      }
      // Execute the concrete strategy's action
      return await concreteStrategy.action(typedError, context)
    }
  }
  
  /**
   Initialises a new default error handler with the specified error logger.
   
   - Parameter errorLogger: The logger to use for error reporting
   */
  public init(errorLogger: ErrorLogger) {
    self.errorLogger = errorLogger
  }
  
  /**
   Maps ErrorPrivacyLevel to LogPrivacy for proper logging integration.
   
   - Parameter level: The error privacy level to map
   - Returns: The corresponding LogPrivacy level
   */
  private func mapPrivacyLevel(_ level: ErrorPrivacyLevel) -> LogPrivacy {
    switch level {
    case .minimal:
      return .public
    case .standard:
      return .private
    case .enhanced, .maximum:
      return .sensitive
    }
  }
  
  /**
   Handles an error with default options.
   
   This method logs the error with the appropriate privacy level and
   includes a stack trace if requested by the options.
   
   - Parameters:
     - error: The error to handle
     - options: Optional handling options
   */
  public func handleError<E: Error>(_ error: E, options: ErrorHandlingOptions?) async {
    // Determine effective options
    let effectiveOptions = options ?? .standard
    
    // Create basic metadata from options
    var metadata: [String: String] = effectiveOptions.additionalMetadata
    
    // Add stack trace if requested
    if effectiveOptions.includeStackTrace {
      // Thread.callStackSymbols returns a non-optional array, so no need for optional binding
      let stackTrace = Thread.callStackSymbols.joined(separator: "\n")
      metadata["stackTrace"] = stackTrace
    }
    
    // Log the error with appropriate privacy level
    await errorLogger.logError(
      error,
      level: mapErrorToLogLevel(error),
      privacyLevel: mapPrivacyLevel(effectiveOptions.privacyLevel),
      metadata: metadata
    )
    
    // Handle user notification if requested
    if effectiveOptions.notifyUser {
      await notifyUser(about: error)
    }
  }
  
  /**
   Maps an error to an appropriate log level.
   
   - Parameter error: The error to map
   - Returns: The appropriate log level for the error
   */
  private func mapErrorToLogLevel<E: Error>(_ error: E) -> ErrorLogLevel {
    // Determine error severity based on error type
    if let umbraError = error as? any UmbraError {
      return umbraError.severity.toLogLevel()
    }
    
    // Default to error level for unknown errors
    return .error
  }
  
  /**
   Notifies the user about an error.
   
   - Parameter error: The error to notify about
   */
  private func notifyUser<E: Error>(about error: E) async {
    // In a real implementation, this would integrate with a notification system
    // For now, we just log that notification would happen
    var metadata: [String: String] = [:]
    
    // Format error for user display
    let userMessage = formatErrorForUser(error)
    metadata["userMessage"] = userMessage
    
    // We would typically notify the user via UI here if appropriate
    // This requires integrating with the UI layer (e.g., through a delegate or callback)
    // For now, we just log this action
    
    // Convert LogMetadataDTOCollection to [String: String] for the debug method
    // Note: This might need adjustment based on the final logger interface
    let stringMetadata: [String: String] = metadata.reduce(into: [:]) { result, dto in
      result[dto.key] = dto.value
    }
    
    // Log that user notification would occur using a specific error type
    let notificationError = UserNotificationSimulatedError(
      underlyingErrorDescription: error.localizedDescription
    )
    // Use .info level for this operational message
    await errorLogger.info(notificationError)
  }
  
  /**
   Formats an error for user display.
   
   - Parameter error: The error to format
   - Returns: A user-friendly error message
   */
  private func formatErrorForUser<E: Error>(_ error: E) -> String {
    // In a real implementation, this would format the error in a user-friendly way
    // For now, we just return a generic message with the error description
    return "An error occurred: \(error.localizedDescription)"
  }
  
  // Define a specific error type for simulated user notifications
  private struct UserNotificationSimulatedError: Error, LocalizedError {
    let underlyingErrorDescription: String
    var errorDescription: String? {
      "Simulated user notification for error: \(underlyingErrorDescription)"
    }
  }

  /**
   Registers a recovery strategy for an error type.
   
   - Parameters:
     - strategy: The recovery strategy to register
     - forErrorType: The error type to register for
   */
  public func registerRecoveryStrategy<E: Error, Outcome>(
    _ strategy: ErrorRecoveryStrategy<E, Outcome>, 
    forErrorType: E.Type
  ) {
    let key = String(describing: E.self)
    
    // Add to existing strategies or create new entry
    var strategies: [AnyErrorRecoveryStrategy] = recoveryRegistry[key] ?? []
    strategies.append(RecoveryStrategyWrapper(concreteStrategy: strategy))
    recoveryRegistry[key] = strategies
  }
  
  /**
   Handles an error with recovery options and context.
   
   - Parameters:
     - error: The error to handle
     - context: Context information for error handling
     - options: Optional handling options
   */
  public func handleErrorWithContext<E: Error>(_ error: E, context: ErrorContext, options: ErrorHandlingOptions?) async {
    // Determine effective options
    let effectiveOptions = options ?? .standard
    
    // Create basic metadata from options and context
    var metadata = effectiveOptions.additionalMetadata
    
    // Add stack trace if requested
    if effectiveOptions.includeStackTrace {
      let stackTrace = Thread.callStackSymbols.joined(separator: "\n")
      metadata["stackTrace"] = stackTrace
    }
    
    // Add source information
    metadata["file"] = context.source.file
    metadata["function"] = context.source.function
    metadata["line"] = "\(context.source.line)"
    
    // Add metadata from context
    for (key, value) in context.metadata {
      metadata[key] = value
    }
    
    // Log the error with appropriate privacy level
    await errorLogger.logError(
      error,
      level: mapErrorToLogLevel(error),
      privacyLevel: mapPrivacyLevel(effectiveOptions.privacyLevel),
      metadata: metadata
    )
    
    // Handle user notification if requested
    if effectiveOptions.notifyUser {
      await notifyUser(about: error)
    }
  }
  
  /**
   Attempts to recover from an error using registered strategies.
   
   - Parameters:
     - error: The error to recover from
     - context: Context information for recovery
   - Returns: A result indicating whether recovery was successful
   */
  public func attemptRecovery<E: Error, Outcome>(
    from error: E,
    context: ErrorContext
  ) async -> ErrorRecoveryResult<Outcome>? {
    let errorType = type(of: error)
    let key = String(describing: errorType)
    
    // Look for strategies for this exact error type
    guard let strategies = recoveryRegistry[key], !strategies.isEmpty else {
      return nil
    }
    
    // Try each strategy in order
    for strategy in strategies {
      // Attempt to execute the type-erased action and cast the result
      if let outcome = await strategy.attemptAction(error: error, context: context) as? Outcome {
        // Found a successful recovery strategy
        return .recovered(outcome)
      }
    }
    
    // If no strategy succeeded
    return nil
  }
  
  // MARK: - Helper Functions
  
  /**
   Maps an Error to an ErrorLogLevel based on its type or severity.
   
   - Parameter error: The error to map.
   - Returns: The corresponding ErrorLogLevel.
   */
  private func mapErrorToLogLevel<E: Error>(_ error: E) -> ErrorLogLevel {
    if let umbraError = error as? UmbraError {
      return umbraError.severity
    } else {
      // Default to .error for generic Swift errors
      return .error
    }
  }
  
  /**
   Maps ErrorPrivacyLevel to LogPrivacy.
   
   - Parameter level: The ErrorPrivacyLevel.
   - Returns: The corresponding LogPrivacy.
   */
  private func mapPrivacyLevel(_ level: ErrorPrivacyLevel) -> LogPrivacy {
    switch level {
    case .standard: return .private // Default to private for safety
    case .public: return .public
    case .sensitive: return .sensitive
    }
  }
}
