import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import UmbraLogging

/**
 # File System Service Factory Implementation

 Provides concrete implementations of the FileSystemServiceFactoryProtocol.
 This factory encapsulates the creation of file system services with different
 configuration for different use cases.
 */
public struct FileSystemServiceFactoryImpl: FileSystemInterfaces.FileSystemServiceFactoryProtocol {

  /// The logger instance for recording factory operations
  private let logger: any LoggingInterfaces.LoggingProtocol

  /**
   Initialises a new file system service factory.

   - Parameter logger: Optional logger for recording factory operations
   */
  public init(logger: (any LoggingInterfaces.LoggingProtocol)?=nil) {
    // Create a NullLogger if no logger is provided
    self.logger=logger ?? NullLogger()
  }
}

// MARK: - Factory Methods - Default Service

extension FileSystemServiceFactoryImpl {
  /**
   Creates a default file system service with standard settings.

   - Returns: A file system service with standard settings
   */
  public func createDefault() -> any FileSystemInterfaces.FileSystemServiceProtocol {
    FileSystemServiceImpl(
      fileManager: FileManager.default,
      operationQueueQoS: .utility,
      defaultBufferSize: 65536,
      securityOptions: SecurityOptions(
        preservePermissions: true,
        enforceSandboxing: true,
        allowSymlinks: true
      ),
      runInBackground: false,
      logger: logger
    )
  }
}

// MARK: - Factory Methods - Secure Service

extension FileSystemServiceFactoryImpl {
  /**
   Creates a security-focused file system service.

   - Parameters:
      - preservePermissions: Whether to preserve permissions during copy/move operations
      - enforceSandboxing: Whether to restrict operations to specific directories
      - allowSymlinks: Whether to allow operations on symbolic links
   - Returns: A file system service with enhanced security settings
   */
  public func createSecureService(
    preservePermissions: Bool,
    enforceSandboxing: Bool,
    allowSymlinks: Bool
  ) -> any FileSystemInterfaces.FileSystemServiceProtocol {
    FileSystemServiceImpl(
      fileManager: FileManager.default,
      operationQueueQoS: .utility,
      defaultBufferSize: 65536,
      securityOptions: SecurityOptions(
        preservePermissions: preservePermissions,
        enforceSandboxing: enforceSandboxing,
        allowSymlinks: allowSymlinks
      ),
      runInBackground: false,
      logger: logger
    )
  }
}

// MARK: - Factory Methods - Performance Optimised Service

extension FileSystemServiceFactoryImpl {
  /**
   Creates a performance-optimised file system service.

   - Parameters:
      - bufferSize: Size of the buffer for file operations
      - operationPriority: Priority of file operations for scheduling
      - backgroundOperations: Whether to run operations in the background
   - Returns: A file system service optimised for performance
   */
  public func createPerformanceOptimisedService(
    bufferSize: Int,
    operationPriority: FSOperationPriority,
    backgroundOperations: Bool
  ) -> any FileSystemInterfaces.FileSystemServiceProtocol {
    // Map the operation priority to the appropriate QoS class
    let qos: DispatchQoS.QoSClass

      // Use a standard switch case with enum values
      = switch operationPriority
    {
      case .background:
        .background
      case .normal:
        .utility
      case .elevated:
        .userInitiated
      case .critical:
        .userInteractive
    }

    return FileSystemServiceImpl(
      fileManager: FileManager.default,
      operationQueueQoS: qos,
      defaultBufferSize: bufferSize,
      securityOptions: SecurityOptions(
        preservePermissions: true,
        enforceSandboxing: true,
        allowSymlinks: true
      ),
      runInBackground: backgroundOperations,
      logger: logger
    )
  }
}

// MARK: - Helper Types

/// A no-op logger implementation that conforms to LoggingProtocol
private struct NullLogger: LoggingInterfaces.LoggingProtocol {
  func debug(_: String, metadata _: LogMetadataDTOCollection?) async {
    // No-op implementation
  }

  func info(_: String, metadata _: LogMetadataDTOCollection?) async {
    // No-op implementation
  }

  func warning(_: String, metadata _: LogMetadataDTOCollection?) async {
    // No-op implementation
  }

  func error(_: String, metadata _: LogMetadataDTOCollection?) async {
    // No-op implementation
  }

  func critical(_: String, metadata _: LogMetadataDTOCollection?) async {
    // No-op implementation
  }
}
