import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Keychain Logging Adapter

 This adapter wraps a LoggingServiceProtocol instance and adapts it to the
 LoggingProtocol interface, compatible with the Alpha Dot Five architecture.

 It enables using logging services across module boundaries while maintaining
 type safety and privacy controls.
 */
public actor LoggingAdapter: LoggingProtocol, CoreLoggingProtocol {
  private let loggingService: LoggingProtocol
  private let _loggingActor: LoggingActor

  /// The domain name for this logger
  public let domainName: String="KeychainServices"

  /// Get the underlying logging actor
  public var loggingActor: LoggingActor {
    _loggingActor
  }

  /**
   Create a new logging adapter wrapping the given logging service.

   - Parameter loggingService: The logging service to wrap
   */
  public init(wrapping loggingService: LoggingProtocol) {
    self.loggingService=loggingService
    _loggingActor=LoggingActor(destinations: [], minimumLogLevel: .info)
  }

  // MARK: - CoreLoggingProtocol Implementation

  /// Required CoreLoggingProtocol implementation
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let formattedMessage="[\(domainName)] \(message)"

    // Directly call the wrapped logging service's log method
    await loggingService.log(level, formattedMessage, context: context)

    // Also log to the actor
    await loggingActor.log(level, formattedMessage, context: context)
  }

  // MARK: - LoggingProtocol Implementation

  /**
   Log a message with trace level

   - Parameters:
     - message: The message to log
     - context: The logging context containing metadata and source information
   */
  public func trace(_ message: String, context: LogContextDTO) async {
    await log(.trace, message, context: context)
  }

  /**
   Log a message with debug level

   - Parameters:
     - message: The message to log
     - context: The logging context containing metadata and source information
   */
  public func debug(_ message: String, context: LogContextDTO) async {
    await log(.debug, message, context: context)
  }

  /**
   Log a message with info level

   - Parameters:
     - message: The message to log
     - context: The logging context containing metadata and source information
   */
  public func info(_ message: String, context: LogContextDTO) async {
    await log(.info, message, context: context)
  }

  /**
   Log a message with warning level

   - Parameters:
     - message: The message to log
     - context: The logging context containing metadata and source information
   */
  public func warning(_ message: String, context: LogContextDTO) async {
    await log(.warning, message, context: context)
  }

  /**
   Log a message with error level

   - Parameters:
     - message: The message to log
     - context: The logging context containing metadata and source information
   */
  public func error(_ message: String, context: LogContextDTO) async {
    await log(.error, message, context: context)
  }

  /**
   Log a message with critical level

   - Parameters:
     - message: The message to log
     - context: The logging context containing metadata and source information
   */
  public func critical(_ message: String, context: LogContextDTO) async {
    await log(.critical, message, context: context)
  }
}
