import Foundation

/// A wrapper for AsyncStream continuations that allows identification and comparison.
/// This addresses Swift's limitation that continuations are value types and can't be compared
/// with identity comparison (===).
public struct ContinuationWrapper<T> {
    /// Unique identifier for this wrapper
    public let id: UUID
    
    /// The wrapped continuation
    public let continuation: AsyncStream<T>.Continuation
    
    /// Creates a new wrapper with a unique identifier
    /// - Parameter continuation: The continuation to wrap
    public init(continuation: AsyncStream<T>.Continuation) {
        self.id = UUID()
        self.continuation = continuation
    }
    
    /// Yields a value to the continuation
    /// - Parameter value: The value to yield
    public func yield(_ value: T) {
        continuation.yield(value)
    }
    
    /// Finishes the continuation
    public func finish() {
        continuation.finish()
    }
}

extension ContinuationWrapper: Equatable {
    public static func == (lhs: ContinuationWrapper<T>, rhs: ContinuationWrapper<T>) -> Bool {
        lhs.id == rhs.id
    }
}

extension ContinuationWrapper: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
