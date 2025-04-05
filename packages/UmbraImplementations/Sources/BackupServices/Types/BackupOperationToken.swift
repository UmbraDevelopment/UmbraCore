import BackupInterfaces
import Foundation

/**
 * Token that represents an ongoing backup operation,
 * enabling functionality like cancellation.
 */
public final class BackupOperationToken: Sendable {
  /// Unique identifier for this operation
  public let id: UUID

  /// Type of operation being performed
  public let operation: BackupOperation

  /// Whether the operation is cancellable
  public let cancellable: Bool

  /// Whether the operation has been cancelled
  @MainActor
  public private(set) var cancelled: Bool

  /**
   * Creates a new operation token.
   *
   * - Parameters:
   *   - id: Unique identifier for the operation
   *   - operation: Type of operation being performed
   *   - cancellable: Whether the operation can be cancelled
   */
  public init(
    id: UUID,
    operation: BackupOperation,
    cancellable: Bool=true
  ) {
    self.id=id
    self.operation=operation
    self.cancellable=cancellable
    cancelled=false
  }
}

/**
 * Extension to make BackupOperationToken hashable.
 *
 * This enables tokens to be used in sets and as dictionary keys.
 */
extension BackupOperationToken: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public static func == (lhs: BackupOperationToken, rhs: BackupOperationToken) -> Bool {
    lhs.id == rhs.id
  }
}
