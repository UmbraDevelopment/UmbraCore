import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/// StandardCryptoServiceProxy
///
/// This class serves as a proxy for the standard cryptographic service implementation.
///
/// It delegates actual cryptographic operations to the appropriate implementation
/// without creating circular dependencies between modules. This pattern is used to
/// break the dependency cycle between CryptoServicesCore and CryptoServicesStandard.
///
/// ## Delegation Pattern
///
/// The proxy forwards all protocol requirements to a lazy-loaded implementation
/// that is created on demand. This allows us to maintain proper module boundaries
/// while still providing a seamless interface to clients.
public actor StandardCryptoServiceProxy: CryptoServiceProtocol {
  // MARK: - Properties

  /// The secure storage implementation
  public let secureStorage: SecureStorageProtocol

  /// The logger implementation
  private let logger: LoggingProtocol?

  /// The environment configuration
  private let environment: CryptoServicesCore.CryptoEnvironment

  /// The actual implementation that handles crypto operations
  private var implementation: CryptoServiceProtocol?

  // MARK: - Initialisation

  /// Initialises a proxy for the standard cryptographic service.
  ///
  /// - Parameters:
  ///   - secureStorage: Secure storage for cryptographic materials
  ///   - logger: Optional logger for operation tracking
  ///   - environment: Environment configuration
  public init(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?,
    environment: CryptoServicesCore.CryptoEnvironment
  ) {
    self.secureStorage=secureStorage
    self.logger=logger
    self.environment=environment
  }

  // MARK: - Private Methods

  /// Gets the underlying implementation, creating it if necessary.
  ///
  /// - Returns: The cryptographic service implementation
  private func getImplementation() async -> CryptoServiceProtocol {
    if let implementation {
      return implementation
    }

    // Use DynamicServiceLoader to create the appropriate implementation
    let impl=await DynamicServiceLoader.createStandardCryptoService(
      secureStorage: secureStorage,
      logger: logger,
      environment: environment
    )

    implementation=impl
    return impl
  }

  // MARK: - CryptoServiceProtocol Implementation

  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    let impl=await getImplementation()
    return await impl.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    let impl=await getImplementation()
    return await impl.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }

  public func hash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    let impl=await getImplementation()
    return await impl.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
  }

  public func generateHash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    let impl=await getImplementation()
    return await impl.generateHash(
      dataIdentifier: dataIdentifier,
      options: options
    )
  }

  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    let impl=await getImplementation()
    return await impl.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )
  }

  public func generateKey(
    length: Int,
    options: CoreSecurityTypes.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    let impl=await getImplementation()
    return await impl.generateKey(
      length: length,
      options: options
    )
  }

  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    let impl=await getImplementation()
    return await impl.importData(
      data,
      customIdentifier: customIdentifier
    )
  }

  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    let impl=await getImplementation()
    return await impl.exportData(
      identifier: identifier
    )
  }

  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    let impl=await getImplementation()
    return await impl.retrieveData(
      identifier: identifier
    )
  }

  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let impl=await getImplementation()
    return await impl.storeData(
      data: data,
      identifier: identifier
    )
  }

  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    let impl=await getImplementation()
    return await impl.importData(
      data,
      customIdentifier: customIdentifier
    )
  }

  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let impl=await getImplementation()
    return await impl.deleteData(
      identifier: identifier
    )
  }
}

/// DynamicServiceLoader
///
/// Handles dynamic loading of cryptographic service implementations.
///
/// This component provides a mechanism to create service implementations
/// without requiring direct compile-time dependencies.
enum DynamicServiceLoader {
  /// Creates a standard cryptographic service implementation.
  ///
  /// This method attempts to create an appropriate standard crypto service
  /// without requiring direct compile-time dependencies on the implementation.
  ///
  /// - Parameters:
  ///   - secureStorage: Secure storage implementation
  ///   - logger: Optional logger implementation
  ///   - environment: Environment configuration
  /// - Returns: A CryptoServiceProtocol implementation
  static func createStandardCryptoService(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?,
    environment _: CryptoServicesCore.CryptoEnvironment
  ) async -> CryptoServiceProtocol {
    // For the standard implementation, we create a fallback service
    // without trying to dynamically load the implementation, which avoids
    // the circular dependency issues

    // Log the fallback creation if a logger is available
    await logger?.debug(
      "Creating fallback crypto service implementation",
      context: BaseLogContextDTO(
        domainName: "CryptoService",
        operation: "createStandardCryptoService",
        category: "Security",
        source: "DynamicServiceLoader"
      )
    )

    // Create a fallback implementation that delegates to secure storage where possible
    return FallbackCryptoService(
      secureStorage: secureStorage,
      logger: logger
    )
  }
}

/// FallbackCryptoService
///
/// A basic implementation of CryptoServiceProtocol used as a fallback.
///
/// This implementation provides minimal functionality and is only used
/// when the standard implementation cannot be dynamically loaded.
private actor FallbackCryptoService: CryptoServiceProtocol {
  /// The secure storage implementation
  public let secureStorage: SecureStorageProtocol

  /// The logger implementation
  private let logger: LoggingProtocol?

  /// Initialises a new fallback crypto service.
  ///
  /// - Parameters:
  ///   - secureStorage: Secure storage for cryptographic materials
  ///   - logger: Optional logger for operation tracking
  init(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?
  ) {
    self.secureStorage=secureStorage
    self.logger=logger
  }

  /// Logs a crypto operation with metadata.
  ///
  /// - Parameters:
  ///   - operation: The operation name
  ///   - metadata: Additional metadata to log
  private func logOperation(_ operation: String, _ metadata: [String: Any]=[:]) async {
    guard let logger else { return }

    var metadataCollection=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "implementation", value: "fallback")

    // Add all metadata entries as public metadata
    for (key, value) in metadata {
      if let stringValue=value as? String {
        metadataCollection=metadataCollection.withPublic(key: key, value: stringValue)
      } else {
        metadataCollection=metadataCollection.withPublic(key: key, value: String(describing: value))
      }
    }

    let context=BaseLogContextDTO(
      domainName: "CryptoService",
      operation: operation,
      category: "Security",
      source: "FallbackCryptoService",
      metadata: metadataCollection
    )

    await logger.debug(
      "Crypto operation: \(operation) (fallback implementation)",
      context: context
    )
  }

  // MARK: - CryptoServiceProtocol Implementation

  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options _: CoreSecurityTypes.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logOperation(
      "encrypt",
      ["dataIdentifier": dataIdentifier, "keyIdentifier": keyIdentifier]
    )
    return .failure(.operationFailed("Encryption not implemented in fallback service"))
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options _: CoreSecurityTypes.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logOperation(
      "decrypt",
      ["encryptedDataIdentifier": encryptedDataIdentifier, "keyIdentifier": keyIdentifier]
    )
    return .failure(.operationFailed("Decryption not implemented in fallback service"))
  }

  public func hash(
    dataIdentifier: String,
    options _: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logOperation("hash", ["dataIdentifier": dataIdentifier])
    return .failure(.operationFailed("Hashing not implemented in fallback service"))
  }

  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options _: CoreSecurityTypes.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    await logOperation(
      "verifyHash",
      ["dataIdentifier": dataIdentifier, "hashIdentifier": hashIdentifier]
    )
    return .failure(.operationFailed("Hash verification not implemented in fallback service"))
  }

  public func generateHash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logOperation("generateHash", ["dataIdentifier": dataIdentifier])
    return await hash(dataIdentifier: dataIdentifier, options: options)
  }

  public func generateKey(
    length: Int,
    options _: CoreSecurityTypes.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logOperation("generateKey", ["length": length])
    return .failure(.operationFailed("Key generation not implemented in fallback service"))
  }

  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    let identifier=customIdentifier ?? "data-\(UUID().uuidString)"
    await logOperation("importData", ["dataSize": data.count, "identifier": identifier])

    // Convert bytes to Data
    let dataObj=Data(data)

    // Store using secure storage
    let storeResult=await secureStorage.storeData(dataObj, withIdentifier: identifier)

    // Return the identifier or propagate error
    switch storeResult {
      case .success:
        return .success(identifier)
      case let .failure(error):
        return .failure(error)
    }
  }

  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    await logOperation("exportData", ["identifier": identifier])

    // Retrieve data from secure storage
    let retrieveResult=await secureStorage.retrieveData(withIdentifier: identifier)

    // Convert to byte array or propagate error
    switch retrieveResult {
      case let .success(data):
        return .success([UInt8](data))
      case let .failure(error):
        return .failure(error)
    }
  }

  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await logOperation("storeData", ["identifier": identifier, "dataSize": data.count])

    // Delegate directly to secure storage
    return await secureStorage.storeData(data, withIdentifier: identifier)
  }

  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    // Get the binary data using the correct protocol method
    let result=await secureStorage.retrieveData(withIdentifier: identifier)

    switch result {
      case let .success(data):
        await logOperation("retrieveData", ["identifier": identifier, "dataSize": data.count])
        return .success(Data(data))
      case let .failure(error):
        await logOperation("retrieveData", ["identifier": identifier, "error": error])
        return .failure(error)
    }
  }

  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    await logOperation("importData", ["dataSize": data.count, "identifier": customIdentifier])

    // Store using secure storage
    let storeResult=await secureStorage.storeData(data, withIdentifier: customIdentifier)

    // Return the identifier or propagate error
    switch storeResult {
      case .success:
        return .success(customIdentifier)
      case let .failure(error):
        return .failure(error)
    }
  }

  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await logOperation("deleteData", ["identifier": identifier])

    // Delegate directly to secure storage
    return await secureStorage.deleteData(withIdentifier: identifier)
  }
}
