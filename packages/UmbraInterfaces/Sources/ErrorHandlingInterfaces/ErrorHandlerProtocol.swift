import ErrorCoreTypes
import Foundation

/**
 # ErrorHandlerProtocol

 Protocol defining requirements for error handler components.

 This protocol establishes a consistent interface for handling errors across
 the system. It follows the Alpha Dot Five architecture by separating the
 error handling interface from its implementation.

 ## Actor-Based Implementation

 Implementations of this protocol MUST use Swift actors to ensure proper
 state isolation and thread safety for error handling operations:

 ```swift
 actor ErrorHandlerActor: ErrorHandlerProtocol {
     // Private state should be isolated within the actor
     private let errorLogger: ErrorLoggingProtocol
     private let metadataCollector: ErrorMetadataCollector

     // All function implementations must use 'await' appropriately when
     // accessing actor-isolated state or calling other actor methods
 }
 ```

 ## Protocol Forwarding

 To support proper protocol conformance while maintaining actor isolation,
 implementations should consider using the protocol forwarding pattern:

 ```swift
 // Public non-actor class that conforms to protocol
 public final class ErrorHandler: ErrorHandlerProtocol {
     private let actor: ErrorHandlerActor

     // Forward all protocol methods to the actor
     public func handle<E>(_ error: E, options: ErrorHandlingOptions?) async where E: Error {
         await actor.handle(error, options: options)
     }
 }
 ```

 ## Privacy Considerations

 Error handling often involves sensitive application data. Implementations must:
 - Use privacy-aware logging for all error details
 - Apply proper redaction to sensitive fields in error metadata
 - Prevent sensitive information from appearing in user-facing error messages
 - Implement appropriate categorisation of errors for proper handling
 */
public protocol ErrorHandlerProtocol: Sendable {
  /**
   Handles an error according to the implementation's strategy.

   This method should take appropriate action to process the error, which may include
   logging, recovery attempts, user notification, or other contextual handling.

   - Parameters:
      - error: The error to handle
      - options: Configuration options for error handling
   */
  func handle<E: Error>(
    _ error: E,
    options: ErrorHandlingOptions?
  ) async

  /**
   Handles an error with a context.

   This is a convenience method that extracts metadata from the context and
   applies privacy controls based on the context's domain.

   - Parameters:
      - error: The error to handle
      - context: Contextual information about the error
      - options: Configuration options for error handling
   */
  func handle<E: Error>(
    _ error: E,
    context: ErrorContext,
    options: ErrorHandlingOptions?
  ) async

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
  func handleWithRecovery<E: Error, Outcome>(
    _ error: E,
    context: ErrorContext,
    recoveryStrategies: [ErrorRecoveryStrategy<E, Outcome>],
    options: ErrorHandlingOptions?
  ) async -> ErrorRecoveryResult<Outcome>
}

/// Default implementations for optional parameters
extension ErrorHandlerProtocol {
  public func handle(_ error: some Error, options: ErrorHandlingOptions?=nil) async {
    await handle(error, options: options)
  }

  public func handle(_ error: some Error, context: ErrorContext) async {
    await handle(error, context: context, options: nil)
  }

  public func handle(
    _ error: some Error,
    context: ErrorContext,
    options: ErrorHandlingOptions?=nil
  ) async {
    await handle(error, context: context, options: options)
  }

  public func handleWithRecovery<E: Error, Outcome>(
    _ error: E,
    context: ErrorContext,
    recoveryStrategies: [ErrorRecoveryStrategy<E, Outcome>],
    options: ErrorHandlingOptions?=nil
  ) async -> ErrorRecoveryResult<Outcome> {
    await handleWithRecovery(
      error,
      context: context,
      recoveryStrategies: recoveryStrategies,
      options: options
    )
  }
}

/**
 Options for configuring error handling behaviour.
 */
public struct ErrorHandlingOptions: Sendable, Equatable {
  /// Standard options for most error handling
  public static let standard=ErrorHandlingOptions()

  /// Whether to include stack traces with the error
  public let includeStackTrace: Bool

  /// Whether to attempt automatic recovery
  public let attemptRecovery: Bool

  /// Whether to notify the user about the error
  public let notifyUser: Bool

  /// Whether to propagate the error to monitoring systems
  public let reportToMonitoring: Bool

  /// Privacy level for error logging
  public let privacyLevel: ErrorPrivacyLevel

  /// Additional metadata to include with the error
  public let additionalMetadata: [String: String]

  /// Creates new error handling options
  public init(
    includeStackTrace: Bool=true,
    attemptRecovery: Bool=true,
    notifyUser: Bool=false,
    reportToMonitoring: Bool=true,
    privacyLevel: ErrorPrivacyLevel = .standard,
    additionalMetadata: [String: String]=[:]
  ) {
    self.includeStackTrace=includeStackTrace
    self.attemptRecovery=attemptRecovery
    self.notifyUser=notifyUser
    self.reportToMonitoring=reportToMonitoring
    self.privacyLevel=privacyLevel
    self.additionalMetadata=additionalMetadata
  }
}

/**
 Privacy level for error handling and logging.
 */
public enum ErrorPrivacyLevel: String, Sendable, Equatable, Comparable {
  /// Minimal privacy controls - suitable for development environments
  case minimal

  /// Standard privacy controls - default for most errors
  case standard

  /// Enhanced privacy controls - for errors with potentially sensitive information
  case enhanced

  /// Maximum privacy controls - for errors with highly sensitive information
  case maximum

  public static func < (lhs: ErrorPrivacyLevel, rhs: ErrorPrivacyLevel) -> Bool {
    let order: [ErrorPrivacyLevel]=[.minimal, .standard, .enhanced, .maximum]
    guard
      let lhsIndex=order.firstIndex(of: lhs),
      let rhsIndex=order.firstIndex(of: rhs)
    else {
      return false
    }
    return lhsIndex < rhsIndex
  }
}

/**
 A strategy for recovering from a specific error.
 */
public struct ErrorRecoveryStrategy<E: Error, Outcome>: Sendable {
  /// The recovery action to attempt
  public let action: (E, ErrorContext) async -> Outcome?

  /// Description of this recovery strategy for logging
  public let description: String

  /// Creates a new error recovery strategy
  public init(
    description: String,
    action: @escaping (E, ErrorContext) async -> Outcome?
  ) {
    self.description=description
    self.action=action
  }
}

/**
 Result of attempting error recovery.
 */
public enum ErrorRecoveryResult<Outcome>: Sendable {
  /// Recovery was successful
  case recovered(Outcome)

  /// Recovery failed
  case failed(Error)

  /// No recovery was attempted
  case notAttempted

  /// Whether recovery was successful
  public var isRecovered: Bool {
    switch self {
      case .recovered:
        true
      case .failed, .notAttempted:
        false
    }
  }

  /// The recovered value if available
  public var value: Outcome? {
    switch self {
      case let .recovered(value):
        value
      case .failed, .notAttempted:
        nil
    }
  }
}
