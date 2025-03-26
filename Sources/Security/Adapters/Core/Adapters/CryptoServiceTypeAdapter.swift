import Errors // Import Errors module for SecurityProtocolError
import Protocols // Import for CryptoServiceProtocol
import SecurityInterfaces
import Types // Import Types for any DTOs
import UmbraCoreTypes

/// Protocol that any crypto service must implement to be adaptable
/// This provides the contract that adaptees must fulfill
public protocol CryptoServiceTypeAdapterProtocol: Sendable {
  /// Encrypt data using the specified key
  func encrypt(data: SecureBytes, key: SecureBytes) async
    -> Result<SecureBytes, SecurityProtocolError>

  /// Decrypt data using the specified key
  func decrypt(data: SecureBytes, key: SecureBytes) async
    -> Result<SecureBytes, SecurityProtocolError>

  /// Hash data using a default algorithm
  func hash(data: SecureBytes) async -> Result<SecureBytes, SecurityProtocolError>

  /// Verify if data matches an expected hash
  func verifyHash(data: SecureBytes, expectedHash: SecureBytes) async
    -> Result<Bool, SecurityProtocolError>
}

/// Adapts any type implementing the custom adapter protocol to CryptoServiceProtocol
/// This provides type safety while allowing implementation flexibility
public struct CryptoServiceTypeAdapter<
  Adaptee: CryptoServiceTypeAdapterProtocol
>: CryptoServiceProtocol {
  // MARK: - Properties

  /// The adaptee being wrapped
  private let adaptee: Adaptee

  // MARK: - Initialization

  /// Initialize with an adaptee
  /// - Parameter adaptee: The service to adapt
  public init(adaptee: Adaptee) {
    self.adaptee=adaptee
  }

  // MARK: - CryptoServiceProtocol Implementation

  /// Encrypt data using the specified key
  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    let transformedData=transformations.transformInputData?(data) ?? data
    let transformedKey=transformations.transformInputKey?(key) ?? key

    let result=await adaptee.encrypt(data: transformedData, key: transformedKey)
    return result.map { transformations.transformOutputData?($0) ?? $0 }
  }

  /// Decrypt data using the specified key
  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    let transformedData=transformations.transformInputData?(data) ?? data
    let transformedKey=transformations.transformInputKey?(key) ?? key

    let result=await adaptee.decrypt(data: transformedData, key: transformedKey)
    return result.map { transformations.transformOutputData?($0) ?? $0 }
  }

  public func hash(data: SecureBytes) async -> Result<SecureBytes, SecurityProtocolError> {
    let transformedData=transformations.transformInputData?(data) ?? data

    let result=await adaptee.hash(data: transformedData)
    return result.map { transformations.transformOutputData?($0) ?? $0 }
  }

  public func verifyHash(
    data: SecureBytes,
    expectedHash: SecureBytes
  ) async -> Result<Bool, SecurityProtocolError> {
    let transformedData=transformations.transformInputData?(data) ?? data
    let transformedHash=transformations.transformInputData?(expectedHash) ?? expectedHash

    let result=await adaptee.verifyHash(data: transformedData, expectedHash: transformedHash)
    return result
  }

  // MARK: - Private Properties

  private var transformations=ServiceTransformations()
}

/// Contains transformations that can be applied to data passing through the adapter
private struct ServiceTransformations: Sendable {
  /// Optional transformation for input data
  var transformInputData: ((@Sendable (SecureBytes) -> SecureBytes))?

  /// Optional transformation for input keys
  var transformInputKey: ((@Sendable (SecureBytes) -> SecureBytes))?

  /// Optional transformation for output data
  var transformOutputData: ((@Sendable (SecureBytes) -> SecureBytes))?
}
