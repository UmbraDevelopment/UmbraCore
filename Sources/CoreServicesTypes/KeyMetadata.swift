import Foundation
import KeyManagementTypes

/// Metadata about a cryptographic key
///
/// - Important: This type is deprecated. Please use the canonical `KeyMetadata` instead.
@available(*, deprecated, message: "Please use KeyManagementTypes.KeyMetadata instead")
public struct KeyMetadata: Sendable, Codable {
  /// Current status of the key
  public var status: KeyManagementTypes.KeyStatus

  /// Storage location of the key
  public let storageLocation: KeyManagementTypes.StorageLocation

  /// Access control settings for the key
  @available(
    *,
    deprecated,
    message: "Please use KeyManagementTypes.KeyMetadata.AccessControls instead"
  )
  public typealias AccessControls = KeyManagementTypes.KeyMetadata.AccessControls

  /// Access controls applied to the key
  public let accessControls: AccessControls

  /// Creation date of the key
  public let createdAt: Date

  /// Last modification date of the key
  public var lastModified: Date

  /// Expiry date of the key (if applicable)
  public var expiryDate: Date?

  /// Key algorithm and parameters
  public let algorithm: String

  /// Key size in bits
  public let keySize: Int

  /// Whether the key is isolated to the current process
  public var isProcessIsolated: Bool

  /// Custom metadata associated with the key
  public var customMetadata: [String: String]?

  /// Create new key metadata
  /// - Parameters:
  ///   - storageLocation: Where the key is stored
  ///   - accessControls: Access control settings
  ///   - algorithm: Key algorithm
  ///   - keySize: Key size in bits
  ///   - expiryDate: Optional expiry date for the key
  ///   - isProcessIsolated: Whether the key is isolated to the current process
  ///   - customMetadata: Additional metadata
  public init(
    storageLocation: KeyManagementTypes.StorageLocation,
    accessControls: AccessControls = .none,
    algorithm: String,
    keySize: Int,
    expiryDate: Date? = nil,
    isProcessIsolated: Bool = false,
    customMetadata: [String: String]? = nil
  ) {
    status = KeyManagementTypes.KeyStatus.active
    self.storageLocation = storageLocation
    self.accessControls = accessControls
    self.algorithm = algorithm
    self.keySize = keySize
    createdAt = Date()
    lastModified = Date()
    self.expiryDate = expiryDate
    self.isProcessIsolated = isProcessIsolated
    self.customMetadata = customMetadata
  }
}
