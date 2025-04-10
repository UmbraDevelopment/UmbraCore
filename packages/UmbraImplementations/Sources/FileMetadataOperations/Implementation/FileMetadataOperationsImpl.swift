import FileSystemInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # File Metadata Operations Implementation

 The implementation of FileMetadataOperationsProtocol that handles file attributes
 and extended attributes.

 This actor-based implementation ensures all operations are thread-safe through
 Swift concurrency. It provides comprehensive metadata handling with proper
 error reporting and logging.

 ## Alpha Dot Five Architecture

 This implementation follows the Alpha Dot Five architecture principles:
 - Uses actor isolation for thread safety
 - Provides comprehensive privacy-aware logging
 - Follows British spelling in documentation
 - Returns standardised operation results
 */

/**
 Extended Attribute DTO for storing extended attribute information
 */
public struct ExtendedAttributeDTO: Sendable, Equatable {
  /// The name of the extended attribute
  public let name: String

  /// The data value of the extended attribute
  public let data: Data

  /// Initializes a new extended attribute DTO
  public init(name: String, data: Data) {
    self.name=name
    self.data=data
  }
}

public actor FileMetadataOperationsImpl: FileMetadataOperationsProtocol {
  /// The underlying file manager isolated within this actor
  private let fileManager: FileManager

  /// Logger for this service
  private let logger: any LoggingProtocol

  /**
   Initialises a new file metadata operations implementation.

   - Parameters:
      - fileManager: Optional custom file manager to use
      - logger: Optional logger for recording operations
   */
  public init(fileManager: FileManager = .default, logger: (any LoggingProtocol)?=nil) {
    self.fileManager=fileManager
    self.logger=logger ?? DefaultLoggerActor()
  }

  /**
   Gets attributes of a file or directory.

   - Parameter path: The path to the file or directory
   - Returns: The file metadata DTO and operation result
   - Throws: If the attributes cannot be retrieved
   */
  public func getAttributes(at path: String) async throws
  -> (FileMetadataDTO, FileOperationResultDTO) {
    let logContext=BaseLogContextDTO(
      domainName: "FileSystem",
      source: "FileMetadataOperationsImpl",
      metadata: LogMetadataDTOCollection().withPublic(key: "path", value: path)
    )

    await logger.debug("Getting attributes for \(path)", context: logContext)

    do {
      // Check if the file exists
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemError.pathNotFound(path: path)
        await logger.error("File not found: \(path)", context: logContext)
        throw error
      }

      // Get the file attributes
      let attributes=try fileManager.attributesOfItem(atPath: path)

      // Extract properties from attributes dictionary
      let fileSize=(attributes[.size] as? NSNumber)?.uint64Value ?? 0
      let creationDate=attributes[.creationDate] as? Date ?? Date.distantPast
      let modificationDate=attributes[.modificationDate] as? Date ?? Date.distantPast
      let accessDate=attributes[.modificationDate] as? Date ?? Date.distantPast
      let fileType=attributes[.type] as? String ?? ""
      let isDirectory=fileType == FileAttributeType.typeDirectory.rawValue
      let isRegularFile=fileType == FileAttributeType.typeRegular.rawValue
      let isSymbolicLink=fileType == FileAttributeType.typeSymbolicLink.rawValue
      let fileExtension=URL(fileURLWithPath: path).pathExtension
        .isEmpty ? nil : URL(fileURLWithPath: path).pathExtension
      let posixPermissions=(attributes[.posixPermissions] as? NSNumber)?.int16Value ?? 0
      let ownerID=(attributes[.ownerAccountID] as? NSNumber)?.intValue ?? 0
      let groupID=(attributes[.groupOwnerAccountID] as? NSNumber)?.intValue ?? 0

      // Create extended attributes dictionary
      var extendedAttributes=[String: ExtendedAttributeDTO]()
      do {
        let attributeNames=try fileManager.extendedAttributeNames(atPath: path)
        if !attributeNames.isEmpty {
          for name in attributeNames {
            if let data=try? fileManager.extendedAttribute(forName: name, atPath: path) {
              extendedAttributes[name]=ExtendedAttributeDTO(name: name, data: data)
            }
          }
        }
      } catch {
        // Just log the error but don't fail the whole operation
        let warningContext=BaseLogContextDTO(
          domainName: "FileSystem",
          source: "FileMetadataOperationsImpl",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "path", value: path)
            .withPublic(key: "error", value: error.localizedDescription)
        )
        await logger.warning(
          "Could not retrieve extended attributes: \(error.localizedDescription)",
          context: warningContext
        )
      }

      // Create metadata DTO directly
      let metadata=FileMetadataDTO(
        size: fileSize,
        creationDate: creationDate,
        modificationDate: modificationDate,
        lastAccessDate: accessDate,
        isDirectory: isDirectory,
        isRegularFile: isRegularFile,
        isSymbolicLink: isSymbolicLink,
        fileExtension: fileExtension,
        posixPermissions: posixPermissions,
        ownerID: ownerID,
        groupID: groupID,
        extendedAttributes: extendedAttributes.isEmpty ? nil : extendedAttributes
          .mapValues { $0.data },
        resourceValues: nil
      )

      let result=FileOperationResultDTO.success(
        path: path,
        metadata: metadata
      )

      await logger.debug("Successfully retrieved attributes for \(path)", context: logContext)
      return (metadata, result)
    } catch let error as FileSystemError {
      throw error
    } catch {
      let fileError=FileSystemError.other(
        path: path,
        reason: "Failed to get attributes: \(error.localizedDescription)"
      )

      let errorContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error(
        "Failed to get attributes: \(error.localizedDescription)",
        context: errorContext
      )
      throw fileError
    }
  }

  /**
   Sets attributes on a file or directory.

   - Parameters:
      - attributes: The attributes to set
      - path: The path to the file or directory
   - Returns: Operation result
   - Throws: If the attributes cannot be set
   */
  public func setAttributes(
    _ attributes: [FileAttributeKey: Any],
    at path: String
  ) async throws -> FileOperationResultDTO {
    let logContext=BaseLogContextDTO(
      domainName: "FileSystem",
      source: "FileMetadataOperationsImpl",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "path", value: path)
        .withPublic(key: "attributes", value: "\(attributes)")
    )

    await logger.debug("Setting attributes for \(path)", context: logContext)

    do {
      // Check if the file exists
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemError.pathNotFound(path: path)
        await logger.error("File not found: \(path)", context: logContext)
        throw error
      }

      // Set the attributes
      try fileManager.setAttributes(attributes, ofItemAtPath: path)

      // Get the updated file attributes for the result metadata
      let updatedAttributes=try fileManager.attributesOfItem(atPath: path)

      // Extract properties from attributes dictionary
      let fileSize=(updatedAttributes[.size] as? NSNumber)?.uint64Value ?? 0
      let creationDate=updatedAttributes[.creationDate] as? Date ?? Date.distantPast
      let modificationDate=updatedAttributes[.modificationDate] as? Date ?? Date.distantPast
      let accessDate=updatedAttributes[.modificationDate] as? Date ?? Date.distantPast
      let fileType=updatedAttributes[.type] as? String ?? ""
      let isDirectory=fileType == FileAttributeType.typeDirectory.rawValue
      let isRegularFile=fileType == FileAttributeType.typeRegular.rawValue
      let isSymbolicLink=fileType == FileAttributeType.typeSymbolicLink.rawValue
      let fileExtension=URL(fileURLWithPath: path).pathExtension
        .isEmpty ? nil : URL(fileURLWithPath: path).pathExtension
      let posixPermissions=(updatedAttributes[.posixPermissions] as? NSNumber)?.int16Value ?? 0
      let ownerID=(updatedAttributes[.ownerAccountID] as? NSNumber)?.intValue ?? 0
      let groupID=(updatedAttributes[.groupOwnerAccountID] as? NSNumber)?.intValue ?? 0

      // Create metadata DTO directly
      let metadata=FileMetadataDTO(
        size: fileSize,
        creationDate: creationDate,
        modificationDate: modificationDate,
        lastAccessDate: accessDate,
        isDirectory: isDirectory,
        isRegularFile: isRegularFile,
        isSymbolicLink: isSymbolicLink,
        fileExtension: fileExtension,
        posixPermissions: posixPermissions,
        ownerID: ownerID,
        groupID: groupID,
        extendedAttributes: nil,
        resourceValues: nil
      )

      let result=FileOperationResultDTO.success(
        path: path,
        metadata: metadata
      )

      await logger.debug("Successfully set attributes for \(path)", context: logContext)
      return result
    } catch let error as FileSystemError {
      throw error
    } catch {
      let fileError=FileSystemError.writeError(
        path: path,
        reason: "Failed to set attributes: \(error.localizedDescription)"
      )

      let errorContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error(
        "Failed to set attributes: \(error.localizedDescription)",
        context: errorContext
      )
      throw fileError
    }
  }

  /**
   Gets the size of a file.

   - Parameter path: The path to the file
   - Returns: The file size in bytes and operation result
   - Throws: If the file size cannot be retrieved
   */
  public func getFileSize(at path: String) async throws -> (UInt64, FileOperationResultDTO) {
    let logContext=BaseLogContextDTO(
      domainName: "FileSystem",
      source: "FileMetadataOperationsImpl",
      metadata: LogMetadataDTOCollection().withPublic(key: "path", value: path)
    )

    await logger.debug("Getting file size for \(path)", context: logContext)

    do {
      // Check if the file exists
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemError.pathNotFound(path: path)
        await logger.error("File not found: \(path)", context: logContext)
        throw error
      }

      // Get the file attributes
      let attributes=try fileManager.attributesOfItem(atPath: path)

      // Extract properties from attributes dictionary
      let fileSize=(attributes[.size] as? NSNumber)?.uint64Value ?? 0
      let creationDate=attributes[.creationDate] as? Date ?? Date.distantPast
      let modificationDate=attributes[.modificationDate] as? Date ?? Date.distantPast
      let accessDate=attributes[.modificationDate] as? Date ?? Date.distantPast
      let fileType=attributes[.type] as? String ?? ""
      let isDirectory=fileType == FileAttributeType.typeDirectory.rawValue
      let isRegularFile=fileType == FileAttributeType.typeRegular.rawValue
      let isSymbolicLink=fileType == FileAttributeType.typeSymbolicLink.rawValue
      let fileExtension=URL(fileURLWithPath: path).pathExtension
        .isEmpty ? nil : URL(fileURLWithPath: path).pathExtension
      let posixPermissions=(attributes[.posixPermissions] as? NSNumber)?.int16Value ?? 0
      let ownerID=(attributes[.ownerAccountID] as? NSNumber)?.intValue ?? 0
      let groupID=(attributes[.groupOwnerAccountID] as? NSNumber)?.intValue ?? 0

      // Create metadata DTO directly
      let metadata=FileMetadataDTO(
        size: fileSize,
        creationDate: creationDate,
        modificationDate: modificationDate,
        lastAccessDate: accessDate,
        isDirectory: isDirectory,
        isRegularFile: isRegularFile,
        isSymbolicLink: isSymbolicLink,
        fileExtension: fileExtension,
        posixPermissions: posixPermissions,
        ownerID: ownerID,
        groupID: groupID,
        extendedAttributes: nil,
        resourceValues: nil
      )

      let result=FileOperationResultDTO.success(
        path: path,
        metadata: metadata
      )

      let successContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "size", value: "\(fileSize)")
      )

      await logger.debug(
        "Successfully retrieved file size for \(path): \(fileSize) bytes",
        context: successContext
      )
      return (fileSize, result)
    } catch let error as FileSystemError {
      throw error
    } catch {
      let fileError=FileSystemError.other(
        path: path,
        reason: "Failed to get file size: \(error.localizedDescription)"
      )

      let errorContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error(
        "Failed to get file size: \(error.localizedDescription)",
        context: errorContext
      )
      throw fileError
    }
  }

  /**
   Gets the creation date of a file or directory.

   - Parameter path: The path to the file or directory
   - Returns: The creation date and operation result
   - Throws: If the creation date cannot be retrieved
   */
  public func getCreationDate(at path: String) async throws -> (Date, FileOperationResultDTO) {
    let logContext=BaseLogContextDTO(
      domainName: "FileSystem",
      source: "FileMetadataOperationsImpl",
      metadata: LogMetadataDTOCollection().withPublic(key: "path", value: path)
    )

    await logger.debug("Getting creation date for \(path)", context: logContext)

    do {
      // Check if the file exists
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemError.pathNotFound(path: path)
        await logger.error("File not found: \(path)", context: logContext)
        throw error
      }

      // Get the file attributes
      let attributes=try fileManager.attributesOfItem(atPath: path)

      // Extract properties from attributes dictionary
      let fileSize=(attributes[.size] as? NSNumber)?.uint64Value ?? 0
      let creationDate=attributes[.creationDate] as? Date ?? Date.distantPast
      let modificationDate=attributes[.modificationDate] as? Date ?? Date.distantPast
      let accessDate=attributes[.modificationDate] as? Date ?? Date.distantPast
      let fileType=attributes[.type] as? String ?? ""
      let isDirectory=fileType == FileAttributeType.typeDirectory.rawValue
      let isRegularFile=fileType == FileAttributeType.typeRegular.rawValue
      let isSymbolicLink=fileType == FileAttributeType.typeSymbolicLink.rawValue
      let fileExtension=URL(fileURLWithPath: path).pathExtension
        .isEmpty ? nil : URL(fileURLWithPath: path).pathExtension
      let posixPermissions=(attributes[.posixPermissions] as? NSNumber)?.int16Value ?? 0
      let ownerID=(attributes[.ownerAccountID] as? NSNumber)?.intValue ?? 0
      let groupID=(attributes[.groupOwnerAccountID] as? NSNumber)?.intValue ?? 0

      // Create metadata DTO directly
      let metadata=FileMetadataDTO(
        size: fileSize,
        creationDate: creationDate,
        modificationDate: modificationDate,
        lastAccessDate: accessDate,
        isDirectory: isDirectory,
        isRegularFile: isRegularFile,
        isSymbolicLink: isSymbolicLink,
        fileExtension: fileExtension,
        posixPermissions: posixPermissions,
        ownerID: ownerID,
        groupID: groupID,
        extendedAttributes: nil,
        resourceValues: nil
      )

      let result=FileOperationResultDTO.success(
        path: path,
        metadata: metadata
      )

      let successContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "creationDate", value: "\(creationDate)")
      )

      await logger.debug(
        "Successfully retrieved creation date for \(path): \(creationDate)",
        context: successContext
      )
      return (creationDate, result)
    } catch let error as FileSystemError {
      throw error
    } catch {
      let fileError=FileSystemError.other(
        path: path,
        reason: "Failed to get creation date: \(error.localizedDescription)"
      )

      let errorContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error(
        "Failed to get creation date: \(error.localizedDescription)",
        context: errorContext
      )
      throw fileError
    }
  }

  /**
   Gets the modification date of a file or directory.

   - Parameter path: The path to the file or directory
   - Returns: The modification date and operation result
   - Throws: If the modification date cannot be retrieved
   */
  public func getModificationDate(at path: String) async throws -> (Date, FileOperationResultDTO) {
    let logContext=BaseLogContextDTO(
      domainName: "FileSystem",
      source: "FileMetadataOperationsImpl",
      metadata: LogMetadataDTOCollection().withPublic(key: "path", value: path)
    )

    await logger.debug("Getting modification date for \(path)", context: logContext)

    do {
      // Check if the file exists
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemError.pathNotFound(path: path)
        await logger.error("File not found: \(path)", context: logContext)
        throw error
      }

      // Get the file attributes
      let attributes=try fileManager.attributesOfItem(atPath: path)

      // Extract properties from attributes dictionary
      let fileSize=(attributes[.size] as? NSNumber)?.uint64Value ?? 0
      let creationDate=attributes[.creationDate] as? Date ?? Date.distantPast
      let modificationDate=attributes[.modificationDate] as? Date ?? Date.distantPast
      let accessDate=attributes[.modificationDate] as? Date ?? Date.distantPast
      let fileType=attributes[.type] as? String ?? ""
      let isDirectory=fileType == FileAttributeType.typeDirectory.rawValue
      let isRegularFile=fileType == FileAttributeType.typeRegular.rawValue
      let isSymbolicLink=fileType == FileAttributeType.typeSymbolicLink.rawValue
      let fileExtension=URL(fileURLWithPath: path).pathExtension
        .isEmpty ? nil : URL(fileURLWithPath: path).pathExtension
      let posixPermissions=(attributes[.posixPermissions] as? NSNumber)?.int16Value ?? 0
      let ownerID=(attributes[.ownerAccountID] as? NSNumber)?.intValue ?? 0
      let groupID=(attributes[.groupOwnerAccountID] as? NSNumber)?.intValue ?? 0

      // Create metadata DTO directly
      let metadata=FileMetadataDTO(
        size: fileSize,
        creationDate: creationDate,
        modificationDate: modificationDate,
        lastAccessDate: accessDate,
        isDirectory: isDirectory,
        isRegularFile: isRegularFile,
        isSymbolicLink: isSymbolicLink,
        fileExtension: fileExtension,
        posixPermissions: posixPermissions,
        ownerID: ownerID,
        groupID: groupID,
        extendedAttributes: nil,
        resourceValues: nil
      )

      let result=FileOperationResultDTO.success(
        path: path,
        metadata: metadata
      )

      let successContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "modificationDate", value: "\(modificationDate)")
      )

      await logger.debug(
        "Successfully retrieved modification date for \(path): \(modificationDate)",
        context: successContext
      )
      return (modificationDate, result)
    } catch let error as FileSystemError {
      throw error
    } catch {
      let fileError=FileSystemError.other(
        path: path,
        reason: "Failed to get modification date: \(error.localizedDescription)"
      )

      let errorContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error(
        "Failed to get modification date: \(error.localizedDescription)",
        context: errorContext
      )
      throw fileError
    }
  }

  /**
   Gets an extended attribute from a file or directory.

   - Parameters:
      - name: The name of the extended attribute
      - path: The path to the file or directory
   - Returns: The extended attribute and operation result
   - Throws: If the extended attribute cannot be retrieved
   */
  public func getExtendedAttribute(
    name: String,
    at path: String
  ) async throws -> (Data, FileOperationResultDTO) {
    let logContext=BaseLogContextDTO(
      domainName: "FileSystem",
      source: "FileMetadataOperationsImpl",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "path", value: path)
        .withPublic(key: "attributeName", value: name)
    )

    await logger.debug("Getting extended attribute", context: logContext)

    do {
      // Check if the file exists
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemError.pathNotFound(path: path)
        await logger.error("File not found: \(path)", context: logContext)
        throw error
      }

      // Get the extended attribute
      let data=try fileManager.extendedAttribute(forName: name, atPath: path)

      // Create the result DTO
      let result=FileOperationResultDTO.success(
        path: path
      )

      let successContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "attributeName", value: name)
          .withPublic(key: "size", value: String(data.count))
      )
      await logger.debug("Successfully retrieved extended attribute", context: successContext)

      return (data, result)
    } catch let error as FileSystemError {
      throw error
    } catch {
      let attributeError=FileSystemError.readError(
        path: path,
        reason: "Failed to retrieve extended attribute \(name): \(error.localizedDescription)"
      )

      let errorContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "attributeName", value: name)
          .withPublic(key: "error", value: error.localizedDescription)
      )
      await logger.error("Failed to retrieve extended attribute", context: errorContext)

      throw attributeError
    }
  }

  /**
   Sets an extended attribute on a file or directory.

   - Parameters:
      - data: The data to set
      - name: Name of the attribute to set
      - path: Path to the file or directory
      - options: Optional flags for the attribute (e.g., create-only)
   - Returns: The operation result
   - Throws: If the extended attribute cannot be set
   */
  public func setExtendedAttribute(
    data: Data,
    name: String,
    at path: String,
    options _: Int32?=nil
  ) async throws -> FileOperationResultDTO {
    let logContext=BaseLogContextDTO(
      domainName: "FileSystem",
      source: "FileMetadataOperationsImpl",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "path", value: path)
        .withPublic(key: "attributeName", value: name)
        .withPublic(key: "size", value: String(data.count))
    )

    await logger.debug("Setting extended attribute", context: logContext)

    do {
      // Check if the file exists
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemError.pathNotFound(path: path)
        await logger.error("File not found: \(path)", context: logContext)
        throw error
      }

      // Set the extended attribute
      try fileManager.setExtendedAttribute(data, forName: name, atPath: path)

      // Create the result DTO
      let result=FileOperationResultDTO.success(
        path: path
      )

      let successContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "attributeName", value: name)
          .withPublic(key: "size", value: String(data.count))
      )
      await logger.debug("Successfully set extended attribute", context: successContext)

      return result
    } catch let error as FileSystemError {
      throw error
    } catch {
      let attributeError=FileSystemError.writeError(
        path: path,
        reason: "Failed to set extended attribute \(name): \(error.localizedDescription)"
      )

      let errorContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "attributeName", value: name)
          .withPublic(key: "error", value: error.localizedDescription)
      )
      await logger.error("Failed to set extended attribute", context: errorContext)

      throw attributeError
    }
  }

  /**
   Gets all extended attributes for a file or directory.

   - Parameter path: Path to the file or directory
   - Returns: A dictionary of extended attribute names to values and operation result
   - Throws: If the extended attributes cannot be retrieved
   */
  public func getExtendedAttributes(at path: String) async throws
  -> ([String: Data], FileOperationResultDTO) {
    let logContext=BaseLogContextDTO(
      domainName: "FileSystem",
      source: "FileMetadataOperationsImpl",
      metadata: LogMetadataDTOCollection().withPublic(key: "path", value: path)
    )

    await logger.debug("Getting all extended attributes for \(path)", context: logContext)

    do {
      // Check if the file exists
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemError.pathNotFound(path: path)
        await logger.error("File not found: \(path)", context: logContext)
        throw error
      }

      // Get the extended attribute names
      let attributeNames=try fileManager.extendedAttributeNames(atPath: path)

      // Create a dictionary of attribute names to values
      var attributes=[String: Data]()
      for name in attributeNames {
        if let data=try? fileManager.extendedAttribute(forName: name, atPath: path) {
          attributes[name]=data
        }
      }

      // Create the result DTO
      let result=FileOperationResultDTO.success(
        path: path
      )

      let successContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "attributeCount", value: String(attributes.count))
      )

      await logger.debug("Successfully retrieved extended attributes", context: successContext)

      return (attributes, result)
    } catch let error as FileSystemError {
      throw error
    } catch {
      let attributeError=FileSystemError.readError(
        path: path,
        reason: "Failed to retrieve extended attributes: \(error.localizedDescription)"
      )

      let errorContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error("Failed to retrieve extended attributes", context: errorContext)

      throw attributeError
    }
  }

  /**
   Lists all extended attributes of a file or directory.

   - Parameter path: The path to the file or directory
   - Returns: The list of extended attribute names and operation result
   - Throws: If the extended attributes cannot be listed
   */
  public func listExtendedAttributes(atPath path: String) async throws
  -> ([String], FileOperationResultDTO) {
    let logContext=BaseLogContextDTO(
      domainName: "FileSystem",
      source: "FileMetadataOperationsImpl",
      metadata: LogMetadataDTOCollection().withPublic(key: "path", value: path)
    )

    await logger.debug("Listing extended attributes for \(path)", context: logContext)

    do {
      // Check if the file exists
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemError.pathNotFound(path: path)
        await logger.error("File not found: \(path)", context: logContext)
        throw error
      }

      // Get the extended attribute names
      let attributeNames=try fileManager.extendedAttributeNames(atPath: path)

      // Get the file attributes for the result metadata
      let attributes=try fileManager.attributesOfItem(atPath: path)

      // Extract properties from attributes dictionary
      let fileSize=(attributes[.size] as? NSNumber)?.uint64Value ?? 0
      let creationDate=attributes[.creationDate] as? Date ?? Date.distantPast
      let modificationDate=attributes[.modificationDate] as? Date ?? Date.distantPast
      let accessDate=attributes[.modificationDate] as? Date ?? Date.distantPast
      let fileType=attributes[.type] as? String ?? ""
      let isDirectory=fileType == FileAttributeType.typeDirectory.rawValue
      let isRegularFile=fileType == FileAttributeType.typeRegular.rawValue
      let isSymbolicLink=fileType == FileAttributeType.typeSymbolicLink.rawValue
      let fileExtension=URL(fileURLWithPath: path).pathExtension
        .isEmpty ? nil : URL(fileURLWithPath: path).pathExtension
      let posixPermissions=(attributes[.posixPermissions] as? NSNumber)?.int16Value ?? 0
      let ownerID=(attributes[.ownerAccountID] as? NSNumber)?.intValue ?? 0
      let groupID=(attributes[.groupOwnerAccountID] as? NSNumber)?.intValue ?? 0

      // Create metadata DTO directly
      let metadata=FileMetadataDTO(
        size: fileSize,
        creationDate: creationDate,
        modificationDate: modificationDate,
        lastAccessDate: accessDate,
        isDirectory: isDirectory,
        isRegularFile: isRegularFile,
        isSymbolicLink: isSymbolicLink,
        fileExtension: fileExtension,
        posixPermissions: posixPermissions,
        ownerID: ownerID,
        groupID: groupID,
        extendedAttributes: nil,
        resourceValues: nil
      )

      let result=FileOperationResultDTO.success(
        path: path,
        metadata: metadata
      )

      let successContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "count", value: String(attributeNames.count))
      )

      await logger.debug(
        "Successfully listed \(attributeNames.count) extended attributes for \(path)",
        context: successContext
      )
      return (attributeNames, result)
    } catch let error as FileSystemError {
      throw error
    } catch {
      let fileError=FileSystemError.other(
        path: path,
        reason: "Failed to list extended attributes: \(error.localizedDescription)"
      )

      let errorContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error(
        "Failed to list extended attributes: \(error.localizedDescription)",
        context: errorContext
      )
      throw fileError
    }
  }

  /**
   Removes an extended attribute from a file or directory.

   - Parameters:
      - name: Name of the attribute to remove
      - path: Path to the file or directory
   - Returns: The operation result
   - Throws: If the extended attribute cannot be removed
   */
  public func removeExtendedAttribute(
    name: String,
    at path: String
  ) async throws -> FileOperationResultDTO {
    let logContext=BaseLogContextDTO(
      domainName: "FileSystem",
      source: "FileMetadataOperationsImpl",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "path", value: path)
        .withPublic(key: "attribute", value: name)
    )

    await logger.debug("Removing extended attribute \(name) from \(path)", context: logContext)

    do {
      // Check if the file exists
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemError.pathNotFound(path: path)
        await logger.error("File not found: \(path)", context: logContext)
        throw error
      }

      // Remove the extended attribute
      try fileManager.removeExtendedAttribute(forName: name, atPath: path)

      // Get the file attributes for the result metadata
      let attributes=try fileManager.attributesOfItem(atPath: path)

      // Extract properties from attributes dictionary
      let fileSize=(attributes[.size] as? NSNumber)?.uint64Value ?? 0
      let creationDate=attributes[.creationDate] as? Date ?? Date.distantPast
      let modificationDate=attributes[.modificationDate] as? Date ?? Date.distantPast
      let accessDate=attributes[.modificationDate] as? Date ?? Date.distantPast
      let fileType=attributes[.type] as? String ?? ""
      let isDirectory=fileType == FileAttributeType.typeDirectory.rawValue
      let isRegularFile=fileType == FileAttributeType.typeRegular.rawValue
      let isSymbolicLink=fileType == FileAttributeType.typeSymbolicLink.rawValue
      let fileExtension=URL(fileURLWithPath: path).pathExtension
        .isEmpty ? nil : URL(fileURLWithPath: path).pathExtension
      let posixPermissions=(attributes[.posixPermissions] as? NSNumber)?.int16Value ?? 0
      let ownerID=(attributes[.ownerAccountID] as? NSNumber)?.intValue ?? 0
      let groupID=(attributes[.groupOwnerAccountID] as? NSNumber)?.intValue ?? 0

      // Create metadata DTO directly
      let metadata=FileMetadataDTO(
        size: fileSize,
        creationDate: creationDate,
        modificationDate: modificationDate,
        lastAccessDate: accessDate,
        isDirectory: isDirectory,
        isRegularFile: isRegularFile,
        isSymbolicLink: isSymbolicLink,
        fileExtension: fileExtension,
        posixPermissions: posixPermissions,
        ownerID: ownerID,
        groupID: groupID,
        extendedAttributes: nil,
        resourceValues: nil
      )

      let result=FileOperationResultDTO.success(
        path: path,
        metadata: metadata
      )

      await logger.debug(
        "Successfully removed extended attribute \(name) from \(path)",
        context: logContext
      )
      return result
    } catch let error as FileSystemError {
      throw error
    } catch {
      let fileError=FileSystemError.other(
        path: path,
        reason: "Failed to remove extended attribute: \(error.localizedDescription)"
      )

      let errorContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "attribute", value: name)
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error(
        "Failed to remove extended attribute: \(error.localizedDescription)",
        context: errorContext
      )
      throw fileError
    }
  }

  /**
   Sets the creation date of a file or directory.

   - Parameters:
      - date: The date to set
      - path: Path to the file or directory
   - Returns: The operation result
   - Throws: If the creation date cannot be set
   */
  public func setCreationDate(
    _ date: Date,
    at path: String
  ) async throws -> FileOperationResultDTO {
    let logContext=BaseLogContextDTO(
      domainName: "FileSystem",
      source: "FileMetadataOperationsImpl",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "path", value: path)
        .withPublic(key: "date", value: "\(date)")
    )

    await logger.debug("Setting creation date for \(path)", context: logContext)

    do {
      // Check if the file exists
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemError.pathNotFound(path: path)
        await logger.error("File not found: \(path)", context: logContext)
        throw error
      }

      // Set the creation date
      let attributes: [FileAttributeKey: Any]=[
        .creationDate: date
      ]

      try fileManager.setAttributes(attributes, ofItemAtPath: path)

      // Create the result DTO
      let result=FileOperationResultDTO.success(
        path: path
      )

      let successContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "date", value: "\(date)")
      )

      await logger.debug("Successfully set creation date for \(path)", context: successContext)

      return result
    } catch let error as FileSystemError {
      throw error
    } catch {
      let fileError=FileSystemError.writeError(
        path: path,
        reason: "Failed to set creation date: \(error.localizedDescription)"
      )

      let errorContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "date", value: "\(date)")
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error("Failed to set creation date", context: errorContext)

      throw fileError
    }
  }

  /**
   Sets the modification date of a file or directory.

   - Parameters:
      - date: The date to set
      - path: Path to the file or directory
   - Returns: The operation result
   - Throws: If the modification date cannot be set
   */
  public func setModificationDate(
    _ date: Date,
    at path: String
  ) async throws -> FileOperationResultDTO {
    let logContext=BaseLogContextDTO(
      domainName: "FileSystem",
      source: "FileMetadataOperationsImpl",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "path", value: path)
        .withPublic(key: "date", value: "\(date)")
    )

    await logger.debug("Setting modification date for \(path)", context: logContext)

    do {
      // Check if the file exists
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemError.pathNotFound(path: path)
        await logger.error("File not found: \(path)", context: logContext)
        throw error
      }

      // Set the modification date
      let attributes: [FileAttributeKey: Any]=[
        .modificationDate: date
      ]

      try fileManager.setAttributes(attributes, ofItemAtPath: path)

      // Create the result DTO
      let result=FileOperationResultDTO.success(
        path: path
      )

      let successContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "date", value: "\(date)")
      )

      await logger.debug("Successfully set modification date for \(path)", context: successContext)

      return result
    } catch let error as FileSystemError {
      throw error
    } catch {
      let fileError=FileSystemError.writeError(
        path: path,
        reason: "Failed to set modification date: \(error.localizedDescription)"
      )

      let errorContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "date", value: "\(date)")
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error("Failed to set modification date", context: errorContext)

      throw fileError
    }
  }

  /**
   Gets resource values for a file or directory.

   - Parameters:
      - keys: Set of resource keys to retrieve
      - path: Path to the file or directory
   - Returns: A dictionary of resource values and operation result
   - Throws: If the resource values cannot be retrieved
   */
  public func getResourceValues(
    forKeys keys: Set<URLResourceKey>,
    at path: String
  ) async throws -> ([URLResourceKey: Any], FileOperationResultDTO) {
    let logContext=BaseLogContextDTO(
      domainName: "FileSystem",
      source: "FileMetadataOperationsImpl",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "path", value: path)
        .withPublic(key: "resourceKeys", value: "\(keys)")
    )

    await logger.debug("Getting resource values for \(path)", context: logContext)

    do {
      // Check if the file exists
      guard fileManager.fileExists(atPath: path) else {
        let error=FileSystemError.pathNotFound(path: path)
        await logger.error("File not found: \(path)", context: logContext)
        throw error
      }

      // Get the resource values
      let url=URL(fileURLWithPath: path)
      var resourceValues=[URLResourceKey: Any]()
      let values=try url.resourceValues(forKeys: keys)

      // Create a dictionary of resource values
      for key in keys {
        if let value=values.allValues[key] {
          resourceValues[key]=value
        }
      }

      // Create the result DTO
      let result=FileOperationResultDTO.success(
        path: path
      )

      let successContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "resourceKeyCount", value: String(resourceValues.count))
      )

      await logger.debug("Successfully retrieved resource values", context: successContext)

      return (resourceValues, result)
    } catch let error as FileSystemError {
      throw error
    } catch {
      let resourceError=FileSystemError.readError(
        path: path,
        reason: "Failed to retrieve resource values: \(error.localizedDescription)"
      )

      let errorContext=BaseLogContextDTO(
        domainName: "FileSystem",
        source: "FileMetadataOperationsImpl",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "path", value: path)
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error("Failed to retrieve resource values", context: errorContext)

      throw resourceError
    }
  }
}

// MARK: - FileManager Extension for Extended Attributes

extension FileManager {
  /**
   Gets an extended attribute for a file or directory.

   - Parameters:
      - name: The name of the extended attribute
      - path: The path to the file or directory
   - Returns: The extended attribute data
   - Throws: If the extended attribute cannot be retrieved
   */
  func extendedAttribute(forName name: String, atPath path: String) throws -> Data {
    let url=URL(fileURLWithPath: path)

    var length=0
    let status=url.withUnsafeFileSystemRepresentation { pathPtr in
      getxattr(pathPtr, name, nil, 0, 0, 0)
    }

    if status == -1 {
      throw FileSystemError.extendedAttributeError(
        path: path,
        attribute: name,
        reason: String(cString: strerror(errno))
      )
    }

    length=Int(status)
    var data=Data(count: length)

    let readStatus=data.withUnsafeMutableBytes { (pointer) -> Int in
      guard let dataPtr=pointer.baseAddress else { return -1 }
      let status=url.withUnsafeFileSystemRepresentation { (pathPtr) -> Int in
        if let pathPtr {
          return Int(getxattr(pathPtr, name, dataPtr, length, 0, 0))
        } else {
          return -1
        }
      }
      return status
    }

    if readStatus == -1 {
      throw FileSystemError.extendedAttributeError(
        path: path,
        attribute: name,
        reason: String(cString: strerror(errno))
      )
    }

    return data
  }

  /**
   Sets an extended attribute on a file or directory.

   - Parameters:
      - data: The data to set
      - name: The name of the extended attribute
      - path: The path to the file or directory
   - Throws: If the extended attribute cannot be set
   */
  func setExtendedAttribute(_ data: Data, forName name: String, atPath path: String) throws {
    let url=URL(fileURLWithPath: path)

    let status=data.withUnsafeBytes { (pointer) -> Int in
      guard let dataPtr=pointer.baseAddress else { return -1 }
      let result=url.withUnsafeFileSystemRepresentation { (pathPtr) -> Int in
        if let pathPtr {
          return Int(setxattr(pathPtr, name, dataPtr, data.count, 0, 0))
        } else {
          return -1
        }
      }
      return result
    }

    if status == -1 {
      throw FileSystemError.extendedAttributeError(
        path: path,
        attribute: name,
        reason: String(cString: strerror(errno))
      )
    }
  }

  /**
   Lists all extended attributes on a file or directory.

   - Parameter path: The path to the file or directory
   - Returns: An array of extended attribute names
   - Throws: If the extended attributes cannot be listed
   */
  func extendedAttributeNames(atPath path: String) throws -> [String] {
    let url=URL(fileURLWithPath: path)

    var length=0
    let status=url.withUnsafeFileSystemRepresentation { pathPtr in
      listxattr(pathPtr, nil, 0, 0)
    }

    if status == -1 {
      throw FileSystemError.extendedAttributeError(
        path: path,
        attribute: "all",
        reason: String(cString: strerror(errno))
      )
    }

    length=Int(status)
    if length == 0 {
      return []
    }

    var nameBuf=[CChar](repeating: 0, count: length)

    let readStatus=url.withUnsafeFileSystemRepresentation { (pathPtr) -> Int in
      if let pathPtr {
        return Int(listxattr(pathPtr, &nameBuf, length, 0))
      } else {
        return -1
      }
    }

    if readStatus == -1 {
      throw FileSystemError.extendedAttributeError(
        path: path,
        attribute: "all",
        reason: String(cString: strerror(errno))
      )
    }

    var names=[String]()
    var start=0
    for i in 0..<length {
      if nameBuf[i] == 0 {
        let nameBytes=nameBuf[start..<i]
        // Convert Int8 array to UInt8 array for String initializer
        let uint8Bytes=nameBytes.map { UInt8(bitPattern: $0) }
        if let name=String(bytes: uint8Bytes, encoding: .utf8) {
          names.append(name)
        }
        start=i + 1
      }
    }

    return names
  }

  /**
   Removes an extended attribute from a file or directory.

   - Parameters:
      - name: The name of the extended attribute
      - path: The path to the file or directory
   - Throws: If the extended attribute cannot be removed
   */
  func removeExtendedAttribute(forName name: String, atPath path: String) throws {
    let url=URL(fileURLWithPath: path)

    let status=url.withUnsafeFileSystemRepresentation { (pathPtr) -> Int in
      if let pathPtr {
        return Int(removexattr(pathPtr, name, 0))
      } else {
        return -1
      }
    }

    if status == -1 {
      throw FileSystemError.extendedAttributeError(
        path: path,
        attribute: name,
        reason: String(cString: strerror(errno))
      )
    }
  }
}

/**
 Default logger implementation
 */
private actor DefaultLoggerActor: LoggingProtocol {
  private let actualLogger: LoggingActor

  init() {
    // Create a minimal logger with no destinations
    actualLogger=LoggingActor(destinations: [], minimumLogLevel: .debug)
  }

  nonisolated var loggingActor: LoggingActor {
    actualLogger
  }

  // Core logging implementation required by CoreLoggingProtocol
  func log(
    _ level: LoggingTypes.LogLevel,
    _ message: String,
    context: any LoggingTypes.LogContextDTO
  ) async {
    // Forward to the actual logger
    await actualLogger.log(level, message, context: context)
  }

  // Convenience methods
  func debug(_ message: String, context: (any LogContextDTO)?) async {
    if let ctx=context {
      await log(.debug, message, context: ctx)
    }
  }

  func info(_ message: String, context: (any LogContextDTO)?) async {
    if let ctx=context {
      await log(.info, message, context: ctx)
    }
  }

  func notice(_ message: String, context: (any LogContextDTO)?) async {
    if let ctx=context {
      await log(.info, message, context: ctx) // Using .info since there's no .notice
    }
  }

  func warning(_ message: String, context: (any LogContextDTO)?) async {
    if let ctx=context {
      await log(.warning, message, context: ctx)
    }
  }

  func error(_ message: String, context: (any LogContextDTO)?) async {
    if let ctx=context {
      await log(.error, message, context: ctx)
    }
  }

  func critical(_ message: String, context: (any LogContextDTO)?) async {
    if let ctx=context {
      await log(.critical, message, context: ctx)
    }
  }
}
