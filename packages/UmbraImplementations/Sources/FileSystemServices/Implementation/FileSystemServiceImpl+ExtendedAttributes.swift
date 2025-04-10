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
     Sets an extended attribute on a file or directory.
     
     - Parameters:
        - data: The data to set
        - withName: The name of the extended attribute
        - forItemAtPath: The path of the file or directory
     - Throws: Error if the attribute cannot be set
     */
    func setExtendedAttribute(_ data: Data, withName name: String, forItemAtPath path: String) throws {
        let result = setxattr(path, name, (data as NSData).bytes, data.count, 0, 0)
        
        if result != 0 {
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            throw error
        }
    }
    
    /**
     Sets a string extended attribute on a file or directory.
     
     - Parameters:
        - name: The name of the extended attribute
        - value: The string value to set (nil to remove the attribute)
        - forItemAtPath: The path of the file or directory
     - Throws: Error if the attribute cannot be set or removed
     */
    func setExtendedAttribute(_ name: String, value: String?, forItemAtPath path: String) throws {
        if let stringValue = value {
            // Set the attribute with string data
            guard let data = stringValue.data(using: .utf8) else {
                throw NSError(domain: NSPOSIXErrorDomain, code: NSFileWriteInapplicableStringEncodingError, userInfo: nil)
            }
            try setExtendedAttribute(data, withName: name, forItemAtPath: path)
        } else {
            // Remove the attribute
            try removeExtendedAttribute(withName: name, fromItemAtPath: path)
        }
    }
    
    /**
     Gets an extended attribute from a file or directory.
     
     - Parameters:
        - withName: The name of the extended attribute
        - fromItemAtPath: The path of the file or directory
     - Returns: The attribute data
     - Throws: Error if the attribute cannot be retrieved
     */
    func getExtendedAttribute(withName name: String, fromItemAtPath path: String) throws -> Data {
        // First get the size of the attribute
        var bufferSize = getxattr(path, name, nil, 0, 0, 0)
        
        if bufferSize == -1 {
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            throw error
        }
        
        // Now get the actual attribute data
        var buffer = [UInt8](repeating: 0, count: Int(bufferSize))
        let result = getxattr(path, name, &buffer, bufferSize, 0, 0)
        
        if result == -1 {
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            throw error
        }
        
        return Data(buffer)
    }
    
    /**
     Lists all extended attributes for a file or directory.
     
     - Parameter atPath: The path of the file or directory
     - Returns: Array of attribute names
     - Throws: Error if the attributes cannot be listed
     */
    func listExtendedAttributes(atPath path: String) throws -> [String] {
        // Get the size of the attribute list
        var bufferSize = listxattr(path, nil, 0, 0)
        
        if bufferSize == -1 {
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            throw error
        }
        
        // If there are no attributes, return an empty array
        if bufferSize == 0 {
            return []
        }
        
        // Get the attribute list
        var buffer = [UInt8](repeating: 0, count: Int(bufferSize))
        let result = listxattr(path, &buffer, bufferSize, 0)
        
        if result == -1 {
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            throw error
        }
        
        // Convert the buffer to a string and split by null terminators
        let attributeString = String(bytes: buffer, encoding: .utf8)!
        return attributeString.split(separator: "\0").map { String($0) }
    }
}

// MARK: - Documentation

/**
 Extended attributes are key-value pairs that can be associated with files and
 directories in many file systems, providing a standardised way to store metadata.
 
 This extension only contains helper methods for the FileManager class and does not
 extend FileSystemServiceImpl directly to avoid conflicts with existing implementations
 in other extension files.
 */
