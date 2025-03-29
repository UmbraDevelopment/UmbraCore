import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

/// Default implementation of SecurityProviderProtocol
public final class SecurityProviderImpl: SecurityProviderProtocol {
  // MARK: - Properties

  /// Cryptographic service implementation
  public let cryptoService: CryptoServiceProtocol

  /// Key management service implementation
  public let keyManager: KeyManagementProtocol

  /// Core implementation that handles the actual security operations
  private let core: SecurityProviderCore

  // MARK: - Initialisation

  /// Initialise with specific implementations
  /// - Parameters:
  ///   - cryptoService: Implementation of CryptoServiceProtocol
  ///   - keyManager: Implementation of KeyManagementProtocol
  public init(
    cryptoService: CryptoServiceProtocol,
    keyManager: KeyManagementProtocol
  ) {
    self.cryptoService = cryptoService
    self.keyManager = keyManager
    core = SecurityProviderCore(
      cryptoService: cryptoService,
      keyManager: keyManager
    )
  }

  /// Convenience initialiser with default implementations
  public convenience init() async {
    // Use a factory method to create default implementations
    // without directly referencing the concrete types
    let defaultCryptoService = createDefaultCryptoService()
    let defaultKeyManager = await createDefaultKeyManager()

    self.init(
      cryptoService: defaultCryptoService,
      keyManager: defaultKeyManager
    )
  }

  // MARK: - Core Operation Methods

  /**
   Encrypts data with the specified configuration.

   - Parameter config: Configuration for the encryption operation
   - Returns: Result containing encrypted data or error
   */
  public func encrypt(config: SecurityConfigDTO) async -> SecurityResultDTO {
    // Extract data and key from config options
    guard
      let dataString = config.options["inputData"],
      let data = SecureBytes(base64Encoded: dataString)
    else {
      return SecurityResultDTO(
        status: .failure,
        error: SecurityError.invalidInput("Missing or invalid input data for encryption")
      )
    }

    // Extract key if provided
    var key: SecureBytes?
    if
      let keyString = config.options["key"],
      let keyData = SecureBytes(base64Encoded: keyString)
    {
      key = keyData
    }

    // Perform the encryption operation
    return await performSecureOperation(
      operation: .encrypt(data: data, key: key),
      config: config
    )
  }

  /**
   Decrypts data with the specified configuration.

   - Parameter config: Configuration for the decryption operation
   - Returns: Result containing decrypted data or error
   */
  public func decrypt(config: SecurityConfigDTO) async -> SecurityResultDTO {
    // Extract data and key from config options
    guard
      let dataString = config.options["ciphertext"],
      let data = SecureBytes(base64Encoded: dataString)
    else {
      return SecurityResultDTO(
        status: .failure,
        error: SecurityError.invalidInput("Missing or invalid input data for decryption")
      )
    }

    // Extract key if provided
    var key: SecureBytes?
    if
      let keyString = config.options["key"],
      let keyData = SecureBytes(base64Encoded: keyString)
    {
      key = keyData
    }

    // Perform the decryption operation
    return await performSecureOperation(
      operation: .decrypt(data: data, key: key),
      config: config
    )
  }

  /**
   Generates a cryptographic key with the specified configuration.

   - Parameter config: Configuration for the key generation operation
   - Returns: Result containing key identifier or error
   */
  public func generateKey(config: SecurityConfigDTO) async -> SecurityResultDTO {
    // Extract key size from config
    let keySize = config.keySize

    // Perform the key generation operation
    return await performSecureOperation(
      operation: .generateKey(size: keySize),
      config: config
    )
  }

  /**
   Securely stores data with the specified configuration.

   - Parameter config: Configuration for the secure storage operation
   - Returns: Result containing storage confirmation or error
   */
  public func secureStore(config: SecurityConfigDTO) async -> SecurityResultDTO {
    // Extract data and identifier from config options
    guard
      let dataString = config.options["data"],
      let data = SecureBytes(base64Encoded: dataString),
      let identifier = config.options["identifier"]
    else {
      return SecurityResultDTO(
        status: .failure,
        error: SecurityError.invalidInput("Missing or invalid parameters for secure storage")
      )
    }

    // Perform the secure store operation
    return await performSecureOperation(
      operation: .store(data: data, identifier: identifier),
      config: config
    )
  }

  /**
   Retrieves securely stored data with the specified configuration.

   - Parameter config: Configuration for the secure retrieval operation
   - Returns: Result containing retrieved data or error
   */
  public func secureRetrieve(config: SecurityConfigDTO) async -> SecurityResultDTO {
    // Extract identifier from config options
    guard let identifier = config.options["identifier"] else {
      return SecurityResultDTO(
        status: .failure,
        error: SecurityError.invalidInput("Missing identifier for secure retrieval")
      )
    }

    // Perform the secure retrieve operation
    return await performSecureOperation(
      operation: .retrieve(identifier: identifier),
      config: config
    )
  }

  /**
   Securely deletes stored data with the specified configuration.

   - Parameter config: Configuration for the secure deletion operation
   - Returns: Result containing deletion confirmation or error
   */
  public func secureDelete(config: SecurityConfigDTO) async -> SecurityResultDTO {
    // Extract identifier from config options
    guard let identifier = config.options["identifier"] else {
      return SecurityResultDTO(
        status: .failure,
        error: SecurityError.invalidInput("Missing identifier for secure deletion")
      )
    }

    // Perform the secure delete operation
    return await performSecureOperation(
      operation: .delete(identifier: identifier),
      config: config
    )
  }

  /**
   Creates a digital signature for data with the specified configuration.

   - Parameter config: Configuration for the digital signature operation
   - Returns: Result containing signature data or error
   */
  public func sign(config: SecurityConfigDTO) async -> SecurityResultDTO {
    // Extract data and key from config options
    guard
      let dataString = config.options["data"],
      let data = SecureBytes(base64Encoded: dataString)
    else {
      return SecurityResultDTO(
        status: .failure,
        error: SecurityError.invalidInput("Missing or invalid data for signing")
      )
    }

    // Extract key if provided
    var key: SecureBytes?
    if
      let keyString = config.options["key"],
      let keyData = SecureBytes(base64Encoded: keyString)
    {
      key = keyData
    }

    // Perform the signing operation
    return await performSecureOperation(
      operation: .sign(data: data, key: key),
      config: config
    )
  }

  /**
   Verifies a digital signature with the specified configuration.

   - Parameter config: Configuration for the signature verification operation
   - Returns: Result containing verification status or error
   */
  public func verify(config: SecurityConfigDTO) async -> SecurityResultDTO {
    // Extract data, signature, and key from config options
    guard
      let dataString = config.options["data"],
      let data = SecureBytes(base64Encoded: dataString),
      let signatureString = config.options["signature"],
      let signature = SecureBytes(base64Encoded: signatureString)
    else {
      return SecurityResultDTO(
        status: .failure,
        error: SecurityError
          .invalidInput("Missing or invalid parameters for signature verification")
      )
    }

    // Extract key if provided
    var key: SecureBytes?
    if
      let keyString = config.options["key"],
      let keyData = SecureBytes(base64Encoded: keyString)
    {
      key = keyData
    }

    // Perform the verification operation
    return await performSecureOperation(
      operation: .verify(data: data, signature: signature, key: key),
      config: config
    )
  }

  // MARK: - SecurityProviderProtocol Implementation

  /// Perform a secure operation with appropriate error handling
  /// - Parameters:
  ///   - operation: The security operation to perform
  ///   - config: Configuration options
  /// - Returns: Result of the operation
  public func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    await core.performSecureOperation(operation: operation, config: config)
  }

  /// Create a secure configuration with appropriate defaults
  /// - Parameter options: Optional dictionary of configuration options
  /// - Returns: A properly configured SecurityConfigDTO
  public func createSecureConfig(options: [String: Any]?) -> SecurityConfigDTO {
    core.createSecureConfig(options: options)
  }
}

// MARK: - Factory Methods

/// Create a default crypto service implementation
/// This breaks the direct dependency on SecurityCryptoServices
private func createDefaultCryptoService() -> CryptoServiceProtocol {
  // This would typically be CryptoServiceImpl() from the SecurityCryptoServices module
  // But since we can't import it directly, we'll use a runtime lookup approach

  // First try to dynamically load the class by name
  if
    let cryptoServiceClass = NSClassFromString(
      "SecurityCryptoServices.CryptoServiceImpl"
    ) as? NSObject.Type,
    let instance = cryptoServiceClass.init() as? CryptoServiceProtocol
  {
    return instance
  }

  // If dynamic loading fails, use a basic implementation that meets the protocol
  return BasicCryptoService()
}

/// Create a default key manager implementation
/// This breaks the direct dependency on SecurityKeyManagement
private func createDefaultKeyManager() async -> KeyManagementProtocol {
  // First try to load the KeyManagementActor implementation via factory method
  if
    let securityKeyManagementClass = NSClassFromString("SecurityKeyManagement.SecurityKeyManagement"),
    securityKeyManagementClass.responds(to: NSSelectorFromString("createKeyManager"))
  {
    // Using Objective-C runtime to call the asynchronous method
    // This is complex because we need to bridge between ObjC runtime and Swift async/await
    // Using a helper type KeyManagerAsyncFactory to handle this properly
    if let factory = KeyManagerAsyncFactory.createInstance() {
      return await factory.createKeyManager()
    }
  }
  
  // If modern async factory method isn't available, fall back to dynamic loading
  // of the legacy KeyManagerImpl (for backwards compatibility)
  if
    let keyManagerClass = NSClassFromString("SecurityKeyManagement.KeyManagerImpl") as? NSObject.Type,
    let instance = keyManagerClass.init() as? KeyManagementProtocol
  {
    return instance
  }
  
  // If all dynamic loading fails, use a basic implementation that meets the protocol
  return BasicKeyManager()
}

// Helper class for bridging async factory methods through ObjC runtime
private final class KeyManagerAsyncFactory: NSObject {
  typealias AsyncKeyManagerFactory = @Sendable () async -> KeyManagementProtocol
  
  private var asyncFactory: AsyncKeyManagerFactory?
  
  // Static factory method to create an instance if possible
  static func createInstance() -> KeyManagerAsyncFactory? {
    let instance = KeyManagerAsyncFactory()
    
    // Try to dynamically load the module and set up the async factory
    if
      let securityKeyManagementClass = NSClassFromString("SecurityKeyManagement.SecurityKeyManagement"),
      class_getClassMethod(securityKeyManagementClass, NSSelectorFromString("createKeyManager")) != nil
    {
      // This is a simplified approach - in a real implementation,
      // we would need more complex bridging to properly handle Swift async methods
      // called through Objective-C runtime
      instance.asyncFactory = {
        // Return a basic implementation for now - the actual implementation
        // would need to properly bridge to Swift's concurrency
        return BasicKeyManager()
      }
      return instance
    } else {
      return nil
    }
  }
  
  func createKeyManager() async -> KeyManagementProtocol {
    if let factory = asyncFactory {
      return await factory()
    }
    return BasicKeyManager()
  }
}

// MARK: - Basic Implementations

/// A basic crypto service implementation used as a fallback
private final class BasicCryptoService: CryptoServiceProtocol {
  func encrypt(
    data _: SecureBytes,
    using _: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "Basic implementation does not support encryption"))
  }

  func decrypt(
    data _: SecureBytes,
    using _: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "Basic implementation does not support decryption"))
  }

  func hash(data _: SecureBytes) async -> Result<SecureBytes, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "Basic implementation does not support hashing"))
  }

  func verifyHash(
    data _: SecureBytes,
    expectedHash _: SecureBytes
  ) async -> Result<Bool, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "Basic implementation does not support hash verification"))
  }
}

/// A basic key manager implementation used as a fallback
private final class BasicKeyManager: KeyManagementProtocol {
  func retrieveKey(withIdentifier _: String) async -> Result<SecureBytes, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "Basic implementation does not support key retrieval"))
  }

  func storeKey(
    _: SecureBytes,
    withIdentifier _: String
  ) async -> Result<Void, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "Basic implementation does not support key storage"))
  }

  func deleteKey(withIdentifier _: String) async -> Result<Void, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "Basic implementation does not support key deletion"))
  }

  func rotateKey(withIdentifier _: String, dataToReencrypt _: SecureBytes?) async -> Result<(
    newKey: SecureBytes,
    reencryptedData: SecureBytes?
  ), SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "Basic implementation does not support key rotation"))
  }

  func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    .failure(
      .unsupportedOperation(name: "Basic implementation does not support listing key identifiers")
    )
  }
}
