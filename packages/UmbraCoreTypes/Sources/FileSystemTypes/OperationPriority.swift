import Foundation

/**
 # Operation Priority
 
 Defines priority levels for file system operations.
 
 This enum provides a standardised set of priority options for file system operations,
 allowing callers to specify their performance requirements while abstracting away the
 underlying system-specific implementation details (such as QoS classes).
 
 ## Usage
 
 ```swift
 let factory = FileSystemServiceFactoryImpl()
 let service = factory.createPerformanceOptimisedService(
     bufferSize: 131072,
     operationPriority: .elevated,
     backgroundOperations: true
 )
 ```
 
 ## Implementation Details
 
 The priority levels correspond to system-specific QoS classes or thread priorities
 in the underlying implementation, but provide a platform-independent abstraction.
 */
public enum OperationPriority: String, Codable, Sendable {
    /// Low priority, suitable for background operations such as cleanup or indexing
    case background
    
    /// Standard priority for typical file operations
    case normal
    
    /// Higher priority for operations that are important but not critical
    case elevated
    
    /// Highest priority for operations that are time-sensitive or user-initiated
    case critical
}
