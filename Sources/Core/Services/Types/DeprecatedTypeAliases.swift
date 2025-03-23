import Foundation
import KeyManagementTypes

/// This file provides migration helpers between legacy types and
/// their canonical counterparts in the KeyManagementTypes module.
/// All legacy type aliases have been removed in favor of fully qualified types.

// Removed type aliases:
// public typealias KeyMetadataLegacy = KeyMetadata
// public typealias KeyStatusLegacy = KeyStatus
// public typealias StorageLocationLegacy = StorageLocation
// public typealias ServiceStateLegacy = ServiceState

/// Extension to provide migration helpers for the canonical KeyMetadata type
extension KeyManagementTypes.KeyMetadata {
  /// Convert from the legacy KeyMetadata to the canonical version
  ///
  /// - Parameter legacy: The legacy KeyMetadata instance
  /// - Returns: A new canonical KeyMetadata instance
  public static func from(legacy: KeyManagementTypes.KeyMetadata) -> KeyManagementTypes
  .KeyMetadata {
    // Create a new instance of the canonical KeyMetadata
    KeyManagementTypes.KeyMetadata(
      status: legacy.status,
      storageLocation: legacy.storageLocation,
      accessControls: translateAccessControls(from: legacy.accessControls),
      createdAt: legacy.createdAt,
      lastModified: legacy.lastModified,
      expiryDate: legacy.expiryDate,
      algorithm: legacy.algorithm,
      keySize: legacy.keySize,
      identifier: legacy.identifier,
      version: legacy.version,
      exportable: false, // Default value as it doesn't exist in legacy version
      isSystemKey: false, // Default value as it doesn't exist in legacy version
      isProcessIsolated: false // Default value as it doesn't exist in legacy version
    )
  }

  /// Convert to the legacy KeyMetadata format
  ///
  /// - Returns: A legacy KeyMetadata instance
  public func toLegacy() -> KeyManagementTypes.KeyMetadata {
    // Create a new instance of the legacy KeyMetadata
    KeyManagementTypes.KeyMetadata(
      status: status,
      storageLocation: storageLocation,
      accessControls: translateAccessControlsToLegacy(from: accessControls),
      createdAt: createdAt,
      lastModified: lastModified,
      expiryDate: expiryDate,
      algorithm: algorithm,
      keySize: keySize,
      identifier: identifier,
      version: version
    )
  }

  /// Translate AccessControls from legacy to canonical format
  private static func translateAccessControls(
    from legacyControls: KeyManagementTypes.KeyMetadata
      .AccessControls
  ) -> KeyManagementTypes.KeyMetadata.AccessControls {
    switch legacyControls {
      case .none:
        .none
      case .requiresAuthentication:
        .requiresAuthentication
      case .requiresBiometric:
        .requiresBiometric
      case .requiresBoth:
        .requiresBoth
      @unknown default:
        // Handle any new case that might be added in the future
        .none
    }
  }

  /// Translate AccessControls from canonical to legacy format
  private func translateAccessControlsToLegacy(
    from controls: KeyManagementTypes.KeyMetadata
      .AccessControls
  ) -> KeyManagementTypes.KeyMetadata.AccessControls {
    switch controls {
      case .none:
        return .none
      case .requiresAuthentication:
        return .requiresAuthentication
      case .requiresBiometric:
        return .requiresBiometric
      case .requiresBoth:
        return .requiresBoth
      @unknown default:
        // Fall back to none as the safest option for unknown future cases
        return .none
    }
  }
}

/// Provides guidance for transitioning from deprecated to canonical types
public enum MigrationGuidance {
  /// Basic migration steps for codebase
  public static let steps="""
    Swift 6 Migration for Key Management Types:

    1. Use the fully qualified types from KeyManagementTypes module directly.

    2. New code should adopt the canonical types from KeyManagementTypes module directly.

    3. For existing code, use the conversion methods:
       - KeyManagementTypes.KeyMetadata.from(legacy:)
       - keyMetadataInstance.toLegacy()

    4. Long-term, plan to fully migrate to the canonical types before a future major release.
    """
}
