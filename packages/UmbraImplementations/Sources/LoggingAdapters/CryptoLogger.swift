import CryptoTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/// A specialised domain logger for cryptographic operations
///
/// This actor provides logging functionality specific to cryptographic
/// operations, with enhanced privacy controls and contextual information
/// relevant to cryptographic processes.
public actor CryptoLogger: DomainLoggerProtocol {
  /// The domain name this logger is responsible for
  public let domainName: String="Crypto"

  /// The underlying logging service
  private let loggingService: LoggingServiceProtocol

  /// Creates a new cryptographic logger
  ///
  /// - Parameter loggingService: The underlying logging service to use
  public init(loggingService: LoggingServiceProtocol) {
    self.loggingService=loggingService
  }

  /// Log a message with the specified level
  public func log(_ level: LogLevel, _ message: String) async {
    let formattedMessage="[\(domainName)] \(message)"

    // Use the appropriate level-specific method
    switch level {
      case .trace:
        await loggingService.verbose(formattedMessage, metadata: nil, source: domainName)
      case .debug:
        await loggingService.debug(formattedMessage, metadata: nil, source: domainName)
      case .info:
        await loggingService.info(formattedMessage, metadata: nil, source: domainName)
      case .warning:
        await loggingService.warning(formattedMessage, metadata: nil, source: domainName)
      case .error:
        await loggingService.error(formattedMessage, metadata: nil, source: domainName)
      case .critical:
        await loggingService.critical(formattedMessage, metadata: nil, source: domainName)
    }
  }

  /// Log a message with trace level
  public func trace(_ message: String) async {
    await log(.trace, message)
  }

  /// Log a message with debug level
  public func debug(_ message: String) async {
    await log(.debug, message)
  }

  /// Log a message with info level
  public func info(_ message: String) async {
    await log(.info, message)
  }

  /// Log a message with warning level
  public func warning(_ message: String) async {
    await log(.warning, message)
  }

  /// Log a message with error level
  public func error(_ message: String) async {
    await log(.error, message)
  }

  /// Log a message with critical level
  public func critical(_ message: String) async {
    await log(.critical, message)
  }

  /// Log a cryptographic operation event
  ///
  /// - Parameters:
  ///   - operation: The cryptographic operation being performed
  ///   - algorithm: The algorithm being used
  ///   - message: The message to log
  ///   - level: The severity level of the log
  public func logOperation(
    _ operation: String,
    algorithm: String,
    message: String,
    level: LogLevel = .info
  ) async {
    let context=CryptoLogContext(
      operation: operation,
      algorithm: algorithm
    )

    await logWithContext(level, message, context: context)
  }

  /// Log a cryptographic operation event with additional metadata
  ///
  /// - Parameters:
  ///   - operation: The cryptographic operation being performed
  ///   - algorithm: The algorithm being used
  ///   - message: The message to log
  ///   - metadata: Additional contextual information
  ///   - level: The severity level of the log
  public func logOperation(
    _ operation: String,
    algorithm: String,
    message: String,
    metadata: LogMetadataDTOCollection,
    level: LogLevel = .info
  ) async {
    var context=CryptoLogContext(
      operation: operation,
      algorithm: algorithm
    )

    let updatedContext=context.withUpdatedMetadata(metadata)
    await logWithContext(level, message, context: updatedContext)
  }

  /// Log a cryptographic error
  ///
  /// - Parameters:
  ///   - error: The error that occurred
  ///   - operation: The operation that failed
  ///   - algorithm: The algorithm that was being used
  public func logError(
    _ error: Error,
    operation: String,
    algorithm: String?=nil
  ) async {
    let context=CryptoLogContext(
      operation: operation,
      algorithm: algorithm
    )

    await logError(error, context: context, privacyLevel: .private)
  }

  /// Log a message with the specified context
  public func logWithContext(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let formattedMessage="[\(domainName)] \(message)"
    let logMetadata=context.asLogMetadata()

    // Choose the appropriate logging method based on level
    switch level {
      case .trace:
        await loggingService.verbose(formattedMessage, metadata: logMetadata, source: domainName)
      case .debug:
        await loggingService.debug(formattedMessage, metadata: logMetadata, source: domainName)
      case .info:
        await loggingService.info(formattedMessage, metadata: logMetadata, source: domainName)
      case .warning:
        await loggingService.warning(formattedMessage, metadata: logMetadata, source: domainName)
      case .error:
        await loggingService.error(formattedMessage, metadata: logMetadata, source: domainName)
      case .critical:
        await loggingService.critical(formattedMessage, metadata: logMetadata, source: domainName)
    }
  }

  /// Log an error with context
  public func logError(
    _ error: Error,
    context: LogContextDTO,
    privacyLevel _: PrivacyClassification
  ) async {
    if let loggableError=error as? LoggableErrorProtocol {
      // Use the error's built-in privacy metadata
      let errorMetadata=loggableError.getPrivacyMetadata().toLogMetadata()
      let formattedMessage="[\(domainName)] \(loggableError.getLogMessage())"
      let source="\(loggableError.getSource()) via \(domainName)"

      await loggingService.error(formattedMessage, metadata: errorMetadata, source: source)
    } else {
      // Handle standard errors with the provided privacy level
      let formattedMessage="[\(domainName)] \(error.localizedDescription)"
      let logMetadata=context.asLogMetadata()

      await loggingService.error(formattedMessage, metadata: logMetadata, source: domainName)
    }
  }
}
