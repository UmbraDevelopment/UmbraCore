import Darwin.C
import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import LoggingAdapters
import CoreDTOs

/**
 # File System Service Implementation

 This class provides the implementation for the FileSystemServiceProtocol, handling
 all file system operations in a thread-safe and efficient manner.

 The implementation is divided into logical extensions to maintain code organisation:
 - Core Operations: Basic file existence and metadata operations
 - Directory Operations: Creating, listing, and managing directories
 - File Operations: Reading, writing, copying, and deleting files
 - Path Operations: Path manipulation and validation
 - Streaming Operations: Efficient handling of large files
 - Temporary File Operations: Working with temporary files and directories
 - Extended Attribute Operations: Setting and retrieving extended attributes

 All operations are properly isolated through Swift's actor system to ensure thread safety.
 */
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor FileSystemServiceImpl: FileServiceProtocol {

  /// The underlying file manager isolated within this actor
  let fileManager: Foundation.FileManager
  
  /// Logger for this service
  private let logger: any LoggingProtocol
  
  /// Secure file operations implementation
  public let secureOperations: SecureFileOperationsProtocol
    
  /**
   Initialises a new file system service implementation.
   
   - Parameters:
      - fileManager: Optional custom file manager to use.
      - logger: Optional logger.
      - secureOperations: Optional secure operations implementation.
   */
  public init(
    fileManager: Foundation.FileManager = .default,
    logger: (any LoggingProtocol)? = nil,
    secureOperations: SecureFileOperationsProtocol? = nil
  ) {
    self.fileManager = fileManager
    self.logger = logger ?? NullLogger()
    self.secureOperations = secureOperations ?? SandboxedSecureFileOperations(rootDirectory: nil)
  }

  // MARK: - Helper Methods

  /**
   Get the metadata for a file or directory.

   This method is used internally to get file metadata without throwing errors
   for files that don't exist, and is primarily used by the exists check methods.

   - Parameter path: The path to check
   - Returns: Metadata for the file/directory, or nil if it doesn't exist
   */
  func getBasicFileMetadata(at path: FilePathDTO) async throws -> FileSystemMetadata? {
    guard !path.path.isEmpty else {
      return nil
    }

    do {
      let attributes=try fileManager.attributesOfItem(atPath: path.path)

      let size=attributes[.size] as? UInt64 ?? 0
      let creationDate=attributes[.creationDate] as? Date
      let modificationDate=attributes[.modificationDate] as? Date
      let fileType=attributes[.type] as? String

      // Determine file type - use the FileSystemItemType from FileSystemTypes to avoid ambiguity
      let isDirectory=fileType == FileAttributeType.typeDirectory.rawValue
      let itemType: FileSystemTypes.FileSystemItemType=isDirectory ? .directory : .file

      // Create and return the metadata
      return FileSystemMetadata(
        path: path,
        itemType: itemType,
        size: size,
        creationDate: creationDate,
        modificationDate: modificationDate
      )
    } catch {
      // If the file doesn't exist, return nil instead of throwing an error
      if
        (error as NSError).domain == NSCocoaErrorDomain &&
        (error as NSError).code == NSFileReadNoSuchFileError
      {
        return nil
      }

      // Otherwise, propagate the error
      await logger.error(
        "Failed to get metadata for \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "stat",
          path: path.path,
          source: "FileSystemService",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "errorType", value: "\(type(of: error))")
            .withPrivate(key: "errorMessage", value: error.localizedDescription)
        )
      )
      throw error
    }
  }

  /**
   Implements the getFileMetadata method required by the FileSystemServiceProtocol.

   - Parameters:
     - path: The path to the file or directory
     - options: Optional metadata options to control which metadata is retrieved
   - Returns: A FileMetadata object containing the requested metadata
   - Throws: FileSystemError if the metadata cannot be retrieved
   */
  public func getFileMetadata(
    at path: FilePathDTO,
    options: FileMetadataOptions?
  ) async throws -> FileMetadata {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    do {
      let url=URL(fileURLWithPath: path.path)

      // Build a set of resource keys to fetch
      var resourceKeys: Set<URLResourceKey>=[
        .contentModificationDateKey,
        .creationDateKey,
        .fileResourceTypeKey,
        .totalFileSizeKey,
        .isHiddenKey,
        .isDirectoryKey,
        .isReadableKey,
        .isWritableKey
      ]

      // Add any additional keys requested by the caller
      if let options {
        for key in options.resourceKeys {
          if let urlKey=key.toURLResourceKey() {
            resourceKeys.insert(urlKey)
          }
        }
      }

      // Check if the file exists
      var exists=true
      if !fileManager.fileExists(atPath: path.path) {
        exists=false

        // Create a minimal metadata for non-existent files
        let emptyAttributes=FileAttributes(
          size: 0,
          creationDate: Date(),
          modificationDate: Date(),
          accessDate: nil,
          ownerID: 0,
          groupID: 0,
          permissions: 0,
          fileType: nil,
          creator: nil,
          flags: 0,
          safeExtendedAttributes: [:]
        )

        return FileMetadata(
          path: path,
          attributes: emptyAttributes,
          safeResourceValues: [:],
          exists: false
        )
      }

      // Fetch file attributes
      let attributes=try fileManager.attributesOfItem(atPath: path.path)

      // Fetch URL resource values
      let urlResourceValues=try url.resourceValues(forKeys: resourceKeys)

      // Convert attributes to our FileAttributes type
      let fileAttributes=FileAttributes(
        size: attributes[.size] as? UInt64 ?? 0,
        creationDate: attributes[.creationDate] as? Date ?? Date(),
        modificationDate: attributes[.modificationDate] as? Date ?? Date(),
        accessDate: nil, // Not available in attributesOfItem
        ownerID: attributes[.ownerAccountID] as? UInt ?? 0,
        groupID: attributes[.groupOwnerAccountID] as? UInt ?? 0,
        permissions: attributes[.posixPermissions] as? UInt16 ?? 0,
        fileType: attributes[.type] as? String,
        creator: nil, // Not commonly used
        flags: 0, // Not commonly used
        safeExtendedAttributes: [:] // Will populate below if needed
      )

      // Convert URL resource values to our safe dictionary type
      var safeResourceValues=[FileResourceKey: SafeAttributeValue]()

      // Convert each resource value
      for key in resourceKeys {
        if
          let value=urlResourceValues.allValues[key],
          let safeValue=SafeAttributeValue(from: value),
          let fileKey=FileResourceKey(fromURLResourceKey: key)
        {
          safeResourceValues[fileKey]=safeValue
        }
      }

      // Create and return the file metadata
      let metadata=FileMetadata(
        path: path,
        attributes: fileAttributes,
        safeResourceValues: safeResourceValues,
        exists: exists
      )

      await logger.debug(
        "Retrieved metadata for \(path.path)",
        context: FileSystemLogContext(
          operation: "stat",
          source: "FileSystemService"
        )
      )

      return metadata
    } catch {
      await logger.error(
        "Failed to get file metadata: \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "getFileMetadata",
          path: path.path,
          source: "FileSystemService",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "errorType", value: "\(type(of: error))")
            .withPrivate(key: "errorMessage", value: error.localizedDescription)
        )
      )
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: "Failed to get metadata: \(error.localizedDescription)"
      )
    }
  }

  // MARK: - Extended Attribute Operations

  /**
   Gets an extended attribute from a file or directory.

   - Parameters:
     - path: The path to the file or directory
     - name: The name of the extended attribute
   - Returns: The attribute value as a SafeAttributeValue
   - Throws:
      - `FileSystemError.invalidPath` if the path is empty
      - `FileSystemError.pathNotFound` if the file or directory does not exist
      - `FileSystemError.readError` if the attribute cannot be read
   */
  public func getExtendedAttribute(
    at path: FilePathDTO,
    name: String
  ) async throws -> SafeAttributeValue {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    guard !name.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Empty attribute name provided"
      )
    }
    
    // Check if file exists
    if !fileManager.fileExists(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }
    
    await logger.debug(
      "Getting extended attribute \(name) from \(path.path)",
      context: FileSystemLogContext(
        operation: "getExtendedAttribute",
        path: path.path,
        source: "FileSystemService",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "attributeName", value: name)
      )
    )
    
    do {
      let data = try fileManager.getExtendedAttribute(withName: name, fromItemAtPath: path.path)
      
      await logger.debug(
        "Successfully read extended attribute \(name)",
        context: FileSystemLogContext(
          operation: "getExtendedAttribute",
          path: path.path,
          source: "FileSystemService",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "attributeName", value: name)
            .withPublic(key: "byteSize", value: "\(data.count)")
        )
      )
      
      return SafeAttributeValue(from: data)
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      // Rethrow FileSystemError directly
      throw fsError
    } catch {
      let errorMetadata = LogMetadataDTOCollection()
        .withPublic(key: "attributeName", value: name)
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPrivate(key: "errorMessage", value: error.localizedDescription)
      
      await logger.error(
        "Failed to get extended attribute: \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "getExtendedAttribute",
          path: path.path,
          source: "FileSystemService",
          metadata: errorMetadata
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: "Failed to read extended attribute '\(name)': \(error.localizedDescription)"
      )
    }
  }

  /**
   Sets an extended attribute on a file or directory.

   - Parameters:
     - path: The path to the file or directory
     - name: The name of the extended attribute
     - value: The value to set
   - Throws:
      - `FileSystemError.invalidPath` if the path is empty
      - `FileSystemError.pathNotFound` if the file or directory does not exist
      - `FileSystemError.writeError` if the attribute cannot be set
   */
  public func setExtendedAttribute(
    at path: FilePathDTO,
    name: String,
    value: SafeAttributeValue
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    guard !name.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Empty attribute name provided"
      )
    }
    
    // Check if file exists
    if !fileManager.fileExists(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }
    
    await logger.debug(
      "Setting extended attribute \(name) on \(path.path)",
      context: FileSystemLogContext(
        operation: "setExtendedAttribute",
        path: path.path,
        source: "FileSystemService",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "attributeName", value: name)
      )
    )
    
    do {
      let data = value.toData()
      try fileManager.setExtendedAttribute(data, withName: name, forItemAtPath: path.path)
      
      await logger.debug(
        "Successfully set extended attribute \(name)",
        context: FileSystemLogContext(
          operation: "setExtendedAttribute",
          path: path.path,
          source: "FileSystemService",
          metadata: LogMetadataDTOCollection()
            .withPrivate(key: "path", value: path.path)
            .withPublic(key: "attributeName", value: name)
        )
      )
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      // Rethrow FileSystemError directly
      throw fsError
    } catch {
      let errorMetadata = LogMetadataDTOCollection()
        .withPublic(key: "attributeName", value: name)
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPrivate(key: "errorMessage", value: error.localizedDescription)
      
      await logger.error(
        "Failed to set extended attribute: \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "setExtendedAttribute",
          path: path.path,
          source: "FileSystemService",
          metadata: errorMetadata
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to set extended attribute '\(name)': \(error.localizedDescription)"
      )
    }
  }

  /**
   Lists all extended attributes for a file or directory.

   - Parameter path: The path to the file or directory
   - Returns: Array of attribute names
   - Throws:
      - `FileSystemError.invalidPath` if the path is empty
      - `FileSystemError.pathNotFound` if the file or directory does not exist
      - `FileSystemError.readError` if the attributes cannot be listed
   */
  public func listExtendedAttributes(
    at path: FilePathDTO
  ) async throws -> [String] {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    // Check if file exists
    if !fileManager.fileExists(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }
    
    await logger.debug(
      "Listing extended attributes for \(path.path)",
      context: FileSystemLogContext(
        operation: "listExtendedAttributes",
        path: path.path,
        source: "FileSystemService"
      )
    )
    
    do {
      let attributes = try fileManager.listExtendedAttributes(atPath: path.path)
      
      let resultMetadata = LogMetadataDTOCollection()
        .withPublic(key: "attributeCount", value: "\(attributes.count)")
      
      await logger.debug(
        "Found \(attributes.count) extended attributes",
        context: FileSystemLogContext(
          operation: "listExtendedAttributes",
          path: path.path,
          source: "FileSystemService",
          metadata: resultMetadata
        )
      )
      
      return attributes
    } catch {
      let errorMetadata = LogMetadataDTOCollection()
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPrivate(key: "errorMessage", value: error.localizedDescription)
      
      await logger.error(
        "Failed to list extended attributes: \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "listExtendedAttributes",
          path: path.path,
          source: "FileSystemService",
          metadata: errorMetadata
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: "Failed to list extended attributes: \(error.localizedDescription)"
      )
    }
  }

  /**
   Removes an extended attribute from a file or directory.

   - Parameters:
     - path: The path to the file or directory
     - attributeName: The name of the extended attribute to remove
   - Throws: FileSystemError if the attribute cannot be removed
   */
  public func removeExtendedAttribute(
    at path: FilePathDTO,
    attributeName: String
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    do {
      // Remove the extended attribute
      try fileManager.setExtendedAttribute(
        attributeName,
        value: nil,
        forItemAtPath: path.path
      )

      await logger.debug(
        "Removing extended attribute \(attributeName) from \(path.path)",
        context: FileSystemLogContext(
          operation: "removeExtendedAttribute",
          path: path.path,
          source: "FileSystemService",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "attributeName", value: attributeName)
        )
      )
    } catch {
      await logger.error(
        "Failed to remove extended attribute: \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "removeExtendedAttribute",
          path: path.path,
          source: "FileSystemService",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "attributeName", value: attributeName)
            .withPublic(key: "errorType", value: "\(type(of: error))")
            .withPrivate(key: "errorMessage", value: error.localizedDescription)
        )
      )
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to remove extended attribute: \(error.localizedDescription)"
      )
    }
  }

  // ... rest of the code remains the same ...
