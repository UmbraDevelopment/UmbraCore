import Foundation
import UmbraCoreTypes

// Default implementations for XPCDataHandlingProtocol
extension XPCDataHandlingProtocol {
  /// Convert Data to SecureBytes
  public func convertDataToSecureBytes(_ data: Data) -> SecureBytes {
    let dataBytes=[UInt8](data)
    return SecureBytes(bytes: dataBytes)
  }

  /// Convert SecureBytes to Data
  public func convertSecureBytesToData(_ secureBytes: SecureBytes) -> Data {
    var data=Data()

    // Access the bytes using withUnsafeBytes since there's no direct bytes property
    secureBytes.withUnsafeBytes { rawBuffer in
      data=Data(rawBuffer)
    }

    return data
  }

  /// Convert byte array to SecureBytes
  public func convertBytesToSecureBytes(_ bytes: [UInt8]) -> SecureBytes {
    SecureBytes(bytes: bytes)
  }

  /// Convert SecureBytes to byte array
  public func convertSecureBytesToBytes(_ secureBytes: SecureBytes) -> [UInt8] {
    var bytes=[UInt8]()

    // Access the bytes using withUnsafeBytes since there's no direct bytes property
    secureBytes.withUnsafeBytes { rawBuffer in
      bytes=Array(rawBuffer)
    }

    return bytes
  }

  /// Convert byte array to Data
  public func convertBytesToData(_ bytes: [UInt8]) -> Data {
    Data(bytes)
  }

  /// Convert Data to byte array
  public func convertDataToBytes(_ data: Data) -> [UInt8] {
    [UInt8](data)
  }
}
