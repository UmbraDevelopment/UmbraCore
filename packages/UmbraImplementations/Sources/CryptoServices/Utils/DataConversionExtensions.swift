import Foundation
import SecurityCoreInterfaces
import UmbraErrors
import BuildConfig

// UMBRA_EXTENSIONS_DEFINED should be defined in BuildConfig
// to prevent duplicate extensions

#if !UMBRA_EXTENSIONS_DEFINED
  /// Extensions to help with conversion between Data and [UInt8]
  extension Data {
    /// Convert Data to [UInt8] array
    public var bytes: [UInt8] {
      [UInt8](self)
    }

    /// Initialize Data from [UInt8] array
    public init(bytes: [UInt8]) {
      self.init(bytes)
    }
  }

  /// Extensions to help with conversion between [UInt8] and Data
  extension [UInt8] {
    /// Convert [UInt8] to Data
    public var data: Data {
      Data(self)
    }
    
    /// Convert to a hexadecimal string representation
    public var hexString: String {
      map { String(format: "%02x", $0) }.joined()
    }
  }
  
  /// Extensions for common error handling
  extension SecurityStorageError {
    /// Creates an error from an optional error or result value
    public static func from(
      error: Error?,
      result: Any? = nil,
      file: String = #file,
      line: Int = #line
    ) -> SecurityStorageError {
      if let specificError = error as? SecurityStorageError {
        return specificError
      }
      
      // Use the appropriate error factory method instead of direct initialisation
      return SecurityStorageError.operationFailed(
        error?.localizedDescription ?? "Unknown error",
        underlyingError: error
      )
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
    await storeData(Array(data), withIdentifier: identifier)
  }

  /// Retrieves data securely by its identifier.
  /// - Parameter identifier: A string identifying the data to retrieve.
  /// - Returns: The retrieved data as a Data object or an error.
  public func retrieveData(withIdentifier identifier: String) async
  -> Result<Data, SecurityStorageError> {
    let result=await retrieveData(withIdentifier: identifier)
    switch result {
      case let .success(bytes):
        return .success(Data(bytes))
      case let .failure(error):
        return .failure(error)
    }
  }
}
