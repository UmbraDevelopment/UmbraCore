import Foundation
import BackupInterfaces

/**
 * Protocol for handling cancellation in operations.
 *
 * This protocol provides a standardised approach to handling
 * cancellation in long-running operations, following the
 * Alpha Dot Five architecture's principles.
 */
public protocol CancellationHandlerProtocol: Sendable {
    /**
     * Executes an operation with cancellation support.
     *
     * - Parameters:
     *   - cancellationToken: Optional token for cancelling the operation
     *   - operation: The operation to execute
     * - Returns: The result of the operation
     * - Throws: Error if the operation fails or is cancelled
     */
    func executeWithCancellationSupport<T>(
        cancellationToken: CancellationToken?,
        operation: @escaping () async throws -> T
    ) async throws -> T
}

/**
 * Modern implementation of the cancellation handler protocol.
 * 
 * This implementation follows the Alpha Dot Five architecture
 * principles for handling cancellation in a privacy-aware manner.
 */
public actor ModernCancellationHandler: CancellationHandlerProtocol {
    /**
     * Initialises a new cancellation handler.
     */
    public init() {}
    
    /**
     * Executes an operation with cancellation support.
     *
     * - Parameters:
     *   - cancellationToken: Optional token for cancelling the operation
     *   - operation: The operation to execute
     * - Returns: The result of the operation
     * - Throws: Error if the operation fails or is cancelled
     */
    public func executeWithCancellationSupport<T>(
        cancellationToken: CancellationToken?,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        // If no token is provided, execute the operation directly
        guard let token = cancellationToken else {
            return try await operation()
        }
        
        // Create a task for checking cancellation
        let cancellationTask = Task {
            while !Task.isCancelled {
                if await token.isCancelled() {
                    throw CancellationError()
                }
                try await Task.sleep(nanoseconds: 100_000_000) // Check every 100ms
            }
        }
        
        // Create a task for the operation
        let operationTask = Task {
            try await operation()
        }
        
        // Wait for either completion or cancellation
        do {
            let result = try await operationTask.value
            cancellationTask.cancel()
            return result
        } catch {
            cancellationTask.cancel()
            throw error
        }
    }
}
