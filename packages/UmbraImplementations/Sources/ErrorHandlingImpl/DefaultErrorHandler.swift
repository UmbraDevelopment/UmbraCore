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
  private let errorLogger: DomainLogger

  /// Registry for type-erased recovery strategies
  private var recoveryRegistry: [String: [AnyErrorRecoveryStrategy]]=[:]

  /// Default options for error handling
  private let defaultOptions=ErrorHandlingOptions.standard

  // MARK: - Type Erasure for Recovery Strategies

  /// Protocol to erase the generic types of ErrorRecoveryStrategy
  public protocol AnyErrorRecoveryStrategy: Sendable {
    /// Attempts to execute the recovery action with type-erased input/output.
    /// The implementation should attempt to cast the error and context to the expected types.
    ///
    /// - Parameters:
    ///   - error: The error to recover from
    ///   - context: The context for the recovery attempt
    /// - Returns: The type-erased recovery result if successful, nil otherwise
    func attemptAction(error: Any, context: ErrorContext) async -> (any Sendable)?

    /// A descriptive name for this strategy
    var description: String { get }
  }

  /// Wrapper to hold a concrete strategy and conform to AnyErrorRecoveryStrategy
  private struct RecoveryStrategyWrapper<E: Error, Outcome: Sendable>: AnyErrorRecoveryStrategy {
    let concreteStrategy: any ErrorRecoveryStrategy<E, Outcome>

    var description: String {
      concreteStrategy.description
    }

    func attemptAction(error: Any, context: ErrorContext) async -> (any Sendable)? {
      // Attempt to cast the provided error to the type this strategy expects
      guard let typedError=error as? E else {
        return nil // Error type doesn't match, can't handle it
      }

      // Execute the concrete strategy's action
      return await concreteStrategy.action(typedError, context)
    }
  }

  /**
   Initialises a new default error handler with the specified domain logger.

   - Parameter logger: The domain logger to use for error reporting
   */
  public init(logger: DomainLogger) {
    errorLogger=logger
  }

  // MARK: - ErrorHandlerProtocol Implementation

  /**
   Handles an error according to the implementation's strategy.

   This method takes appropriate action to process the error, including
   logging, recovery attempts, and user notification.

   - Parameters:
      - error: The error to handle
      - options: Configuration options for error handling
   */
  public func handle(
    _ error: some Error,
    options: ErrorHandlingOptions?
  ) async {
    // Create default context from current execution point
    let context=ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      ),
      metadata: [:],
      timestamp: Date()
    )

    await handle(error, context: context, options: options)
  }

  /**
   Handles an error with a context.

   This method extracts metadata from the context and applies
   privacy controls based on the context's domain.

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
    let effectiveOptions=options ?? defaultOptions

    // Convert to LoggableErrorDTO if not already
    let loggableError=convertToLoggableErrorDTO(error, context: context)

    // Log the error with appropriate privacy controls
    await logError(loggableError, context: context, options: effectiveOptions)

    // Check if user notification is enabled in options
    if effectiveOptions.notifyUser {
      await notifyUser(about: loggableError)
    }

    // Attempt recovery if strategies are registered and recovery is enabled
    if effectiveOptions.attemptRecovery {
      _=await attemptRecovery(for: error, context: context)
    }
  }

  /**
   Handles an error with recovery options.

   This method attempts to recover from the error using the provided recovery strategies.

   - Parameters:
      - error: The error to handle
      - context: Contextual information about the error
      - recoveryStrategies: Ordered list of recovery strategies to attempt
      - options: Configuration options for error handling

   - Returns: Result indicating whether recovery was successful and the recovery outcome
   */
  public func handleWithRecovery<E: Error, Outcome: Sendable>(
    _ error: E,
    context: ErrorContext?,
    recoveryStrategies: [any ErrorRecoveryStrategy<E, Outcome>],
    options: ErrorHandlingOptions?
  ) async -> ErrorRecoveryResult<Outcome> {
    let actualContext=context ?? ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      ),
      metadata: [:],
      timestamp: Date()
    )

    let effectiveOptions=options ?? defaultOptions

    // Log the error with appropriate privacy controls
    let loggableError=convertToLoggableErrorDTO(error, context: actualContext)
    await logError(loggableError, context: actualContext, options: effectiveOptions)

    // Try each recovery strategy in order
    for strategy in recoveryStrategies {
      let result=await strategy.action(error, actualContext)
      if let outcome=result {
        // Log successful recovery
        await logRecoverySuccess(
          for: loggableError,
          using: strategy.description,
          context: actualContext
        )
        return .recovered(outcome)
      }
    }

    // Log failed recovery
    await logRecoveryFailure(
      for: loggableError,
      context: actualContext,
      options: effectiveOptions
    )

    return .failed(error)
  }

  /**
   Registers a recovery strategy for a specific error type.

   - Parameters:
      - strategy: The recovery strategy to register
      - forErrorType: The concrete error type this strategy handles
   */
  public func registerRecoveryStrategy<E: Error, O: Sendable>(
    _ strategy: any ErrorRecoveryStrategy<E, O>,
    forErrorType: E.Type
  ) async {
    let typeName=String(describing: forErrorType)
    let wrapper=RecoveryStrategyWrapper<E, O>(concreteStrategy: strategy)

    // Create entry if it doesn't exist
    if recoveryRegistry[typeName] == nil {
      recoveryRegistry[typeName]=[]
    }

    // Add the strategy
    recoveryRegistry[typeName]?.append(wrapper)
  }

  // MARK: - Private Helper Methods

  /**
   Converts an Error to a LoggableErrorDTO for structured logging.

   - Parameters:
     - error: The error to convert
     - context: The context for the error
   - Returns: A LoggableErrorDTO suitable for privacy-aware logging
   */
  private func convertToLoggableErrorDTO(
    _ error: some Error,
    context: ErrorContext
  ) -> LoggableErrorDTO {
    // If it's already a LoggableErrorDTO, return it
    if let loggableError=error as? LoggableErrorDTO {
      return loggableError
    }

    // For LoggableErrorProtocol, adapt to the new DTO format
    if let loggableErrorProtocol=error as? LoggableErrorProtocol {
      let message=loggableErrorProtocol.getLogMessage()
      let metadata=loggableErrorProtocol.createMetadataCollection()
      var detailsString=""

      // Extract details from metadata, prioritising sensitive data
      for entry in metadata.entries {
        detailsString += "\(entry.key): \(entry.value)\n"
      }

      return LoggableErrorDTO(
        error: error,
        domain: "App.\(String(describing: type(of: error)))",
        code: 0,
        message: message,
        details: detailsString,
        source: loggableErrorProtocol.getSource(),
        correlationID: context.metadata["correlationID"] ?? UUID().uuidString
      )
    }

    // For NSError, create a structured LoggableErrorDTO
    // In Swift, all Error types can be cast to NSError, so we use direct cast
    let nsError=error as NSError

    // Extract user info for details while filtering sensitive keys
    let sensitiveKeys=["NSUnderlyingError", "NSSensitiveKeys", "NSCredential"]
    let filteredUserInfo=nsError.userInfo.filter { !sensitiveKeys.contains($0.key) }
    let details=filteredUserInfo.description

    return LoggableErrorDTO(
      error: error,
      domain: nsError.domain,
      code: nsError.code,
      message: nsError.localizedDescription,
      details: details,
      source: "\(context.source.file):\(context.source.line)",
      correlationID: context.metadata["correlationID"] ?? UUID().uuidString
    )
  }

  /**
   Logs an error with appropriate privacy controls.

   - Parameters:
     - error: The error to log
     - context: The error context
     - options: Configuration options
   */
  private func logError(
    _ error: LoggableErrorDTO,
    context: ErrorContext,
    options: ErrorHandlingOptions
  ) async {
    // Determine the appropriate log level based on error and options
    _=determineLogLevel(for: error, options: options)

    // Determine privacy level from options
    _=mapPrivacyLevelToClassification(options.privacyLevel)

    // Create log context
    let logContext=CoreLogContext(
      source: "\(context.source.file):\(context.source.line)",
      correlationID: error.correlationID ?? UUID().uuidString,
      metadata: error.createMetadataCollection()
    )

    // Log the error using the domain logger's error method
    await errorLogger.error(
      error.message,
      context: logContext
    )
  }

  /**
   Determines the appropriate log level for an error.

   - Parameters:
     - error: The error to log
     - options: Configuration options
   - Returns: The appropriate error log level
   */
  private func determineLogLevel(
    for error: LoggableErrorDTO,
    options _: ErrorHandlingOptions
  ) -> ErrorLogLevel {
    // Determine based on error domain and code
    switch error.domain {
      case "Network", "NSURLErrorDomain":
        .warning
      case "Security":
        .critical
      case "Validation":
        .info
      default:
        // Based on code ranges
        if error.code >= 500 {
          .critical
        } else if error.code >= 400 {
          .error
        } else {
          .warning
        }
    }
  }

  /**
   Maps ErrorPrivacyLevel to PrivacyClassification.

   - Parameter level: The error privacy level to map
   - Returns: The corresponding privacy classification
   */
  private func mapPrivacyLevelToClassification(_ level: ErrorPrivacyLevel)
  -> PrivacyClassification {
    switch level {
      case .minimal:
        .public
      case .standard:
        .private
      case .enhanced, .maximum:
        .sensitive
    }
  }

  /**
   Notifies the user about an error.

   This creates a user-friendly error notification with
   appropriate privacy controls.

   - Parameter error: The error to notify about
   */
  private func notifyUser(about error: LoggableErrorDTO) async {
    // Create a user-friendly notification context
    _=ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      ),
      metadata: ["notificationType": "userFacing"],
      timestamp: Date()
    )

    // Create a notification metadata collection
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "errorDomain", value: error.domain)
    metadata=metadata.withPublic(key: "errorCode", value: String(error.code))

    // Extract user-friendly message
    let userMessage=formatErrorForUser(error)

    // Log at info level with public classification
    let logContext=CoreLogContext(
      source: "UserNotification",
      correlationID: nil,
      metadata: metadata
    )

    await errorLogger.info("User notification: \(userMessage)", context: logContext)
  }

  /**
   Formats an error for user display.

   Creates a user-friendly error message that doesn't expose sensitive details.

   - Parameter error: The error to format
   - Returns: A user-friendly error message
   */
  private func formatErrorForUser(_ error: LoggableErrorDTO) -> String {
    // Create user-friendly messages based on domain
    switch error.domain {
      case "Network", "NSURLErrorDomain":
        "A network error occurred. Please check your connection and try again."
      case "Security":
        "A security error occurred. Please try again or contact support."
      case "Validation":
        "Please check your input and try again."
      default:
        // Generic message, no sensitive details
        "An error occurred: \(error.message)"
    }
  }

  /**
   Attempts to recover from an error using registered strategies.

   - Parameters:
     - error: The error to recover from
     - context: The context for recovery
   - Returns: Recovery result if successful, nil otherwise
   */
  private func attemptRecovery(
    for error: some Error,
    context: ErrorContext
  ) async -> Any? {
    // Get the type name for this error
    let typeName=String(describing: type(of: error))

    // Check if we have strategies registered for this type
    guard let strategies=recoveryRegistry[typeName] else {
      return nil
    }

    // Log recovery attempt
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "errorType", value: typeName)
      .withPublic(key: "strategyCount", value: String(strategies.count))

    let logContext=CoreLogContext(
      source: "DefaultErrorHandler.attemptRecovery",
      correlationID: nil,
      metadata: metadata
    )

    await errorLogger.debug("Attempting error recovery", context: logContext)

    // Try each strategy in order
    for strategy in strategies {
      if let result=await strategy.attemptAction(error: error, context: context) {
        // Log successful recovery
        await errorLogger.info("Error recovery successful", context: logContext)
        return result
      }
    }

    // Log failed recovery
    await errorLogger.warning("Error recovery failed - no strategy succeeded", context: logContext)
    return nil
  }

  /**
   Logs a successful recovery attempt.

   - Parameters:
     - error: The error that was recovered from
     - strategyName: The name of the successful strategy
     - context: The error context
   */
  private func logRecoverySuccess(
    for error: LoggableErrorDTO,
    using strategyName: String,
    context _: ErrorContext
  ) async {
    var metadata=error.createMetadataCollection()
    metadata=metadata.withPublic(key: "recoveryStrategy", value: strategyName)
    metadata=metadata.withPublic(key: "recoveryStatus", value: "success")

    let logContext=CoreLogContext(
      source: "ErrorRecovery",
      correlationID: error.correlationID ?? UUID().uuidString,
      metadata: metadata
    )

    await errorLogger.info("Successfully recovered from error", context: logContext)
  }

  /**
   Logs a failed recovery attempt.

   - Parameters:
     - error: The error that failed recovery
     - context: The error context
     - options: Configuration options
   */
  private func logRecoveryFailure(
    for error: LoggableErrorDTO,
    context _: ErrorContext,
    options: ErrorHandlingOptions
  ) async {
    var metadata=error.createMetadataCollection()
    metadata=metadata.withPublic(key: "recoveryStatus", value: "failure")

    let logContext=CoreLogContext(
      source: "ErrorRecovery",
      correlationID: error.correlationID ?? UUID().uuidString,
      metadata: metadata
    )

    _=mapPrivacyLevelToClassification(options.privacyLevel)
    // No need to pass the privacy level if not used
    await errorLogger.warning("Failed to recover from error", context: logContext)
  }
}

/**
 Protocol defining an error recovery strategy with typed error and outcome.
 */
public protocol ErrorRecoveryStrategy<ErrorType, Outcome>: Sendable, CustomStringConvertible where Outcome: Sendable {
  /// The specific type of error this strategy handles.
  associatedtype ErrorType: Error

  /// The type of the successful outcome if recovery succeeds.
  associatedtype Outcome: Sendable

  /// A descriptive name for the strategy (e.g., "Retry Network Request").
  var description: String { get }

  /// Attempts to recover from the error.
  ///
  /// - Parameters:
  ///   - error: The error to recover from
  ///   - context: The context for the recovery attempt
  /// - Returns: The recovery outcome if successful, nil otherwise
  func action(_ error: ErrorType, _ context: ErrorContext) async -> Outcome?
}
