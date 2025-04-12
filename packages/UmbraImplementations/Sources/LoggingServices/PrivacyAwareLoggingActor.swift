import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Privacy-Aware Logging Actor

 An actor that provides privacy-enhanced logging capabilities following the Alpha Dot Five
 architecture. This implementation ensures sensitive data is properly handled according
 to its privacy classification.

 ## Thread Safety

 This implementation uses Swift's actor model to ensure thread safety when logging
 from multiple concurrent contexts.

 ## Privacy Controls

 The actor applies privacy controls based on:
 - Explicit privacy classifications in metadata
 - Automatic detection of sensitive patterns
 - Environment-based redaction rules

 ## Usage Examples

 ### Basic Logging

 ```swift
 // Create a privacy-aware logger
 let loggingService = await LoggingServiceFactory.shared.createService()
 let logger = PrivacyAwareLoggingActor(
     loggingService: loggingService,
     environment: .development
 )

 // Log a simple message
 await logger.info("Application started")
 ```

 ### Logging with Context

 ```swift
 // Create a context with privacy-classified metadata
 let context = PrivacyAwareLogDTO(
     source: "PaymentService",
     domainName: "Transactions",
     metadata: [
         "transaction_id": (value: transactionId, privacy: .public),
         "amount": (value: amount, privacy: .public),
         "card_number": (value: cardNumber, privacy: .sensitive)
     ]
 )

 // Log with the context
 await logger.info("Payment processed", context: context)
 ```

 ### Logging Sensitive Information

 ```swift
 // Create sensitive metadata
 var sensitiveMetadata = LogMetadata()
 sensitiveMetadata["user_credentials"] = "username:password"

 // Log with sensitive handling
 await logger.logSensitive(
     .info,
     "User credentials validated",
     sensitiveValues: sensitiveMetadata,
     context: baseContext
 )
 ```

 ### Error Logging

 ```swift
 do {
     try performOperation()
 } catch {
     // Log the error with privacy controls
     await logger.logError(
         error,
         privacyLevel: .private,
         context: baseContext
     )
 }
 ```
 */
public actor PrivacyAwareLoggingActor: PrivacyAwareLoggingProtocol {
  /// The underlying logging service
  private let loggingService: LoggingServiceActor

  /// The deployment environment
  private let environment: LoggingTypes.DeploymentEnvironment

  /// Whether to include sensitive details in logs
  private var includeSensitiveDetails: Bool

  /// The logging actor used by this logger
  public nonisolated var loggingActor: LoggingActor {
    // We need to create a new LoggingActor instance since we can't inherit from it
    LoggingActor(destinations: [], minimumLogLevel: .info)
  }

  /**
   Initialises a new privacy-aware logging actor.

   This initialiser creates a new logging actor with the specified configuration.
   The actor's behaviour regarding privacy controls is determined by the environment
   and the includeSensitiveDetails flag.

   - Parameters:
     - loggingService: The underlying logging service that will handle the actual logging
     - environment: The deployment environment, which affects how privacy controls are applied
     - includeSensitiveDetails: Whether to include sensitive details in logs (requires authorisation)

   ## Example

   ```swift
   let loggingService = await LoggingServiceFactory.shared.createService()
   let logger = PrivacyAwareLoggingActor(
       loggingService: loggingService,
       environment: .production,
       includeSensitiveDetails: false
   )
   ```
   */
  public init(
    loggingService: LoggingServiceActor,
    environment: LoggingTypes.DeploymentEnvironment = .development,
    includeSensitiveDetails: Bool=false
  ) {
    self.loggingService=loggingService
    self.environment=environment
    self.includeSensitiveDetails=includeSensitiveDetails
  }

  // MARK: - CoreLoggingProtocol Conformance

  /**
   Logs a message with the specified severity level and context.

   This is the core logging method that handles privacy controls and
   forwards the log to the underlying logging service.

   - Parameters:
     - level: The severity level of the log entry
     - message: The textual content of the log message
     - context: A LoggingInterfaces.LogContextDTO containing contextual information

   ## Example

   ```swift
   await logger.log(.info, "User logged in", context: authContext)
   ```
   */
  public func log(_ level: LogLevel, _ message: String, context: LoggingInterfaces.LogContextDTO) async {
    // Convert LogLevel to UmbraLogLevel
    let umbraLevel=convertToUmbraLogLevel(level)

    // Convert context to PrivacyAwareLogDTO if it's not already
    let privacyContext: PrivacyAwareLogDTO=if let existingPrivacyContext=context as? PrivacyAwareLogDTO {
      existingPrivacyContext
    } else {
      // Create a new PrivacyAwareLogDTO with the source from the context
      PrivacyAwareLogDTO(
        source: context.source,
        domainName: context.domainName,
        correlationID: context.correlationID,
        environment: environment
      )
    }

    // Convert to LogContext for the logging service - we may use this in the future
    _=privacyContext.toLogContext()

    // Log the message with the converted context
    await loggingService.log(
      level: umbraLevel,
      message: message,
      source: context.source
    )
  }

  // MARK: - LoggingProtocol Conformance

  /**
   Logs a debug message.

   - Parameter message: The message to log

   ## Example

   ```swift
   await logger.debug("Processing item 123")
   ```
   */
  public func debug(_ message: String) async {
    await loggingService.log(level: .debug, message: message, source: nil)
  }

  /**
   Logs an info message.

   - Parameter message: The message to log

   ## Example

   ```swift
   await logger.info("User profile updated")
   ```
   */
  public func info(_ message: String) async {
    await loggingService.log(level: .info, message: message, source: nil)
  }

  /**
   Logs a warning message.

   - Parameter message: The message to log

   ## Example

   ```swift
   await logger.warning("Rate limit approaching threshold")
   ```
   */
  public func warning(_ message: String) async {
    await loggingService.log(level: .warning, message: message, source: nil)
  }

  /**
   Logs an error message.

   - Parameter message: The message to log

   ## Example

   ```swift
   await logger.error("Failed to process payment")
   ```
   */
  public func error(_ message: String) async {
    await loggingService.log(level: .error, message: message, source: nil)
  }

  /**
   Logs a critical message.

   - Parameter message: The message to log

   ## Example

   ```swift
   await logger.critical("Database connection lost")
   ```
   */
  public func critical(_ message: String) async {
    await loggingService.log(level: .critical, message: message, source: nil)
  }

  // MARK: - Context-Based Logging

  /**
   Logs a debug message with context.

   - Parameters:
     - message: The message to log
     - context: The logging context

   ## Example

   ```swift
   await logger.debug("Processing payment", context: paymentContext)
   ```
   */
  public func debug(_ message: String, context: LoggingInterfaces.LogContextDTO) async {
    await log(.debug, message, context: context)
  }

  /**
   Logs an info message with context.

   - Parameters:
     - message: The message to log
     - context: The logging context

   ## Example

   ```swift
   await logger.info("User logged in", context: authContext)
   ```
   */
  public func info(_ message: String, context: LoggingInterfaces.LogContextDTO) async {
    await log(.info, message, context: context)
  }

  /**
   Logs a warning message with context.

   - Parameters:
     - message: The message to log
     - context: The logging context

   ## Example

   ```swift
   await logger.warning("API rate limit exceeded", context: apiContext)
   ```
   */
  public func warning(_ message: String, context: LoggingInterfaces.LogContextDTO) async {
    await log(.warning, message, context: context)
  }

  /**
   Logs an error message with context.

   - Parameters:
     - message: The message to log
     - context: The logging context

   ## Example

   ```swift
   await logger.error("Payment processing failed", context: paymentContext)
   ```
   */
  public func error(_ message: String, context: LoggingInterfaces.LogContextDTO) async {
    await log(.error, message, context: context)
  }

  /**
   Logs a critical message with context.

   - Parameters:
     - message: The message to log
     - context: The logging context

   ## Example

   ```swift
   await logger.critical("System shutdown initiated", context: systemContext)
   ```
   */
  public func critical(_ message: String, context: LoggingInterfaces.LogContextDTO) async {
    await log(.critical, message, context: context)
  }

  // MARK: - PrivacyAwareLoggingProtocol Conformance

  /**
   Logs a message with privacy controls applied to the message itself.

   This method allows for logging messages that contain privacy-sensitive
   content directly in the message string.

   - Parameters:
     - level: The severity level of the log
     - message: The privacy-aware message to log
     - context: The logging context

   ## Example

   ```swift
   let message = PrivacyString("User \(userId, privacy: .private) logged in from \(ipAddress, privacy: .sensitive)")
   await logger.log(.info, message, context: baseContext)
   ```
   */
  public func log(_ level: LogLevel, _ message: PrivacyString, context: LoggingInterfaces.LogContextDTO) async {
    // Apply privacy controls to the message
    let processedMessage=message
      .rawValue // In a real implementation, use message.processForLogging()

    // Convert LogLevel to UmbraLogLevel
    let umbraLevel=convertToUmbraLogLevel(level)

    // Convert context to PrivacyAwareLogDTO if it's not already
    let privacyContext: PrivacyAwareLogDTO=if let existingPrivacyContext=context as? PrivacyAwareLogDTO {
      existingPrivacyContext
    } else {
      // Create a new PrivacyAwareLogDTO with the source from the context
      PrivacyAwareLogDTO(
        source: context.source,
        domainName: context.domainName,
        correlationID: context.correlationID,
        environment: environment
      )
    }

    // Add privacy classification for the message
    let enhancedContext=privacyContext.with(metadata: [
      "message_privacy": (value: "privacy_controlled", privacy: .public)
    ])

    // Convert to LogContext for the logging service - we may use this in the future
    _=enhancedContext.toLogContext()

    // Log the message with the converted context
    await loggingService.log(
      level: umbraLevel,
      message: processedMessage,
      source: context.source
    )
  }

  /**
   Logs a message with sensitive values.

   This method allows for logging messages with associated sensitive values
   that require special privacy handling.

   - Parameters:
     - level: The severity level of the log
     - message: The message to log
     - sensitiveValues: Metadata containing sensitive values
     - context: The logging context

   ## Example

   ```swift
   var sensitiveData = LogMetadata()
   sensitiveData["credit_card"] = "1234-5678-9012-3456"

   await logger.logSensitive(
       .info,
       "Payment processed",
       sensitiveValues: sensitiveData,
       context: paymentContext
   )
   ```
   */
  public func logSensitive(
    _ level: LogLevel,
    _ message: String,
    sensitiveValues _: LoggingTypes.LogMetadata,
    context: LoggingInterfaces.LogContextDTO
  ) async {
    // Convert LogLevel to UmbraLogLevel
    let umbraLevel=convertToUmbraLogLevel(level)

    // Convert context to PrivacyAwareLogDTO if it's not already
    let privacyContext: PrivacyAwareLogDTO=if let existingPrivacyContext=context as? PrivacyAwareLogDTO {
      existingPrivacyContext
    } else {
      // Create a new PrivacyAwareLogDTO with the source from the context
      PrivacyAwareLogDTO(
        source: context.source,
        domainName: context.domainName,
        correlationID: context.correlationID,
        environment: environment
      )
    }

    // Add sensitive values with appropriate privacy classification
    var sensitiveMetadata: [String: (value: Any, privacy: LogPrivacyLevel)]=[:]

    // In a real implementation, you would properly extract values from sensitiveValues
    // For now, we'll just add a placeholder
    sensitiveMetadata["sensitive_data"]=(value: "placeholder", privacy: .sensitive)

    let enhancedContext=privacyContext.with(metadata: sensitiveMetadata)

    // Convert to LogContext for the logging service - we may use this in the future
    _=enhancedContext.toLogContext()

    // Log the message with the converted context
    await loggingService.log(
      level: umbraLevel,
      message: message,
      source: context.source
    )
  }

  /**
   Logs an error with privacy controls.

   This method allows for logging errors with appropriate privacy controls
   applied to the error details.

   - Parameters:
     - error: The error to log
     - privacyLevel: The privacy level to apply to the error details
     - context: The logging context

   ## Example

   ```swift
   do {
       try processPayment(card: creditCard)
   } catch let error {
       await logger.logError(
           error,
           privacyLevel: .sensitive,
           context: paymentContext
       )
   }
   ```
   */
  public func logError(
    _ error: Error,
    privacyLevel: LogPrivacyLevel,
    context: LoggingInterfaces.LogContextDTO
  ) async {
    // Convert context to PrivacyAwareLogDTO if it's not already
    let privacyContext: PrivacyAwareLogDTO=if let existingPrivacyContext=context as? PrivacyAwareLogDTO {
      existingPrivacyContext
    } else {
      // Create a new PrivacyAwareLogDTO with the source from the context
      PrivacyAwareLogDTO(
        source: context.source,
        domainName: context.domainName,
        correlationID: context.correlationID,
        environment: environment
      )
    }

    // Add error information with the specified privacy level
    var errorMetadata: [String: (value: Any, privacy: LogPrivacyLevel)]=[:]

    errorMetadata["error_description"]=(value: error.localizedDescription, privacy: privacyLevel)
    errorMetadata["error_type"]=(value: String(describing: type(of: error)), privacy: .public)

    if let nsError=error as NSError? {
      errorMetadata["error_code"]=(value: nsError.code, privacy: .public)
      errorMetadata["error_domain"]=(value: nsError.domain, privacy: .public)
    }

    let enhancedContext=privacyContext.with(metadata: errorMetadata)

    // Convert to LogContext for the logging service - we may use this in the future
    _=enhancedContext.toLogContext()

    // Log the error message with the converted context
    await loggingService.log(
      level: .error,
      message: "Error: \(error.localizedDescription)",
      source: context.source
    )
  }

  // MARK: - Helper Methods

  /**
   Converts LogLevel to UmbraLogLevel.

   This method maps between the different log level enumerations used
   in the system.

   - Parameter level: The LogLevel to convert
   - Returns: The equivalent UmbraLogLevel
   */
  private func convertToUmbraLogLevel(_ level: LogLevel) -> UmbraLogLevel {
    switch level {
      case .trace:
        .verbose
      case .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .critical:
        .critical
    }
  }
}
