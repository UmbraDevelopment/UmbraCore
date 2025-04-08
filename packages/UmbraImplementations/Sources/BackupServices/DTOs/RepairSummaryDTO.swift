import BackupInterfaces
import Foundation

/**
 * DTO for summary of repair actions taken during backup verification.
 */
public struct RepairSummaryDTO: Sendable, Equatable {
  /// Whether the repair operation was successful overall
  public let successful: Bool

  /// Number of issues successfully repaired
  public let repairedCount: Int

  /// Number of issues that could not be repaired
  public let unrepairedCount: Int

  /// Specific repair actions taken
  public let actions: [RepairActionDTO]

  /**
   * Creates a new repair summary DTO.
   *
   * - Parameters:
   *   - successful: Whether the repair operation was successful overall
   *   - repairedCount: Number of issues successfully repaired
   *   - unrepairedCount: Number of issues that could not be repaired
   *   - actions: Specific repair actions taken
   */
  public init(
    successful: Bool,
    repairedCount: Int,
    unrepairedCount: Int,
    actions: [RepairActionDTO]
  ) {
    self.successful=successful
    self.repairedCount=repairedCount
    self.unrepairedCount=unrepairedCount
    self.actions=actions
  }
}
