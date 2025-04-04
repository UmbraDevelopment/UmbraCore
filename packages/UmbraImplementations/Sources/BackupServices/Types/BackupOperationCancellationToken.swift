import Foundation
import BackupInterfaces

/**
 * This file is deprecated and has been replaced by the actor implementation in CancellationToken.swift
 * Keeping this file temporarily to maintain backward compatibility with legacy code.
 * 
 * @deprecated Use BackupOperationCancellationToken from BackupInterfaces instead
 */

/**
 * Legacy wrapper to maintain backward compatibility.
 * This class redirects to the canonical actor-based implementation.
 *
 * @deprecated Use BackupOperationCancellationToken from BackupInterfaces instead
 */
public class BackupOperationCancellationTokenImpl: Sendable {
  /// Unique identifier for this token
  public let id: String
  
  /// Whether the operation has been cancelled
  public var cancelled: Bool
  
  /// The actual actor-based token
  private let actorToken: BackupOperationCancellationToken
  
  /**
   * Creates a new cancellation token.
   *
   * - Parameter id: Unique identifier for this token
   */
  public init(id: String) {
    self.id = id
    self.cancelled = false
    self.actorToken = BackupOperationCancellationToken(id: id)
  }
  
  /**
   * Marks the operation as cancelled.
   */
  public func cancel() {
    Task {
      await actorToken.cancel()
      self.cancelled = await actorToken.isCancelled
    }
  }
}

/**
 * Extension to make BackupOperationCancellationTokenImpl conform to ProgressCancellationToken.
 *
 * This enables the token to be used with the progress reporting system.
 */
extension BackupOperationCancellationTokenImpl: ProgressCancellationToken {
  /// Returns whether the operation has been cancelled
  public var isCancelled: Bool {
    cancelled
  }
}
