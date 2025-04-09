import LoggingInterfaces
import LoggingTypes
import Foundation

/// Protocol defining domain-specific logging capabilities
public protocol DomainLoggerProtocol: Sendable {
  /// The domain name this logger is responsible for
  var domainName: String { get }

  /// Log a message with the specified level and context
  func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async

  /// Log a message with the specified level (legacy method)
  func log(_ level: LogLevel, _ message: String) async

  /// Log a message with trace level and context
  func trace(_ message: String, context: LogContextDTO) async

  /// Log a message with debug level and context
  func debug(_ message: String, context: LogContextDTO) async

  /// Log a message with info level and context
  func info(_ message: String, context: LogContextDTO) async

  /// Log a message with warning level and context
  func warning(_ message: String, context: LogContextDTO) async

  /// Log a message with error level and context
  func error(_ message: String, context: LogContextDTO) async

  /// Log a message with critical level and context
  func critical(_ message: String, context: LogContextDTO) async

  /// Log a message with trace level (legacy method)
  func trace(_ message: String) async

  /// Log a message with debug level (legacy method)
  func debug(_ message: String) async

  /// Log a message with info level (legacy method)
  func info(_ message: String) async

  /// Log a message with warning level (legacy method)
  func warning(_ message: String) async

  /// Log a message with error level (legacy method)
  func error(_ message: String) async

  /// Log a message with critical level (legacy method)
  func critical(_ message: String) async

  /// Log an error with context
  func logError(_ error: Error, context: LogContextDTO) async

  /// Log with specific domain context
  func logWithContext(_ level: LogLevel, _ message: String, context: LogContextDTO) async
}

/// Base implementation of the domain logger pattern
///
/// This actor provides a reusable implementation of domain-specific logging
/// that follows the Alpha Dot Five architecture principles with proper
/// thread safety through the actor model.
public actor BaseDomainLogger: DomainLoggerProtocol {
  /// The domain name this logger is responsible for
  public let domainName: String

  /// The underlying logging service
  private let loggingService: LoggingServiceProtocol

  /// Creates a new domain logger
  ///
  /// - Parameters:
  ///   - domainName: The name of the domain this logger is responsible for
  ///   - loggingService: The underlying logging service to use
  public init(domainName: String, loggingService: LoggingServiceProtocol) {
    self.domainName=domainName
    self.loggingService=loggingService
  }

  /// Log a message with the specified level and context
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let formattedMessage="[\(domainName)] \(message)"
    let metadata = context.metadata
    
    // Choose the appropriate logging method based on level
    switch level {
      case .trace:
        await loggingService.verbose(formattedMessage, metadata: metadata, source: domainName)
      case .debug:
        await loggingService.debug(formattedMessage, metadata: metadata, source: domainName)
      case .info:
        await loggingService.info(formattedMessage, metadata: metadata, source: domainName)
      case .warning:
        await loggingService.warning(formattedMessage, metadata: metadata, source: domainName)
      case .error:
        await loggingService.error(formattedMessage, metadata: metadata, source: domainName)
      case .critical:
        await loggingService.critical(formattedMessage, metadata: metadata, source: domainName)
    }
  }

  /// Log a message with the specified level (legacy method)
  public func log(_ level: LogLevel, _ message: String) async {
    // Create a basic context for backward compatibility
    let emptyContext=BasicLogContext(source: domainName)
    await log(level, message, context: emptyContext)
  }

  /// Log a message with trace level and context
  public func trace(_ message: String, context: LogContextDTO) async {
    await log(.trace, message, context: context)
  }

  /// Log a message with debug level and context
  public func debug(_ message: String, context: LogContextDTO) async {
    await log(.debug, message, context: context)
  }

  /// Log a message with info level and context
  public func info(_ message: String, context: LogContextDTO) async {
    await log(.info, message, context: context)
  }

  /// Log a message with warning level and context
  public func warning(_ message: String, context: LogContextDTO) async {
    await log(.warning, message, context: context)
  }

  /// Log a message with error level and context
  public func error(_ message: String, context: LogContextDTO) async {
    await log(.error, message, context: context)
  }

  /// Log a message with critical level and context
  public func critical(_ message: String, context: LogContextDTO) async {
    await log(.critical, message, context: context)
  }

  /// Log a message with trace level (legacy method)
  public func trace(_ message: String) async {
    await log(.trace, message)
  }

  /// Log a message with debug level (legacy method)
  public func debug(_ message: String) async {
    await log(.debug, message)
  }

  /// Log a message with info level (legacy method)
  public func info(_ message: String) async {
    await log(.info, message)
  }

  /// Log a message with warning level (legacy method)
  public func warning(_ message: String) async {
    await log(.warning, message)
  }

  /// Log a message with error level (legacy method)
  public func error(_ message: String) async {
    await log(.error, message)
  }

  /// Log a message with critical level (legacy method)
  public func critical(_ message: String) async {
    await log(.critical, message)
  }

  /// Log an error with context
  public func logError(_ error: Error, context: LogContextDTO) async {
    if let loggableError=error as? LoggableErrorProtocol {
      // Use the error's built-in metadata collection
      let metadataCollection = loggableError.createMetadataCollection()
      let formattedMessage = "[\(domainName)] \(loggableError.getLogMessage())"
      let source = "\(loggableError.getSource()) via \(domainName)"

      // The logging service expects LogMetadataDTOCollection
      await loggingService.error(formattedMessage, metadata: metadataCollection, source: source)
    } else {
      // Handle standard errors with the provided privacy level
      let formattedMessage = "[\(domainName)] \(error.localizedDescription)"
      let metadata = context.metadata

      await loggingService.error(formattedMessage, metadata: metadata, source: domainName)
    }
  }

  /// Log with specific domain context
  public func logWithContext(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    await log(level, message, context: context)
  }
}

/**
 A basic implementation of LogContextDTO for legacy logging methods
 */
struct BasicLogContext: LogContextDTO {
  let domainName: String="Default"
  let correlationID: String?=LogIdentifier(value: UUID().uuidString).description
  let source: String?
  let metadata: LogMetadataDTOCollection = .init()

  init(source: String?=nil) {
    self.source=source
  }

  func asLogMetadata() -> LogMetadata? {
    LogMetadata.from(["correlationId": correlationID ?? ""])
  }

  func withUpdatedMetadata(_: LogMetadataDTOCollection) -> Self {
    // Return a new instance with the same source
    BasicLogContext(source: source)
  }

  func toPrivacyMetadata() -> PrivacyMetadata {
    PrivacyMetadata()
  }

  func getSource() -> String {
    source ?? "Default"
  }

  func toMetadata() -> LogMetadataDTOCollection {
    metadata
  }
}
