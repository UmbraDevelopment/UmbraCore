import FileSystemInterfaces
import Foundation
import LoggingInterfaces
import LoggingServices

/**
 # Secure File System Service Actor

 A secure implementation of the FileSystemServiceProtocol that provides enhanced
 security guarantees for file operations. This actor ensures that all file operations
 are performed securely and respects sandboxing requirements.

 ## Security Features

 - Enforces sandboxing of file operations to a specified root directory
 - Ensures proper file permissions and attributes
 - Guards against path traversal attacks
 - Performs secure deletion of sensitive files

 ## Alpha Dot Five Architecture

 This implementation follows the Alpha Dot Five architecture principles:
 - Uses actors for thread safety
 - Provides comprehensive error handling
 - Follows British spelling in documentation and public-facing elements.
 */
public actor SecureFileSystemServiceActor: FileSystemServiceProtocol {
  /// The file path service for path operations
  private let filePathService: FilePathServiceProtocol

  /// The read operations component
  private let readOperations: FileSystemReadActor

  /// The write operations component
  private let writeOperations: FileSystemWriteActor

  /// The metadata operations component
  private let metadataOperations: FileMetadataActor

  /// The secure operations component
  public nonisolated var secureOperations: SecureFileOperationsProtocol {
    secureOperationsActor
  }

  /// The secure operations actor
  private let secureOperationsActor: SecureFileOperationsActor

  /// The logger for this service
  private let logger: LoggingServiceProtocol

  /// The root directory for sandboxed operations
  private let rootDirectory: String?

  /**
   Initialises a new secure file system service.

   - Parameters:
      - logger: The logger to use for logging operations.
      - rootDirectory: Optional root directory for sandboxed operations.
   */
  public init(
    logger: LoggingServiceProtocol,
    rootDirectory: String?=nil
  ) {
    self.logger=logger
    self.rootDirectory=rootDirectory
    filePathService=FilePathService()

    readOperations=FileSystemReadActor(
      logger: logger,
      rootDirectory: rootDirectory
    )

    writeOperations=FileSystemWriteActor(
      logger: logger,
      rootDirectory: rootDirectory
    )

    metadataOperations=FileMetadataActor(
      logger: logger,
      rootDirectory: rootDirectory
    )

    secureOperationsActor=SecureFileOperationsActor(
      logger: logger,
      rootDirectory: rootDirectory
    )
  }

  // MARK: - FileSystemServiceProtocol

  /**
   Gets the temporary directory path appropriate for this file system service.

   - Returns: The path to the temporary directory.
   */
  public func temporaryDirectoryPath() async -> String {
    let tempDir=NSTemporaryDirectory()
    if let rootDirectory {
      return await filePathService.join(rootDirectory, tempDir)
    }
    return tempDir
  }

  /**
   Creates a unique file name in the specified directory.

   - Parameters:
      - directory: The directory in which to create the unique name.
      - prefix: Optional prefix for the file name.
      - extension: Optional file extension.
   - Returns: A unique file path.
   */
  public func createUniqueFilename(
    in directory: String,
    prefix: String?,
    extension: String?
  ) async -> String {
    let uuid=UUID().uuidString
    let filename=[prefix, uuid].compactMap { $0 }.joined(separator: "-")
    let filenameWithExt=`extension` != nil ? "\(filename).\(`extension`!)" : filename
    return await filePathService.join(directory, filenameWithExt)
  }

  /**
   Normalises a file path according to system rules.

   - Parameter path: The path to normalise.
   - Returns: The normalised path.
   */
  public func normalisePath(_ path: String) async -> String {
    (path as NSString).standardizingPath
  }

  /**
   Creates a sandboxed file system service instance that restricts
   all operations to within the specified root directory.

   - Parameter rootDirectory: The directory to restrict operations to.
   - Returns: A sandboxed file system service.
   */
  public static func createSandboxed(rootDirectory: String) -> Self {
    // Create a privacy-aware logger for the sandboxed service
    let logger=LoggingServiceFactory.shared.createPrivacyAwareLogger(
      subsystem: "com.umbra.filesystemservices",
      category: "SecureFileSystemService"
    )
    return SecureFileSystemServiceActor(logger: logger, rootDirectory: rootDirectory)
  }

  // MARK: - FileReadOperationsProtocol

  public func readFile(at path: String) async throws -> Data {
    try await readOperations.readFile(at: path)
  }

  public func readFileAsString(at path: String, encoding: String.Encoding) async throws -> String {
    try await readOperations.readFileAsString(at: path, encoding: encoding)
  }

  public func fileExists(at path: String) async -> Bool {
    await readOperations.fileExists(at: path)
  }

  public func listDirectory(at path: String) async throws -> [String] {
    try await readOperations.listDirectory(at: path)
  }

  public func listDirectoryRecursively(at path: String) async throws -> [String] {
    try await readOperations.listDirectoryRecursively(at: path)
  }

  // MARK: - FileWriteOperationsProtocol

  public func writeFile(_ data: Data, to path: String, options: FileWriteOptions) async throws {
    try await writeOperations.writeFile(data, to: path, options: options)
  }

  public func writeString(
    _ string: String,
    to path: String,
    encoding: String.Encoding,
    options: FileWriteOptions
  ) async throws {
    try await writeOperations.writeString(string, to: path, encoding: encoding, options: options)
  }

  public func createFile(at path: String, options: FileCreationOptions) async throws {
    try await writeOperations.createFile(at: path, options: options)
  }

  public func createDirectory(at path: String, options: DirectoryCreationOptions) async throws {
    try await writeOperations.createDirectory(at: path, options: options)
  }

  public func copyItem(
    at sourcePath: String,
    to destinationPath: String,
    options: FileCopyOptions
  ) async throws {
    try await writeOperations.copyItem(at: sourcePath, to: destinationPath, options: options)
  }

  public func moveItem(
    at sourcePath: String,
    to destinationPath: String,
    options: FileCopyOptions
  ) async throws {
    try await writeOperations.moveItem(at: sourcePath, to: destinationPath, options: options)
  }

  public func removeItem(at path: String) async throws {
    try await writeOperations.removeItem(at: path)
  }

  public func removeDirectory(at path: String, includeContents: Bool) async throws {
    try await writeOperations.removeDirectory(at: path, includeContents: includeContents)
  }

  // MARK: - FileMetadataProtocol

  public func getAttributes(at path: String) async throws -> FileAttributes {
    try await metadataOperations.getAttributes(at: path)
  }

  public func setAttributes(_ attributes: FileAttributes, at path: String) async throws {
    try await metadataOperations.setAttributes(attributes, at: path)
  }

  public func getFileSize(at path: String) async throws -> UInt64 {
    try await metadataOperations.getFileSize(at: path)
  }

  public func getCreationDate(at path: String) async throws -> Date {
    try await metadataOperations.getCreationDate(at: path)
  }

  public func getModificationDate(at path: String) async throws -> Date {
    try await metadataOperations.getModificationDate(at: path)
  }

  public func getExtendedAttribute(
    withName name: String,
    fromItemAtPath path: String
  ) async throws -> Data {
    try await metadataOperations.getExtendedAttribute(withName: name, fromItemAtPath: path)
  }

  public func setExtendedAttribute(
    _ data: Data,
    withName name: String,
    onItemAtPath path: String
  ) async throws {
    try await metadataOperations.setExtendedAttribute(data, withName: name, onItemAtPath: path)
  }

  public func listExtendedAttributes(atPath path: String) async throws -> [String] {
    try await metadataOperations.listExtendedAttributes(atPath: path)
  }

  public func removeExtendedAttribute(
    withName name: String,
    fromItemAtPath path: String
  ) async throws {
    try await metadataOperations.removeExtendedAttribute(withName: name, fromItemAtPath: path)
  }
}
