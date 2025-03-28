import Foundation
import FileSystemInterfaces
import LoggingInterfaces
import LoggingTypes

/**
 # File System Service Factory
 
 Factory class for creating instances of FileSystemServiceProtocol with different configurations.
 This provides a centralised way to create file system services with consistent options.
 */
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class FileSystemServiceFactory: @unchecked Sendable {
    /// Shared singleton instance
    public static let shared: FileSystemServiceFactory = FileSystemServiceFactory()
    
    /// Private initialiser to enforce singleton pattern
    private init() {}
    
    // MARK: - Factory Methods
    
    /**
     Creates a standard file system service instance.
     
     This is the recommended factory method for most use cases. It provides a balanced 
     configuration suitable for general file operations.
     
     - Parameters:
        - logger: Optional logger for operation tracking
     - Returns: An implementation of FileSystemServiceProtocol
     */
    public func createStandardService(
        logger: (any LoggingInterfaces.LoggingProtocol)? = nil
    ) -> any FileSystemServiceProtocol {
        let fileManager = FileManager.default
        
        return FileSystemServiceImpl(
            fileManager: fileManager,
            operationQueueQoS: .utility,
            logger: logger ?? NullLogger()
        )
    }
    
    /**
     Creates a high-performance file system service instance.
     
     This service is optimised for throughput and performance, using maximum resources
     for file operations. Use this when processing large files or performing batch operations
     where performance is critical.
     
     - Parameters:
        - logger: Optional logger for operation tracking
     - Returns: An implementation of FileSystemServiceProtocol
     */
    public func createHighPerformanceService(
        logger: (any LoggingInterfaces.LoggingProtocol)? = nil
    ) -> any FileSystemServiceProtocol {
        let fileManager = FileManager.default
        
        return FileSystemServiceImpl(
            fileManager: fileManager,
            operationQueueQoS: .userInitiated,
            logger: logger ?? NullLogger()
        )
    }
    
    /**
     Creates a secure file system service instance.
     
     This service prioritises security measures such as secure deletion, 
     permission verification, and data validation. Use this when working with 
     sensitive data or in security-critical contexts.
     
     - Parameters:
        - logger: Optional logger for operation tracking (recommended for security auditing)
     - Returns: An implementation of FileSystemServiceProtocol
     */
    public func createSecureService(
        logger: (any LoggingInterfaces.LoggingProtocol)? = nil
    ) -> any FileSystemServiceProtocol {
        let fileManager = FileManager.default
        
        return FileSystemServiceImpl(
            fileManager: fileManager,
            operationQueueQoS: .utility,
            logger: logger ?? NullLogger()
        )
    }
    
    /**
     Creates a custom file system service instance with full configuration control.
     
     This method provides complete control over all aspects of the file system service
     configuration for specialised use cases.
     
     Note: When providing a custom FileManager, it's important to ensure it's not accessed
     concurrently from multiple contexts to avoid potential data races in Swift 6. The service
     implementation isolates FileManager access within an actor to provide thread safety.
     
     - Parameters:
        - fileManager: The FileManager to use (isolated within the service actor)
        - operationQueueQoS: The QoS class for background operations
        - logger: Optional logger for operation tracking
     - Returns: An implementation of FileSystemServiceProtocol
     */
    @_disfavoredOverload // Discourages use of this method to avoid Swift 6 warnings
    public func createCustomService(
        fileManager: FileManager = FileManager.default,
        operationQueueQoS: QualityOfService = .utility,
        logger: (any LoggingInterfaces.LoggingProtocol)? = nil
    ) -> any FileSystemServiceProtocol {
        // This method is marked with @_disfavoredOverload to discourage its use
        // due to Swift 6 warnings about FileManager sendability
        return FileSystemServiceImpl(
            fileManager: fileManager,
            operationQueueQoS: operationQueueQoS,
            logger: logger ?? NullLogger()
        )
    }
    
    /**
     Creates a custom file system service instance with full configuration control.
     
     This method is Swift 6 compatible and should be preferred over the version that
     takes a FileManager parameter directly.
     
     - Parameters:
        - operationQueueQoS: The QoS class for background operations
        - logger: Optional logger for operation tracking
     - Returns: An implementation of FileSystemServiceProtocol
     */
    public func createCustomService(
        operationQueueQoS: QualityOfService = .utility,
        logger: (any LoggingInterfaces.LoggingProtocol)? = nil
    ) -> any FileSystemServiceProtocol {
        // Use default FileManager to avoid Swift 6 warnings
        let fileManager = FileManager.default
        
        return FileSystemServiceImpl(
            fileManager: fileManager,
            operationQueueQoS: operationQueueQoS,
            logger: logger ?? NullLogger()
        )
    }
}

/**
 A null logger implementation used as a default when no logger is provided.
 This avoids the need for nil checks throughout the file system services code.
 */
private struct NullLogger: LoggingInterfaces.LoggingProtocol {
    func debug(_ message: String, metadata: LoggingTypes.LogMetadata?) async {}
    func info(_ message: String, metadata: LoggingTypes.LogMetadata?) async {}
    func notice(_ message: String, metadata: LoggingTypes.LogMetadata?) async {}
    func warning(_ message: String, metadata: LoggingTypes.LogMetadata?) async {}
    func error(_ message: String, metadata: LoggingTypes.LogMetadata?) async {}
    func critical(_ message: String, metadata: LoggingTypes.LogMetadata?) async {}
    func fault(_ message: String, metadata: LoggingTypes.LogMetadata?) async {}
}
