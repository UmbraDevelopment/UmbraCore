import Foundation
import FileSystemInterfaces
import FileSystemTypes
import LoggingTypes

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
        - name: The name of the attribute
        - value: The value to set
        - path: The path of the file or directory
     - Throws: `FileSystemError.invalidPath` if the path is invalid
               `FileSystemError.pathNotFound` if the file does not exist
               `FileSystemError.writeError` if the attribute cannot be set
     */
    public func setExtendedAttribute(
        name: String,
        value: [UInt8],
        at path: FilePath
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
        
        do {
            let data = Data(value)
            try data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Void in
                let result = setxattr(
                    path.path,
                    name,
                    pointer.baseAddress,
                    data.count,
                    0,  // Position (0 for entire attribute)
                    0   // Options (0 for default)
                )
                
                if result == -1 {
                    throw NSError(
                        domain: NSPOSIXErrorDomain,
                        code: Int(errno),
                        userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))]
                    )
                }
            }
            
            await logger.debug("Set extended attribute '\(name)' on \(path.path)", metadata: nil)
        } catch {
            await logger.error("Failed to set extended attribute '\(name)' on \(path.path): \(error.localizedDescription)", metadata: nil)
            throw FileSystemInterfaces.FileSystemError.writeError(
                path: path.path,
                reason: "Failed to set extended attribute: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Gets an extended attribute from a file or directory.
     
     - Parameters:
        - name: The name of the attribute
        - path: The path of the file or directory
     - Returns: The attribute value
     - Throws: `FileSystemError.invalidPath` if the path or name is invalid
               `FileSystemError.pathNotFound` if the file does not exist
               `FileSystemError.readError` if the attribute cannot be read
               `FileSystemError.readError` if the attribute does not exist
     */
    public func getExtendedAttribute(
        name: String,
        at path: FilePath
    ) async throws -> [UInt8] {
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
            // First, determine the size of the attribute
            let size = getxattr(path.path, name, nil, 0, 0, 0)
            
            if size == -1 {
                let error = errno
                if error == ENOATTR {
                    throw FileSystemInterfaces.FileSystemError.readError(
                        path: path.path,
                        reason: "Extended attribute '\(name)' does not exist"
                    )
                } else {
                    throw NSError(
                        domain: NSPOSIXErrorDomain,
                        code: Int(error),
                        userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(error))]
                    )
                }
            }
            
            // Allocate a buffer of the right size
            var data = Data(count: size)
            
            // Get the attribute value
            let result = data.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> Int in
                return getxattr(
                    path.path,
                    name,
                    pointer.baseAddress,
                    size,
                    0,  // Position (0 for entire attribute)
                    0   // Options (0 for default)
                )
            }
            
            if result == -1 {
                throw NSError(
                    domain: NSPOSIXErrorDomain,
                    code: Int(errno),
                    userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))]
                )
            }
            
            await logger.debug("Read extended attribute '\(name)' from \(path.path)", metadata: nil)
            
            return [UInt8](data)
        } catch let fsError as FileSystemInterfaces.FileSystemError {
            // Rethrow FileSystemError directly
            throw fsError
        } catch {
            await logger.error("Failed to get extended attribute '\(name)' from \(path.path): \(error.localizedDescription)", metadata: nil)
            throw FileSystemInterfaces.FileSystemError.readError(
                path: path.path,
                reason: "Failed to read extended attribute: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Removes an extended attribute from a file or directory.
     
     - Parameters:
        - name: The name of the attribute
        - path: The path of the file or directory
     - Throws: `FileSystemError.invalidPath` if the path or name is invalid
               `FileSystemError.pathNotFound` if the file does not exist
               `FileSystemError.writeError` if the attribute cannot be removed
     */
    public func removeExtendedAttribute(
        name: String,
        at path: FilePath
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
        
        do {
            let result = removexattr(path.path, name, 0)
            
            if result == -1 {
                if errno == ENOATTR {
                    // Attribute doesn't exist, which is fine for removal
                    await logger.debug("Extended attribute '\(name)' already did not exist on \(path.path)", metadata: nil)
                    return
                }
                
                throw NSError(
                    domain: NSPOSIXErrorDomain,
                    code: Int(errno),
                    userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))]
                )
            }
            
            await logger.debug("Removed extended attribute '\(name)' from \(path.path)", metadata: nil)
        } catch let fsError as FileSystemInterfaces.FileSystemError {
            // Rethrow FileSystemError directly
            throw fsError
        } catch {
            await logger.error("Failed to remove extended attribute '\(name)' from \(path.path): \(error.localizedDescription)", metadata: nil)
            throw FileSystemInterfaces.FileSystemError.writeError(
                path: path.path,
                reason: "Failed to remove extended attribute: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Lists all extended attributes of a file or directory.
     
     - Parameter path: The path of the file or directory
     - Returns: Array of attribute names
     - Throws: `FileSystemError.invalidPath` if the path is invalid
               `FileSystemError.pathNotFound` if the file does not exist
               `FileSystemError.readError` if the attributes cannot be listed
     */
    public func listExtendedAttributes(
        at path: FilePath
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
        
        do {
            // First, determine the size needed for the attribute list
            let size = listxattr(path.path, nil, 0, 0)
            
            if size == -1 {
                throw NSError(
                    domain: NSPOSIXErrorDomain,
                    code: Int(errno),
                    userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))]
                )
            }
            
            // If size is 0, there are no attributes
            if size == 0 {
                return []
            }
            
            // Allocate a buffer of the right size
            var namebuf = [CChar](repeating: 0, count: size)
            
            // Get the attribute names
            let result = listxattr(path.path, &namebuf, size, 0)
            
            if result == -1 {
                throw NSError(
                    domain: NSPOSIXErrorDomain,
                    code: Int(errno),
                    userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))]
                )
            }
            
            // Parse the result into an array of strings
            // The format is a series of null-terminated strings
            var names = [String]()
            var start = 0
            
            for i in 0..<size {
                if namebuf[i] == 0 {
                    let nameData = Data(bytes: &namebuf[start], count: i - start)
                    if let name = String(data: nameData, encoding: .utf8) {
                        names.append(name)
                    }
                    start = i + 1
                }
            }
            
            await logger.debug("Listed \(names.count) extended attributes on \(path.path)", metadata: nil)
            
            return names
        } catch let fsError as FileSystemInterfaces.FileSystemError {
            // Rethrow FileSystemError directly
            throw fsError
        } catch {
            await logger.error("Failed to list extended attributes on \(path.path): \(error.localizedDescription)", metadata: nil)
            throw FileSystemInterfaces.FileSystemError.readError(
                path: path.path,
                reason: "Failed to list extended attributes: \(error.localizedDescription)"
            )
        }
    }
}
