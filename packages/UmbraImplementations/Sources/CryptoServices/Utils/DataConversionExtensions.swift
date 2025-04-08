import Foundation
import SecurityCoreInterfaces
import UmbraErrors

// Only define these extensions if they don't already exist elsewhere
#if !EXTENSIONS_DEFINED
/// Extensions to help with conversion between Data and [UInt8]
extension Data {
    /// Convert Data to [UInt8] array
    public var bytes: [UInt8] {
        return [UInt8](self)
    }
    
    /// Initialize Data from [UInt8] array
    public init(bytes: [UInt8]) {
        self.init(bytes)
    }
}

/// Extensions to help with conversion between [UInt8] and Data
extension Array where Element == UInt8 {
    /// Convert [UInt8] array to Data
    public var data: Data {
        return Data(self)
    }
}
#endif

/// Extension to SecureStorageProtocol to provide Data-based convenience methods
extension SecureStorageProtocol {
    /// Stores data securely with the given identifier.
    /// - Parameters:
    ///   - data: The data to store as a Data object.
    ///   - identifier: A string identifier for the stored data.
    /// - Returns: Success or an error.
    public func storeData(_ data: Data, withIdentifier identifier: String) async
        -> Result<Void, SecurityStorageError> {
        return await storeData(Array(data), withIdentifier: identifier)
    }
    
    /// Retrieves data securely by its identifier.
    /// - Parameter identifier: A string identifying the data to retrieve.
    /// - Returns: The retrieved data as a Data object or an error.
    public func retrieveData(withIdentifier identifier: String) async
        -> Result<Data, SecurityStorageError> {
        let result = await retrieveData(withIdentifier: identifier)
        switch result {
        case .success(let bytes):
            return .success(Data(bytes))
        case .failure(let error):
            return .failure(error)
        }
    }
}
