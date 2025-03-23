// Standard modules
import Foundation

/// The operational state of a repository.
///
/// This enum represents the various states a repository can be in during
/// its lifecycle, from initialization through active use.
public enum RepositoryState: Equatable, Sendable, Codable {
  /// The repository has not been initialized.
  case uninitialized

  /// The repository is initialized and ready for operations.
  case ready

  /// The repository is locked for exclusive access.
  case locked

  /// The repository is in an error state.
  case error(RepositoryError)

  public static func == (lhs: RepositoryState, rhs: RepositoryState) -> Bool {
    switch (lhs, rhs) {
      case (.uninitialized, .uninitialized),
           (.ready, .ready),
           (.locked, .locked):
        true
      case let (.error(lhsError), .error(rhsError)):
        lhsError.localizedDescription == rhsError.localizedDescription
      default:
        false
    }
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case type
    case error
  }

  public func encode(to encoder: Encoder) throws {
    var container=encoder.container(keyedBy: CodingKeys.self)
    switch self {
      case .uninitialized:
        try container.encode("uninitialized", forKey: .type)
      case .ready:
        try container.encode("ready", forKey: .type)
      case .locked:
        try container.encode("locked", forKey: .type)
      case let .error(error):
        try container.encode("error", forKey: .type)
        try container.encode(error, forKey: .error)
    }
  }

  @preconcurrency
  @available(*, deprecated, message: "Will need to be refactored for Swift 6")
  public init(from decoder: Decoder) throws {
    let container=try decoder.container(keyedBy: CodingKeys.self)
    let type=try container.decode(String.self, forKey: .type)
    switch type {
      case "uninitialized":
        self = .uninitialized
      case "ready":
        self = .ready
      case "locked":
        self = .locked
      case "error":
        let error=try container.decode(RepositoryError.self, forKey: .error)
        self = .error(error)
      default:
        throw DecodingError.dataCorruptedError(
          forKey: .type,
          in: container,
          debugDescription: "Invalid repository state type: \(type)"
        )
    }
  }
}
