import Foundation

/**
 * Summary of repair actions taken during backup verification.
 *
 * This struct encapsulates information about repair actions taken
 * during backup verification, including counts of repaired and
 * unrepaired issues, and details of specific actions taken.
 */
public struct RepairSummary: Sendable, Equatable {
  /// Number of issues successfully repaired
  public let repairedCount: Int

  /// Number of issues that could not be repaired
  public let unrepairedCount: Int

  /// Specific repair actions taken
  public let actions: [RepairAction]

  /**
   * Creates a new repair summary.
   *
   * - Parameters:
   *   - repairedCount: Number of issues successfully repaired
   *   - unrepairedCount: Number of issues that could not be repaired
   *   - actions: Specific repair actions taken
   */
  public init(
    repairedCount: Int,
    unrepairedCount: Int,
    actions: [RepairAction]
  ) {
    self.repairedCount=repairedCount
    self.unrepairedCount=unrepairedCount
    self.actions=actions
  }
}

/**
 * Represents a repair action taken during verification.
 */
public struct RepairAction: Sendable, Equatable {
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

    /// Removed corrupted data
    case removeCorrupted

    /// Other repair action
    case other
  }

  /// Type of the action
  public let type: ActionType

  /// Path to the repaired object
  public let path: String?

  /// Description of the repair action
  public let description: String

  /// Whether the repair was successful
  public let successful: Bool

  /**
   * Creates a new repair action.
   *
   * - Parameters:
   *   - type: Type of the action
   *   - path: Path to the repaired object
   *   - description: Description of the repair action
   *   - successful: Whether the repair was successful
   */
  public init(
    type: ActionType,
    path: String?=nil,
    description: String,
    successful: Bool
  ) {
    self.type=type
    self.path=path
    self.description=description
    self.successful=successful
  }
}
