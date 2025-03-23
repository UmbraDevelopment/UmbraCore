// Test support for SecurityInterfaces
import CoreTypesInterfaces
import Foundation
import SecurityBridge
import SecurityInterfaces
import SecurityInterfacesProtocols

/// Mock implementation of SecurityProviderProtocol for testing
public final class TestSecurityProviderImplementation: SecurityInterfacesProtocols
.SecurityProviderProtocol {
  public init() {}

  public func encrypt(
    _ data: CoreTypesInterfaces.BinaryData,
    key _: CoreTypesInterfaces.BinaryData
  ) async throws -> CoreTypesInterfaces.BinaryData {
    data // Mock implementation returns the original data
  }

  public func decrypt(
    _ data: CoreTypesInterfaces.BinaryData,
    key _: CoreTypesInterfaces.BinaryData
  ) async throws -> CoreTypesInterfaces.BinaryData {
    data // Mock implementation returns the original data
  }

  public func hash(
    _: CoreTypesInterfaces.BinaryData
  ) async throws -> CoreTypesInterfaces.BinaryData {
    // Return a fixed hash value for testing
    CoreTypesInterfaces.BinaryData(bytes: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  }

  public func generateKey(length: Int) async throws -> CoreTypesInterfaces.BinaryData {
    // Return a fixed key for testing
    CoreTypesInterfaces.BinaryData(bytes: Array(repeating: 0, count: length))
  }
}

/// Test utilities for SecurityInterfaces module
public enum SecurityInterfacesTestSupport {
  /// Creates a test security provider for testing
  public static func createTestSecurityProvider() -> any SecurityInterfacesProtocols
  .SecurityProviderProtocol {
    TestSecurityProviderImplementation()
  }

  /// Creates test binary data for testing
  public static func createTestBinaryData(length: Int=32) -> CoreTypesInterfaces.BinaryData {
    var bytes=[UInt8](repeating: 0, count: length)
    for i in 0..<length {
      bytes[i]=UInt8.random(in: 0...255)
    }
    return CoreTypesInterfaces.BinaryData(bytes: bytes)
  }
}
