import FileSystemInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # File System Service Actor

 The main file system service implementation that composes specialized actors
 into a cohesive service. This implementation follows the actor-based concurrency
 model to ensure thread safety in all file operations.

 Each responsibility is delegated to a specialized actor:
 - Reading operations: FileSystemReadActor
 - Writing operations: FileSystemWriteActor
 - Metadata operations: FileMetadataActor
 - Secure operations: SecureFileOperationsActor

 ## Alpha Dot Five Architecture

 This implementation follows the Alpha Dot Five architecture principles:
 1. Using proper British spelling in documentation
 2. Implementing actor-based concurrency for thread safety
 3. Providing comprehensive privacy-aware logging
 4. Using composition to maintain separation of concerns
 5. Implementing dependency injection for testability
 6. Supporting sandboxed operation for enhanced security
 */
public actor FileSystemServiceActor: FileSystemServiceProtocol {
  /// Logger for operation tracking
  private let logger: LoggingProtocol

  /// Actor for read operations
  private let readActor: FileSystemReadActor

  /// Actor for write operations
  private let writeActor: FileSystemWriteActor

  /// Actor for metadata operations
  private let metadataActor: FileMetadataActor

  /// Actor for secure operations
  private let secureActor: SecureFileOperationsActor

  /// File manager instance
  private let fileManager: FileManager

  /// Optional root directory for sandboxed operation
  private let rootDirectory: String?

  /// The secure operations component of this service
  public var secureOperations: SecureFileOperationsProtocol {
    secureActor
  }

  /**
   Initialises a new FileSystemServiceActor with the specified components.

   - Parameters:
      - logger: The logger to use for operation tracking
      - readActor: The actor for read operations
      - writeActor: The actor for write operations
      - metadataActor: The actor for metadata operations
      - secureActor: The actor for secure operations
      - rootDirectory: Optional root directory to restrict operations to
   */
  public init(
    logger: LoggingProtocol,
    readActor: FileSystemReadActor,
    writeActor: FileSystemWriteActor,
    metadataActor: FileMetadataActor,
    secureActor: SecureFileOperationsActor,
    rootDirectory: String?=nil
  ) {
    self.logger=logger
    self.readActor=readActor
    self.writeActor=writeActor
    self.metadataActor=metadataActor
    self.secureActor=secureActor
    fileManager=FileManager.default
    self.rootDirectory=rootDirectory
  }

  /**
   Convenience initialiser that creates all required actors.

   - Parameters:
      - logger: The logger to use for operation tracking
      - rootDirectory: Optional root directory to restrict operations to
   */
  public convenience init(logger: LoggingProtocol, rootDirectory: String?=nil) {
    let readActor=FileSystemReadActor(logger: logger, rootDirectory: rootDirectory)
    let writeActor=FileSystemWriteActor(logger: logger, rootDirectory: rootDirectory)
    let metadataActor=FileMetadataActor(logger: logger, rootDirectory: rootDirectory)
    let secureActor=SecureFileOperationsActor(
      logger: logger,
      fileReadActor: readActor,
      fileWriteActor: writeActor,
      rootDirectory: rootDirectory
    )

    self.init(
      logger: logger,
      readActor: readActor,
      writeActor: writeActor,
      metadataActor: metadataActor,
      secureActor: secureActor,
      rootDirectory: rootDirectory
    )
  }

  /**
   Creates a sandboxed instance of the file system service that restricts
   all operations to within the specified root directory.

   - Parameters:
      - logger: The logger to use for operation tracking
      - rootDirectory: The directory to restrict operations to
   - Returns: A sandboxed file system service
   */
  public static func createSandboxed(
    logger: LoggingProtocol,
    rootDirectory: String
  ) -> FileSystemServiceActor {
    // Create actors with rootDirectory for sandboxing
    FileSystemServiceActor(logger: logger, rootDirectory: rootDirectory)
  }

  // MARK: - FileReadOperationsProtocol Delegation

  public func readFile(at path: String) async throws -> Data {
    try await readActor.readFile(at: path)
  }

  public func readFileAsString(at path: String, encoding: String.Encoding) async throws -> String {
    try await readActor.readFileAsString(at: path, encoding: encoding)
  }

  public func fileExists(at path: String) async -> Bool {
    await readActor.fileExists(at: path)
  }

  public func listDirectory(at path: String) async throws -> [String] {
    try await readActor.listDirectory(at: path)
  }

  public func listDirectoryRecursively(at path: String) async throws -> [String] {
    try await readActor.listDirectoryRecursively(at: path)
  }

  // MARK: - FileWriteOperationsProtocol Delegation

  public func createFile(at path: String, options: FileCreationOptions?) async throws -> String {
    try await writeActor.createFile(at: path, options: options)
  }

  public func writeFile(data: Data, to path: String, options: FileWriteOptions?) async throws {
    try await writeActor.writeFile(data: data, to: path, options: options)
  }

  public func writeString(
    _ string: String,
    to path: String,
    encoding: String.Encoding,
    options: FileWriteOptions?
  ) async throws {
    try await writeActor.writeString(string, to: path, encoding: encoding, options: options)
  }

  public func createDirectory(
    at path: String,
    options: DirectoryCreationOptions?
  ) async throws -> String {
    try await writeActor.createDirectory(at: path, options: options)
  }

  public func delete(at path: String) async throws {
    try await writeActor.delete(at: path)
  }

  public func move(
    from sourcePath: String,
    to destinationPath: String,
    options: FileMoveOptions?
  ) async throws {
    try await writeActor.move(from: sourcePath, to: destinationPath, options: options)
  }

  public func copy(
    from sourcePath: String,
    to destinationPath: String,
    options: FileCopyOptions?
  ) async throws {
    try await writeActor.copy(from: sourcePath, to: destinationPath, options: options)
  }

  // MARK: - FileMetadataProtocol Delegation

  public func getAttributes(at path: String) async throws -> FileAttributes {
    try await metadataActor.getAttributes(at: path)
  }

  public func setAttributes(_ attributes: FileAttributes, at path: String) async throws {
    try await metadataActor.setAttributes(attributes, at: path)
  }

  public func getFileSize(at path: String) async throws -> UInt64 {
    try await metadataActor.getFileSize(at: path)
  }

  public func getCreationDate(at path: String) async throws -> Date {
    try await metadataActor.getCreationDate(at: path)
  }

  public func getModificationDate(at path: String) async throws -> Date {
    try await metadataActor.getModificationDate(at: path)
  }

  public func getExtendedAttribute(
    withName name: String,
    fromItemAtPath path: String
  ) async throws -> Data {
    try await metadataActor.getExtendedAttribute(withName: name, fromItemAtPath: path)
  }

  public func setExtendedAttribute(
    _ data: Data,
    withName name: String,
    onItemAtPath path: String
  ) async throws {
    try await metadataActor.setExtendedAttribute(data, withName: name, onItemAtPath: path)
  }

  public func listExtendedAttributes(atPath path: String) async throws -> [String] {
    try await metadataActor.listExtendedAttributes(atPath: path)
  }

  public func removeExtendedAttribute(
    withName name: String,
    fromItemAtPath path: String
  ) async throws {
    try await metadataActor.removeExtendedAttribute(withName: name, fromItemAtPath: path)
  }

  // MARK: - Additional FileSystemServiceProtocol Methods

  /**
   Gets the temporary directory path appropriate for this file system service.

   - Returns: The path to the temporary directory.
   */
  public func temporaryDirectoryPath() async -> String {
    let context=FileSystemLogContext(operation: "temporaryDirectoryPath")
    await logger.debug("Getting temporary directory path", context: context)

    let tempPath=NSTemporaryDirectory()

    await logger.debug(
      "Retrieved temporary directory path",
      context: context
        .withStatus("success")
        .withPath(tempPath)
    )

    return tempPath
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
    let context=FileSystemLogContext(
      operation: "createUniqueFilename",
      path: directory
    )

    let metadata=context.metadata
      .withPublic(key: "prefix", value: prefix ?? "none")
      .withPublic(key: "extension", value: `extension` ?? "none")
    let enhancedContext=context.withUpdatedMetadata(metadata)

    await logger.debug("Creating unique filename", context: enhancedContext)

    // Generate a unique name using UUID
    let uuid=UUID().uuidString
    var filename=prefix != nil ? "\(prefix!)-\(uuid)" : uuid

    // Add extension if provided
    if let ext=`extension` {
      filename=filename + "." + ext
    }

    // Create full path
    let fullPath=(directory as NSString).appendingPathComponent(filename)

    await logger.debug(
      "Created unique filename",
      context: enhancedContext
        .withStatus("success")
        .withPath(fullPath)
    )

    return fullPath
  }

  /**
   Normalises a file path according to system rules.

   - Parameter path: The path to normalise.
   - Returns: The normalised path.
   */
  public func normalisePath(_ path: String) async -> String {
    let context=FileSystemLogContext(
      operation: "normalisePath",
      path: path
    )

    await logger.debug("Normalising path", context: context)

    let url=URL(fileURLWithPath: path)
    let normalizedPath=url.standardized.path

    await logger.debug(
      "Normalised path",
      context: context
        .withStatus("success")
        .withPath(normalizedPath)
    )

    return normalizedPath
  }
}
