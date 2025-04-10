import CoreDTOs
import Foundation

/**
 # Secure File Operations Protocol

 Defines operations for working with files in a secure manner, including
 encryption, secure deletion, and permission management.

 This protocol centralises all secure file operations to ensure consistency
 across different file system service implementations.

 ## Alpha Dot Five Architecture

 This protocol conforms to the Alpha Dot Five architecture principles:
 - Focuses on a single responsibility (secure operations)
 - Uses asynchronous APIs for thread safety
 - Provides comprehensive error handling
 - Implements strong privacy protections
 */
public protocol SecureFileOperationsProtocol: Actor, Sendable {
  /**
   Creates a secure temporary file with the specified prefix.

   - Parameters:
      - prefix: Optional prefix for the temporary file name.
      - options: Optional file creation options.
   - Returns: The path to the secure temporary file.
   - Throws: FileSystemError if the temporary file cannot be created.
   */
  func createSecureTemporaryFile(prefix: String?, options: FileCreationOptions?) async throws
    -> FilePathDTO

  /**
   Creates a secure temporary directory with the specified prefix.

   - Parameters:
      - prefix: Optional prefix for the temporary directory name.
      - options: Optional directory creation options.
   - Returns: The path to the secure temporary directory.
   - Throws: FileSystemError if the temporary directory cannot be created.
   */
  func createSecureTemporaryDirectory(
    prefix: String?,
    options: DirectoryCreationOptions?
  ) async throws -> FilePathDTO

  /**
   Securely writes data to a file with encryption.

   - Parameters:
      - data: The data to write.
      - path: The path where the data should be written.
      - options: Optional secure write options.
   - Throws: FileSystemError if the secure write operation fails.
   */
  func secureWriteFile(
    data: Data,
    to path: FilePathDTO,
    options: SecureFileWriteOptions?
  ) async throws

  /**
   Securely reads data from a file with decryption.

   - Parameters:
      - path: The path to the file to read.
      - options: Optional secure read options.
   - Returns: The decrypted data.
   - Throws: FileSystemError if the secure read operation fails.
   */
  func secureReadFile(at path: FilePathDTO, options: SecureFileReadOptions?) async throws -> Data

  /**
   Securely deletes a file or directory to prevent recovery.

   - Parameters:
      - path: The path to the file or directory to delete.
      - options: Optional secure deletion options.
   - Throws: FileSystemError if the secure deletion fails.
   */
  func secureDelete(at path: FilePathDTO, options: SecureDeletionOptions?) async throws

  /**
   Sets secure permissions on a file or directory.

   - Parameters:
      - permissions: The secure permissions to set.
      - path: The path to the file or directory.
   - Throws: FileSystemError if the permissions cannot be set.
   */
  func setSecurePermissions(_ permissions: SecureFilePermissions, at path: FilePathDTO) async throws

  /**
   Verifies the integrity of a file using a cryptographic signature.

   - Parameters:
      - path: The path to the file to verify.
      - signature: The cryptographic signature to check against.
   - Returns: A boolean indicating whether the file's integrity is verified.
   - Throws: FileSystemError if the verification operation fails.
   */
  func verifyFileIntegrity(at path: FilePathDTO, against signature: Data) async throws -> Bool
}
