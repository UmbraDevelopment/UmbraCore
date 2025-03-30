import Foundation
import BackupInterfaces

/**
 * Manages the cancellation of asynchronous operations in a thread-safe manner.
 *
 * This actor-based implementation ensures that task cancellation is properly
 * coordinated across multiple operations, preventing race conditions and ensuring
 * operations can be properly cleaned up when cancelled.
 */
public actor CancellationHandler {
    /// Storage for active operations that can be cancelled
    private var activeOperations: [String: Task<Void, Error>] = [:]
    
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
    public func registerOperation(id: String, operation: Task<Void, Error>) {
        activeOperations[id] = operation
    }
    
    /**
     * Cancels a specific operation by its ID.
     *
     * - Parameter id: The ID of the operation to cancel
     * - Returns: True if an operation was found and cancelled, false otherwise
     */
    public func cancelOperation(id: String) -> Bool {
        guard let operation = activeOperations[id] else {
            return false
        }
        
        operation.cancel()
        activeOperations[id] = nil
        return true
    }
    
    /**
     * Cancels all currently active operations.
     *
     * - Returns: The number of operations that were cancelled
     */
    public func cancelAllOperations() -> Int {
        let count = activeOperations.count
        
        for (_, task) in activeOperations {
            task.cancel()
        }
        
        activeOperations.removeAll()
        return count
    }
    
    /**
     * Removes a completed operation from the registry.
     *
     * - Parameter id: The ID of the operation to remove
     */
    public func operationCompleted(id: String) {
        activeOperations[id] = nil
    }
    
    /**
     * Checks if an operation with the specified ID is still active.
     *
     * - Parameter id: The operation ID to check
     * - Returns: True if the operation is active, false otherwise
     */
    public func isOperationActive(id: String) -> Bool {
        return activeOperations[id] != nil
    }
    
    /**
     * Gets the count of currently active operations.
     *
     * - Returns: The number of active operations
     */
    public func activeOperationCount() -> Int {
        return activeOperations.count
    }
    
    /**
     * Creates a new operation ID.
     *
     * - Returns: A unique operation ID
     */
    public func createOperationID() -> String {
        return UUID().uuidString
    }
    
    /**
     * Wraps a task with cancellation support.
     *
     * - Parameters:
     *   - cancellationToken: Optional token to signal cancellation
     *   - operation: The operation to execute
     * - Returns: The result of the operation
     * - Throws: BackupError.operationCancelled if the operation is cancelled
     */
    public func executeWithCancellationSupport<T>(
        cancellationToken: CancellationToken?,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        // Pre-check for cancellation
        try cancellationToken?.checkCancelled()
        
        // Create a unique ID for this operation
        let operationID = createOperationID()
        
        // Create a task that we can cancel
        let task: Task<T, Error> = Task {
            try await operation()
        }
        
        // Register the operation if we have a cancellation token
        if let token = cancellationToken {
            // We need a dummy task that we can cancel since we can't cast between Task types
            let wrapperTask: Task<Void, Error> = Task {
                _ = try await task.value
            }
            
            registerOperation(id: operationID, operation: wrapperTask)
            
            // Set up cancellation handler
            await token.onCancelled { [weak self] in
                guard let self = self else { return }
                
                Task {
                    await self.cancelOperation(id: operationID)
                }
            }
        }
        
        do {
            // Execute the operation
            let result = try await task.value
            
            // Clean up
            await operationCompleted(id: operationID)
            
            return result
        } catch is CancellationError {
            // Operation was cancelled
            await operationCompleted(id: operationID)
            
            throw BackupError.operationCancelled(reason: "Operation was cancelled")
        } catch {
            // Operation failed with a different error
            await operationCompleted(id: operationID)
            
            throw error
        }
    }
}
