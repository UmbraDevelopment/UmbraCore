import FileSystemCommonTypes
import FileSystemInterfaces
import Foundation

import CoreFileOperations
import FileMetadataOperations
import FileSandboxing

// Removed FileSystemTypes import to resolve type ambiguities
import LoggingInterfaces
import SecureFileOperations

/**
 # Composite File System Service Implementation

 A composite implementation that combines all file system operation subdomains.

 This actor-based implementation delegates operations to the appropriate
 subdomain implementations, providing a unified interface for all file
 system operations while maintaining separation of concerns internally.

 ## Alpha Dot Five Architecture

 This implementation follows the Alpha Dot Five architecture principles:
 - Uses actor isolation for thread safety
 - Leverages dependency injection for modularity
 - Provides comprehensive privacy-aware logging
 - Follows British spelling in documentation
 */
public actor CompositeFileSystemServiceImpl: CompositeFileSystemServiceProtocol {
  /// Core file operations implementation
  private let coreOperations: any CoreFileOperationsProtocol

  /// File metadata operations implementation
  private let metadataOperations: any FileMetadataOperationsProtocol

  /// Secure file operations implementation
  private let secureOperations: any SecureFileOperationsProtocol

  /// File sandboxing implementation
  private let sandboxing: any FileSandboxingProtocol

  /// Logger for this service
  private let logger: any LoggingProtocol

  /// File manager instance
  private let fileManager=FileManager.default

  /**
   Initialises a new composite file system service implementation.

   - Parameters:
      - coreOperations: The core file operations implementation
      - metadataOperations: The file metadata operations implementation
      - secureOperations: The secure file operations implementation
      - sandboxing: The file sandboxing implementation
      - logger: Optional logger for recording operations
   */
  public init(
    coreOperations: any CoreFileOperationsProtocol,
    metadataOperations: any FileMetadataOperationsProtocol,
    secureOperations: any SecureFileOperationsProtocol,
    sandboxing: any FileSandboxingProtocol,
    logger: (any LoggingProtocol)?=nil
  ) {
    self.coreOperations=coreOperations
    self.metadataOperations=metadataOperations
    self.secureOperations=secureOperations
    self.sandboxing=sandboxing
    self.logger=logger ?? NullLogger()
  }

  // MARK: - CoreFileOperationsProtocol

  public func readFile(at path: String) async throws -> (Data, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "readFile", path: path)
    await logger.debug("Delegating readFile operation", context: logContext)
    return try await coreOperations.readFile(at: path)
  }

  public func readFileAsString(
    at path: String,
    encoding: String.Encoding
  ) async throws -> (String, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "readFileAsString", path: path)
    await logger.debug("Delegating readFileAsString operation", context: logContext)
    return try await coreOperations.readFileAsString(at: path, encoding: encoding)
  }

  public func fileExists(at path: String) async -> (Bool, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "fileExists", path: path)
    await logger.debug("Delegating fileExists operation", context: logContext)
    return await coreOperations.fileExists(at: path)
  }

  public func isFile(at path: String) async -> Bool {
    let logContext=FileSystemLogContext(operation: "isFile", path: path)
    await logger.debug("Delegating isFile operation", context: logContext)

    // Since this method doesn't exist in CoreFileOperationsProtocol,
    // we need to implement it directly
    let (exists, _)=await coreOperations.fileExists(at: path)
    if !exists {
      return false
    }

    // Check if it's a file by using the fileManager directly
    var isDir: ObjCBool=false
    if fileManager.fileExists(atPath: path, isDirectory: &isDir) {
      return !isDir.boolValue
    }
    return false
  }

  public func isDirectory(at path: String) async -> Bool {
    let logContext=FileSystemLogContext(operation: "isDirectory", path: path)
    await logger.debug("Delegating isDirectory operation", context: logContext)

    // Since this method doesn't exist in CoreFileOperationsProtocol,
    // we need to implement it directly
    let (exists, _)=await coreOperations.fileExists(at: path)
    if !exists {
      return false
    }

    // Check if it's a directory by using the fileManager directly
    var isDir: ObjCBool=false
    if fileManager.fileExists(atPath: path, isDirectory: &isDir) {
      return isDir.boolValue
    }
    return false
  }

  public func writeFile(
    data: Data,
    to path: String,
    options: FileSystemInterfaces.FileWriteOptions?
  ) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(operation: "writeFile", path: path)
    await logger.debug("Delegating writeFile operation", context: logContext)
    return try await coreOperations.writeFile(data: data, to: path, options: options)
  }

  public func writeString(
    _ string: String,
    to path: String,
    encoding: String.Encoding,
    options: FileSystemInterfaces.FileWriteOptions?
  ) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(operation: "writeString", path: path)
    await logger.debug("Delegating writeString operation", context: logContext)
    return try await coreOperations.writeFileFromString(
      string,
      to: path,
      encoding: encoding,
      options: options
    )
  }

  public func normalisePath(_ path: String) async -> String {
    let logContext=FileSystemLogContext(operation: "normalisePath", path: path)
    await logger.debug("Delegating normalisePath operation", context: logContext)

    // Since this method doesn't exist in CoreFileOperationsProtocol,
    // we need to implement it directly
    // Convert to a URL and back to handle tilde expansion, etc.
    let url=URL(fileURLWithPath: path)
    return url.standardized.path
  }

  public func temporaryDirectoryPath() async -> String {
    let logContext=FileSystemLogContext(operation: "temporaryDirectoryPath", path: "")
    await logger.debug("Getting temporary directory path", context: logContext)

    // Since this method doesn't exist in CoreFileOperationsProtocol,
    // we need to implement it directly
    return fileManager.temporaryDirectory.path
  }

  public func createUniqueFilename(
    in directory: String,
    prefix: String?,
    extension: String?
  ) async -> String {
    let logContext=FileSystemLogContext(operation: "createUniqueFilename", path: directory)
    await logger.debug("Delegating createUniqueFilename operation", context: logContext)

    // Since this method doesn't exist in CoreFileOperationsProtocol,
    // we need to implement it directly
    let uuid=UUID().uuidString
    let filename=prefix != nil ? "\(prefix!)-\(uuid)" : uuid
    let fileWithExt=`extension` != nil ? "\(filename).\(`extension`!)" : filename
    return (directory as NSString).appendingPathComponent(fileWithExt)
  }

  public func writeFileFromString(
    _ string: String,
    to path: String,
    encoding: String.Encoding,
    options: FileSystemInterfaces.FileWriteOptions?
  ) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(operation: "writeFileFromString", path: path)
    await logger.debug("Delegating writeFileFromString operation", context: logContext)
    return try await coreOperations.writeFileFromString(
      string,
      to: path,
      encoding: encoding,
      options: options
    )
  }

  public func getFileURLs(in path: String) async throws -> ([URL], FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "getFileURLs", path: path)
    await logger.debug("Delegating getFileURLs operation", context: logContext)
    return try await coreOperations.getFileURLs(in: path)
  }

  // MARK: - FileMetadataOperationsProtocol

  public func getAttributes(at path: String) async throws
  -> (FileMetadataDTO, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "getAttributes", path: path)
    await logger.debug("Delegating getAttributes operation", context: logContext)
    return try await metadataOperations.getAttributes(at: path)
  }

  public func setAttributes(
    _ attributes: [FileAttributeKey: Any],
    at path: String
  ) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(operation: "setAttributes", path: path)
    await logger.debug("Delegating setAttributes operation", context: logContext)

    // Instead of delegating to metadataOperations with a potentially non-Sendable dictionary,
    // implement the functionality directly to avoid data races
    do {
      let fileManager=FileManager.default

      // Verify the file exists
      guard fileManager.fileExists(atPath: path) else {
        throw FileSystemInterfaces.FileSystemError.other(path: path, reason: "File not found")
      }

      // Set the attributes directly using FileManager
      try fileManager.setAttributes(attributes, ofItemAtPath: path)

      // Get updated metadata
      let updatedAttributes=try fileManager.attributesOfItem(atPath: path)
      let metadata=FileMetadataDTO.from(
        attributes: updatedAttributes,
        path: path
      )

      return FileOperationResultDTO.success(
        path: path,
        metadata: metadata
      )
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      throw fsError
    } catch {
      let errorContext=FileSystemLogContext(
        operation: "setAttributes",
        path: path,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: error.localizedDescription)
      )
      await logger.error(
        "Failed to set attributes: \(error.localizedDescription)",
        context: errorContext
      )
      throw FileSystemInterfaces.FileSystemError.other(
        path: path,
        reason: "Failed to set attributes: \(error.localizedDescription)"
      )
    }
  }

  public func getFileSize(at path: String) async throws -> (UInt64, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "getFileSize", path: path)
    await logger.debug("Delegating getFileSize operation", context: logContext)

    // Since this method doesn't exist in FileMetadataOperationsProtocol,
    // we need to implement it directly
    do {
      // Get attributes to extract the file size
      let fileManager=FileManager.default

      // Make sure the file exists
      guard fileManager.fileExists(atPath: path) else {
        throw FileSystemInterfaces.FileSystemError.other(
          path: path,
          reason: "File not found"
        )
      }

      let attributes=try fileManager.attributesOfItem(atPath: path)
      if let size=attributes[.size] as? UInt64 {
        let metadata=FileMetadataDTO.from(
          attributes: attributes,
          path: path
        )

        let result=FileOperationResultDTO.success(
          path: path,
          metadata: metadata
        )

        return (size, result)
      } else {
        throw FileSystemInterfaces.FileSystemError.metadataError(
          path: path,
          reason: "Could not determine file size"
        )
      }
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      throw fsError
    } catch {
      throw FileSystemInterfaces.FileSystemError.metadataError(
        path: path,
        reason: "Failed to get file size: \(error.localizedDescription)"
      )
    }
  }

  public func getCreationDate(at path: String) async throws -> (Date, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "getCreationDate", path: path)
    await logger.debug("Delegating getCreationDate operation", context: logContext)
    return try await metadataOperations.getCreationDate(at: path)
  }

  public func getModificationDate(at path: String) async throws -> (Date, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "getModificationDate", path: path)
    await logger.debug("Delegating getModificationDate operation", context: logContext)
    return try await metadataOperations.getModificationDate(at: path)
  }

  public func getExtendedAttribute(
    withName name: String,
    fromItemAtPath path: String
  ) async throws -> (ExtendedAttributeDTO, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(
      operation: "getExtendedAttribute",
      path: path,
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "attribute", value: name)
    )
    await logger.debug("Delegating getExtendedAttribute operation", context: logContext)

    // Get the actual data using the correct protocol method
    let (data, result)=try await metadataOperations.getExtendedAttribute(name: name, at: path)

    // Convert from Data to ExtendedAttributeDTO
    let extAttr=ExtendedAttributeDTO(
      name: name,
      data: data
    )

    return (extAttr, result)
  }

  public func setExtendedAttribute(
    _ attribute: ExtendedAttributeDTO,
    onItemAtPath path: String
  ) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(
      operation: "setExtendedAttribute",
      path: path,
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "attribute", value: attribute.name)
    )
    await logger.debug("Delegating setExtendedAttribute operation", context: logContext)

    // Call using the correct protocol method
    return try await metadataOperations.setExtendedAttribute(
      data: attribute.data,
      name: attribute.name,
      at: path,
      options: nil
    )
  }

  public func listExtendedAttributes(atPath path: String) async throws
  -> ([String], FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "listExtendedAttributes", path: path)
    await logger.debug("Delegating listExtendedAttributes operation", context: logContext)

    // Implementation for getting extended attributes
    do {
      let fileManager=FileManager.default

      // Make sure the file exists
      guard fileManager.fileExists(atPath: path) else {
        throw FileSystemInterfaces.FileSystemError.other(
          path: path,
          reason: "File not found"
        )
      }

      // This is a placeholder implementation
      // In a real implementation, we would use platform-specific APIs to get the list of extended
      // attributes
      // Here, we're just returning an empty list with a success result

      let metadata=try FileMetadataDTO.from(
        attributes: fileManager.attributesOfItem(atPath: path),
        path: path
      )

      let result=FileOperationResultDTO.success(
        path: path,
        metadata: metadata
      )

      return ([], result)
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      throw fsError
    } catch {
      let errorContext=FileSystemLogContext(
        operation: "listExtendedAttributes",
        path: path,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: error.localizedDescription)
      )
      await logger.error(
        "Failed to list extended attributes: \(error.localizedDescription)",
        context: errorContext
      )
      throw FileSystemInterfaces.FileSystemError.other(
        path: path,
        reason: "Failed to list extended attributes: \(error.localizedDescription)"
      )
    }
  }

  public func removeExtendedAttribute(
    name: String,
    at path: String
  ) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(
      operation: "removeExtendedAttribute",
      path: path,
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "attribute", value: name)
    )
    await logger.debug("Delegating removeExtendedAttribute operation", context: logContext)
    return try await metadataOperations.removeExtendedAttribute(name: name, at: path)
  }

  public func setExtendedAttribute(
    data: Data,
    name: String,
    at path: String,
    options: Int32?
  ) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(
      operation: "setExtendedAttribute",
      path: path,
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "attribute", value: name)
    )
    await logger.debug("Delegating setExtendedAttribute operation", context: logContext)
    return try await metadataOperations.setExtendedAttribute(
      data: data,
      name: name,
      at: path,
      options: options
    )
  }

  public func getExtendedAttribute(
    name: String,
    at path: String
  ) async throws -> (Data, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(
      operation: "getExtendedAttribute",
      path: path,
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "attribute", value: name)
    )
    await logger.debug("Delegating getExtendedAttribute operation", context: logContext)

    // Call with the correct parameter names
    return try await metadataOperations.getExtendedAttribute(name: name, at: path)
  }

  public func getExtendedAttributes(at path: String) async throws
  -> ([String: Data], FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "getExtendedAttributes", path: path)
    await logger.debug("Delegating getExtendedAttributes operation", context: logContext)
    return try await metadataOperations.getExtendedAttributes(at: path)
  }

  // Additional methods required by FileMetadataOperationsProtocol
  public func setCreationDate(
    _ date: Date,
    at path: String
  ) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(operation: "setCreationDate", path: path)
    await logger.debug("Delegating setCreationDate operation", context: logContext)
    return try await metadataOperations.setCreationDate(date, at: path)
  }

  public func setModificationDate(
    _ date: Date,
    at path: String
  ) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(operation: "setModificationDate", path: path)
    await logger.debug("Delegating setModificationDate operation", context: logContext)
    return try await metadataOperations.setModificationDate(date, at: path)
  }

  public func getResourceValues(
    forKeys keys: Set<URLResourceKey>,
    at path: String
  ) async throws -> ([URLResourceKey: Any], FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "getResourceValues", path: path)
    await logger.debug("Delegating getResourceValues operation", context: logContext)

    // To address the non-sendable warning, create our own implementation instead of delegating
    do {
      let fileManager=FileManager.default
      guard fileManager.fileExists(atPath: path) else {
        throw FileSystemInterfaces.FileSystemError.other(path: path, reason: "File not found")
      }

      let url=URL(fileURLWithPath: path)
      var resourceValues: [URLResourceKey: Any]=[:]

      // Get resource values one by one to avoid Sendable issues
      for key in keys {
        do {
          let value=try url.resourceValues(forKeys: [key])
          if let val=value.allValues.first?.value {
            resourceValues[key]=val
          }
        } catch {
          // Ignore errors for individual keys
        }
      }

      let metadata=try FileMetadataDTO.from(
        attributes: fileManager.attributesOfItem(atPath: path),
        path: path
      )

      let result=FileOperationResultDTO.success(
        path: path,
        metadata: metadata
      )

      return (resourceValues, result)
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      throw fsError
    } catch {
      let errorContext=FileSystemLogContext(
        operation: "getResourceValues",
        path: path,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: error.localizedDescription)
      )
      await logger.error(
        "Failed to get resource values: \(error.localizedDescription)",
        context: errorContext
      )
      throw FileSystemInterfaces.FileSystemError.other(
        path: path,
        reason: "Failed to get resource values: \(error.localizedDescription)"
      )
    }
  }

  // MARK: - SecureFileOperationsProtocol

  public func createSecurityBookmark(for path: FilePathDTO, readOnly: Bool) async throws -> Data {
    let logContext=FileSystemLogContext(operation: "createSecurityBookmark", path: path.path)
    await logger.debug("Delegating createSecurityBookmark operation", context: logContext)

    // In a real implementation, we would use NSURL's bookmarkData method
    do {
      // Check if the file exists
      let fileManager=FileManager.default
      if !fileManager.fileExists(atPath: path.path) {
        throw FileSystemInterfaces.FileSystemError.other(
          path: path.path,
          reason: "File not found"
        )
      }

      // Convert the path to a URL
      let url=URL(fileURLWithPath: path.path)

      // Create the security bookmark data with appropriate options
      var options: NSURL.BookmarkCreationOptions=[.withSecurityScope]
      if readOnly {
        options.insert(.securityScopeAllowOnlyReadAccess)
      }

      // Create the bookmark data
      return try url.bookmarkData(
        options: options,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      throw fsError
    } catch {
      let errorContext=FileSystemLogContext(
        operation: "createSecurityBookmark",
        path: path.path,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: error.localizedDescription)
      )
      await logger.error(
        "Failed to create security bookmark: \(error.localizedDescription)",
        context: errorContext
      )
      throw FileSystemInterfaces.FileSystemError.other(
        path: path.path,
        reason: "Failed to create security bookmark: \(error.localizedDescription)"
      )
    }
  }

  public func resolveSecurityBookmark(_ bookmark: Data) async throws -> (FilePathDTO, Bool) {
    let logContext=FileSystemLogContext(operation: "resolveSecurityBookmark")
    await logger.debug("Delegating resolveSecurityBookmark operation", context: logContext)

    do {
      // Resolve the bookmark data to a URL
      var isStale=false
      let url=try URL(
        resolvingBookmarkData: bookmark,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      // Convert the URL to a FilePathDTO
      let filePath=FilePathDTO(path: url.path, isDirectory: url.hasDirectoryPath)

      // Log the operation completion
      let successContext=FileSystemLogContext(
        operation: "resolveSecurityBookmark",
        path: filePath.path,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "isStale", value: String(isStale))
      )
      await logger.debug("Successfully resolved security bookmark", context: successContext)

      return (filePath, isStale)
    } catch {
      let errorContext=FileSystemLogContext(
        operation: "resolveSecurityBookmark",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: error.localizedDescription)
      )
      await logger.error(
        "Failed to resolve security bookmark: \(error.localizedDescription)",
        context: errorContext
      )
      throw FileSystemInterfaces.FileSystemError.securityError(
        path: "unknown",
        reason: "Failed to resolve security bookmark: \(error.localizedDescription)"
      )
    }
  }

  public func pathToURL(_ path: FilePathDTO) async throws -> URL {
    let logContext=FileSystemLogContext(operation: "pathToURL", path: path.path)
    await logger.debug("Converting path to URL", context: logContext)

    // Simple conversion from path string to URL
    return URL(fileURLWithPath: path.path)
  }

  public func startAccessingSecurityScopedResource(at path: FilePathDTO) async throws -> Bool {
    let logContext=FileSystemLogContext(
      operation: "startAccessingSecurityScopedResource",
      path: path.path
    )
    await logger.debug(
      "Delegating startAccessingSecurityScopedResource operation",
      context: logContext
    )

    do {
      // Check if the file exists
      let fileManager=FileManager.default
      if !fileManager.fileExists(atPath: path.path) {
        throw FileSystemInterfaces.FileSystemError.other(
          path: path.path,
          reason: "File not found"
        )
      }

      // Convert the path to a URL
      let url=URL(fileURLWithPath: path.path)

      // Start accessing the security-scoped resource
      let accessGranted=url.startAccessingSecurityScopedResource()

      // Log the access status
      let successContext=FileSystemLogContext(
        operation: "startAccessingSecurityScopedResource",
        path: path.path,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "accessGranted", value: String(accessGranted))
      )
      await logger.debug("Access to security-scoped resource status", context: successContext)
      return accessGranted
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      throw fsError
    } catch {
      let securityError=FileSystemInterfaces.FileSystemError.securityError(
        path: path.path,
        reason: "Failed to start accessing security-scoped resource: \(error.localizedDescription)"
      )

      let errorContext=FileSystemLogContext(
        operation: "startAccessingSecurityScopedResource",
        path: path.path,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: error.localizedDescription)
      )
      await logger.error(
        "Failed to start accessing security-scoped resource",
        context: errorContext
      )
      throw securityError
    }
  }

  public func stopAccessingSecurityScopedResource(at path: FilePathDTO) async {
    let logContext=FileSystemLogContext(
      operation: "stopAccessingSecurityScopedResource",
      path: path.path
    )
    await logger.debug(
      "Delegating stopAccessingSecurityScopedResource operation",
      context: logContext
    )

    // In a real implementation, we would use NSURL's stopAccessingSecurityScopedResource method
    do {
      // Convert the path to a URL and stop accessing the resource
      let url=URL(fileURLWithPath: path.path)
      url.stopAccessingSecurityScopedResource()

      // Log the operation completion
      let successContext=FileSystemLogContext(
        operation: "stopAccessingSecurityScopedResource",
        path: path.path
      )
      await logger.debug("Stopped accessing security-scoped resource", context: successContext)
    } catch {
      // Log the error
      let errorContext=FileSystemLogContext(
        operation: "stopAccessingSecurityScopedResource",
        path: path.path,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: error.localizedDescription)
      )
      await logger.error(
        "Error during stopAccessingSecurityScopedResource: \(error.localizedDescription)",
        context: errorContext
      )
    }
  }

  public func createSecureTemporaryFile(
    prefix: String?,
    options: FileCreationOptions?
  ) async throws -> FilePathDTO {
    let logContext=FileSystemLogContext(operation: "createSecureTemporaryFile")
    await logger.debug("Delegating createSecureTemporaryFile operation", context: logContext)
    return try await secureOperations.createSecureTemporaryFile(prefix: prefix, options: options)
  }

  public func createSecureTemporaryFile(
    options _: FileSystemInterfaces
      .TemporaryFileOptions?
  ) async throws -> FilePathDTO {
    let logContext=FileSystemLogContext(operation: "createSecureTemporaryFile")
    await logger.debug("Delegating createSecureTemporaryFile operation", context: logContext)

    do {
      // Extract standard prefix if available or use default
      let prefix="temp"
      // Call the standard protocol method
      return try await createSecureTemporaryFile(prefix: prefix, options: nil)
    } catch {
      let errorContext=FileSystemLogContext(
        operation: "createSecureTemporaryFile",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: error.localizedDescription)
      )
      await logger.error(
        "Failed to create secure temporary file: \(error.localizedDescription)",
        context: errorContext
      )
      throw FileSystemInterfaces.FileSystemError.other(
        path: "temporary file",
        reason: "Failed to create secure temporary file: \(error.localizedDescription)"
      )
    }
  }

  public func createSecureTemporaryDirectory(
    prefix: String?,
    options: DirectoryCreationOptions?
  ) async throws -> FilePathDTO {
    let logContext=FileSystemLogContext(operation: "createSecureTemporaryDirectory")
    await logger.debug("Delegating createSecureTemporaryDirectory operation", context: logContext)
    return try await secureOperations.createSecureTemporaryDirectory(
      prefix: prefix,
      options: options
    )
  }

  public func writeSecureFile(
    data: Data,
    to path: FilePathDTO,
    options: FileSystemInterfaces.SecureFileWriteOptions?
  ) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(operation: "writeSecureFile", path: path.path)
    await logger.debug("Delegating writeSecureFile operation", context: logContext)

    // Convert String path to FilePathDTO
    let pathDTO=try await toFilePathDTO(path.path)

    // Basic implementation without actual security features
    do {
      // Call secure operations with the FilePathDTO
      try await secureOperations.secureWriteFile(data: data, to: pathDTO, options: options)

      // Get file attributes for the result metadata
      let fileManager=FileManager.default
      var metadata: FileMetadataDTO?

      if fileManager.fileExists(atPath: path.path) {
        if let attributes=try? fileManager.attributesOfItem(atPath: path.path) {
          metadata=FileMetadataDTO.from(
            attributes: attributes,
            path: path.path
          )
        }
      }

      return FileOperationResultDTO.success(
        path: path.path,
        metadata: metadata
      )
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      throw fsError
    } catch {
      let errorContext=FileSystemLogContext(
        operation: "writeSecureFile",
        path: path.path,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: error.localizedDescription)
      )
      await logger.error(
        "Failed to write secure file: \(error.localizedDescription)",
        context: errorContext
      )
      throw FileSystemInterfaces.FileSystemError.other(
        path: path.path,
        reason: "Failed to write secure file: \(error.localizedDescription)"
      )
    }
  }

  public func secureDelete(at path: FilePathDTO, options: SecureDeletionOptions?) async throws {
    let logContext=FileSystemLogContext(operation: "secureDelete", path: path.path)
    await logger.debug("Delegating secureDelete operation", context: logContext)
    try await secureOperations.secureDelete(at: path, options: options)
  }

  public func setSecurePermissions(
    _ permissions: SecureFilePermissions,
    at path: FilePathDTO
  ) async throws {
    let logContext=FileSystemLogContext(operation: "setSecurePermissions", path: path.path)
    await logger.debug("Delegating setSecurePermissions operation", context: logContext)
    try await secureOperations.setSecurePermissions(permissions, at: path)
  }

  public func verifyFileIntegrity(
    at path: String,
    expectedChecksum: Data,
    algorithm _: ChecksumAlgorithm
  ) async throws -> (Bool, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "verifyFileIntegrity", path: path)
    await logger.debug("Delegating verifyFileIntegrity operation", context: logContext)

    // Convert String path to FilePathDTO for the new method
    let pathDTO=try await toFilePathDTO(path)

    // Call the proper verifyFileIntegrity implementation with FilePathDTO
    let result=try await verifyFileIntegrity(at: pathDTO, against: expectedChecksum)

    // Create the result DTO
    let fileManager=FileManager.default
    var metadata: FileMetadataDTO?

    if fileManager.fileExists(atPath: path) {
      if let attributes=try? fileManager.attributesOfItem(atPath: path) {
        metadata=FileMetadataDTO.from(
          attributes: attributes,
          path: path
        )
      }
    }

    let fileOpResult=FileOperationResultDTO.success(
      path: path,
      metadata: metadata
    )

    return (result, fileOpResult)
  }

  public func verifyFileIntegrity(
    at path: FilePathDTO,
    against signature: Data
  ) async throws -> Bool {
    let logContext=FileSystemLogContext(operation: "verifyFileIntegrity", path: path.path)
    await logger.debug("Delegating verifyFileIntegrity operation", context: logContext)
    return try await secureOperations.verifyFileIntegrity(at: path, against: signature)
  }

  public func encryptFile(
    at path: FilePathDTO,
    withKey _: Data,
    options: FileSystemInterfaces.SecureFileWriteOptions?
  ) async throws {
    let logContext=FileSystemLogContext(operation: "encryptFile", path: path.path)
    await logger.debug("Handling encryptFile operation", context: logContext)

    // Implement basic encryption by reading file, encrypting in memory, and writing back
    do {
      // Read the file data
      let data=try await secureReadFile(at: path, options: nil)

      // Encrypt the data (placeholder for real encryption)
      var encryptedData=data
      // In a real implementation, this would use actual encryption

      // Write the encrypted data back
      try await secureWriteFile(data: encryptedData, to: path, options: options)
    } catch {
      await logger.error(
        "Failed to encrypt file: \(error.localizedDescription)",
        context: logContext
      )
      throw error
    }
  }

  public func decryptFile(
    at path: FilePathDTO,
    withKey _: Data,
    options: FileSystemInterfaces.SecureFileReadOptions?
  ) async throws -> Data {
    let logContext=FileSystemLogContext(operation: "decryptFile", path: path.path)
    await logger.debug("Handling decryptFile operation", context: logContext)

    // Read encrypted file and decrypt
    do {
      // Read the encrypted file
      let encryptedData=try await secureReadFile(at: path, options: options)

      // Decrypt the data (placeholder for real decryption)
      var decryptedData=encryptedData
      // In a real implementation, this would use actual decryption

      return decryptedData
    } catch {
      await logger.error(
        "Failed to decrypt file: \(error.localizedDescription)",
        context: logContext
      )
      throw error
    }
  }

  public func calculateChecksum(
    of path: FilePathDTO,
    using algorithm: ChecksumAlgorithm
  ) async throws -> Data {
    let logContext=FileSystemLogContext(operation: "calculateChecksum", path: path.path)
    await logger.debug("Handling calculateChecksum operation", context: logContext)

    // Implement basic checksum calculation
    do {
      // Read the file data
      let data=try await secureReadFile(at: path, options: nil)

      // Calculate checksum (placeholder implementation)
      let checksum=switch algorithm {
        case .md5:
          Data([0x01]) // Placeholder
        case .sha1:
          Data([0x02]) // Placeholder
        case .sha256:
          Data([0x03]) // Placeholder
        case .sha512:
          Data([0x04]) // Placeholder
        case .custom:
          Data([0x05]) // Placeholder
      }

      return checksum
    } catch {
      await logger.error(
        "Failed to calculate checksum: \(error.localizedDescription)",
        context: logContext
      )
      throw error
    }
  }

  public func createSecureTemporaryDirectory(options: DirectoryCreationOptions?) async throws
  -> FilePathDTO {
    let logContext=FileSystemLogContext(operation: "createSecureTemporaryDirectory")
    await logger.debug("Delegating createSecureTemporaryDirectory operation", context: logContext)

    do {
      // Use a default prefix
      let prefix="tempDir"
      return try await createSecureTemporaryDirectory(prefix: prefix, options: options)
    } catch {
      let errorContext=FileSystemLogContext(
        operation: "createSecureTemporaryDirectory",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: error.localizedDescription)
      )
      await logger.error(
        "Failed to create secure temporary directory: \(error.localizedDescription)",
        context: errorContext
      )
      throw FileSystemError.other(
        path: "temporary directory",
        reason: "Failed to create secure temporary directory: \(error.localizedDescription)"
      )
    }
  }

  // MARK: - FileSandboxingProtocol

  public static func createSandboxed(rootDirectory _: String)
  -> (any CompositeFileSystemServiceProtocol, FileOperationResultDTO) {
    fatalError(
      "Cannot be used to create a sandboxed instance. Use FileSystemServiceFactory instead."
    )
  }

  public func isPathWithinSandbox(_ path: String) async -> (Bool, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "isPathWithinSandbox", path: path)
    await logger.debug("Delegating isPathWithinSandbox operation", context: logContext)
    return await sandboxing.isPathWithinSandbox(path)
  }

  public func pathRelativeToSandbox(_ path: String) async throws -> String {
    let logContext=FileSystemLogContext(operation: "pathRelativeToSandbox", path: path)
    await logger.debug("Delegating pathRelativeToSandbox operation", context: logContext)

    // This is a placeholder since sandboxing.pathRelativeToSandbox doesn't exist
    // Just return the path as is
    return path
  }

  public func sandboxRootDirectory() async -> String {
    let logContext=FileSystemLogContext(operation: "sandboxRootDirectory")
    await logger.debug("Delegating sandboxRootDirectory operation", context: logContext)
    // Since sandboxRootDirectory doesn't exist in FileSandboxingProtocol,
    // we'll return a sensible default for now
    return "/"
  }

  public func createSandboxedDirectory(
    at path: String,
    options: DirectoryCreationOptions?
  ) async throws -> (String, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "createSandboxedDirectory", path: path)
    await logger.debug("Delegating createSandboxedDirectory operation", context: logContext)
    return try await sandboxing.createSandboxedDirectory(at: path, options: options)
  }

  public func createSandboxedFile(
    at path: String,
    options: FileCreationOptions?
  ) async throws -> (String, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "createSandboxedFile", path: path)
    await logger.debug("Delegating createSandboxedFile operation", context: logContext)
    return try await sandboxing.createSandboxedFile(at: path, options: options)
  }

  public func writeSandboxedFile(
    data: Data,
    to path: String,
    options: FileSystemInterfaces.FileWriteOptions?
  ) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(operation: "writeSandboxedFile", path: path)
    await logger.debug("Delegating writeSandboxedFile operation", context: logContext)
    return try await sandboxing.writeSandboxedFile(data: data, to: path, options: options)
  }

  public func listSandboxedDirectory(at path: String) async throws
  -> ([String], FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "listSandboxedDirectory", path: path)
    await logger.debug("Delegating listSandboxedDirectory operation", context: logContext)

    // Since the method doesn't exist in the sandboxing protocol,
    // use the standard directory listing implementation
    do {
      let fileManager=FileManager.default
      let contents=try fileManager.contentsOfDirectory(atPath: path)

      let now=Date()
      let metadata=FileMetadataDTO.from(
        attributes: [
          .size: 0,
          .creationDate: now,
          .modificationDate: now,
          .type: FileAttributeType.typeDirectory
        ],
        path: path
      )

      let result=FileOperationResultDTO.success(
        path: path,
        metadata: metadata
      )

      return (contents, result)
    } catch {
      throw FileSystemInterfaces.FileSystemError.other(
        path: path,
        reason: "Failed to list directory contents: \(error.localizedDescription)"
      )
    }
  }

  public func isSandboxEnabled() async -> Bool {
    let logContext=FileSystemLogContext(operation: "isSandboxEnabled")
    await logger.debug("Delegating isSandboxEnabled operation", context: logContext)
    return await sandboxing.isPathWithinSandbox("/")
      .0 // If sandbox is enabled, this should return true
  }

  public func readSandboxedFile(at path: String) async throws -> (Data, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "readSandboxedFile", path: path)
    await logger.debug("Delegating readSandboxedFile operation", context: logContext)
    return try await sandboxing.readSandboxedFile(at: path)
  }

  public func getAbsolutePath(for relativePath: String) async throws
  -> (String, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "getAbsolutePath", path: relativePath)
    await logger.debug("Delegating getAbsolutePath operation", context: logContext)
    return try await sandboxing.getAbsolutePath(for: relativePath)
  }

  public func getSandboxRoot() async -> String {
    let logContext=FileSystemLogContext(operation: "getSandboxRoot")
    await logger.debug("Delegating getSandboxRoot operation", context: logContext)
    // Since sandboxRootDirectory doesn't exist in FileSandboxingProtocol,
    // we'll return a sensible default for now
    return "/"
  }

  // MARK: - CompositeFileSystemServiceProtocol Additional Operations

  public func createDirectory(
    at path: String,
    options: DirectoryCreationOptions?
  ) async throws -> (String, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "createDirectory", path: path)
    await logger.debug("Handling createDirectory operation", context: logContext)

    // Check if the path is within the sandbox
    let (isWithinSandbox, _)=await sandboxing.isPathWithinSandbox(path)

    if isWithinSandbox {
      // Use sandboxed implementation if within sandbox
      return try await sandboxing.createSandboxedDirectory(at: path, options: options)
    } else {
      // If not in sandbox, create directly using FileManager
      let fileManager=FileManager.default

      do {
        // Create the directory
        try fileManager.createDirectory(
          atPath: path,
          withIntermediateDirectories: true,
          attributes: options?.attributes
        )

        // Get the directory attributes for the result metadata
        let attributes=try fileManager.attributesOfItem(atPath: path)
        let metadata=FileMetadataDTO.from(
          attributes: attributes,
          path: path
        )

        let result=FileOperationResultDTO.success(
          path: path,
          metadata: metadata
        )

        return (path, result)
      } catch {
        let dirError=FileSystemInterfaces.FileSystemError.other(
          path: path,
          reason: "Failed to create directory: \(error.localizedDescription)"
        )

        let errorContext=FileSystemLogContext(
          operation: "createDirectory",
          path: path,
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "error", value: error.localizedDescription)
        )
        await logger.error(
          "Failed to create directory: \(error.localizedDescription)",
          context: errorContext
        )
        throw dirError
      }
    }
  }

  public func createFile(
    at path: String,
    options: FileCreationOptions?
  ) async throws -> (String, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "createFile", path: path)
    await logger.debug("Handling createFile operation", context: logContext)

    // Check if the path is within the sandbox
    let (isWithinSandbox, _)=await sandboxing.isPathWithinSandbox(path)

    if isWithinSandbox {
      // Use sandboxed implementation if within sandbox
      return try await sandboxing.createSandboxedFile(at: path, options: options)
    } else {
      // If not in sandbox, create directly using FileManager
      let fileManager=FileManager.default

      do {
        // Check if we need to create intermediate directories
        if let dirPath=(path as NSString).deletingLastPathComponent as String? {
          if !dirPath.isEmpty && !fileManager.fileExists(atPath: dirPath) {
            try fileManager.createDirectory(
              atPath: dirPath,
              withIntermediateDirectories: true,
              attributes: nil as [FileAttributeKey: Any]?
            )
          }
        }

        // Check if the file exists and if we should overwrite
        let fileOptions=options ?? FileCreationOptions()
        let path=path.trimmingCharacters(in: .whitespacesAndNewlines)

        if fileManager.fileExists(atPath: path) && !fileOptions.shouldOverwrite {
          throw FileSystemInterfaces.FileSystemError.other(
            path: path,
            reason: "File already exists and overwrite not allowed"
          )
        }

        // Create the file
        let created=fileManager.createFile(
          atPath: path,
          contents: nil,
          attributes: fileOptions.attributes
        )

        guard created else {
          throw FileSystemInterfaces.FileSystemError.other(
            path: path,
            reason: "Failed to create file"
          )
        }

        // Get the file attributes for the result metadata
        let attributes=try fileManager.attributesOfItem(atPath: path)
        let metadata=FileMetadataDTO.from(
          attributes: attributes,
          path: path
        )

        let result=FileOperationResultDTO.success(
          path: path,
          metadata: metadata
        )

        return (path, result)
      } catch let fsError as FileSystemInterfaces.FileSystemError {
        throw fsError
      } catch {
        let fileError=FileSystemInterfaces.FileSystemError.other(
          path: path,
          reason: "Failed to create file: \(error.localizedDescription)"
        )

        let errorContext=FileSystemLogContext(
          operation: "createFile",
          path: path,
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "error", value: error.localizedDescription)
        )
        await logger.error(
          "Failed to create file: \(error.localizedDescription)",
          context: errorContext
        )
        throw fileError
      }
    }
  }

  public func delete(at path: String) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(operation: "delete", path: path)
    await logger.debug("Handling delete operation", context: logContext)

    do {
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemInterfaces.FileSystemError.other(
          path: path,
          reason: "File not found"
        )

        let errorContext=FileSystemLogContext(
          operation: "delete",
          path: path,
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "error", value: "File not found")
        )
        await logger.error("File not found: \(path)", context: errorContext)
        throw error
      }

      // Delete the item
      try fileManager.removeItem(atPath: path)

      let result=FileOperationResultDTO.success(
        path: path
      )

      let logContext=FileSystemLogContext(
        operation: "delete",
        path: path
      )

      await logger.debug("Successfully deleted item at \(path)", context: logContext)
      return result
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      // If it's already a FileSystemError, just rethrow it
      throw fsError
    } catch {
      let deleteError=FileSystemInterfaces.FileSystemError.deleteError(
        path: path,
        reason: "Failed to delete item: \(error.localizedDescription)"
      )

      let errorContext=FileSystemLogContext(
        operation: "delete",
        path: path,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error(
        "Failed to delete item: \(error.localizedDescription)",
        context: errorContext
      )
      throw deleteError
    }
  }

  public func move(
    from sourcePath: String,
    to destinationPath: String,
    options: FileSystemInterfaces.FileMoveOptions?
  ) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(
      operation: "move",
      path: sourcePath,
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "destinationPath", value: destinationPath)
    )

    await logger.debug("Moving file from \(sourcePath) to \(destinationPath)", context: logContext)

    let fileManager=fileManager

    do {
      // Make sure the source exists
      guard fileManager.fileExists(atPath: sourcePath) else {
        throw FileSystemInterfaces.FileSystemError.moveError(
          source: sourcePath,
          destination: destinationPath,
          reason: "Source file does not exist"
        )
      }

      let copyOptions=options ?? FileSystemInterfaces.FileMoveOptions()

      if fileManager.fileExists(atPath: destinationPath) && !copyOptions.shouldOverwrite {
        throw FileSystemInterfaces.FileSystemError.moveError(
          source: sourcePath,
          destination: destinationPath,
          reason: "Destination file already exists and overwrite is not enabled"
        )
      }

      // Create intermediate directories if needed
      if copyOptions.createIntermediateDirectories {
        let destinationURL=URL(fileURLWithPath: destinationPath)
        let destinationDir=destinationURL.deletingLastPathComponent().path

        if !fileManager.fileExists(atPath: destinationDir) {
          try fileManager.createDirectory(
            atPath: destinationDir,
            withIntermediateDirectories: true,
            attributes: nil
          )
        }
      }

      // Remove destination if it exists and overwrite is allowed
      if fileManager.fileExists(atPath: destinationPath) && copyOptions.shouldOverwrite {
        try fileManager.removeItem(atPath: destinationPath)
      }

      // Move the item
      try fileManager.moveItem(atPath: sourcePath, toPath: destinationPath)

      // Get the file attributes for the result metadata
      let attributes=try fileManager.attributesOfItem(atPath: destinationPath)
      let metadata=FileMetadataDTO.from(
        attributes: attributes,
        path: destinationPath
      )

      let result=FileOperationResultDTO.success(
        path: destinationPath,
        metadata: metadata
      )

      let logContext=FileSystemLogContext(
        operation: "move",
        path: sourcePath,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "destinationPath", value: destinationPath)
      )

      await logger.debug(
        "Successfully moved file from \(sourcePath) to \(destinationPath)",
        context: logContext
      )

      return result
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      // If it's already a FileSystemError, just rethrow it
      throw fsError
    } catch {
      let moveError=FileSystemInterfaces.FileSystemError.moveError(
        source: sourcePath,
        destination: destinationPath,
        reason: "Failed to move item: \(error.localizedDescription)"
      )

      let errorContext=FileSystemLogContext(
        operation: "move",
        path: sourcePath,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "destinationPath", value: destinationPath)
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error(
        "Failed to move item: \(error.localizedDescription)",
        context: errorContext
      )
      throw moveError
    }
  }

  public func copy(
    from sourcePath: String,
    to destinationPath: String,
    options: FileSystemInterfaces.FileCopyOptions?
  ) async throws -> FileOperationResultDTO {
    let logContext=FileSystemLogContext(
      operation: "copy",
      path: sourcePath,
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "destinationPath", value: destinationPath)
    )

    await logger.debug("Copying file from \(sourcePath) to \(destinationPath)", context: logContext)

    let fileManager=fileManager

    do {
      // Validate source path
      guard fileManager.fileExists(atPath: sourcePath) else {
        throw FileSystemInterfaces.FileSystemError.copyError(
          source: sourcePath,
          destination: destinationPath,
          reason: "Source file does not exist"
        )
      }

      let copyOptions=options ?? FileSystemInterfaces.FileCopyOptions()

      if fileManager.fileExists(atPath: destinationPath) && !copyOptions.shouldOverwrite {
        throw FileSystemInterfaces.FileSystemError.copyError(
          source: sourcePath,
          destination: destinationPath,
          reason: "Destination file already exists and overwrite is not enabled"
        )
      }

      // Create parent directories if needed
      if copyOptions.createIntermediateDirectories {
        let destinationURL=URL(fileURLWithPath: destinationPath)
        let destinationDir=destinationURL.deletingLastPathComponent().path

        if !fileManager.fileExists(atPath: destinationDir) {
          try fileManager.createDirectory(
            atPath: destinationDir,
            withIntermediateDirectories: true,
            attributes: nil
          )
        }
      }

      // Remove destination if it exists and overwrite is allowed
      if fileManager.fileExists(atPath: destinationPath) && copyOptions.shouldOverwrite {
        try fileManager.removeItem(atPath: destinationPath)
      }

      // Copy the item
      try fileManager.copyItem(atPath: sourcePath, toPath: destinationPath)

      // Get the file attributes for the result metadata
      let attributes=try fileManager.attributesOfItem(atPath: destinationPath)
      let metadata=FileMetadataDTO.from(
        attributes: attributes,
        path: destinationPath
      )

      let result=FileOperationResultDTO.success(
        path: destinationPath,
        metadata: metadata
      )

      let logContext=FileSystemLogContext(
        operation: "copy",
        path: destinationPath,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "source", value: sourcePath)
          .withPublic(key: "destination", value: destinationPath)
      )

      await logger.debug(
        "Successfully copied file from \(sourcePath) to \(destinationPath)",
        context: logContext
      )

      return result
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      throw fsError
    } catch {
      let copyError=FileSystemInterfaces.FileSystemError.copyError(
        source: sourcePath,
        destination: destinationPath,
        reason: "Failed to copy item: \(error.localizedDescription)"
      )

      let errorContext=FileSystemLogContext(
        operation: "copy",
        path: destinationPath,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "source", value: sourcePath)
          .withPublic(key: "destination", value: destinationPath)
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error(
        "Failed to copy item: \(error.localizedDescription)",
        context: errorContext
      )
      throw copyError
    }
  }

  public func listDirectoryRecursively(at path: String) async throws
  -> ([String], FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "listDirectoryRecursively", path: path)
    await logger.debug("Handling listDirectoryRecursively operation", context: logContext)

    let fileManager=FileManager.default

    do {
      // Check if directory exists
      var isDir: ObjCBool=false
      let exists=fileManager.fileExists(atPath: path, isDirectory: &isDir)

      guard exists else {
        throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path)
      }

      guard isDir.boolValue else {
        throw FileSystemInterfaces.FileSystemError.other(
          path: path,
          reason: "Path is not a directory: \(path)"
        )
      }

      // Get directory enumerator
      guard let enumerator=fileManager.enumerator(atPath: path) else {
        throw FileSystemInterfaces.FileSystemError.other(
          path: path,
          reason: "Failed to create directory enumerator"
        )
      }

      // Collect all paths recursively
      var paths=[String]()
      while let subpath=enumerator.nextObject() as? String {
        paths.append(subpath)
      }

      // Get the directory attributes for the result metadata
      let dirAttributes=try fileManager.attributesOfItem(atPath: path)
      let metadata=FileMetadataDTO.from(
        attributes: dirAttributes,
        path: path
      )

      let result=FileOperationResultDTO.success(
        path: path,
        metadata: metadata
      )

      let logContext=FileSystemLogContext(
        operation: "listDirectoryRecursively",
        path: path,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "itemCount", value: "\(paths.count)")
      )

      await logger.debug("Successfully listed directory recursively", context: logContext)

      return (paths, result)
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      // If it's already a FileSystemError, just rethrow it
      throw fsError
    } catch {
      let dirError=FileSystemInterfaces.FileSystemError.other(
        path: path,
        reason: "Failed to list directory recursively: \(error.localizedDescription)"
      )

      let errorContext=FileSystemLogContext(
        operation: "listDirectoryRecursively",
        path: path,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error(
        "Failed to list directory recursively: \(error.localizedDescription)",
        context: errorContext
      )
      throw dirError
    }
  }

  // MARK: - Helper Methods

  /// Converts a path string to a FilePathDTO
  private func toFilePathDTO(_ path: String) async throws -> FilePathDTO {
    // Create FilePathDTO from string path
    let url=URL(fileURLWithPath: path)
    let fileName=url.lastPathComponent
    let directoryPath=url.deletingLastPathComponent().path

    // Determine resource type (file or directory)
    let fileManager=FileManager.default
    var isDirectory: ObjCBool=false
    let exists=fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
    let resourceType = !exists ? FilePathDTO.ResourceType.unknown :
      (
        isDirectory.boolValue ? FilePathDTO.ResourceType.directory :
          FilePathDTO.ResourceType.file
      )

    return FilePathDTO(
      path: path,
      fileName: fileName,
      directoryPath: directoryPath,
      resourceType: resourceType,
      isAbsolute: path.starts(with: "/")
    )
  }

  // MARK: - SecureFileOperationsProtocol

  public func secureWriteFile(
    data: Data,
    to path: FilePathDTO,
    options: SecureFileWriteOptions?
  ) async throws {
    let logContext=FileSystemLogContext(operation: "secureWriteFile", path: path.path)
    await logger.debug("Delegating secureWriteFile operation", context: logContext)
    try await secureOperations.secureWriteFile(data: data, to: path, options: options)
  }

  public func secureReadFile(
    at path: FilePathDTO,
    options: SecureFileReadOptions?
  ) async throws -> Data {
    let logContext=FileSystemLogContext(operation: "secureReadFile", path: path.path)
    await logger.debug("Delegating secureReadFile operation", context: logContext)
    return try await secureOperations.secureReadFile(at: path, options: options)
  }

  public func calculateChecksum(
    forFileAt path: String,
    algorithm: ChecksumAlgorithm
  ) async throws -> (Data, FileOperationResultDTO) {
    let logContext=FileSystemLogContext(operation: "calculateChecksum", path: path)
    await logger.debug("Delegating calculateChecksum operation", context: logContext)

    // Perform checksum calculation here
    let fileManager=FileManager.default

    do {
      // Check if the file exists
      if !fileManager.fileExists(atPath: path) {
        throw FileSystemInterfaces.FileSystemError.notFound(path: path)
      }

      // Read file data
      _=try Data(contentsOf: URL(fileURLWithPath: path))

      // Calculate checksum based on algorithm
      let checksum=switch algorithm {
        case .md5:
          // Implement MD5 checksum
          Data() // Placeholder
        case .sha1:
          // Implement SHA1 checksum
          Data() // Placeholder
        case .sha256:
          // Implement SHA256 checksum
          Data() // Placeholder
        case .sha512:
          // Implement SHA512 checksum
          Data() // Placeholder
        case .custom:
          // Handle custom algorithm
          Data() // Placeholder
      }

      // Create metadata for file
      let metadata=try FileMetadataDTO.from(
        attributes: fileManager.attributesOfItem(atPath: path),
        path: path
      )

      return (checksum, FileOperationResultDTO.success(path: path, metadata: metadata))
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      throw fsError
    } catch {
      let errorContext=FileSystemLogContext(
        operation: "calculateChecksum",
        path: path,
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: error.localizedDescription)
      )
      await logger.error(
        "Failed to calculate checksum: \(error.localizedDescription)",
        context: errorContext
      )
      throw FileSystemInterfaces.FileSystemError.other(
        path: path,
        reason: "Failed to calculate checksum: \(error.localizedDescription)"
      )
    }
  }
}
