import Foundation

/// Represents the current state of a service
@frozen
public enum ServiceState: String, Sendable, Codable {
  /// Service is not yet initialized
  case uninitialized
  /// Service is initializing
  case initializing
  /// Service is running normally
  case running
  /// Service is ready for use
  case ready
  /// Service is shutting down
  case shuttingDown
  /// Service has encountered an error
  case error
  /// Service has been suspended
  case suspended
  /// Service has been shut down
  case shutdown
}
