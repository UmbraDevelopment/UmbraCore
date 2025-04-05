import Darwin.C
import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Directory Operations Extension

 This extension provides directory-specific operations for the FileSystemServiceImpl,
 including listing, creating, and removing directories.
 */
extension FileSystemServiceImpl {
  /**
   Creates a directory at the specified path.

   - Parameters:
      - path: The directory path to create
      - createIntermediates: Whether to create intermediate directories
      - attributes: Optional file attributes to set on the created directory
   - Throws: `FileSystemError.writeError` if the directory cannot be created
             `FileSystemError.pathAlreadyExists` if a file already exists at the path
   */
  public func createDirectory(
    at path: FilePath,
    createIntermediates: Bool=true,
    attributes: FileAttributes?=nil
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemError.invalidPath(
        path: path.path,
        reason: "Empty path provided"
      )
    }

    let url=URL(fileURLWithPath: path.path)

    // Check if a file (not directory) already exists at this path
    if fileManager.fileExists(atPath: path.path) {
      var isDir: ObjCBool=false
      fileManager.fileExists(atPath: path.path, isDirectory: &isDir)

      if !isDir.boolValue {
        await logger.warning(
          "Path exists but is not a directory: \(path.path)",
          context: FileSystemLogContext(
            operation: "createDirectory",
            path: path.path,
            source: "FileSystemService"
          )
        )
        throw FileSystemError.pathAlreadyExists(path: path.path)
      } else if !createIntermediates {
        // Directory already exists, which is fine
        await logger.debug(
          "Directory already exists at \(path.path)",
          context: FileSystemLogContext(
            operation: "createDirectory",
            path: path.path,
            source: "FileSystemService"
          )
        )
        return
      }
    }

    do {
      // Convert our FileAttributes to the format expected by FileManager
      var fileManagerAttributes: [FileAttributeKey: Any]?

      if let attributes {
        fileManagerAttributes=[:]

        // Map the attributes to FileManager's expected format
        if attributes.creationDate != Date(timeIntervalSince1970: 0) {
          fileManagerAttributes?[.creationDate]=attributes.creationDate
        }

        if attributes.modificationDate != Date(timeIntervalSince1970: 0) {
          fileManagerAttributes?[.modificationDate]=attributes.modificationDate
        }

        if attributes.permissions != 0 {
          fileManagerAttributes?[.posixPermissions]=Int16(attributes.permissions)
        }

        if attributes.ownerID != 0 {
          fileManagerAttributes?[.ownerAccountID]=NSNumber(value: attributes.ownerID)
        }

        if attributes.groupID != 0 {
          fileManagerAttributes?[.groupOwnerAccountID]=NSNumber(value: attributes.groupID)
        }

        // Note: Extended attributes would need a separate call to set them,
        // as they're not supported directly by the createDirectory API
      }

      try fileManager.createDirectory(
        at: url,
        withIntermediateDirectories: createIntermediates,
        attributes: fileManagerAttributes
      )

      // If we have any extended attributes, set them after creation
      if let attributes, !attributes.safeExtendedAttributes.isEmpty {
        for (key, value) in attributes.safeExtendedAttributes {
          // Convert the SafeAttributeValue to a Foundation-compatible type
          if let data=convertSafeAttributeToData(value) {
            // Create a local var to hold any error that occurs
            var setxattrError: Error?

            // Use a synchronous closure for withUnsafeFileSystemRepresentation
            url.withUnsafeFileSystemRepresentation { fileSystemPath in
              // Set the extended attribute using the low-level C API
              let result=setxattr(
                fileSystemPath,
                key,
                (data as NSData).bytes,
                data.count,
                0,
                0
              )

              if result != 0 {
                let error=errno
                setxattrError=FileSystemError.writeError(
                  path: path.path,
                  reason: String(cString: strerror(error))
                )
              }
            }

            // Now check if there was an error and log it asynchronously
            if let error=setxattrError {
              await logger.error(
                "Failed to set extended attribute \(key) on \(path.path): \(error.localizedDescription)",
                context: FileSystemLogContext(
                  operation: "createDirectory",
                  path: path.path,
                  source: "FileSystemService"
                ).withUpdatedMetadata(LogMetadataDTOCollection().withPrivate(
                  key: "error",
                  value: error.localizedDescription
                ))
              )
              throw error
            }
          }
        }
      }

      await logger.debug(
        "Created directory at \(path.path)",
        context: FileSystemLogContext(
          operation: "createDirectory",
          path: path.path,
          source: "FileSystemService"
        )
      )
    } catch {
      await logger.error(
        "Failed to create directory at \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "createDirectory",
          path: path.path,
          source: "FileSystemService"
        ).withUpdatedMetadata(LogMetadataDTOCollection().withPrivate(
          key: "error",
          value: error.localizedDescription
        ))
      )
      throw FileSystemError.writeError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Converts a SafeAttributeValue to Data for use with extended attributes.

   - Parameter value: The SafeAttributeValue to convert
   - Returns: Data representation if possible, nil otherwise
   */
  private func convertSafeAttributeToData(_ value: SafeAttributeValue) -> Data? {
    switch value {
      case let .string(strValue):
        return strValue.data(using: .utf8)
      case let .int(intValue):
        return withUnsafeBytes(of: intValue) { Data($0) }
      case let .uint(uintValue):
        return withUnsafeBytes(of: uintValue) { Data($0) }
      case let .int64(int64Value):
        return withUnsafeBytes(of: int64Value) { Data($0) }
      case let .uint64(uint64Value):
        return withUnsafeBytes(of: uint64Value) { Data($0) }
      case let .bool(boolValue):
        return withUnsafeBytes(of: boolValue) { Data($0) }
      case let .date(dateValue):
        return withUnsafeBytes(of: dateValue.timeIntervalSince1970) { Data($0) }
      case let .double(doubleValue):
        return withUnsafeBytes(of: doubleValue) { Data($0) }
      case let .data(dataValue):
        return dataValue
      case let .url(urlValue):
        return urlValue.absoluteString.data(using: .utf8)
      case .array, .dictionary:
        // These would need more complex serialization (e.g., JSON)
        do {
          let encoder=JSONEncoder()
          let data=try encoder.encode(String(describing: value))
          return data
        } catch {
          return nil
        }
    }
  }

  /**
   Checks if a directory is empty.

   - Parameter path: The directory path to check
   - Returns: Whether the directory is empty
   - Throws: `FileSystemError.invalidPath` if the path is invalid
             `FileSystemError.pathNotFound` if the directory does not exist
             `FileSystemError.invalidPath` if the path is not a directory
             `FileSystemError.readError` if the directory cannot be read
   */
  public func isDirectoryEmpty(at path: FilePath) async throws -> Bool {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Empty path provided"
      )
    }

    // Check if the path exists
    if !fileManager.fileExists(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Check if the path is a directory
    var isDir: ObjCBool=false
    fileManager.fileExists(atPath: path.path, isDirectory: &isDir)

    if !isDir.boolValue {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Path is not a directory"
      )
    }

    do {
      let contents=try fileManager.contentsOfDirectory(atPath: path.path)
      let isEmpty=contents.isEmpty

      await logger.debug(
        "Directory at \(path.path) is \(isEmpty ? "empty" : "not empty")",
        context: FileSystemLogContext(
          operation: "isDirectoryEmpty",
          path: path.path,
          source: "FileSystemService"
        )
      )

      return isEmpty
    } catch {
      await logger.error(
        "Failed to check if directory is empty at \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "isDirectoryEmpty",
          path: path.path,
          source: "FileSystemService"
        ).withUpdatedMetadata(LogMetadataDTOCollection().withPrivate(
          key: "error",
          value: error.localizedDescription
        ))
      )
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }
}
