import CoreDTOs
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import UmbraErrors

/**
 # CryptoServiceMonitor

 Modern actor-based implementation of crypto service monitoring.

 This actor provides monitoring capabilities for cryptographic operations
 using Swift's structured concurrency and async sequences. It replaces the
 older delegate/callback pattern with modern Swift concurrency patterns.

 Following the Alpha Dot Five architecture, it:
 - Uses proper actor isolation for all mutable state
 - Provides async sequences for event monitoring
 - Uses domain-specific DTOs for all communications
 */
public actor CryptoServiceMonitor: CryptoServiceMonitorProtocol {
  /// Logger for recording operations and errors
  private let logger: LoggingProtocol

  /// Domain-specific logger for crypto operations
  private let cryptoLogger: CryptoMonitorLogger

  /// Event stream for crypto operation events
  private let eventStream: CryptoEventStream

  /// Whether the monitor is currently active
  private var isActive: Bool = false

  /**
   Initialises a new crypto service monitor.

   - Parameter logger: Logger for recording operations and errors
   */
  public init(logger: LoggingProtocol) {
    self.logger = logger
    cryptoLogger = CryptoMonitorLogger(logger: logger)
    eventStream = CryptoEventStream()
  }

  /**
   Starts monitoring crypto operations.

   - Returns: True if monitoring was successfully started, false if already active
   */
  public func startMonitoring() async -> Bool {
    await cryptoLogger.logOperationStart(operation: "startMonitoring")

    if isActive == true {
      await cryptoLogger.logOperationWarning(
        operation: "startMonitoring",
        message: "Monitoring is already active"
      )
      return false
    }

    isActive = true

    await cryptoLogger.logOperationSuccess(
      operation: "startMonitoring",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "isActive", value: "true")
    )

    return true
  }

  /**
   Stops monitoring crypto operations.

   - Returns: True if monitoring was successfully stopped, false if not active
   */
  public func stopMonitoring() async -> Bool {
    await cryptoLogger.logOperationStart(operation: "stopMonitoring")

    if isActive == false {
      await cryptoLogger.logOperationWarning(
        operation: "stopMonitoring",
        message: "Monitoring is not active"
      )
      return false
    }

    isActive = false
    eventStream.complete()

    await cryptoLogger.logOperationSuccess(
      operation: "stopMonitoring",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "isActive", value: "false")
    )

    return true
  }

  /**
   Returns an AsyncSequence of crypto operation events.

   This method provides a modern way to monitor crypto operations using
   Swift's AsyncSequence protocol, allowing for-await-in loops and other
   structured concurrency patterns.

   - Returns: AsyncSequence of CryptoEventDTO
   */
  public nonisolated func events() -> AsyncStream<CryptoEventDTO> {
    eventStream.stream
  }

  /**
   Records a crypto operation event.

   - Parameter event: The crypto event to record
   */
  public func recordEvent(_ event: CryptoEventDTO) async {
    guard isActive == true else {
      await cryptoLogger.logOperationWarning(
        operation: "recordEvent",
        message: "Monitoring is not active"
      )
      return
    }

    await cryptoLogger.logOperationStart(
      operation: "recordEvent",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "eventType", value: event.eventType.rawValue)
    )

    eventStream.send(event)

    await cryptoLogger.logOperationSuccess(
      operation: "recordEvent",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "eventType", value: event.eventType.rawValue)
        .withPrivate(key: "eventIdentifier", value: event.identifier)
    )
  }

  /**
   Records a batch of crypto operation events.

   - Parameter events: The crypto events to record
   */
  public func recordEvents(_ events: [CryptoEventDTO]) async {
    guard isActive == true else {
      await cryptoLogger.logOperationWarning(
        operation: "recordEvents",
        message: "Monitoring is not active"
      )
      return
    }

    await cryptoLogger.logOperationStart(
      operation: "recordEvents",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "eventCount", value: String(events.count))
    )

    for event in events {
      eventStream.send(event)
    }

    await cryptoLogger.logOperationSuccess(
      operation: "recordEvents",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "eventCount", value: String(events.count))
    )
  }

  /**
   Filters events based on specified criteria.

   - Parameter filter: The filter criteria to apply

   - Returns: AsyncSequence of filtered CryptoEventDTO
   */
  public nonisolated func filteredEvents(
    matching filter: CryptoEventFilterDTO
  ) -> AsyncStream<CryptoEventDTO> {
    AsyncStream { continuation in
      Task {
        for await event in events() {
          if filter.matches(event) == true {
            continuation.yield(event)
          }
        }
        continuation.finish()
      }
    }
  }
}

/**
 # CryptoEventStream

 A class that manages an AsyncStream of crypto events.

 This class encapsulates the continuation and stream creation
 for crypto events, providing a clean interface for sending
 events and accessing the stream.
 */
private final class CryptoEventStream: @unchecked Sendable {
  /// The continuation used to send events to the stream
  private let continuation: AsyncStream<CryptoEventDTO>.Continuation

  /// The stream of crypto events
  let stream: AsyncStream<CryptoEventDTO>

  init() {
    // Create the stream and capture the continuation
    var continuation: AsyncStream<CryptoEventDTO>.Continuation!
    stream = AsyncStream { cont in
      continuation = cont
      cont.onTermination = { @Sendable _ in
        // Clean up resources if needed
      }
    }
    self.continuation = continuation
  }

  /**
   Sends an event to the stream.

   - Parameter event: The event to send
   */
  func send(_ event: CryptoEventDTO) {
    continuation.yield(event)
  }

  /**
   Completes the stream.
   */
  func complete() {
    continuation.finish()
  }
}

/**
 # CryptoMonitorLogger

 Domain-specific logger for crypto monitoring operations.

 This logger provides standardised logging for all crypto monitoring
 operations with proper privacy controls and context handling.
 */
private struct CryptoMonitorLogger {
  private let logger: LoggingProtocol

  init(logger: LoggingProtocol) {
    self.logger = logger
  }

  func logOperationStart(
    operation: String,
    additionalContext: LogMetadataDTOCollection? = nil
  ) async {
    await logger.log(
      level: .debug,
      message: "Starting crypto monitor operation: \(operation)",
      metadata: additionalContext
    )
  }

  func logOperationSuccess(
    operation: String,
    additionalContext: LogMetadataDTOCollection? = nil
  ) async {
    await logger.log(
      level: .debug,
      message: "Successfully completed crypto monitor operation: \(operation)",
      metadata: additionalContext
    )
  }

  func logOperationWarning(
    operation: String,
    message: String,
    additionalContext: LogMetadataDTOCollection? = nil
  ) async {
    var context = additionalContext ?? LogMetadataDTOCollection()
    context = context.withPrivate(key: "warning", value: message)

    await logger.log(
      level: .warning,
      message: "Warning in crypto monitor operation: \(operation)",
      metadata: context
    )
  }

  func logOperationError(
    operation: String,
    error: Error,
    additionalContext: LogMetadataDTOCollection? = nil
  ) async {
    var context = additionalContext ?? LogMetadataDTOCollection()
    context = context.withPrivate(key: "error", value: "\(error)")

    await logger.log(
      level: .error,
      message: "Failed crypto monitor operation: \(operation)",
      metadata: context
    )
  }
}
