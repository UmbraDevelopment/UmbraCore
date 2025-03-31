import Foundation

/// The lifecycle state of a managed resource.
///
/// Resources progress through these states during their lifecycle,
/// from initialisation through active use to eventual release.
/// State transitions should be handled atomically to ensure thread safety.
///
/// Example state flow:
/// ```
/// uninitialized -> initializing -> ready -> inUse -> ready -> released
/// ```
public enum ResourceState: String, Sendable {
  /// The resource has not been initialised.
  case uninitialized

  /// The resource is currently being initialised.
  case initializing

  /// The resource is initialised and available for use.
  case ready

  /// The resource is currently in use by a client.
  case inUse

  /// The resource encountered an error during operation.
  case error

  /// The resource is being released back to the pool.
  case releasing

  /// The resource has been fully released and cleaned up.
  case released
}

/// A protocol for resources that require lifecycle management.
///
/// Managed resources provide thread-safe access through the actor model
/// and support operations like acquisition, release, and cleanup.
/// Implementations should ensure proper state transitions and handle
/// concurrent access safely.
///
/// Example:
/// ```swift
/// actor DatabaseConnection: ManagedResource {
///     static let resourceType = "database"
///     nonisolated let id: String
///     nonisolated private(set) var state: ResourceState
///
///     func acquire() async throws {
///         guard state == .ready else {
///             throw ResourceError.invalidState("Resource not ready")
///         }
///         state = .inUse
///         // Acquire database connection
///     }
///
///     func release() async {
///         // Release connection
///         state = .ready
///     }
/// }
/// ```
public protocol ManagedResource: Actor, Sendable {
  /// A string identifying the type of resource.
  ///
  /// This should be a unique, lowercase identifier for the resource type,
  /// such as "database" or "file-handle". The identifier should be
  /// consistent across the application.
  static var resourceType: String { get }

  /// The current lifecycle state of the resource.
  ///
  /// This property must be safe to access from any context and should
  /// accurately reflect the resource's current state. State transitions
  /// should be handled atomically.
  nonisolated var state: ResourceState { get }

  /// A unique identifier for this resource instance.
  ///
  /// This should be unique within the scope of the resource type
  /// and must be safe to access from any context. Consider using
  /// UUID or another guaranteed unique identifier.
  nonisolated var id: String { get }

  /// Acquires the resource for use.
  ///
  /// This method should transition the resource from `ready` to `inUse`
  /// state if successful. The transition should be atomic to prevent
  /// race conditions.
  ///
  /// - Throws: `ResourceError` if acquisition fails due to invalid state,
  ///           timeout, or other errors.
  /// - Returns: Void if acquisition succeeds.
  func acquire() async throws

  /// Releases the resource back to the pool.
  ///
  /// This method should transition the resource from `inUse` to `ready`
  /// state after performing any necessary cleanup. The transition should
  /// be atomic to prevent race conditions.
  ///
  /// - Important: This method should be idempotent and safe to call
  ///             multiple times.
  func release() async

  /// Performs final cleanup of the resource.
  ///
  /// This method should release any system resources and transition
  /// the resource to the `released` state. Once cleaned up, the resource
  /// cannot be reused.
  ///
  /// - Important: This method should be idempotent and safe to call
  ///             multiple times.
  func cleanup() async
}

/// Errors that can occur during resource operations.
///
/// These errors provide specific information about what went wrong
/// during resource management operations. Each case includes a detailed
/// message to aid in debugging and error handling.
public enum ResourceError: LocalizedError, Sendable {
  /// The resource could not be acquired.
  ///
  /// - Parameter message: A description of why acquisition failed,
  ///                     such as "Connection timeout" or "Invalid credentials".
  case acquisitionFailed(String)

  /// The resource is in an invalid state for the requested operation.
  ///
  /// - Parameter message: A description of the state conflict,
  ///                     such as "Resource already in use" or "Resource not initialised".
  case invalidState(String)

  /// The operation timed out.
  ///
  /// - Parameter message: A description of what operation timed out,
  ///                     including relevant timing information.
  case timeout(String)

  /// No resources are available in the pool.
  ///
  /// - Parameter message: A description of the resource shortage,
  ///                     including pool size and current usage.
  case poolExhausted(String)

  /// Resource cleanup failed.
  ///
  /// - Parameter message: A description of why cleanup failed,
  ///                     such as "Failed to close connection" or "Failed to release lock".
  case cleanupFailed(String)

  /// A localised description of the error.
  ///
  /// This property provides a human-readable description of the error,
  /// suitable for logging or user display.
  public var errorDescription: String? {
    switch self {
      case let .acquisitionFailed(message):
        "Failed to acquire resource: \(message)"
      case let .invalidState(message):
        "Invalid resource state: \(message)"
      case let .timeout(message):
        "Operation timed out: \(message)"
      case let .poolExhausted(message):
        "Resource pool exhausted: \(message)"
      case let .cleanupFailed(message):
        "Resource cleanup failed: \(message)"
    }
  }
}
