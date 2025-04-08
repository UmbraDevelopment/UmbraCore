import FileSystemInterfaces
import FileSystemTypes
import Foundation

/**
 # FilePathServiceFactory

 Factory for creating FilePathServiceProtocol implementations.
 This factory follows the Alpha Dot Five architecture pattern
 of providing asynchronous factory methods that return actor-based
 implementations.

 ## Usage Examples

 ```swift
 // Create a default implementation
 let filePathService = await FilePathServiceFactory.createDefault()

 // Create a service with a custom bundle identifier
 let customService = await FilePathServiceFactory.createWithBundleIdentifier("com.umbra.customapp")
 ```
 */
public enum FilePathServiceFactory {
  /**
   Creates a default file path service implementation.

   - Returns: A FilePathServiceProtocol implementation
   */
  public static func createDefault() async -> FilePathServiceProtocol {
    FilePathServiceImpl()
  }

  /**
   Creates a file path service with the specified bundle identifier.

   - Parameter bundleIdentifier: The bundle identifier to use
   - Returns: A FilePathServiceProtocol implementation
   */
  public static func createWithBundleIdentifier(
    _ bundleIdentifier: String
  ) async -> FilePathServiceProtocol {
    FilePathServiceImpl(bundleIdentifier: bundleIdentifier)
  }

  /**
   Creates a file path service with a custom file manager.

   - Parameter fileManager: The file manager to use
   - Returns: A FilePathServiceProtocol implementation
   */
  public static func createWithFileManager(
    _ fileManager: FileManager
  ) async -> FilePathServiceProtocol {
    FilePathServiceImpl(fileManager: fileManager)
  }

  /**
   Creates a file path service for testing purposes.

   This factory method creates a service with a new FileManager instance
   that is isolated from the default shared instance, making it suitable
   for use in unit tests.

   - Returns: A FilePathServiceProtocol implementation suitable for testing
   */
  public static func createForTesting() async -> FilePathServiceProtocol {
    let testFileManager=FileManager()
    return FilePathServiceImpl(
      fileManager: testFileManager,
      bundleIdentifier: "com.umbra.testing"
    )
  }
}
