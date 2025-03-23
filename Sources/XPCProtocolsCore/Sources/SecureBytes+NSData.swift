import Foundation
import UmbraCoreTypes

/// Extensions for SecureBytes to work with NSData
extension SecureBytes {
  /// Create SecureBytes from NSData
  /// - Parameter nsData: NSData to convert
  /// - Returns: SecureBytes instance
  public init(nsData: NSData) {
    let bytes=nsData.bytes.bindMemory(to: UInt8.self, capacity: nsData.length)
    let buffer=UnsafeBufferPointer(start: bytes, count: nsData.length)
    self.init(bytes: Array(buffer))
  }

  /// Convert SecureBytes to NSData
  public var nsData: NSData {
    // Use withUnsafeBytes to safely access the raw bytes
    withUnsafeBytes { bytes in
      NSData(bytes: bytes.baseAddress!, length: bytes.count)
    }
  }
}
