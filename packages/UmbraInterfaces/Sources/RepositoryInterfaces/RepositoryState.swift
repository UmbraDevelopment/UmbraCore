import Foundation

/// Represents the operational state of a repository.
public enum RepositoryState: Equatable, Sendable {
  /// Repository has not been initialised yet
  case uninitialized

  /// Repository is ready for use
  case ready

  /// Repository is locked for exclusive access
  case locked

  /// Repository is undergoing maintenance
  case maintenance

  /// Repository has been corrupted and needs repair
  case corrupted

  /// Repository has been closed and is not currently accessible
  case closed

  /// Repository is in an unknown state
  case unknown

  /// Whether the repository can be used for operations
  public var isOperational: Bool {
    switch self {
      case .ready, .maintenance:
        true
      case .uninitialized, .locked, .corrupted, .closed, .unknown:
        false
    }
  }

  /// A textual description of the repository state suitable for logs and diagnostics
  public var description: String {
    switch self {
      case .uninitialized:
        "Uninitialised"
      case .ready:
        "Ready"
      case .locked:
        "Locked"
      case .maintenance:
        "Maintenance"
      case .corrupted:
        "Corrupted"
      case .closed:
        "Closed"
      case .unknown:
        "Unknown"
    }
  }
}
