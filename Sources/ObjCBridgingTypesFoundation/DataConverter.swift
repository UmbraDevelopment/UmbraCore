import Foundation

/// Utility class to handle conversions between byte arrays and Foundation types
public class DataConverter {
  /// Convert a byte array to NSData
  /// - Parameter bytes: Array of bytes to convert
  /// - Returns: An NSData representation of the bytes
  public static func convertToNSData(fromBytes bytes: [UInt8]) -> NSData {
    Data(bytes) as NSData
  }

  /// Convert NSData to a byte array
  /// - Parameter nsData: The NSData object to convert
  /// - Returns: Array of bytes
  public static func convertToBytes(fromNSData nsData: NSData) -> [UInt8] {
    let data = nsData as Data
    return [UInt8](data)
  }

  /// Execute a closure with NSData converted to Data
  /// - Parameters:
  ///   - nsData: The NSData to convert
  ///   - block: Closure to execute with the converted Data
  public static func withConvertedData(_ nsData: NSData, _ block: (Foundation.Data) -> Void) {
    block(nsData as Foundation.Data)
  }
}
