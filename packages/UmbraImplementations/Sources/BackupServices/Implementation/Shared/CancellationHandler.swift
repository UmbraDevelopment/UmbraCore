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
  @unchecked Sendable private var activeOperations: [String: Task<Any, Error>]=[:]

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
  public func registerOperation(id: String, operation: Task<some Any, Error>) {
    // Store the task as Task<Any, Error> for type erasure
    activeOperations[id]=operation as? Task<Any, Error>
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

    // Otherwise, create a new token
    let token=BackupOperationCancellationToken(id: id)

    // Register an onCancelled callback to remove the token when cancelled
    await token.onCancelled { [weak self] in
      Task { [weak self] in
        await self?.operationCompleted(id: id)
      }
    }

    cancellationTokens[id]=token
    return token
  }

  /**
   * Cancels a specific operation by its ID.
   *
   * - Parameter id: The ID of the operation to cancel
   * - Returns: True if an operation was found and cancelled, false otherwise
   */
  public func cancelOperation(id: String) async -> Bool {
    var cancelled=false

    // Try to cancel a task-based operation
    if let operation=activeOperations[id] {
      operation.cancel()
      activeOperations[id]=nil
      cancelled=true
    }

    // Try to cancel a token-based operation
    if let token=cancellationTokens[id] {
      await token.cancel()
      cancellationTokens[id]=nil
      cancelled=true
    }

    return cancelled
  }

  /**
   * Checks if an operation has been cancelled.
   *
   * - Parameter id: ID of the operation to check
   * - Returns: Whether the operation has been cancelled
   */
  public func isOperationCancelled(id: String) async -> Bool {
    // Check if we have a token for this ID
    if let token=cancellationTokens[id] {
      return await token.isCancelled
    }

    // If there's no token, the operation might be cancelled if it's not active
    return await !(isOperationActive(id: id))
  }

  /**
   * Unregisters an operation from cancellation tracking.
   *
   * - Parameter id: Identifier of the operation to unregister
   */
  public func unregisterOperation(id: String) async {
    operationCompleted(id: id)
  }

  /**
   * Cancels all currently active operations.
   *
   * - Returns: The number of operations that were cancelled
   */
  public func cancelAllOperations() async -> Int {
    let taskCount=activeOperations.count
    let tokenCount=cancellationTokens.count

    // Cancel all task-based operations
    for (_, task) in activeOperations {
      task.cancel()
    }
    activeOperations.removeAll()

    // Cancel all token-based operations
    for (_, token) in cancellationTokens {
      await token.cancel()
    }
    cancellationTokens.removeAll()

    return taskCount + tokenCount
  }

  /**
   * Removes a completed operation from the registry.
   *
   * - Parameter id: The ID of the operation to remove
   */
  public func operationCompleted(id: String) {
    activeOperations[id]=nil
    cancellationTokens[id]=nil
  }

  /**
   * Checks if an operation with the specified ID is still active.
   *
   * - Parameter id: The operation ID to check
   * - Returns: True if the operation is active, false otherwise
   */
  public func isOperationActive(id: String) async -> Bool {
    activeOperations[id] != nil || cancellationTokens[id] != nil
  }

  /**
   * Gets the count of currently active operations.
   *
   * - Returns: The number of active operations
   */
  public func activeOperationCount() -> Int {
    activeOperations.count + cancellationTokens.count
  }

  /**
   * Creates a new operation ID.
   *
   * - Returns: A unique operation ID
   */
  public func createOperationID() -> String {
    UUID().uuidString
  }

  /**
   * Executes an operation with cancellation support.
   *
   * - Parameters:
   *   - operation: The function to execute
   *   - cancellationToken: Optional token for cancelling the operation
   * - Returns: The result of the operation
   * - Throws: CancellationError if the operation is cancelled
   */
  public func withCancellationSupport<T: Sendable>(
    _ operation: @Sendable @escaping () async throws -> T,
    cancellationToken: BackupCancellationToken?
  ) async throws -> T {
    // Pre-check for cancellation
    if let token=cancellationToken as? BackupOperationCancellationToken {
      try await token.checkCancelled()
    }

    // Create a unique ID for this operation
    let operationID=createOperationID()

    // Transform the operation into a Task
    let task=Task<T, Error> {
      do {
        let result=try await operation()
        operationCompleted(id: operationID)
        return result
      } catch {
        operationCompleted(id: operationID)
        throw error
      }
    }

    // Register the task for cancellation with proper generic type
    registerOperation(id: operationID, operation: task)

    // If we have a cancellation token, set up a callback
    if let token=cancellationToken {
      if let concreteToken=token as? BackupOperationCancellationToken {
        await concreteToken.onCancelled { [weak self] in
          guard let self else { return }

          // Cancel the task if the token is cancelled
          Task { [weak self] in
            guard let self else { return }
            _=await cancelOperation(id: operationID)
          }
        }
      } else {
        // For other token types, we need to periodically check
        Task { [weak self] in
          guard let self else { return }

          while !task.isCancelled {
            if await isOperationActive(id: operationID) {
              if await token.isCancelled {
                _=await cancelOperation(id: operationID)
                break
              }
              try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            } else {
              break
            }
          }
        }
      }
    }

    do {
      return try await task.value
    } catch {
      // Re-throw the caught error (could be CancellationError or something else)
      throw error
    }
  }
}

/**
 * Extension to provide backward compatibility with ModernCancellationHandler.
 */
public typealias ModernCancellationHandler=CancellationHandler
