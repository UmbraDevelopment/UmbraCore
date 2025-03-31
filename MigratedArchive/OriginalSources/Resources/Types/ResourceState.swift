import Foundation

/// Represents the current state of a managed resource
public enum ResourceState: String, Sendable, Equatable, CaseIterable {
  /// Resource has not been initialized
  case uninitialized

  /// Resource is being initialized
  case initializing

  /// Resource is ready for use
  case ready

  /// Resource is in use
  case inUse

  /// Resource is being released
  case releasing

  /// Resource has been released
  case released

  /// Resource is in an error state
  case error
}
