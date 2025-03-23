import Core
import CoreTypesInterfaces

// TestSupport for Core module
import Foundation

/// Test support utilities for Core module
public enum CoreTestSupport {
  /// Creates a test instance with default values
  public static func createTestInstance() -> String {
    "Test Instance"
  }

  /// Creates a test BinaryData instance with random bytes
  public static func createTestBinaryData(length: Int=32) -> CoreTypesInterfaces.BinaryData {
    var bytes=[UInt8](repeating: 0, count: length)
    for i in 0..<length {
      bytes[i]=UInt8.random(in: 0...255)
    }
    return CoreTypesInterfaces.BinaryData(bytes: bytes)
  }
}
