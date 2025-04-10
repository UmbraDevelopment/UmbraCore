import FileSystemInterfaces
import Foundation
import LoggingInterfaces

/**
 # Secure File Operations Factory

 A factory class for creating SecureFileOperationsProtocol instances.

 This factory provides a clean way to instantiate secure file operations
 implementations with proper dependencies.

 ## Alpha Dot Five Architecture

 This factory follows the Alpha Dot Five architecture principles:
 - Provides dependency injection
 - Supports creation of both standard and testing instances
 - Follows British spelling in documentation
 */
public enum SecureFileOperationsFactory {
  /**
   Creates a standard implementation of SecureFileOperationsProtocol.

   - Parameters:
      - fileManager: Optional custom file manager to use
      - logger: Optional logger for recording operations
   - Returns: A new SecureFileOperationsProtocol instance
   */
  public static func createStandardOperations(
    fileManager: FileManager = .default,
    logger: (any LoggingProtocol)?=nil
  ) -> any SecureFileOperationsProtocol {
    SecureFileOperationsImpl(
      fileManager: fileManager,
      logger: logger
    )
  }

  /**
   Creates a test-friendly implementation of SecureFileOperationsProtocol.

   This method can be used in tests to create an implementation with
   a mock file manager and logger.

   - Parameters:
      - fileManager: The test file manager to use
      - logger: The test logger to use
   - Returns: A new SecureFileOperationsProtocol instance for testing
   */
  public static func createTestOperations(
    fileManager: FileManager,
    logger: any LoggingProtocol
  ) -> any SecureFileOperationsProtocol {
    SecureFileOperationsImpl(
      fileManager: fileManager,
      logger: logger
    )
  }
}
