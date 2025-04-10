import ErrorLoggingInterfaces
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import UmbraErrors
import UmbraErrorsCore

/// Protocol for errors that provide additional context information
public protocol ContextualError: Error {
  /// Domain where the error occurred
  var domain: String { get }

  /// Operation being performed when error occurred
  var operation: String? { get }

  /// Details about the error
  var details: String? { get }

  /// Optional underlying error
  var underlyingError: Error? { get }

  /// Severity of the error
  var severity: ErrorSeverity? { get }

  /// Context metadata
  var contextMetadata: [String: String] { get }
}

/**
 # Error Logger Actor

 Actor-based implementation of ErrorLoggingProtocol that provides thread-safe
 error logging capabilities following the Alpha Dot Five architecture.

 ## Thread Safety

 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in logging configuration and operation.

 ## Features

 This implementation provides a comprehensive error logging service with:
 - Context-aware error logging
 - Domain-specific filtering
 - Privacy controls for sensitive information
 - Severity mapping based on error types
 - Source code location tracking

 ## Implementation Details

 The implementation delegates the actual logging to a LoggingServiceProtocol instance,
 applying appropriate transformations to errors and context information before logging.
 */
public actor ErrorLoggerActor: ErrorLoggingProtocol {
  /// The underlying logger for output
  private let logger: LoggingServiceProtocol

  /// Configuration for the error logger
  private let configuration: ErrorLoggerConfiguration

  /// Domain-specific log level filters
  private var domainFilters: [String: ErrorLoggingLevel]=[:]

  /**
   Initialise a new error logger with default settings.

   - Parameter logger: The logging service to use for output
   */
  public init(logger: LoggingServiceProtocol) {
    self.logger=logger
    configuration=ErrorLoggerConfiguration()
  }

  /**
   Initialise a new error logger with custom configuration.

   - Parameters:
     - logger: The logging service to use for output
     - configuration: Custom configuration for error logging
   */
  public init(logger: LoggingServiceProtocol, configuration: ErrorLoggerConfiguration) {
    self.logger=logger
    self.configuration=configuration
  }

  // MARK: - Error Logging Methods

  /**
   Log an error with full context.

   This method provides complete control over the logging process,
   allowing detailed customisation of context and severity.

   - Parameters:
     - error: The error to log
     - context: Additional context for the error
     - level: The severity level for logging
     - file: Source file where the error occurred
     - function: Function where the error occurred
     - line: Line number where the error occurred
   */
  public func logWithContext(
    _ error: Error,
    context: ErrorContext,
    level: ErrorLoggingLevel,
    file _: String,
    function _: String,
    line _: Int
  ) async {
    // Check if we should log based on domain filters
    let errorDomain=extractErrorDomain(from: error)
    guard shouldLog(level: level, forDomain: errorDomain) else {
      return
    }

    // Create metadata from error and context
    let metadata=constructMetadataCollection(from: error, context: context)

    // Format the message
    let message=formatErrorMessage(error: error, context: context)

    // Log using the appropriate level - using the correct logging method
    switch level {
      case .debug:
        await logger.debug(message, metadata: metadata, source: errorDomain)
      case .info:
        await logger.info(message, metadata: metadata, source: errorDomain)
      case .warning:
        await logger.warning(message, metadata: metadata, source: errorDomain)
      case .error:
        await logger.error(message, metadata: metadata, source: errorDomain)
      case .critical:
        await logger.critical(message, metadata: metadata, source: errorDomain)
    }
  }

  /**
   Log an error with automatic context extraction.

   This convenience method automatically extracts context from the error
   if it conforms to relevant contextual protocols, simplifying common logging.

   - Parameters:
     - error: The error to log
     - level: Optional override for the severity level
     - file: Source file where the error occurred
     - function: Function where the error occurred
     - line: Line number where the error occurred
   */
  public func log(
    _ error: Error,
    level: ErrorLoggingLevel?,
    file: String,
    function: String,
    line: Int
  ) async {
    // Extract context from the error if possible
    let context=extractContext(from: error)

    // Determine the appropriate logging level
    let logLevel=level ?? determineSeverity(for: error, context: context)

    // Log with the extracted/determined values
    await logWithContext(
      error,
      context: context,
      level: logLevel,
      file: file,
      function: function,
      line: line
    )
  }

  // MARK: - Domain Filter Methods

  /**
   Set filters for domain-specific log levels.

   This method allows configuring different minimum log levels
   for different error domains, enabling fine-grained control.

   - Parameter filters: Dictionary mapping domain names to minimum log levels
   */
  public func setDomainFilters(_ filters: [String: ErrorLoggingLevel]) async {
    domainFilters=filters
  }

  /**
   Get the current domain filters.

   Retrieves the currently active domain-specific logging level filters.

   - Returns: Dictionary of domain filters
   */
  public func getDomainFilters() async -> [String: ErrorLoggingLevel] {
    domainFilters
  }

  /**
   Add a single domain filter.

   Sets the minimum logging level for a specific error domain.

   - Parameters:
     - domain: The error domain to filter
     - level: The minimum level to log for this domain
   */
  public func addDomainFilter(domain: String, level: ErrorLoggingLevel) async {
    domainFilters[domain]=level
  }

  /**
   Remove a domain filter.

   Removes any specific logging level filter for the given domain.

   - Parameter domain: The domain to remove filtering for
   */
  public func removeDomainFilter(domain: String) async {
    domainFilters.removeValue(forKey: domain)
  }

  /**
   Set the minimum logging level for a specific error domain.

   - Parameters:
     - level: The minimum logging level for the domain
     - domain: The error domain to filter
   */
  public func setLogLevel(_ level: ErrorLoggingLevel, forDomain domain: String) async {
    domainFilters[domain]=level
  }

  /**
   Clear all domain-specific filters.

   Removes all domain-specific log level filters, returning to
   global minimum level filtering only.
   */
  public func clearDomainFilters() async {
    domainFilters.removeAll()
  }

  // MARK: - Helper Methods

  /**
   Determine if an error should be logged based on level and domain filters.

   - Parameters:
     - level: The level the error would be logged at
     - domain: The domain the error belongs to
   - Returns: True if the error should be logged, false otherwise
   */
  private func shouldLog(level: ErrorLoggingLevel, forDomain domain: String) -> Bool {
    // Check if there's a domain-specific filter
    if let domainLevel=domainFilters[domain] {
      return level.rawValue >= domainLevel.rawValue
    }

    // Check if there's a global minimum level
    return level.rawValue >= configuration.minimumLevel.rawValue
  }

  /**
   Extract the domain from an error.

   - Parameter error: The error to extract the domain from
   - Returns: The domain string
   */
  private func extractErrorDomain(from error: Error) -> String {
    // Check if the error provides its own domain
    if let contextualError=error as? ContextualError {
      return contextualError.domain
    }

    // Fall back to NSError domain
    let nsError=error as NSError
    return nsError.domain
  }

  /**
   Determine the appropriate severity level for an error.

   - Parameters:
     - error: The error to determine severity for
     - context: Additional context for the error
   - Returns: The appropriate logging level
   */
  private func determineSeverity(for error: Error, context: ErrorContext) -> ErrorLoggingLevel {
    // Check if the error provides its own severity
    if let contextualError=error as? ContextualError, let severity=contextualError.severity {
      return mapSeverityToLevel(severity)
    }

    // Check if the context specifies a severity
    if let severity=context.value(for: "severity") as? ErrorSeverity {
      return mapSeverityToLevel(severity)
    }

    // Default to error level
    return .error
  }

  /**
   Map error severity to logging level.

   - Parameter severity: The error severity
   - Returns: The corresponding logging level
   */
  private func mapSeverityToLevel(_ severity: ErrorSeverity) -> ErrorLoggingLevel {
    switch severity {
      case .trace:
        .debug // Map trace to debug since ErrorLoggingLevel doesn't have trace
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

  /**
   Extract context information from an error.

   - Parameter error: The error to extract context from
   - Returns: Error context with extracted information
   */
  private func extractContext(from error: Error) -> ErrorContext {
    var metadata: [String: Any]=[:]
    var domain="unknown"
    var operation: String?
    var details: String?

    // Extract information from contextual error
    if let contextualError=error as? ContextualError {
      domain=contextualError.domain
      operation=contextualError.operation
      details=contextualError.details

      // Add metadata from contextual error
      for (key, value) in contextualError.contextMetadata {
        metadata[key]=value
      }

      // Add underlying error if available
      if let underlyingError=contextualError.underlyingError {
        metadata["underlyingError"]=String(describing: underlyingError)
      }
    }

    // Create context with extracted information
    return ErrorContext(
      metadata,
      source: domain,
      operation: operation,
      details: details
    )
  }

  /**
   Construct metadata collection from error and context.

   - Parameters:
     - error: The error to extract metadata from
     - context: Additional context for the error
   - Returns: Privacy-aware metadata collection for logging
   */
  private func constructMetadataCollection(
    from error: Error,
    context: ErrorContext
  ) -> LogMetadataDTOCollection {
    var collection=LogMetadataDTOCollection()

    // Add basic error type information - public information
    collection=collection.withPublic(key: "errorType", value: String(describing: type(of: error)))

    // Add domain and other context info if available
    if let source=context.source {
      collection=collection.withPublic(key: "domain", value: source)
    }

    if let operation=context.operation {
      collection=collection.withPublic(key: "operation", value: operation)
    }

    // Add source information if configured
    if configuration.includeSourceInfo {
      collection=collection.withPublic(key: "file", value: context.file)
      collection=collection.withPublic(key: "function", value: context.function)
      collection=collection.withPublic(key: "line", value: String(context.line))
    }

    // Add contextual information from the error - some as private
    let nsError=error as NSError
    collection=collection.withPublic(key: "errorCode", value: String(nsError.code))

    // Add user info keys that might be relevant - as private since they may contain sensitive
    // details
    if let failureReason=nsError.localizedFailureReason {
      collection=collection.withPrivate(key: "failureReason", value: failureReason)
    }
    if let recoverySuggestion=nsError.localizedRecoverySuggestion {
      collection=collection.withPrivate(key: "recoverySuggestion", value: recoverySuggestion)
    }

    // Add additional metadata from the context using value(for:)
    // Use appropriate privacy levels based on the type of information
    if let userID=context.value(for: "userId") {
      collection=collection.withSensitive(key: "userId", value: String(describing: userID))
    }

    if let sessionID=context.value(for: "sessionId") {
      collection=collection.withPrivate(key: "sessionId", value: String(describing: sessionID))
    }

    if let documentID=context.value(for: "documentId") {
      collection=collection.withPrivate(key: "documentId", value: String(describing: documentID))
    }

    if let errorCode=context.value(for: "errorCode") {
      collection=collection.withPublic(
        key: "contextErrorCode",
        value: String(describing: errorCode)
      )
    }

    if let attemptCount=context.value(for: "attemptCount") {
      collection=collection.withPublic(key: "attemptCount", value: String(describing: attemptCount))
    }

    return collection
  }

  /**
   Format an error message with available context information.

   - Parameters:
     - error: The error to format
     - context: Additional context for the error
   - Returns: Formatted error message string
   */
  private func formatErrorMessage(error: Error, context: ErrorContext) -> String {
    var components: [String]=[]

    // Add domain and operation if available
    if let operation=context.operation {
      if let source=context.source {
        components.append("[\(source):\(operation)]")
      } else {
        components.append("[\(operation)]")
      }
    } else if let source=context.source {
      components.append("[\(source)]")
    }

    // Add error message
    if let details=context.details {
      components.append(details)
    } else {
      components.append(error.localizedDescription)
    }

    return components.joined(separator: " ")
  }
}
