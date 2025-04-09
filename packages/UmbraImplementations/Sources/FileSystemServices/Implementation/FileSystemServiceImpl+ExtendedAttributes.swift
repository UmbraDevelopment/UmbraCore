import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingTypes

// MARK: - FileManager Extended Attributes Extension

extension FileManager {
    /**
     Removes an extended attribute from a file or directory.
     
     - Parameters:
        - withName: The name of the extended attribute to remove
        - fromItemAtPath: The path of the file or directory
     - Throws: Error if the attribute cannot be removed
     */
    func removeExtendedAttribute(withName name: String, fromItemAtPath path: String) throws {
        let result = removexattr(path, name, 0)
        
        if result != 0 {
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            throw error
        }
    }
    
    /**
     Gets an extended attribute from a file or directory.
     
     - Parameters:
        - withName: The name of the extended attribute to get
        - fromItemAtPath: The path of the file or directory
     - Returns: The attribute data
     - Throws: Error if the attribute cannot be retrieved
     */
    func getExtendedAttribute(withName name: String, fromItemAtPath path: String) throws -> Data {
        // Get the size of the attribute
        let size = getxattr(path, name, nil, 0, 0, 0)
        
        if size == -1 {
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            throw error
        }
        
        // Create a buffer to hold the attribute data
        var data = Data(count: Int(size))
        
        // Get the attribute data
        let result = data.withUnsafeMutableBytes { bufferPtr in
            getxattr(path, name, bufferPtr.baseAddress, size, 0, 0)
        }
        
        if result == -1 {
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            throw error
        }
        
        return data
    }
    
    /**
     Sets an extended attribute on a file or directory.
     
     - Parameters:
        - data: The attribute data to set
        - withName: The name of the extended attribute
        - forItemAtPath: The path of the file or directory
        - options: Options for setting the attribute
     - Throws: Error if the attribute cannot be set
     */
    func setExtendedAttribute(
        _ data: Data,
        withName name: String,
        forItemAtPath path: String,
        options: Int32 = 0
    ) throws {
        let result = data.withUnsafeBytes { bufferPtr in
            setxattr(path, name, bufferPtr.baseAddress, data.count, 0, options)
        }
        
        if result != 0 {
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            throw error
        }
    }
    
    /**
     Lists all extended attributes for a file or directory.
     
     - Parameter path: The path of the file or directory
     - Returns: Array of attribute names
     - Throws: Error if the attributes cannot be listed
     */
    func listExtendedAttributes(atPath path: String) throws -> [String] {
        // Get the size needed for the attribute list
        var size = listxattr(path, nil, 0, 0)
        
        if size == -1 {
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            throw error
        }
        
        // If there are no attributes, return an empty array
        if size == 0 {
            return []
        }
        
        // Create a buffer to hold the attribute names
        var namebuf = [CChar](repeating: 0, count: Int(size))
        
        // Get the attribute names
        size = listxattr(path, &namebuf, size, 0)
        
        if size == -1 {
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            throw error
        }
        
        // Convert the C string list to Swift strings
        var attributes: [String] = []
        var start = 0
        
        for i in 0..<Int(size) {
            if namebuf[i] == 0 {
                if let attr = String(cString: namebuf[start..<i] + [0], encoding: .utf8) {
                    attributes.append(attr)
                }
                start = i + 1
            }
        }
        
        return attributes
    }
}

/**
 # Extended Attribute Operations Extension

 This extension provides operations for managing extended attributes on files and
 directories, allowing for custom metadata to be stored alongside file content.

 Extended attributes are key-value pairs that can be associated with files and
 directories in many file systems, providing a standardised way to store metadata.
 */
extension FileSystemServiceImpl {
  /**
   Sets an extended attribute on a file or directory.

   - Parameters:
      - path: The path of the file or directory
      - name: The name of the attribute
      - value: The value to set
   - Throws: `FileSystemError.invalidPath` if the path is invalid
             `FileSystemError.pathNotFound` if the file does not exist
             `FileSystemError.writeError` if the attribute cannot be set
   */
  public func setExtendedAttribute(
    at path: FilePath,
    name: String,
    value: SafeAttributeValue
  ) async throws {
    let metadata = LogMetadataDTOCollection()
      .withPrivate(key: "path", value: path.path)
      .withPrivate(key: "attributeName", value: name)
      
    await logger.debug(
      "Setting extended attribute",
      context: FileSystemLogContext(
        operation: "setExtendedAttribute",
        source: "FileSystemService",
        metadata: metadata
      )
    )

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

    do {
      let data = Data(value)
      try fileManager.setExtendedAttribute(data, withName: name, forItemAtPath: path.path)
      
      await logger.debug(
        "Set extended attribute",
        context: FileSystemLogContext(
          operation: "setExtendedAttribute",
          source: "FileSystemService",
          metadata: LogMetadataDTOCollection().withPrivate(key: "path", value: path.path)
        )
      )
    } catch {
      let errorMetadata = LogMetadataDTOCollection()
        .withPrivate(key: "path", value: path.path)
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPrivate(key: "errorMessage", value: error.localizedDescription)
        
      await logger.error(
        "Failed to set extended attribute",
        context: FileSystemLogContext(
          operation: "setExtendedAttribute",
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
   Gets an extended attribute from a file or directory.

   - Parameters:
      - path: The path of the file or directory
      - name: The name of the attribute
   - Returns: The attribute value
   - Throws: `FileSystemError.invalidPath` if the path or name is invalid
             `FileSystemError.pathNotFound` if the file does not exist
             `FileSystemError.readError` if the attribute cannot be read
             `FileSystemError.readError` if the attribute does not exist
   */
  public func getExtendedAttribute(
    at path: FilePath,
    name: String
  ) async throws -> SafeAttributeValue {
    let metadata = LogMetadataDTOCollection()
      .withPrivate(key: "path", value: path.path)
      .withPrivate(key: "attributeName", value: name)
      
    await logger.debug(
      "Getting extended attribute",
      context: FileSystemLogContext(
        operation: "getExtendedAttribute",
        source: "FileSystemService",
        metadata: metadata
      )
    )

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

    do {
      let data = try fileManager.getExtendedAttribute(withName: name, fromItemAtPath: path.path)
      
      await logger.debug(
        "Read extended attribute",
        context: FileSystemLogContext(
          operation: "getExtendedAttribute",
          source: "FileSystemService",
          metadata: LogMetadataDTOCollection().withPrivate(key: "path", value: path.path)
        )
      )
      
      return SafeAttributeValue(data: data)
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      // Rethrow FileSystemError directly
      throw fsError
    } catch {
      let errorMetadata = LogMetadataDTOCollection()
        .withPrivate(key: "path", value: path.path)
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPrivate(key: "errorMessage", value: error.localizedDescription)
        
      await logger.error(
        "Failed to read extended attribute",
        context: FileSystemLogContext(
          operation: "getExtendedAttribute",
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
   Lists all extended attributes on a file or directory.

   - Parameter path: The path of the file or directory
   - Returns: Array of attribute names
   - Throws: `FileSystemError.invalidPath` if the path is invalid
             `FileSystemError.pathNotFound` if the file does not exist
             `FileSystemError.readError` if the attributes cannot be listed
   */
  public func listExtendedAttributes(
    at path: FilePath
  ) async throws -> [String] {
    let metadata = LogMetadataDTOCollection()
      .withPrivate(key: "path", value: path.path)
      
    await logger.debug(
      "Listing extended attributes",
      context: FileSystemLogContext(
        operation: "listExtendedAttributes",
        source: "FileSystemService",
        metadata: metadata
      )
    )

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

    do {
      let attributes = try fileManager.listExtendedAttributes(atPath: path.path)
      
      let resultMetadata = LogMetadataDTOCollection()
        .withPrivate(key: "path", value: path.path)
        .withPublic(key: "count", value: "\(attributes.count)")
        
      await logger.debug(
        "Listed extended attributes",
        context: FileSystemLogContext(
          operation: "listExtendedAttributes",
          source: "FileSystemService",
          metadata: resultMetadata
        )
      )

      return attributes
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      // Rethrow FileSystemError directly
      throw fsError
    } catch {
      let errorMetadata = LogMetadataDTOCollection()
        .withPrivate(key: "path", value: path.path)
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPrivate(key: "errorMessage", value: error.localizedDescription)
        
      await logger.error(
        "Failed to list extended attributes",
        context: FileSystemLogContext(
          operation: "listExtendedAttributes",
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
}
