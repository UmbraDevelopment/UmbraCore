import ErrorHandlingDomains
import SecurityProtocolsCore
import UmbraCoreTypes

/// Type adapter that converts between different crypto service implementations
/// This allows us to adapt between different implementations of crypto services
/// without requiring them to directly implement each other's interfaces
public struct CryptoServiceTypeAdapter<
  Adaptee: CryptoServiceProtocol &
    Sendable
>: CryptoServiceProtocol {
  // MARK: - Properties

  /// The adaptee being wrapped
  private let adaptee: Adaptee

  /// Transformation functions for custom type conversions
  private let transformations: Transformations

  // MARK: - Initialization

  /// Create a new adapter wrapping an existing crypto service
  /// - Parameters:
  ///   - adaptee: The crypto service to adapt
  ///   - transformations: Optional custom transformations for adapting types
  public init(
    adaptee: Adaptee,
    transformations: Transformations=Transformations()
  ) {
    self.adaptee=adaptee
    self.transformations=transformations
  }

  // MARK: - CryptoServiceProtocol Implementation

  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityError> {
    let transformedData=transformations.transformInputData?(data) ?? data
    let transformedKey=transformations.transformInputKey?(key) ?? key

    let result=await adaptee.encrypt(data: transformedData, using: transformedKey)

    return result.map { transformations.transformOutputData?($0) ?? $0 }
  }

  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityError> {
    let transformedData=transformations.transformInputData?(data) ?? data
    let transformedKey=transformations.transformInputKey?(key) ?? key

    let result=await adaptee.decrypt(data: transformedData, using: transformedKey)

    return result.map { transformations.transformOutputData?($0) ?? $0 }
  }

  public func hash(data: SecureBytes) async -> Result<SecureBytes, SecurityError> {
    let transformedData=transformations.transformInputData?(data) ?? data

    let result=await adaptee.hash(data: transformedData)

    return result.map { transformations.transformOutputData?($0) ?? $0 }
  }

  public func generateKey() async -> Result<SecureBytes, SecurityError> {
    let result=await adaptee.generateKey()

    return result.map { transformations.transformOutputKey?($0) ?? $0 }
  }

  public func verify(
    data: SecureBytes,
    against hash: SecureBytes
  ) async -> Result<Bool, SecurityError> {
    let transformedData=transformations.transformInputData?(data) ?? data
    let transformedHash=transformations.transformInputData?(hash) ?? hash

    return await adaptee.verify(data: transformedData, against: transformedHash)
  }

  public func generateRandomData(length: Int) async -> Result<SecureBytes, SecurityError> {
    let result=await adaptee.generateRandomData(length: length)

    return result.map { transformations.transformOutputData?($0) ?? $0 }
  }

  // MARK: - New required methods

  public func encryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityError> {
    let transformedData=transformations.transformInputData?(data) ?? data
    let transformedKey=transformations.transformInputKey?(key) ?? key

    return await adaptee.encryptSymmetric(
      data: transformedData,
      key: transformedKey,
      config: config
    )
  }

  public func decryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityError> {
    let transformedData=transformations.transformInputData?(data) ?? data
    let transformedKey=transformations.transformInputKey?(key) ?? key

    return await adaptee.decryptSymmetric(
      data: transformedData,
      key: transformedKey,
      config: config
    )
  }

  public func encryptAsymmetric(
    data: SecureBytes,
    publicKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityError> {
    let transformedData=transformations.transformInputData?(data) ?? data
    let transformedKey=transformations.transformInputKey?(publicKey) ?? publicKey

    return await adaptee.encryptAsymmetric(
      data: transformedData,
      publicKey: transformedKey,
      config: config
    )
  }

  public func decryptAsymmetric(
    data: SecureBytes,
    privateKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityError> {
    let transformedData=transformations.transformInputData?(data) ?? data
    let transformedKey=transformations.transformInputKey?(privateKey) ?? privateKey

    return await adaptee.decryptAsymmetric(
      data: transformedData,
      privateKey: transformedKey,
      config: config
    )
  }

  public func hash(
    data: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityError> {
    let transformedData=transformations.transformInputData?(data) ?? data

    return await adaptee.hash(
      data: transformedData,
      config: config
    )
  }

  // MARK: - Types

  /// Functions for transforming input and output types
  /// This allows customized adapting between different implementations
  public struct Transformations: Sendable {
    /// Transform input data before passing to the adapted service
    public let transformInputData: (@Sendable (SecureBytes) -> SecureBytes)?

    /// Transform input keys before passing to the adapted service
    public let transformInputKey: (@Sendable (SecureBytes) -> SecureBytes)?

    /// Transform input signatures before passing to the adapted service
    public let transformInputSignature: (@Sendable (SecureBytes) -> SecureBytes)?

    /// Transform output data after receiving from the adapted service
    public let transformOutputData: (@Sendable (SecureBytes) -> SecureBytes)?

    /// Transform output keys after receiving from the adapted service
    public let transformOutputKey: (@Sendable (SecureBytes) -> SecureBytes)?

    /// Transform output signatures after receiving from the adapted service
    public let transformOutputSignature: (@Sendable (SecureBytes) -> SecureBytes)?

    /// Transform errors if needed between the wrapped and exposed service
    public let transformError: (@Sendable (SecurityError) -> SecurityError)?

    /// Initialize a new set of transformations
    ///
    /// - Parameters:
    ///   - transformInputData: Transform input data
    ///   - transformInputKey: Transform input keys
    ///   - transformInputSignature: Transform input signatures
    ///   - transformOutputData: Transform output data
    ///   - transformOutputKey: Transform output keys
    ///   - transformOutputSignature: Transform output signatures
    ///   - transformError: Transform errors
    public init(
      transformInputData: (@Sendable (SecureBytes) -> SecureBytes)?=nil,
      transformInputKey: (@Sendable (SecureBytes) -> SecureBytes)?=nil,
      transformInputSignature: (@Sendable (SecureBytes) -> SecureBytes)?=nil,
      transformOutputData: (@Sendable (SecureBytes) -> SecureBytes)?=nil,
      transformOutputKey: (@Sendable (SecureBytes) -> SecureBytes)?=nil,
      transformOutputSignature: (@Sendable (SecureBytes) -> SecureBytes)?=nil,
      transformError: (@Sendable (SecurityError) -> SecurityError)?=nil
    ) {
      self.transformInputData=transformInputData
      self.transformInputKey=transformInputKey
      self.transformInputSignature=transformInputSignature
      self.transformOutputData=transformOutputData
      self.transformOutputKey=transformOutputKey
      self.transformOutputSignature=transformOutputSignature
      self.transformError=transformError
    }
  }
}
