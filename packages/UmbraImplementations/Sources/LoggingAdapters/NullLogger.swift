import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Null Logger

 A logger implementation that does nothing. This is useful for cases where
 logging is not required but a logger instance is expected by the API.

 This logger conforms to the PrivacyAwareLoggingProtocol and implements all
 required methods, but does not perform any actual logging.
 */
@preconcurrency
public actor NullLogger: PrivacyAwareLoggingProtocol {
  /// The logging actor used by this logger
  public nonisolated let loggingActor: LoggingActor = .init(destinations: [])

  /// Initializes a new NullLogger instance
  public init() {}

  // MARK: - CoreLoggingProtocol

  /// Does nothing
  public func log(_: LogLevel, _: String, context _: LogContextDTO) async {}

  // MARK: - LoggingProtocol Convenience Methods

  /// Does nothing
  public func trace(_: String, context _: LogContextDTO) async {}

  /// Does nothing
  public func debug(_: String, context _: LogContextDTO) async {}

  /// Does nothing
  public func info(_: String, context _: LogContextDTO) async {}

  /// Does nothing
  public func warning(_: String, context _: LogContextDTO) async {}

  /// Does nothing
  public func error(_: String, context _: LogContextDTO) async {}

  /// Does nothing
  public func critical(_: String, context _: LogContextDTO) async {}

  // MARK: - PrivacyAwareLoggingProtocol

  /// Does nothing
  public func log(_: LogLevel, _: PrivacyString, context _: LogContextDTO) async {}

  /// Does nothing
  public func logSensitive(
    _: LogLevel,
    _: String,
    sensitiveValues _: LogMetadata,
    context _: LogContextDTO
  ) async {}

  /// Does nothing
  public func trace(_: String, metadata _: LogMetadataDTOCollection?, source _: String) async {}

  /// Does nothing
  public func debug(_: String, metadata _: LogMetadataDTOCollection?, source _: String) async {}

  /// Does nothing
  public func info(_: String, metadata _: LogMetadataDTOCollection?, source _: String) async {}

  /// Does nothing
  public func warning(_: String, metadata _: LogMetadataDTOCollection?, source _: String) async {}

  /// Does nothing
  public func error(_: String, metadata _: LogMetadataDTOCollection?, source _: String) async {}

  /// Does nothing
  public func critical(_: String, metadata _: LogMetadataDTOCollection?, source _: String) async {}

  /// Does nothing
  public func logError(_: Error, context _: LogContextDTO) async {}

  /// Does nothing
  public func logError(
    _: Error,
    privacyLevel _: LogPrivacyLevel,
    context _: LogContextDTO
  ) async {}
}
