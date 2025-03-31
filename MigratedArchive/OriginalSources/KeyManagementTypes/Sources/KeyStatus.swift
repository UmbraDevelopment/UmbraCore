import Foundation

/// Represents the current status of a cryptographic key
///
/// This is the canonical implementation of KeyStatus used across the UmbraCore framework.
/// It provides compatibility with both Foundation-based and Foundation-free environments
/// by supporting date-based and timestamp-based representations for the `pendingDeletion` case.
@frozen
public enum KeyStatus: Sendable, Equatable, Codable {
  /// Key is active and can be used
  case active

  /// Key has been compromised and should not be used
  case compromised

  /// Key has been retired and should not be used
  case retired

  /// Key is scheduled for deletion at the specified time (Date-based version)
  case pendingDeletion(Date)

  // MARK: - Timestamp-based conversion methods

  /// Creates a pendingDeletion instance with a Unix timestamp
  /// - Parameter timestamp: Unix timestamp (seconds since 1970)
  /// - Returns: A KeyStatus.pendingDeletion instance with the equivalent Date
  public static func pendingDeletionWithTimestamp(_ timestamp: Int64) -> KeyStatus {
    let date=Date(timeIntervalSince1970: TimeInterval(timestamp))
    return .pendingDeletion(date)
  }

  /// Gets the Unix timestamp if this is a pendingDeletion status
  /// - Returns: Unix timestamp (seconds since 1970) if this is pendingDeletion, nil otherwise
  public func getDeletionTimestamp() -> Int64? {
    switch self {
      case let .pendingDeletion(date):
        Int64(date.timeIntervalSince1970)
      default:
        nil
    }
  }

  // MARK: - Codable implementation

  private enum CodingKeys: String, CodingKey {
    case type
    case deletionDate
  }

  // Internal representation of the key status for encoding/decoding
  // This is intentionally kept private to enforce the use of the public KeyStatus API
  private enum StatusTypeInternal: String, Codable {
    case active
    case compromised
    case retired
    case pendingDeletion
  }

  @preconcurrency
  @available(*, deprecated, message: "Will need to be refactored for Swift 6")
  public init(from decoder: Decoder) throws {
    let container=try decoder.container(keyedBy: CodingKeys.self)
    let type=try container.decode(StatusTypeInternal.self, forKey: .type)

    switch type {
      case .active:
        self = .active
      case .compromised:
        self = .compromised
      case .retired:
        self = .retired
      case .pendingDeletion:
        let date=try container.decode(Date.self, forKey: .deletionDate)
        self = .pendingDeletion(date)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container=encoder.container(keyedBy: CodingKeys.self)

    switch self {
      case .active:
        try container.encode(StatusTypeInternal.active, forKey: .type)
      case .compromised:
        try container.encode(StatusTypeInternal.compromised, forKey: .type)
      case .retired:
        try container.encode(StatusTypeInternal.retired, forKey: .type)
      case let .pendingDeletion(date):
        try container.encode(StatusTypeInternal.pendingDeletion, forKey: .type)
        try container.encode(date, forKey: .deletionDate)
    }
  }
}

// MARK: - CoreServicesTypesNoFoundation Conversions

extension KeyStatus {
  /// Convert to CoreServicesTypesNoFoundation.KeyStatus
  /// - Returns: The equivalent CoreServicesTypesNoFoundation.KeyStatus
  public func toCoreServicesNoFoundation() -> Any {
    // This is a type-erased conversion to avoid direct import
    // The actual type is CoreServicesTypesNoFoundation.KeyStatus
    switch self {
      case .active:
        return "active"
      case .compromised:
        return "compromised"
      case .retired:
        return "retired"
      case let .pendingDeletion(date):
        let timestamp=Int64(date.timeIntervalSince1970)
        // We pass a tuple with type "pendingDeletion" and the timestamp value
        return ("pendingDeletion", timestamp)
    }
  }

  /// Create from CoreServicesTypesNoFoundation.KeyStatus
  /// - Parameter coreServicesNoFoundation: The CoreServicesTypesNoFoundation.KeyStatus to convert
  /// from
  /// - Returns: The equivalent canonical KeyStatus
  public static func fromCoreServicesNoFoundation(_ coreServicesNoFoundation: Any) -> KeyStatus {
    // This is a type-erased conversion to avoid direct import
    // The actual type is CoreServicesTypesNoFoundation.KeyStatus

    // Handle tuple representation for pendingDeletion
    if
      let tuple=coreServicesNoFoundation as? (String, Int64),
      tuple.0 == "pendingDeletion"
    {
      return .pendingDeletionWithTimestamp(tuple.1)
    }

    // Handle simple string values
    let rawValue=String(describing: coreServicesNoFoundation)
    switch rawValue {
      case "active":
        return .active
      case "compromised":
        return .compromised
      case "retired":
        return .retired
      default:
        fatalError("Unknown key status: \(rawValue)")
    }
  }
}
