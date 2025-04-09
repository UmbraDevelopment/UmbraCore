/**
 # File System Service Factory Protocol

 Defines a factory for creating file system service instances with various configurations.

 ## Purpose

 This protocol provides a standard way to instantiate file system services with different
 configurations and behaviours. By using this factory, applications can:

 - Create file system services with appropriate security and performance settings
 - Inject custom configuration into services without exposing implementation details
 - Maintain a consistent interface for service creation across the application

 ## Usage Patterns

 The factory supports several common patterns for service creation:

 - Default services with standard configuration
 - Services with custom security profiles for different access patterns
 - Services with performance characteristics optimised for specific workloads
 */
public protocol FileSystemServiceFactoryProtocol: Sendable {
  /**
   Creates a default file system service.

   This method returns a standard file system service with balanced security
   and performance characteristics suitable for most operations.

   - Returns: A file system service instance conforming to FileSystemServiceProtocol
   */
  func createDefault() -> any FileSystemServiceProtocol

  /**
   Creates a file system service with custom security settings.

   This method allows customisation of security-related settings like sandboxing,
   ownership preservation, and permission handling.

   - Parameters:
      - preservePermissions: Whether to preserve permissions during copy/move operations
      - enforceSandboxing: Whether to restrict operations to specific directories
      - allowSymlinks: Whether to allow operations on symbolic links
   - Returns: A file system service instance with the specified security settings
   */
  func createSecureService(
    preservePermissions: Bool,
    enforceSandboxing: Bool,
    allowSymlinks: Bool
  ) -> any FileSystemServiceProtocol

  /**
   Creates a file system service with performance characteristics optimised for specific workloads.

   This method allows customisation of performance-related settings like buffer sizes,
   operation queue priority, and background task handling.

   - Parameters:
      - bufferSize: Size of the buffer to use for streaming operations
      - operationPriority: Priority for file system operations
      - backgroundOperations: Whether operations should run in the background
   - Returns: A file system service instance with the specified performance characteristics
   */
  func createPerformanceOptimisedService(
    bufferSize: Int,
    operationPriority: FSOperationPriority,
    backgroundOperations: Bool
  ) -> any FileSystemServiceProtocol
}

/**
 Defines the priority levels for file system operations.

 These priorities determine how file system operations are scheduled and
 executed relative to other system activities.
 */
public enum FSOperationPriority: String, Sendable {
  /// Lowest priority, suitable for non-critical background operations
  case background

  /// Standard priority, suitable for normal operations
  case normal

  /// Higher priority for time-sensitive operations
  case elevated

  /// Highest priority for critical operations
  case critical
}
