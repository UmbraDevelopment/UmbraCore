import Foundation

/**
 # Async Backup Progress Reporting
 
 This file defines types and extensions for modern progress reporting
 using Swift's async/await concurrency model and async sequences.
 
 The approach eliminates the need for separate progress reporter and
 cancellation token parameters by providing a built-in way to:
 
 1. Report progress via AsyncStream
 2. Use Swift's native Task cancellation
 3. Handle operation updates in a more composable way
 */

/// Extension to BackupProgress to provide helpers for async progress reporting
public extension BackupProgress {
    /// Creates a continued progress stream from a completed progress
    /// - Returns: Tuple of progress stream and continuation for sending updates
    static func createStream() -> (stream: AsyncStream<BackupProgress>, continuation: AsyncStream<BackupProgress>.Continuation) {
        var continuation: AsyncStream<BackupProgress>.Continuation!
        let stream = AsyncStream<BackupProgress> { cont in
            continuation = cont
            cont.onTermination = { @Sendable _ in
                // Handle stream termination if needed
            }
        }
        return (stream, continuation)
    }
    
    /// Creates a continuous progress stream with initialisation started
    /// - Returns: Tuple of progress stream and a function to update progress
    static func createProgressStream() -> (
        stream: AsyncStream<BackupProgress>,
        update: (BackupProgress) -> Void,
        complete: () -> Void
    ) {
        let (stream, continuation) = createStream()
        
        // Send initial progress
        continuation.yield(.initialising())
        
        // Return stream with convenience functions
        return (
            stream: stream,
            update: { progress in
                continuation.yield(progress)
            },
            complete: {
                continuation.finish()
            }
        )
    }
}

/// Extends Task to provide progress tracking capabilities
public extension Task where Success == Never, Failure == Never {
    /// Creates a progress reporting task that handles operation progress
    /// - Parameters:
    ///   - operation: The backup operation being performed
    ///   - progressHandler: Handler for progress updates
    ///   - action: The action to perform with progress reporting
    /// - Returns: A cancellable task
    static func withProgressReporting(
        operation: BackupOperation,
        progressHandler: @escaping (BackupProgress) -> Void,
        action: @escaping (AsyncStream<BackupProgress>.Continuation) async throws -> Void
    ) -> Task {
        Task {
            let (_, continuation) = BackupProgress.createStream()
            
            do {
                try await action(continuation)
                await MainActor.run { progressHandler(BackupProgress.completed()) }
            } catch is CancellationError {
                await MainActor.run { progressHandler(BackupProgress.cancelled()) }
            } catch {
                await MainActor.run { progressHandler(BackupProgress.failed(error)) }
            }
            
            continuation.finish()
            
            // Satisfy the 'Never' return type requirement by suspending indefinitely
            await Task.detached { while true { try? await Task.sleep(nanoseconds: .max) } }.value
        }
    }
}

/// Protocol for progress reporting using Swift's modern async sequences
@preconcurrency public protocol AsyncProgressReporting: Sendable {
    /// Get a progress stream for the specified operation
    /// - Parameter operation: The backup operation to track
    /// - Returns: An async sequence of progress updates
    func progressStream(for operation: BackupOperation) -> AsyncStream<BackupProgress>
    
    /// Report progress for an operation
    /// - Parameters:
    ///   - progress: The progress update
    ///   - operation: The operation being performed
    func reportProgress(_ progress: BackupProgress, for operation: BackupOperation)
    
    /// Mark an operation as complete
    /// - Parameter operation: The completed operation
    func completeOperation(_ operation: BackupOperation)
}

/// Standard implementation of async progress reporting
public actor AsyncProgressReporter: AsyncProgressReporting {
    /// Progress streams by operation type
    private var streams: [BackupOperation: (stream: AsyncStream<BackupProgress>, continuation: AsyncStream<BackupProgress>.Continuation)] = [:]
    
    /// Initialises a new async progress reporter
    public init() {}
    
    /// Get a progress stream for the specified operation
    /// - Parameter operation: The backup operation to track
    /// - Returns: An async sequence of progress updates
    public nonisolated func progressStream(for operation: BackupOperation) -> AsyncStream<BackupProgress> {
        // Since we need actor isolation for this function, we'll create a stream here
        // and keep updating it from the actor-isolated methods
        let (stream, continuation) = BackupProgress.createStream()
        
        // Initialize with creating phase
        continuation.yield(BackupProgress.initialising())
        
        // Schedule task to set up the stream properly with actor
        Task {
            await setupStreamInternally(operation: operation, continuation: continuation)
        }
        
        return stream
    }
    
    /// Set up the stream internally (actor-isolated)
    private func setupStreamInternally(operation: BackupOperation, continuation: AsyncStream<BackupProgress>.Continuation) {
        streams[operation] = (BackupProgress.createStream().0, continuation)
    }
    
    /// Report progress for an operation
    /// - Parameters:
    ///   - progress: The progress update
    ///   - operation: The operation being performed
    public nonisolated func reportProgress(_ progress: BackupProgress, for operation: BackupOperation) {
        Task {
            await reportProgressInternally(progress, for: operation)
        }
    }
    
    /// Report progress internally (actor-isolated)
    private func reportProgressInternally(_ progress: BackupProgress, for operation: BackupOperation) {
        if let continuation = streams[operation]?.continuation {
            continuation.yield(progress)
        }
    }
    
    /// Mark an operation as complete
    /// - Parameter operation: The completed operation
    public nonisolated func completeOperation(_ operation: BackupOperation) {
        Task {
            await completeOperationInternally(operation)
        }
    }
    
    /// Complete operation internally (actor-isolated)
    private func completeOperationInternally(_ operation: BackupOperation) {
        if let continuation = streams[operation]?.continuation {
            continuation.yield(BackupProgress.completed())
            continuation.finish()
            streams.removeValue(forKey: operation)
        }
    }
}
