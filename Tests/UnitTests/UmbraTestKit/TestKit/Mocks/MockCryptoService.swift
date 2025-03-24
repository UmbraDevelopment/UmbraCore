import CryptoTypes
import CryptoTypesProtocols
import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

public actor MockCryptoService: SecurityProtocolsCore.CryptoServiceProtocol {
  private var encryptedData: [String: Data]=[:]
  private var decryptedData: [String: Data]=[:]

  public init() {}

  // MARK: - CryptoServiceProtocol Methods

  public func encrypt(
    data: UmbraCoreTypes.SecureBytes,
    using _: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data) // Mock implementation just returns the data
  }

  public func decrypt(
    data: UmbraCoreTypes.SecureBytes,
    using _: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data) // Mock implementation just returns the data
  }

  public func generateKey() async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let bytes=Array(repeating: UInt8(0), count: 32)
    return .success(UmbraCoreTypes.SecureBytes(bytes: bytes))
  }

  public func hash(
    data _: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let bytes=Array(repeating: UInt8(0), count: 32)
    return .success(UmbraCoreTypes.SecureBytes(bytes: bytes))
  }

  public func verify(
    data _: UmbraCoreTypes.SecureBytes,
    against _: UmbraCoreTypes
      .SecureBytes
  ) async -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(true)
  }

  public func encryptSymmetric(
    data: UmbraCoreTypes.SecureBytes,
    key _: UmbraCoreTypes.SecureBytes,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data)
  }

  public func decryptSymmetric(
    data: UmbraCoreTypes.SecureBytes,
    key _: UmbraCoreTypes.SecureBytes,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data)
  }

  public func encryptAsymmetric(
    data: UmbraCoreTypes.SecureBytes,
    publicKey _: UmbraCoreTypes.SecureBytes,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data)
  }

  public func decryptAsymmetric(
    data: UmbraCoreTypes.SecureBytes,
    privateKey _: UmbraCoreTypes.SecureBytes,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data)
  }

  public func hash(
    data _: UmbraCoreTypes.SecureBytes,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let bytes=Array(repeating: UInt8(0), count: 32)
    return .success(UmbraCoreTypes.SecureBytes(bytes: bytes))
  }

  public func sign(
    data _: UmbraCoreTypes.SecureBytes,
    privateKey _: UmbraCoreTypes.SecureBytes,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let bytes=Array(repeating: UInt8(0), count: 64)
    return .success(UmbraCoreTypes.SecureBytes(bytes: bytes))
  }

  public func verify(
    signature _: UmbraCoreTypes.SecureBytes,
    data _: UmbraCoreTypes.SecureBytes,
    publicKey _: UmbraCoreTypes.SecureBytes,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(true)
  }

  public func generateRandomData(length: Int) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let bytes=Array(repeating: UInt8(0), count: length)
    return .success(UmbraCoreTypes.SecureBytes(bytes: bytes))
  }

  // MARK: - Legacy Methods

  public func encrypt(_ data: Data, using key: Data, iv: Data) async throws -> Data {
    let identifier="\(key.hashValue):\(iv.hashValue)"
    encryptedData[identifier]=data
    return data // Mock implementation just returns the original data
  }

  public func decrypt(_ data: Data, using key: Data, iv: Data) async throws -> Data {
    let identifier="\(key.hashValue):\(iv.hashValue)"
    decryptedData[identifier]=data
    return data // Mock implementation just returns the original data
  }

  public func deriveKey(from password: String, salt: Data, iterations _: Int) async throws -> Data {
    // Mock implementation just returns a deterministic key based on inputs
    let combinedData=password.data(using: .utf8)! + salt
    return Data(combinedData.prefix(32))
  }

  public func generateSecureRandomKey(length: Int) async throws -> Data {
    // Mock implementation returns predictable data for testing
    Data(repeating: 0xAA, count: length)
  }

  public func generateHMAC(for _: Data, using _: Data) async throws -> Data {
    // Mock implementation returns predictable HMAC for testing
    Data(repeating: 0xBB, count: 32)
  }

  // Test helper methods
  public func setDecryptedData(_ data: Data, forKey key: Data, initializationVector: Data) async {
    let identifier="\(key.base64EncodedString()):\(initializationVector.base64EncodedString())"
    decryptedData[identifier]=data
  }

  public func reset() async {
    encryptedData.removeAll()
    decryptedData.removeAll()
  }
}
