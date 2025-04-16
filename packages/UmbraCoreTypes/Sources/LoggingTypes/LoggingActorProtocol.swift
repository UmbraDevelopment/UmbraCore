import Foundation

/**
 # Logging Actor Protocol

 A protocol for actors that process logs with associated metadata and source information.

 The logging actor is the core component responsible for processing log entries and
 distributing them to appropriate destinations. It handles log message formatting,
 privacy annotations, and destination management.
 */
@preconcurrency
public protocol LoggingActorProtocol: Actor {
  /**
   Logs a message with the specified level, metadata, and source information.

   - Parameters:
     - level: The severity level of the log entry.
     - message: The text content of the log entry.
     - metadata: Collection of metadata associated with this log entry.
     - source: Optional source information (file, function, line).
   */
  func log(
    _ level: UmbraLogLevel,
    _ message: String,
    metadata: LogMetadataDTOCollection,
    source: String?
  ) async
}
