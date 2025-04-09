import Foundation

/**
 # Extended Attribute DTO
 
 A data transfer object representing an extended attribute for a file or directory.
 
 Extended attributes are name-value pairs associated with filesystem objects (files, 
 directories, symlinks, etc). They are used to store metadata not interpreted by the 
 filesystem, and are specific to the user or application.
 
 ## Alpha Dot Five Architecture
 
 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Implements Sendable for safe concurrent access
 - Provides clear, well-documented properties
 - Uses British spelling in documentation
 */
public struct ExtendedAttributeDTO: Sendable, Equatable {
    /// Name of the extended attribute
    public let name: String
    
    /// Data value of the extended attribute
    public let data: Data
    
    /**
     Creates a new extended attribute DTO.
     
     - Parameters:
        - name: Name of the extended attribute
        - data: Data value of the extended attribute
     */
    public init(name: String, data: Data) {
        self.name = name
        self.data = data
    }
    
    /**
     Creates a new extended attribute DTO with a string value.
     
     - Parameters:
        - name: Name of the extended attribute
        - stringValue: String value to be converted to data
        - encoding: String encoding to use
     */
    public init?(name: String, stringValue: String, encoding: String.Encoding = .utf8) {
        guard let data = stringValue.data(using: encoding) else {
            return nil
        }
        
        self.name = name
        self.data = data
    }
    
    /**
     Gets the string value of this extended attribute.
     
     - Parameter encoding: String encoding to use
     - Returns: String value if the data can be converted, nil otherwise
     */
    public func stringValue(using encoding: String.Encoding = .utf8) -> String? {
        return String(data: data, encoding: encoding)
    }
}
