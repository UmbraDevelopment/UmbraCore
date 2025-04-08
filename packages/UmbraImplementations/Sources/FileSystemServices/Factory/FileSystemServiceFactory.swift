import FileSystemInterfaces
import Foundation
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
  public static let shared: FileSystemServiceFactory = .init()

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
    logger: (any LoggingInterfaces.LoggingProtocol)?=nil
  ) -> any FileSystemServiceProtocol {
    let fileManager=FileManager.default

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
    logger: (any LoggingInterfaces.LoggingProtocol)?=nil
  ) -> any FileSystemServiceProtocol {
    let fileManager=FileManager.default

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
    logger: (any LoggingInterfaces.LoggingProtocol)?=nil
  ) async -> any FileSystemServiceProtocol {
    // Create the file path service
    let filePathService = await FilePathServiceFactory.createDefault()
    
    // Create the secure file system service
    return FileSystemServiceSecure(
      filePathService: filePathService,
      logger: logger
    )
  }

  /**
   Creates a custom file system service instance with full configuration control.

   This method is Swift 6 compatible and uses the default FileManager to avoid
   data race risks with sendability.

   - Parameters:
      - operationQueueQoS: The QoS class for background operations
      - logger: Optional logger for operation tracking
   - Returns: An implementation of FileSystemServiceProtocol
   */
  public func createCustomService(
    operationQueueQoS: QualityOfService = .utility,
    logger: (any LoggingInterfaces.LoggingProtocol)?=nil
  ) -> any FileSystemServiceProtocol {
    // Use default FileManager to avoid Swift 6 warnings
    let fileManager=FileManager.default

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
@preconcurrency
private actor NullLogger: LoggingInterfaces.LoggingProtocol {
  // Add loggingActor property required by LoggingProtocol
  nonisolated let loggingActor: LoggingInterfaces.LoggingActor = .init(destinations: [])

  // Implement the required log method from CoreLoggingProtocol
  func log(_: LoggingInterfaces.LogLevel, _: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation for no-op logger
  }

  // Convenience methods with empty implementations
  func trace(_: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }

  func debug(_: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }

  func info(_: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }

  func warning(_: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }

  func error(_: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }

  func critical(_: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }
}
