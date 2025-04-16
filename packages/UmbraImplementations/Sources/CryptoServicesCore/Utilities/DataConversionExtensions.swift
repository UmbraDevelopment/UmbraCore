import Foundation
import SecurityCoreInterfaces
import UmbraErrors

// UMBRA_EXTENSIONS_DEFINED should be defined in BuildConfig
// to prevent duplicate extensions

#if !UMBRA_EXTENSIONS_DEFINED

  /// Extensions to help with conversion between Data and [UInt8].
  extension Data {
    /// Convert Data to [UInt8] array.
    public var bytes: [UInt8] {
      [UInt8](self)
    }

    /// Initialise Data from [UInt8] array.
    public init(bytes: [UInt8]) {
      self.init(bytes)
    }

    /// Create a URL-safe Base64 representation.
    public var urlSafeBase64: String {
      base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
    }

    /// Initialise from a URL-safe Base64 string.
    ///
    /// - Parameter urlSafeBase64: The URL-safe Base64 encoded string.
    /// - Returns: Data if successful, nil if conversion fails.
    public static func from(urlSafeBase64: String) -> Data? {
      var base64=urlSafeBase64
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")

      // Add padding if needed.
      let remainder=base64.count % 4
      if remainder > 0 {
        base64 += String(repeating: "=", count: 4 - remainder)
      }

      return Data(base64Encoded: base64)
    }
  }

  /// Extensions to help with conversion between [UInt8] and Data.
  extension [UInt8] {
    /// Convert [UInt8] to Data.
    public var data: Data {
      Data(self)
    }

    /// Convert to a hexadecimal string representation.
    public var hexString: String {
      map { String(format: "%02x", $0) }.joined()
    }

    /// Initialise from a hexadecimal string.
    ///
    /// - Parameter hexString: The hexadecimal string.
    /// - Returns: Byte array if successful, nil if conversion fails.
    public static func from(hexString: String) -> [UInt8]? {
      let hexString=hexString.lowercased()

      // Check if string has valid length.
      let len=hexString.count
      if len % 2 != 0 {
        return nil
      }

      var result=[UInt8]()
      result.reserveCapacity(len / 2)

      // Convert each pair of characters to a byte.
      var index=hexString.startIndex
      for _ in 0..<(len / 2) {
        let nextIndex=hexString.index(index, offsetBy: 2)
        let byteString=hexString[index..<nextIndex]

        if let byte=UInt8(byteString, radix: 16) {
          result.append(byte)
        } else {
          return nil
        }

        index=nextIndex
      }

      return result
    }
  }

  /// Extensions for common error handling in security operations.
  extension SecurityStorageError {
    /// Creates an error from an optional error or result value.
    ///
    /// - Parameters:
    ///   - error: The source error, if any.
    ///   - result: Optional result value that might indicate an error condition.
    ///   - file: Source file where error occurred (automatically provided).
    ///   - line: Source line where error occurred (automatically provided).
    /// - Returns: The most appropriate SecurityStorageError.
    public static func from(
      error: Error?,
      result: Any?=nil,
      file: String=#file,
      line: Int=#line
    ) -> SecurityStorageError {
      if let error {
        let nsError=error as NSError

        // Check for specific error domains and codes.
        if nsError.domain == NSOSStatusErrorDomain {
          return .generalError(reason: "Security framework error: \(nsError.code)")
        } else if nsError.domain == NSPOSIXErrorDomain {
          return .generalError(reason: "System error: \(nsError.code)")
        }

        return .operationFailed(error.localizedDescription)
      }

      // If no error but also no result, it's a failure.
      if result == nil {
        return .generalError(reason: "Operation completed but no result was returned")
      }

      // Default to unknown error.
      return .generalError(reason: "Unknown error occurred")
    }
  }
#endif

/// Extension to SecureStorageProtocol to provide Data-based convenience methods.
extension SecureStorageProtocol {
  /// Stores data securely with the given identifier.
  ///
  /// - Parameters:
  ///   - data: The data to store as a Data object.
  ///   - identifier: A string identifier for the stored data.
  /// - Returns: Success or an error.
  public func storeData(_ data: Data, withIdentifier identifier: String) async
  -> Result<Void, SecurityStorageError> {
    await storeData(Array(data), withIdentifier: identifier)
  }

  /// Retrieves data securely by its identifier.
  ///
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

  /// Deletes data securely by its identifier.
  ///
  /// - Parameter identifier: A string identifying the data to delete.
  /// - Returns: Success or an error.
  public func deleteData(identifier: String) async
  -> Result<Void, SecurityStorageError> {
    await deleteData(withIdentifier: identifier)
  }
}
