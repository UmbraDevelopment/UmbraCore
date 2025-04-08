import BackupInterfaces
import Foundation

/**
 * Manages the cancellation of asynchronous operations in a thread-safe manner.
 *
 * This actor-based implementation ensures that task cancellation is properly
 * coordinated across multiple operations, preventing race conditions and ensuring
 * operations can be properly cleaned up when cancelled.
 *
 * The implementation follows Alpha Dot Five architecture principles using:
 * - Actor isolation for thread safety
 * - Standardised cancellation tokens
 * - Support for both task-based and token-based cancellation
 */
public actor CancellationHandler: CancellationHandlerProtocol {
  /// Storage for active operations that can be cancelled
  private var activeOperations: [String: Task<any Sendable, Error>]=[:]

  /// Storage for active cancellation tokens
  private var cancellationTokens: [String: BackupCancellationToken]=[:]

  /**
   * Creates a new cancellation handler.
   */
  public init() {}

  /**
   * Registers an operation that can be cancelled.
   *
   * - Parameters:
   *   - id: Unique identifier for the operation
   *   - operation: The task representing the operation
   */
  public func registerOperation(id: String, operation: Task<some Sendable, Error>) {
    // Store the task with type erasure
    activeOperations[id]=operation as? Task<any Sendable, Error>
  }

  /**
   * Registers a new operation for cancellation tracking.
   *
   * - Parameter id: Unique identifier for the operation
   * - Returns: A cancellation token for the operation
   */
  public func registerOperation(id: String) async -> BackupCancellationToken {
    // If a token already exists for this ID, return it
    if let token=cancellationTokens[id] {
      return token
    }

    // Create a new token
    let token=BackupCancellationTokenImpl(id: id, handler: self)
    cancellationTokens[id]=token
    return token
  }

  /**
   * Unregisters an operation from cancellation tracking.
   *
   * - Parameter id: Identifier of the operation to unregister
   */
  public func unregisterOperation(id: String) async {
    activeOperations[id]=nil
    cancellationTokens[id]=nil
  }

  /**
   * Checks if an operation has been cancelled.
   *
   * - Parameter id: Identifier of the operation to check
   * - Returns: Whether the operation has been cancelled
   */
  public func isOperationCancelled(id: String) async -> Bool {
    // Check if the token exists and is cancelled
    if let token=cancellationTokens[id] {
      return await token.isCancelled
    }
    return false
  }

  /**
   * Cancels a specific operation.
   *
   * - Parameter id: Identifier of the operation to cancel
   * - Returns: Whether the operation was successfully cancelled
   */
  public func cancelOperation(id: String) -> Bool {
    var cancelled=false

    // Try to cancel a task-based operation
    if let operation=activeOperations[id] {
      operation.cancel()
      activeOperations[id]=nil
      cancelled=true
    }

    // Try to cancel a token-based operation
    if let token=cancellationTokens[id] as? BackupCancellationTokenImpl {
      token.setCancelled()
      cancelled=true
    }

    return cancelled
  }

  /**
   * Executes an operation with cancellation support.
   *
   * - Parameters:
   *   - operation: The operation to execute
   *   - token: The cancellation token for the operation
   * - Returns: The result of the operation
   * - Throws: CancellationError if the operation is cancelled
   */
  public func withCancellationSupport<T: Sendable>(
    _ operation: @Sendable () async throws -> T,
    cancellationToken token: BackupCancellationToken?
  ) async throws -> T {
    // If no token, just execute the operation
    guard let token else {
      return try await operation()
    }

    // Check if already cancelled
    if await token.isCancelled {
      throw CancellationError()
    }

    // Create a task that can be cancelled
    let task=Task<T, Error> {
      try await operation()
    }

    // Register the task for cancellation
    if let tokenImpl=token as? BackupCancellationTokenImpl {
      registerOperation(id: tokenImpl.id, operation: task)
    }

    do {
      // Execute the operation
      return try await task.value
    } catch is CancellationError {
      // Propagate cancellation
      throw CancellationError()
    } catch {
      // Propagate other errors
      throw error
    }
  }

  /**
   * Cancels all active operations.
   */
  public func cancelAllOperations() {
    // Cancel all task-based operations
    for (_, task) in activeOperations {
      task.cancel()
    }
    activeOperations.removeAll()

    // Cancel all token-based operations
    for (_, token) in cancellationTokens {
      if let cancellable=token as? BackupCancellationTokenImpl {
        cancellable.setCancelled()
      }
    }
  }
}

/**
 * Implementation of BackupCancellationToken.
 */
private final class BackupCancellationTokenImpl: BackupCancellationToken, @unchecked Sendable {
  /// The unique identifier for this token
  public let id: String

  /// Whether the operation has been cancelled
  public private(set) var isCancelled: Bool=false

  /// The handler that created this token
  private weak var handler: CancellationHandler?

  /// Lock for thread-safe access to isCancelled
  private let lock=NSLock()

  /**
   * Creates a new cancellation token.
   *
   * - Parameters:
   *   - id: Unique identifier for the token
   *   - handler: The handler that created this token
   */
  init(id: String, handler: CancellationHandler) {
    self.id=id
    self.handler=handler
  }

  /**
   * Sets the token as cancelled.
   */
  func setCancelled() {
    lock.lock()
    defer { lock.unlock() }
    isCancelled=true
  }

  /**
   * Cancels the operation associated with this token.
   */
  public func cancel() async {
    // Set as cancelled
    setCancelled()

    // Notify the handler
    await handler?.cancelOperation(id: id)
  }
}
