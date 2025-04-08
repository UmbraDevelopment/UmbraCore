import BackupInterfaces
import Foundation

/**
 * DTO for repair actions taken during verification.
 */
public struct RepairActionDTO: Sendable, Equatable {
  /**
   * Type of repair action.
   */
  public enum ActionType: String, Sendable, Equatable, CaseIterable {
    /// Recreated missing data
    case recreateData

    /// Restored from backup copy
    case restoreFromBackup

    /// Rebuilt metadata
    case rebuildMetadata

    /// Prune repository to remove unreferenced data
    case pruneRepository
  }

  /// Type of the action
  public let type: ActionType

  /// Path to the repaired object
  public let path: String?

  /// Description of the repair action
  public let description: String

  /// Whether the repair was successful
  public let successful: Bool

  /// Files affected by this repair action
  public let affectedFiles: [String]?

  /**
   * Creates a new repair action DTO.
   *
   * - Parameters:
   *   - type: Type of the action
   *   - path: Path to the repaired object
   *   - description: Description of the repair action
   *   - successful: Whether the repair was successful
   *   - affectedFiles: Files affected by this repair action
   */
  public init(
    type: ActionType,
    path: String?=nil,
    description: String,
    successful: Bool,
    affectedFiles: [String]?=nil
  ) {
    self.type=type
    self.path=path
    self.description=description
    self.successful=successful
    self.affectedFiles=affectedFiles
  }
}
