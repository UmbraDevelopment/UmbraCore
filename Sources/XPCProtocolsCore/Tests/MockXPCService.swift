import Foundation
import UmbraCoreTypes
import XPCProtocolsCore

/// A mock implementation of XPCServiceProtocolStandard for testing purposes
/// Replaces the deprecated DummyXPCService
@available(macOS 14.0, *)
public final class MockXPCService: XPCServiceProtocolStandard, XPCServiceProtocolBasic {
  public init() {}

  public static var protocolIdentifier: String {
    "com.umbra.test.xpc.service"
  }

  // MARK: - XPCServiceProtocolBasic Implementation

  public func ping() async -> Bool {
    true
  }

  public func getStatus() async -> XPCProtocolTypeDefs.ServiceStatusInfo {
    XPCProtocolTypeDefs.ServiceStatusInfo(
      status: XPCProtocolTypeDefs.ServiceStatus.operational.rawValue,
      details: "Test service is operational",
      protocolVersion: "1.0"
    )
  }

  public func generateRandomBytes(count: Int) async -> Result<Data, SecurityError> {
    // Generate random bytes for testing
    var bytes=[UInt8](repeating: 0, count: count)
    for i in 0..<count {
      bytes[i]=UInt8.random(in: 0...255)
    }
    return .success(Data(bytes))
  }

  // MARK: - XPCServiceProtocolStandard Implementation

  public func status() async -> Result<[String: Any], SecurityError> {
    let statusDict: [String: Any]=[
      "status": "active",
      "version": "1.0.0"
    ]
    return .success(statusDict)
  }

  public func getHardwareIdentifier() async -> Result<String, SecurityError> {
    let hardwareID="TEST-HARDWARE-ID-\(UUID().uuidString)"
    return .success(hardwareID)
  }

  public func getServiceVersion() async -> Result<String, SecurityError> {
    .success("1.0.0-test")
  }

  public func generateRandomData(length: Int) async -> Result<Data, SecurityError> {
    await generateRandomBytes(count: length)
  }

  public func synchroniseKeys(_ keys: [String: Data]) async
  -> Result<[String: Data], SecurityError> {
    // Just return the keys unchanged for testing
    .success(keys)
  }

  public func storeSecureData(key _: String, data _: Data) async -> Result<Bool, SecurityError> {
    .success(true)
  }

  public func retrieveSecureData(key: String) async -> Result<Data, SecurityError> {
    // Return some mock data
    let mockData="MockSecureData-\(key)".data(using: .utf8) ?? Data()
    return .success(mockData)
  }

  public func deleteSecureData(key _: String) async -> Result<Bool, SecurityError> {
    .success(true)
  }

  public func encryptSecureData(
    _ data: Data,
    keyIdentifier _: String
  ) async -> Result<Data, SecurityError> {
    // Just return the data unchanged for testing
    .success(data)
  }

  public func decryptSecureData(
    _ data: Data,
    keyIdentifier _: String
  ) async -> Result<Data, SecurityError> {
    // Just return the data unchanged for testing
    .success(data)
  }

  public func sign(_: Data, keyIdentifier _: String) async -> Result<Data, SecurityError> {
    // Return some mock signature
    let mockSignature=Data([0x01, 0x02, 0x03, 0x04])
    return .success(mockSignature)
  }

  public func verify(
    signature _: Data,
    for _: Data,
    keyIdentifier _: String
  ) async -> Result<Bool, SecurityError> {
    .success(true)
  }

  public func importKey(
    _: Data,
    keyType _: String,
    keyIdentifier: String?,
    metadata _: [String: Any]?
  ) async -> Result<String, SecurityError> {
    let identifier=keyIdentifier ?? "generated-\(UUID().uuidString)"
    return .success(identifier)
  }

  public func exportKey(
    _: String,
    format _: String
  ) async -> Result<Data, SecurityError> {
    // Return some mock key data
    let mockKeyData=Data([0x10, 0x20, 0x30, 0x40])
    return .success(mockKeyData)
  }

  public func deleteKey(_: String) async -> Result<Bool, SecurityError> {
    .success(true)
  }
}
