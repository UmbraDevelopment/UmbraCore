import ErrorCoreTypes
import ErrorHandlingInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import UmbraErrors
import LoggingAdapters

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
  
  /// Default options for error handling
  private let defaultOptions = ErrorHandlingOptions.standard
  
  // MARK: - Type Erasure for Recovery Strategies
  
  /// Protocol to erase the generic types of ErrorRecoveryStrategy
  public protocol AnyErrorRecoveryStrategy {
    /// Attempts to execute the recovery action with type-erased input/output.
    /// The implementation should attempt to cast the error and context to the expected types.
    ///
    /// - Parameters:
    ///   - error: The error to recover from
    ///   - context: The context for the recovery attempt
    /// - Returns: The type-erased recovery result if successful, nil otherwise
    func attemptAction(error: Any, context: ErrorContext) async -> Any?
    
    /// A descriptive name for this strategy
    var description: String { get }
  }
  
  /// Wrapper to hold a concrete strategy and conform to AnyErrorRecoveryStrategy
  private struct RecoveryStrategyWrapper<E: Error, Outcome>: AnyErrorRecoveryStrategy {
    let concreteStrategy: ErrorRecoveryStrategy<E, Outcome>
    
    var description: String {
      return concreteStrategy.description
    }
    
    func attemptAction(error: Any, context: ErrorContext) async -> Any? {
      // Attempt to cast the provided error to the type this strategy expects
      guard let typedError = error as? E else {
        return nil // Error type doesn't match, can't handle it
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
   Maps ErrorPrivacyLevel to PrivacyClassification.
   
   - Parameter level: The error privacy level to map
   - Returns: The corresponding privacy classification
   */
  private func mapPrivacyLevelToClassification(_ level: ErrorPrivacyLevel) -> PrivacyClassification {
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
   Handles a specific error with context.
   
   - Parameters:
     - error: The error to handle
     - context: Optional context for error handling
     - options: Optional configuration options
   */
  private func handleError<E: Error>(
    _ error: E,
    context: ErrorContext? = nil,
    options: ErrorHandlingOptions? = nil
  ) async {
    // Apply default options if not provided
    _ = options ?? defaultOptions
    
    // Extract domain information for the error
    let errorDomain = getErrorDomain(for: error)
    
    // Start with base metadata
    var metadata = LogMetadataDTOCollection()
    metadata = metadata.withPublic(key: "errorDomain", value: errorDomain)
    
    // Check if the error conforms to LoggableErrorProtocol
    if let loggableError = error as? LoggableErrorProtocol {
      // Create standard privacy level for logging
      let errorMetadata = loggableError.getPrivacyMetadata()
      
      // Convert PrivacyMetadata to our log metadata format
      var convertedMetadata = LogMetadataDTOCollection()
      // Use subscript to access PrivacyMetadata since it doesn't conform to Sequence
      let keys = ["errorType", "errorMessage", "errorDomain", "errorContext"]
      for key in keys {
        if let metaValue = errorMetadata[key] {
          // For simplicity, treat all error metadata as public in this conversion
          convertedMetadata = convertedMetadata.withPublic(key: key, value: metaValue.valueString)
        }
      }
      
      // Merge with our existing metadata
      metadata = metadata.merging(with: convertedMetadata)
      
      // Create an error context from the current context
      let sourceFile: String
      let sourceFunction: String
      let sourceLine: Int
      
      if let ctx = context {
        sourceFile = ctx.source.file
        sourceFunction = ctx.source.function
        sourceLine = ctx.source.line
      } else {
        sourceFile = #file
        sourceFunction = #function
        sourceLine = #line
      }
      
      let errorContext = ErrorContext(
        source: ErrorSource(
          file: sourceFile,
          function: sourceFunction,
          line: sourceLine
        ),
        metadata: ["domain": errorDomain],
        timestamp: Date()
      )
      
      // Log the error with its defined privacy level and description
      let options = ErrorLoggingOptions(privacyLevel: .standard)
      await errorLogger.logError(
        error,
        level: mapErrorToLogLevel(error),
        context: errorContext,
        options: options
      )
    } else {
      await handleErrorWithMetadata(error, context: context, options: options)
    }
  }
  
  /**
   Determines the error domain for an error.
   
   - Parameter error: The error to get the domain for
   - Returns: The error domain as a string
   */
  private func getErrorDomain<E: Error>(for error: E) -> String {
    // Use defined domain if available
    if let domainError = error as? ErrorDomainProtocol {
      return String(describing: type(of: domainError))
    }
    
    // For NSError, use its domain
    let nsError = error as NSError
    return nsError.domain
  }
  
  /**
   Maps an error to the appropriate logging level based on its severity.
   
   - Parameter error: The error to map
   - Returns: The corresponding ErrorLogLevel.
   */
  private func mapErrorToLogLevel<E>(_ error: E) -> ErrorLogLevel where E: Error {
    // For NSError types, determine level based on domain and code
    let nsError = error as NSError
    if nsError.domain == NSURLErrorDomain {
      // Network errors are typically warnings unless they're connectivity related
      if nsError.code == NSURLErrorNotConnectedToInternet || nsError.code == NSURLErrorTimedOut {
        return .error
      }
      return .warning
    } else if nsError.domain == "NSOSStatusErrorDomain" {
      // OS status errors are typically critical
      return .critical
    }
    
    // Default to warning for unknown errors
    return .warning
  }
  
  /**
   Notifies the user about an error.
   
   - Parameter error: The error to notify about
   */
  private func notifyUser<E: Error>(about error: E) async {
    // Create a metadata collection for user notification
    var metadata = LogMetadataDTOCollection()
    metadata = metadata.withPublic(key: "notificationType", value: "error")
    metadata = metadata.withPublic(key: "errorType", value: String(describing: type(of: error)))
    
    // For LoggableError types, use defined privacy classification
    if let loggableError = error as? LoggableErrorProtocol {
      // Extract public metadata from the error's privacy metadata
      let errorMetadata = loggableError.getPrivacyMetadata()
      var publicValues = [String: String]()
      
      // Get public entries for user notifications
      // Use subscript to access PrivacyMetadata since it doesn't conform to Sequence
      let keys = ["errorType", "errorMessage", "errorDomain", "errorContext"]
      for key in keys {
        if let metaValue = errorMetadata[key], metaValue.privacy == .public {
          publicValues[key] = metaValue.valueString
        }
      }
      
      // Convert to our metadata format
      let publicMetadata = publicValues.reduce(LogMetadataDTOCollection()) { result, entry in
        result.withPublic(key: entry.key, value: entry.value)
      }
      
      metadata = metadata.merging(with: publicMetadata)
    }
    
    // Create a simulated error for user notification
    let notificationError = UserNotificationSimulatedError(
      underlyingErrorDescription: error.localizedDescription
    )
    
    // Create an error context
    let errorContext = ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      ),
      metadata: metadata.toDictionary(),
      timestamp: Date()
    )
    
    // Log the notification separately
    let options = ErrorLoggingOptions(privacyLevel: .minimal)
    await errorLogger.logError(
      notificationError,
      level: .info, // Notifications are informational
      context: errorContext,
      options: options
    )
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
  private struct UserNotificationSimulatedError: Error, LocalizedError, LoggableErrorProtocol {
    let underlyingErrorDescription: String
    
    var errorDescription: String? {
      "Simulated user notification for error: \(underlyingErrorDescription)"
    }
    
    func getPrivacyMetadata() -> PrivacyMetadata {
      var metadata = PrivacyMetadata()
      metadata["errorType"] = PrivacyMetadataValue(value: "UserNotificationSimulatedError", privacy: .public)
      metadata["description"] = PrivacyMetadataValue(value: underlyingErrorDescription, privacy: .auto)
      return metadata
    }
    
    func getSource() -> String {
      return "DefaultErrorHandler"
    }
    
    func getLogMessage() -> String {
      return "User notification simulated: \(underlyingErrorDescription)"
    }
  }
  
  /**
   Represents the result of an error recovery attempt.
   */
  public enum ErrorRecoveryResult<Value> {
    /// Recovery was successful, with associated value
    case recovered(Value)
    
    /// Recovery was unsuccessful, with associated error
    case failed(Error)
    
    /// The recovered value, if recovery was successful
    var value: Value? {
      switch self {
      case .recovered(let value):
        return value
      case .failed:
        return nil
      }
    }
    
    /// The error if recovery failed
    var error: Error? {
      switch self {
      case .recovered:
        return nil
      case .failed(let error):
        return error
      }
    }
    
    /// Whether recovery was successful
    var isSuccessful: Bool {
      switch self {
      case .recovered:
        return true
      case .failed:
        return false
      }
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
   Attempts to recover from an error using registered strategies.
   
   - Parameters:
     - error: The error to recover from
     - strategies: Strategies to try for recovery
   - Returns: A result indicating whether recovery was successful
   */
  public func attemptRecovery<E: Error>(
    from error: E,
    strategies: [AnyErrorRecoveryStrategy]?
  ) async -> Any? {
    let errorType = type(of: error)
    let key = String(describing: errorType)
    
    // Get registered strategies for this error type
    let strategies = strategies ?? recoveryRegistry[key] ?? []
    
    // Try each strategy in order
    for strategy in strategies {
      // Create a default context for recovery
      let context = ErrorContext(
        source: ErrorSource(
          file: #file,
          function: #function,
          line: #line
        ),
        metadata: [:],
        timestamp: Date()
      )
      
      // Attempt to execute the type-erased action and cast the result
      if let outcome = await strategy.attemptAction(error: error, context: context) {
        // Found a successful recovery strategy
        return outcome
      }
    }
    
    // No strategy succeeded
    return nil
  }
  
  /**
   Handles an error with recovery options and context.
   
   - Parameters:
     - error: The error to handle
     - recoveryStrategies: Options for error recovery
     - context: Optional contextual information for the error
     - options: Optional handling options
   - Returns: True if recovery was successful, false otherwise
   */
  public func handleError<E: Error>(
    _ error: E,
    recoveryStrategies: [AnyErrorRecoveryStrategy]?,
    context: ErrorContext?,
    options: ErrorHandlingOptions?
  ) async -> Bool {
    // Log the error first
    await handleError(error, context: context, options: options)
    
    // Apply default options if not provided
    let effectiveOptions = options ?? defaultOptions
    
    // If recovery is disabled, return false early
    if !effectiveOptions.attemptRecovery {
      return false
    }
    
    // Attempt to recover using the specified strategies
    if let _ = await attemptRecovery(from: error, strategies: recoveryStrategies) {
      // If recovery succeeded, log success
      var metadata = LogMetadataDTOCollection()
      metadata = metadata.withPublic(key: "errorType", value: String(describing: type(of: error)))
      metadata = metadata.withPublic(key: "recoverySuccess", value: "true")
      
      // Create an error context
      let errorContext = ErrorContext(
        source: ErrorSource(
          file: #file,
          function: #function,
          line: #line
        ),
        metadata: metadata.toDictionary(),
        timestamp: Date()
      )
      
      // Log recovery success
      let options = ErrorLoggingOptions(privacyLevel: .standard)
      await errorLogger.info(
        error,  // Log the original error that was recovered from
        context: errorContext,
        options: options
      )
      
      return true
    }
    
    // If no strategy succeeded
    return false
  }
  
  /**
   * For non-LoggableErrorProtocol types, use the default privacy level from options
   */
  private func handleErrorWithMetadata(_ error: Error, context: ErrorContext?, options: ErrorHandlingOptions?) async {
    // Start with base metadata
    var metadata = LogMetadataDTOCollection()
    
    // Add error type information
    metadata = metadata.withPublic(key: "errorType", value: String(describing: type(of: error)))
    
    // Add localized description if available
    metadata = metadata.withPrivate(key: "description", value: error.localizedDescription)
    
    // Include file and function information if available
    let sourceFile: String
    let sourceFunction: String
    let sourceLine: Int
    
    if let ctx = context {
      sourceFile = ctx.source.file
      sourceFunction = ctx.source.function
      sourceLine = ctx.source.line
      
      metadata = metadata.withPublic(key: "file", value: sourceFile)
      metadata = metadata.withPublic(key: "function", value: sourceFunction)
      metadata = metadata.withPublic(key: "line", value: String(sourceLine))
    } else {
      sourceFile = #file
      sourceFunction = #function
      sourceLine = #line
    }
    
    // For NSError, include domain and code
    let nsError = error as NSError
    metadata = metadata.withPublic(key: "nsDomain", value: nsError.domain)
    metadata = metadata.withPublic(key: "nsCode", value: String(nsError.code))
    
    // Convert private metadata to a dictionary for the logger
    let metadataDict = metadata.toDictionary()
    
    // Create an error context from the current context
    let errorContext = ErrorContext(
      source: ErrorSource(
        file: sourceFile,
        function: sourceFunction,
        line: sourceLine
      ),
      metadata: metadataDict,
      timestamp: Date()
    )
    
    // Apply default options if not provided
    let effectiveOptions = options ?? defaultOptions
    
    // Create options with the appropriate privacy level
    let loggingOptions = ErrorLoggingOptions(privacyLevel: effectiveOptions.privacyLevel)
    
    // Log the error
    await errorLogger.logError(
      error,
      level: mapErrorToLogLevel(error),
      context: errorContext,
      options: loggingOptions
    )
  }
}
