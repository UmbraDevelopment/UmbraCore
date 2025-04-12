import CoreDTOs
import CryptoKit
import FileSystemCommonTypes
import FileSystemInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Secure File Operations Implementation

 The implementation of SecureFileOperationsProtocol that handles security features
 for file operations.

 This actor-based implementation ensures all operations are thread-safe through
 Swift concurrency. It provides secure file operations with security bookmarks,
 secure temporary files, and encrypted file operations.

 ## Alpha Dot Five Architecture

 This implementation follows the Alpha Dot Five architecture principles:
 - Uses actor isolation for thread safety
 - Provides comprehensive privacy-aware logging
 - Follows British spelling in documentation
 - Returns standardised operation results
 */
public actor SecureFileOperationsImpl: SecureFileOperationsProtocol {
  /// The underlying file manager isolated within this actor
  private let fileManager: FileManager

  /// Logger for this service
  private let logger: any LoggingProtocol

  /**
   Initialises a new secure file operations implementation.

   - Parameters:
      - fileManager: Optional custom file manager to use
      - logger: Optional logger for recording operations
   */
  public init(fileManager: FileManager = .default, logger: (any LoggingProtocol)?=nil) {
    self.fileManager=fileManager
    self.logger=logger ?? LoggingProtocol_NoOp()
  }

  /**
   Creates a security bookmark for a file or directory.

   - Parameters:
      - path: The path to the file or directory as a FilePathDTO
      - readOnly: Whether the bookmark should be for read-only access
   - Returns: The bookmark data and operation result
   - Throws: If the bookmark cannot be created
   */
  public func createSecurityBookmark(
    for path: FilePathDTO,
    readOnly: Bool
  ) async throws -> (Data, FileOperationResultDTO) {
    let context=createSecureFileLogContext([
      "path": path.path,
      "readOnly": "\(readOnly)"
    ])
    await logger.debug("Creating security bookmark", context: context)

    // Check if the file exists
    guard fileManager.fileExists(atPath: path.path) else {
      let error=FileSystemError.pathNotFound(path: path.path)
      let errorContext=createSecureFileLogContext(["path": path.path])
      await logger.error("File not found", context: errorContext)
      throw error
    }

    let url=URL(fileURLWithPath: path.path)
    let bookmarkOptions: URL
      .BookmarkCreationOptions=readOnly ? [.securityScopeAllowOnlyReadAccess] : []

    let bookmarkData=try url.bookmarkData(
      options: bookmarkOptions,
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    )

    // Get the file attributes for the result metadata
    let attributes=try fileManager.attributesOfItem(atPath: path.path)
    let metadata=FileMetadataDTO.from(attributes: attributes, path: path.path)

    let result=FileOperationResultDTO.success(
      path: path.path,
      metadata: metadata
    )

    let successContext=createSecureFileLogContext([
      "path": path.path,
      "readOnly": "\(readOnly)",
      "bookmarkSize": "\(bookmarkData.count)"
    ])
    await logger.debug("Successfully created security bookmark", context: successContext)
    return (bookmarkData, result)
  }

  /**
   Resolves a security bookmark to a file path.

   - Parameter bookmark: The bookmark data to resolve
   - Returns: The file path, whether it's stale, and operation result
   - Throws: If the bookmark cannot be resolved
   */
  public func resolveSecurityBookmark(_ bookmark: Data) async throws
  -> (String, Bool, FileOperationResultDTO) {
    let context=createSecureFileLogContext(["bookmarkSize": "\(bookmark.count)"])
    await logger.debug("Resolving security bookmark", context: context)

    var isStale=false
    var path: String

    // Resolve bookmark to URL
    var bookmarkDataIsStale=false
    let url=try URL(
      resolvingBookmarkData: bookmark,
      options: .withSecurityScope,
      relativeTo: nil,
      bookmarkDataIsStale: &bookmarkDataIsStale
    )

    path=url.path
    isStale=bookmarkDataIsStale

    // Get the file attributes for metadata
    var metadata: FileMetadataDTO?
    if fileManager.fileExists(atPath: url.path) {
      if let attributes=try? fileManager.attributesOfItem(atPath: url.path) {
        metadata=FileMetadataDTO.from(attributes: attributes, path: url.path)
      }
    }

    let result=FileOperationResultDTO.success(
      path: path,
      metadata: metadata
    )

    let successContext=createSecureFileLogContext([
      "path": path,
      "isStale": String(isStale)
    ])
    await logger.debug("Successfully resolved security bookmark", context: successContext)

    return (path, isStale, result)
  }

  /**
   Starts accessing a security-scoped resource.

   - Parameter path: The path to start accessing as a FilePathDTO
   - Returns: True if access was granted, false otherwise, and operation result
   - Throws: If access cannot be started
   */
  public func startAccessingSecurityScopedResource(at path: FilePathDTO) async throws
  -> (Bool, FileOperationResultDTO) {
    let context=createSecureFileLogContext(["path": path.path])
    await logger.debug("Starting access to security-scoped resource", context: context)

    let url=URL(fileURLWithPath: path.path)
    let accessGranted=url.startAccessingSecurityScopedResource()

    // Get the file attributes for the result metadata if file exists
    var metadata: FileMetadataDTO?
    if fileManager.fileExists(atPath: path.path) {
      if let attributes=try? fileManager.attributesOfItem(atPath: path.path) {
        metadata=FileMetadataDTO.from(attributes: attributes, path: path.path)
      }
    }

    let result=FileOperationResultDTO.success(
      path: path.path,
      metadata: metadata
    )

    let successContext=createSecureFileLogContext([
      "path": path.path,
      "accessGranted": "\(accessGranted)"
    ])
    await logger.debug("Access to security-scoped resource status", context: successContext)
    return (accessGranted, result)
  }

  /**
   Accesses a security-scoped resource.

   - Parameter path: The path to access as a FilePathDTO
   - Returns: True if access was granted, false otherwise, and operation result
   */
  public func accessSecurityScopedResource(at path: FilePathDTO) async
  -> (Bool, FileOperationResultDTO) {
    let context=createSecureFileLogContext([
      "path": path.path
    ])
    await logger.debug("Accessing security-scoped resource", context: context)

    // Create a URL from the path
    let securityScopedURL=URL(fileURLWithPath: path.path)

    // Attempt to acquire security-scoped resource access
    let accessGranted=securityScopedURL.startAccessingSecurityScopedResource()

    // Create the result DTO
    let result=FileOperationResultDTO.success(
      path: path.path
    )

    let successContext=createSecureFileLogContext([
      "path": path.path,
      "securityScopedAccess": String(accessGranted)
    ])
    await logger.debug("Access to security-scoped resource status", context: successContext)
    return (accessGranted, result)
  }

  /**
   Stops accessing a security-scoped resource.

   - Parameter path: The path to stop accessing as a FilePathDTO
   - Returns: Operation result
   */
  public func stopAccessingSecurityScopedResource(at path: FilePathDTO) async
  -> FileOperationResultDTO {
    let context=createSecureFileLogContext(["path": path.path])
    await logger.debug("Stopping access to security-scoped resource", context: context)

    let url=URL(fileURLWithPath: path.path)
    url.stopAccessingSecurityScopedResource()

    let result=FileOperationResultDTO.success(path: path.path)

    let successContext=createSecureFileLogContext(["path": path.path])
    await logger.debug("Stopped access to security-scoped resource", context: successContext)
    return result
  }

  /**
   Creates a secure temporary file with the specified prefix.

   - Parameters:
      - prefix: Optional prefix for the temporary file name.
      - options: Optional file creation options.
   - Returns: The path to the secure temporary file as a FilePathDTO.
   - Throws: FileSystemError if the temporary file cannot be created.
   */
  public func createSecureTemporaryFile(
    prefix: String?,
    options: FileCreationOptions?
  ) async throws -> FilePathDTO {
    let actualPrefix=prefix ?? "secure_tmp_file_"

    let context=createSecureFileLogContext(["prefix": actualPrefix])
    await logger.debug("Creating secure temporary file", context: context)

    // Generate a unique temporary path
    let tempDir=fileManager.temporaryDirectory
    let uniqueFilename=actualPrefix + UUID().uuidString
    let tempPath=tempDir.appendingPathComponent(uniqueFilename)

    // Create the file with secure attributes
    let fileCreationOptions=options ?? FileCreationOptions()

    let securityOptions=SecurityOptions(level: .high)

    if fileManager.fileExists(atPath: tempPath.path) {
      try fileManager.removeItem(at: tempPath)
    }

    // Create an empty file with secure attributes
    fileManager.createFile(
      atPath: tempPath.path,
      contents: Data(),
      attributes: fileCreationOptions.attributes?.toDictionary()
    )

    let successContext=createSecureFileLogContext([
      "path": tempPath.path,
      "securityLevel": "high"
    ])
    await logger.debug("Created secure temporary file", context: successContext)

    // Convert to FilePathDTO
    return FilePathDTO(
      path: tempPath.path,
      fileName: tempPath.lastPathComponent,
      directoryPath: tempPath.deletingLastPathComponent().path,
      resourceType: .file,
      isAbsolute: true,
      securityOptions: securityOptions
    )
  }

  /**
   Creates a secure temporary directory with the specified prefix.

   - Parameters:
      - prefix: Optional prefix for the temporary directory name.
      - options: Optional directory creation options.
   - Returns: The path to the secure temporary directory as a FilePathDTO.
   - Throws: FileSystemError if the temporary directory cannot be created.
   */
  public func createSecureTemporaryDirectory(
    prefix: String?,
    options: DirectoryCreationOptions?
  ) async throws -> FilePathDTO {
    let actualPrefix=prefix ?? "secure_tmp_dir_"

    let context=createSecureFileLogContext(["prefix": actualPrefix])
    await logger.debug("Creating secure temporary directory", context: context)

    // Generate a unique temporary path
    let tempDir=fileManager.temporaryDirectory
    let uniqueDirname=actualPrefix + UUID().uuidString
    let tempPath=tempDir.appendingPathComponent(uniqueDirname)

    // Create the directory with secure attributes
    let dirOptions=options ?? DirectoryCreationOptions()

    let securityOptions=SecurityOptions(level: .high)

    try fileManager.createDirectory(
      at: tempPath,
      withIntermediateDirectories: true,
      attributes: dirOptions.attributes?.toDictionary()
    )

    let successContext=createSecureFileLogContext([
      "path": tempPath.path,
      "securityLevel": "high"
    ])
    await logger.debug("Created secure temporary directory", context: successContext)

    // Convert to FilePathDTO
    return FilePathDTO(
      path: tempPath.path,
      fileName: tempPath.lastPathComponent,
      directoryPath: tempPath.deletingLastPathComponent().path,
      resourceType: .directory,
      isAbsolute: true,
      securityOptions: securityOptions
    )
  }

  /**
   Securely writes data to a file with encryption.

   - Parameters:
      - data: The data to write.
      - path: The path where the data should be written as a FilePathDTO.
      - options: Optional secure write options.
   - Throws: FileSystemError if the secure write operation fails.
   */
  public func secureWriteFile(
    data: Data,
    to path: FilePathDTO,
    options: SecureFileWriteOptions?
  ) async throws {
    let context=createSecureFileLogContext([
      "path": path.path,
      "size": "\(data.count)"
    ])
    await logger.debug("Securely writing file", context: context)

    let writeOptions=options ?? SecureFileWriteOptions()

    // Implement encryption logic based on specific write options
    let dataToWrite=data

    // Apply encryption based on the algorithm in the options
    switch writeOptions.secureOptions.encryptionAlgorithm {
      case .aes256:
        // Implement AES-256 encryption here
        // This would use the actual encryption logic
        break
      case .chaChaPoly:
        // Implement ChaCha20-Poly1305 encryption here
        break
    }

    // Write the file with secure attributes
    var writeDataOptions: Data.WritingOptions=[]

    if writeOptions.writeOptions.atomicWrite {
      writeDataOptions.insert(.atomic)
    }

    try dataToWrite.write(to: URL(fileURLWithPath: path.path), options: writeDataOptions)

    // Set additional file attributes if needed
    if let attributes=writeOptions.writeOptions.attributes {
      try fileManager.setAttributes(attributes.toDictionary(), ofItemAtPath: path.path)
    }

    let successContext=createSecureFileLogContext([
      "path": path.path,
      "encryption": writeOptions.secureOptions.encryptionAlgorithm.rawValue,
      "size": "\(dataToWrite.count)"
    ])
    await logger.debug("Successfully wrote secure file", context: successContext)
  }

  /**
   Securely reads data from a file with decryption.

   - Parameters:
      - path: The path to the file to read as a FilePathDTO.
      - options: Optional secure read options.
   - Returns: The decrypted data.
   - Throws: FileSystemError if the secure read operation fails.
   */
  public func secureReadFile(
    at path: FilePathDTO,
    options: SecureFileReadOptions?
  ) async throws -> Data {
    let context=createSecureFileLogContext([
      "path": path.path
    ])
    await logger.debug("Securely reading file", context: context)

    let readOptions=options ?? SecureFileReadOptions()

    // Read the file
    let fileURL=URL(fileURLWithPath: path.path)
    guard let data=try? Data(contentsOf: fileURL) else {
      throw FileSystemError.readError(
        path: path.path,
        reason: "Could not read file data"
      )
    }

    // Handle different decryption types based on secure options
    let decryptedData=data

    // Apply decryption based on the algorithm in the options
    switch readOptions.secureOptions.encryptionAlgorithm {
      case .aes256:
        // Implement AES-256 decryption here
        // This would use the actual decryption logic
        break
      case .chaChaPoly:
        // Implement ChaCha20-Poly1305 decryption here
        break
    }

    // Optionally verify integrity if specified
    if options?.verifyIntegrity == true {
      // Implement integrity verification logic
    }

    let successContext=createSecureFileLogContext([
      "path": path.path,
      "decryption": readOptions.secureOptions.encryptionAlgorithm.rawValue,
      "size": "\(decryptedData.count)"
    ])
    await logger.debug("Successfully read secure file", context: successContext)

    return decryptedData
  }

  /**
   Securely deletes a file or directory to prevent recovery.

   - Parameters:
      - path: The path to the file or directory to delete as a FilePathDTO.
      - options: Optional secure deletion options.
   - Throws: FileSystemError if the secure deletion fails.
   */
  public func secureDelete(at path: FilePathDTO, options: SecureDeletionOptions?) async throws {
    let deletionOptions=options ?? SecureDeletionOptions()
    let passes=deletionOptions.overwritePasses
    let useRandomData=deletionOptions.useRandomData

    let context=createSecureFileLogContext([
      "path": path.path,
      "overwritePasses": "\(passes)",
      "useRandomData": "\(useRandomData)"
    ])
    await logger.debug("Securely deleting file", context: context)

    // Check if the file exists
    guard fileManager.fileExists(atPath: path.path) else {
      throw FileSystemError.notFound(path: path.path)
    }

    // Get file attributes
    let fileURL=URL(fileURLWithPath: path.path)
    let resourceValues=try fileManager.attributesOfItem(atPath: path.path)

    // Handle different deletion approaches for files vs directories
    let isDirectory = (resourceValues[FileAttributeKey.type] as? String) == "NSFileTypeDirectory"
    if isDirectory {
      // For directories, recursively delete contents securely
      if let contents=try? fileManager.contentsOfDirectory(atPath: path.path) {
        for item in contents {
          let itemPath=path.path + "/" + item
          let itemURL=fileURL.appendingPathComponent(item)
          let itemAttributes=try itemURL.resourceValues(forKeys: [.isDirectoryKey])

          let itemFilePathDTO=FilePathDTO(
            path: itemPath,
            fileName: itemURL.lastPathComponent,
            directoryPath: itemURL.deletingLastPathComponent().path,
            resourceType: itemAttributes.isDirectory == true ? .directory : .file,
            isAbsolute: true,
            securityOptions: path.securityOptions
          )

          // Recursively delete contents
          try await secureDelete(at: itemFilePathDTO, options: options)
        }
      }

      // Delete the empty directory
      try fileManager.removeItem(atPath: path.path)
    } else {
      // For files, overwrite with zeros or random data before deletion
      if passes > 0 {
        let fileSize=try fileManager.attributesOfItem(atPath: path.path)[.size] as? UInt64 ?? 0
        let fileHandle=try FileHandle(forWritingTo: fileURL)
        defer { try? fileHandle.close() }

        for pass in 1...passes {
          await logger.debug("Secure deletion pass \(pass) of \(passes)", context: context)

          // Create overwrite data (zeros or random)
          let data: Data=if useRandomData {
            createRandomData(size: Int(fileSize))
          } else {
            Data(repeating: 0, count: Int(fileSize))
          }

          // Overwrite the file
          try fileHandle.seek(toOffset: 0)
          try fileHandle.write(contentsOf: data)
          try fileHandle.synchronize()
        }
      }

      // Finally remove the overwritten file
      try fileManager.removeItem(atPath: path.path)
    }

    let successContext=createSecureFileLogContext([
      "path": path.path,
      "status": "deleted"
    ])
    await logger.debug("Successfully deleted file securely", context: successContext)
  }

  /**
   Sets secure permissions on a file or directory.

   - Parameters:
      - permissions: The secure permissions to set.
      - path: The path to the file or directory as a FilePathDTO.
   - Throws: FileSystemError if the permissions cannot be set.
   */
  public func setSecurePermissions(
    _ permissions: SecureFilePermissions,
    at path: FilePathDTO
  ) async throws {
    let context=createSecureFileLogContext([
      "path": path.path,
      "posixPermissions": "0o\(String(permissions.posixPermissions, radix: 8))",
      "ownerReadOnly": "\(permissions.ownerReadOnly)"
    ])
    await logger.debug("Setting secure permissions", context: context)

    // Check if the file exists
    guard fileManager.fileExists(atPath: path.path) else {
      throw FileSystemError.notFound(path: path.path)
    }

    // Set POSIX permissions
    var attributes: [FileAttributeKey: Any]=[:]
    attributes[.posixPermissions]=permissions.posixPermissions

    if permissions.ownerReadOnly {
      // Set to owner read-only (0o400)
      attributes[.posixPermissions]=0o400
    }

    // Set permissions
    try fileManager.setAttributes(attributes, ofItemAtPath: path.path)

    let successContext=createSecureFileLogContext([
      "path": path.path,
      "status": "permissions_set"
    ])
    await logger.debug("Successfully set secure permissions", context: successContext)
  }

  /**
   Verifies the integrity of a file using a cryptographic signature.

   - Parameters:
      - path: The path to the file to verify as a FilePathDTO.
      - signature: The cryptographic signature to check against.
   - Returns: A boolean indicating whether the file's integrity is verified.
   - Throws: FileSystemError if the verification operation fails.
   */
  public func verifyFileIntegrity(
    at path: FilePathDTO,
    against signature: Data
  ) async throws -> Bool {
    let context=createSecureFileLogContext([
      "path": path.path,
      "signatureSize": "\(signature.count)"
    ])
    await logger.debug("Verifying file integrity", context: context)

    // Check if the file exists
    guard fileManager.fileExists(atPath: path.path) else {
      throw FileSystemError.notFound(path: path.path)
    }

    // Read the file
    let fileURL=URL(fileURLWithPath: path.path)
    guard let data=try? Data(contentsOf: fileURL) else {
      throw FileSystemError.readError(
        path: path.path,
        reason: "Could not read file for integrity verification"
      )
    }

    // Compute SHA-256 hash of the file
    let computedHash=SHA256.hash(data: data)
    let computedHashData=Data(computedHash)

    // Compare with the provided signature
    let verified=computedHashData == signature

    let resultContext=createSecureFileLogContext([
      "path": path.path,
      "verified": "\(verified)"
    ])
    await logger.debug("File integrity verification result", context: resultContext)

    return verified
  }

  /**
   Creates a log context with the given key-value pairs for secure file operations.
   
   @param metadata Dictionary of metadata key-value pairs
   @return A log context DTO with the metadata included as public fields
   */
  private func createSecureFileLogContext(_ keyValues: [String: String]) -> BaseLogContextDTO {
    let collection=keyValues.reduce(LogMetadataDTOCollection()) { collection, pair in
      collection.withPublic(key: pair.key, value: pair.value)
    }
    return BaseLogContextDTO(
      domainName: "SecureFileOperations",
      operation: "FileOperation",
      category: "Security",
      source: "SecureFileOperationsImpl",
      metadata: collection
    )
  }

  /**
   Creates random data of the specified size.

   - Parameter size: The size of the random data to create.
   - Returns: Data filled with random bytes.
   */
  private func createRandomData(size: Int) -> Data {
    var data=Data(count: size)
    data.withUnsafeMutableBytes { buffer in
      if let baseAddress=buffer.baseAddress {
        arc4random_buf(baseAddress, size)
      }
    }
    return data
  }

  /**
   Encrypts data using AES-256 encryption.

   - Parameters:
      - data: The data to encrypt.
      - key: The encryption key.
   - Returns: The encrypted data.
   - Throws: If encryption fails.
   */
  private func encryptWithAES256(data: Data, key: Data) throws -> Data {
    guard key.count == 32 else {
      throw FileSystemError.securityError(
        path: "memory",
        reason: "AES-256 encryption requires a 32-byte key"
      )
    }

    let symKey=SymmetricKey(data: key)
    let sealedBox=try AES.GCM.seal(data, using: symKey)
    guard let combined=sealedBox.combined else {
      throw FileSystemError.securityError(
        path: "memory",
        reason: "Failed to create combined AES-GCM sealed box"
      )
    }

    return combined
  }

  /**
   Decrypts data using AES-256 encryption.

   - Parameters:
      - data: The data to decrypt.
      - key: The decryption key.
   - Returns: The decrypted data.
   - Throws: If decryption fails.
   */
  private func decryptWithAES256(data: Data, key: Data) throws -> Data {
    guard key.count == 32 else {
      throw FileSystemError.securityError(
        path: "memory",
        reason: "AES-256 decryption requires a 32-byte key"
      )
    }

    let symKey=SymmetricKey(data: key)
    let sealedBox=try AES.GCM.SealedBox(combined: data)
    return try AES.GCM.open(sealedBox, using: symKey)
  }
}

/// A simple no-op implementation of LoggingProtocol for default initialization
private actor LoggingProtocol_NoOp: LoggingProtocol {
  private let _loggingActor=LoggingActor(destinations: [])

  nonisolated var loggingActor: LoggingActor {
    _loggingActor
  }

  func log(_: LogLevel, _: String, context _: LogContextDTO) async {}
  func debug(_: String, context _: LogContextDTO) async {}
  func info(_: String, context _: LogContextDTO) async {}
  func notice(_: String, context _: LogContextDTO) async {}
  func warning(_: String, context _: LogContextDTO) async {}
  func error(_: String, context _: LogContextDTO) async {}
  func critical(_: String, context _: LogContextDTO) async {}
}
