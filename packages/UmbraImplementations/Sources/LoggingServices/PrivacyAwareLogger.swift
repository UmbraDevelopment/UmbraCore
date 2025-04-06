import LoggingInterfaces
import LoggingTypes

/// An actor that implements the PrivacyAwareLoggingProtocol with support for
/// privacy controls and proper isolation for concurrent logging.
public actor PrivacyAwareLogger: PrivacyAwareLoggingProtocol, LoggingProtocol {
  /// The minimum log level to process
  private let minimumLevel: LogLevel

  /// The identifier for this logger instance
  private let identifier: String

  /// The backend that will actually write the logs
  private let backend: LoggingBackend

  /// The logging actor required by LoggingProtocol
  public let loggingActor: LoggingActor

  /// Creates a new privacy-aware logger
  /// - Parameters:
  ///   - minimumLevel: The minimum log level to process
  ///   - identifier: The identifier for this logger instance
  ///   - backend: The backend that will actually write the logs
  ///   - loggingActor: Optional custom logging actor, will create a default one if not provided
  public init(
    minimumLevel: LogLevel,
    identifier: String,
    backend: LoggingBackend,
    loggingActor: LoggingActor?=nil
  ) {
    self.minimumLevel=minimumLevel
    self.identifier=identifier
    self.backend=backend

    // Use provided logging actor or create a default one
    self.loggingActor=loggingActor ?? LoggingActor(destinations: [])
  }

  // MARK: - CoreLoggingProtocol Implementation

  /// Implements the core logging functionality with LogContextDTO
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message to log
  ///   - context: Contextual information about the log as DTO
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    // Check if this log level should be processed
    guard backend.shouldLog(level: level, minimumLevel: minimumLevel) else {
      return
    }

    // Create LogContext from LogContextDTO
    let logContext=LogContext(
      source: context.getSource(),
      metadata: convertToPrivacyMetadata(context.metadata)
    )

    // Write to the backend
    await backend.writeLog(
      level: level,
      message: message,
      context: logContext,
      subsystem: identifier
    )

    // Also log to the logging actor for compatibility
    await loggingActor.log(level, message, context: context)
  }

  // MARK: - Helper Methods

  /// Helper method to convert from metadata to LogMetadataDTOCollection
  /// - Parameter metadata: The metadata to use directly
  /// - Returns: A metadata collection
  private func createMetadataCollection(from metadata: LogMetadataDTOCollection?) -> LogMetadataDTOCollection {
    return metadata ?? LogMetadataDTOCollection()
  }

  /// Helper function to convert LogMetadataDTOCollection to PrivacyMetadata until we can fully remove PrivacyMetadata
  private func convertToPrivacyMetadata(_ metadata: LogMetadataDTOCollection) -> PrivacyMetadata {
    // Use the built-in conversion method from LogMetadataDTOCollection
    return metadata.toPrivacyMetadata()
  }

  // MARK: - LoggingProtocol Methods

  /// Log a trace message
  public func trace(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {
    let context=BaseLogContextDTO(
      domainName: identifier,
      source: source,
      metadata: createMetadataCollection(from: metadata)
    )
    await trace(message, context: context)
  }

  /// Log a debug message
  public func debug(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {
    let context=BaseLogContextDTO(
      domainName: identifier,
      source: source,
      metadata: createMetadataCollection(from: metadata)
    )
    await debug(message, context: context)
  }

  /// Log an info message
  public func info(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {
    let context=BaseLogContextDTO(
      domainName: identifier,
      source: source,
      metadata: createMetadataCollection(from: metadata)
    )
    await info(message, context: context)
  }

  /// Log a warning message
  public func warning(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {
    let context=BaseLogContextDTO(
      domainName: identifier,
      source: source,
      metadata: createMetadataCollection(from: metadata)
    )
    await warning(message, context: context)
  }

  /// Log an error message
  public func error(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {
    let context=BaseLogContextDTO(
      domainName: identifier,
      source: source,
      metadata: createMetadataCollection(from: metadata)
    )
    await error(message, context: context)
  }

  /// Log a critical message
  public func critical(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {
    let context=BaseLogContextDTO(
      domainName: identifier,
      source: source,
      metadata: createMetadataCollection(from: metadata)
    )
    await critical(message, context: context)
  }

  // MARK: - PrivacyAwareLoggingProtocol Methods

  /// Log a message with explicit privacy controls using DTO context
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message with privacy annotations
  ///   - context: The logging context DTO containing metadata, source, and privacy info
  public func log(
    _ level: LogLevel,
    _ message: PrivacyString,
    context: LogContextDTO
  ) async {
    // Check if this log level should be processed
    guard backend.shouldLog(level: level, minimumLevel: minimumLevel) else {
      return
    }

    // Process the privacy-annotated string
    let processedMessage=message.processForLogging()

    // Create LogContext from LogContextDTO
    let logContext=LogContext(
      source: context.getSource(),
      metadata: convertToPrivacyMetadata(context.metadata)
    )

    // Write to the backend
    await backend.writeLog(
      level: level,
      message: processedMessage,
      context: logContext,
      subsystem: identifier
    )

    // Also log to the logging actor for compatibility
    await loggingActor.log(level, processedMessage, context: context)
  }

  /// Log a message with explicit privacy controls (legacy API)
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message with privacy annotations
  ///   - metadata: Additional structured data with privacy annotations
  ///   - source: The component that generated the log
  public func log(
    _ level: LogLevel,
    _ message: PrivacyString,
    metadata: LogMetadataDTOCollection?,
    source: String
  ) async {
    let context=BaseLogContextDTO(
      domainName: identifier,
      source: source,
      metadata: createMetadataCollection(from: metadata)
    )
    await log(level, message, context: context)
  }

  /// Log sensitive information with appropriate redaction using context
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The basic message without sensitive content
  ///   - sensitiveValues: Sensitive values that should be automatically handled
  ///   - context: The logging context DTO
  public func logSensitive(
    _ level: LogLevel,
    _ message: String,
    sensitiveValues: LoggingTypes.LogMetadata,
    context: LogContextDTO
  ) async {
    // Convert sensitive values to metadata
    var metadata=context.metadata

    for (key, value) in sensitiveValues.asDictionary {
      metadata=metadata.withPrivate(key: key, value: value)
    }

    // Update context with combined metadata
    let updatedContext=context.withUpdatedMetadata(metadata)

    // Log with context
    await log(level, message, context: updatedContext)
  }

  /// Log sensitive information with appropriate redaction (legacy API)
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The basic message without sensitive content
  ///   - sensitiveValues: Sensitive values that should be automatically handled
  ///   - source: The component that generated the log
  public func logSensitive(
    _ level: LogLevel,
    _ message: String,
    sensitiveValues: LoggingTypes.LogMetadata,
    source: String
  ) async {
    let context=BaseLogContextDTO(
      domainName: identifier,
      source: source,
      metadata: createMetadataCollection(from: nil)
    )
    await logSensitive(level, message, sensitiveValues: sensitiveValues, context: context)
  }

  /// Handle an error and log it with privacy controls
  public func logError(
    _ error: Error,
    privacyLevel: LogPrivacyLevel,
    context: LogContextDTO
  ) async {
    var message="Error occurred: \(error.localizedDescription)"

    // Create updated metadata collection
    var updatedMetadata=context.metadata

    // Add error metadata
    updatedMetadata=updatedMetadata.withPrivate(key: "errorDescription", value: error.localizedDescription)

    updatedMetadata=updatedMetadata.withPublic(key: "errorType", value: String(describing: type(of: error)))

    // If it's a loggable error, extract more details
    if let loggableError=error as? LoggableErrorDTO {
      // Get structured error information using available methods
      let errorDetails=loggableError.getLogMessage()

      // Include error details in message if different from default
      if errorDetails != "Error: \(error.localizedDescription)" {
        message=errorDetails
      }

      // Add error metadata
      updatedMetadata=updatedMetadata.merging(with: loggableError.createMetadataCollection())
    }

    // Create a new context with the updated metadata
    let updatedContext=BaseLogContextDTO(
      domainName: context.domainName,
      source: context.source,
      metadata: updatedMetadata,
      correlationID: context.correlationID
    )

    // Choose log level based on severity (default to error)
    let level: LogLevel = .error

    // Log the error with the appropriate privacy level
    switch privacyLevel {
      case .public:
        // Create a privacy string with public visibility
        let privacyString=PrivacyString(
          rawValue: message,
          privacyAnnotations: [(message.startIndex..<message.endIndex): .public]
        )
        await log(level, privacyString, context: updatedContext)
      case .private:
        // Create a privacy string with private visibility
        let privacyString=PrivacyString(
          rawValue: message,
          privacyAnnotations: [(message.startIndex..<message.endIndex): .private]
        )
        await log(level, privacyString, context: updatedContext)
      case .sensitive:
        // Create a privacy string with sensitive visibility
        let privacyString=PrivacyString(
          rawValue: message,
          privacyAnnotations: [(message.startIndex..<message.endIndex): .sensitive]
        )
        await log(level, privacyString, context: updatedContext)
      case .hash:
        // Create a privacy string with hash visibility
        let privacyString=PrivacyString(
          rawValue: message,
          privacyAnnotations: [(message.startIndex..<message.endIndex): .hash]
        )
        await log(level, privacyString, context: updatedContext)
      case .auto:
        // Default to private for auto
        let privacyString=PrivacyString(
          rawValue: message,
          privacyAnnotations: [(message.startIndex..<message.endIndex): .private]
        )
        await log(level, privacyString, context: updatedContext)
    }
  }

  /// Log an error with privacy controls (legacy API)
  /// - Parameters:
  ///   - error: The error to log
  ///   - privacyLevel: The privacy level to apply to the error details
  ///   - metadata: Additional structured data with privacy annotations
  ///   - source: The component that generated the log
  public func logError(
    _ error: Error,
    privacyLevel: LoggingTypes.LogPrivacyLevel,
    metadata: LogMetadataDTOCollection?,
    source: String
  ) async {
    let context=BaseLogContextDTO(
      domainName: identifier,
      source: source,
      metadata: createMetadataCollection(from: metadata)
    )
    await logError(error, privacyLevel: privacyLevel, context: context)
  }

  /// Utility method to calculate the range of the error in the error message
  /// - Parameter error: The error to find the range for
  /// - Returns: The range of the error description in the error message
  private func errorRange(for error: Error) -> Range<String.Index> {
    let errorString="Error occurred: \(error)"
    if let range=errorString.range(of: "\(error)") {
      return range
    }
    // Fallback to the entire range if we can't find the error
    return errorString.startIndex..<errorString.endIndex
  }
}
