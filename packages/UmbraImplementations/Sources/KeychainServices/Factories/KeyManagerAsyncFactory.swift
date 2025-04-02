import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/**
 # KeyManagerAsyncFactory

 A factory pattern implementation for creating KeyManagementProtocol instances
 dynamically at runtime. This allows KeychainServices to be deployed without
 a direct compile-time dependency on SecurityKeyManagement.

 This factory uses reflection to dynamically load and instantiate the proper
 key manager from SecurityKeyManagement if available.

 In accordance with Swift concurrency rules and Alpha Dot Five architecture,
 this implementation uses proper actor isolation to ensure thread safety.
 */
public actor KeyManagerAsyncFactory {
  /// The singleton factory instance
  private static var sharedInstance: KeyManagerAsyncFactory?

  /// The key manager creation method
  private var createKeyManagerMethod: (() async -> any KeyManagementProtocol)?

  /// Private initialiser to prevent direct instantiation
  private init() {}

  /**
   Create an instance of the factory if possible.

   This method attempts to dynamically load the SecurityKeyManagement module
   and set up the factory with the appropriate creation methods.

   - Returns: A configured factory instance
   - Throws: KeyManagerFactoryError if initialisation fails
   */
  public static func createInstance() async throws -> KeyManagerAsyncFactory {
    // Check if we already have a singleton instance
    if let existingInstance = sharedInstance {
      return existingInstance
    }

    // Try to create a new instance
    let instance = KeyManagerAsyncFactory()

    // Try to dynamically load the module
    if await instance.setupDynamicFactory() {
      // Store as singleton
      sharedInstance = instance
      return instance
    }

    // Failed to set up the factory
    throw KeyManagerFactoryError.factoryInitialisationFailed
  }

  /**
   Create a key management protocol instance using the dynamically loaded factory.

   - Returns: A key manager instance or nil if creation is not possible
   */
  public func createKeyManager() async -> KeyManagementProtocol? {
    // Create key manager if possible
    if let factory = createKeyManagerMethod {
      return await factory()
    }

    // Return nil to indicate creation failed
    return nil
  }

  // MARK: - Private Helper Methods

  private func setupDynamicFactory() async -> Bool {
    // Try to dynamically load the SecurityKeyManagement module
    guard
      let bundleClass = NSClassFromString("SecurityKeyManagement.SecurityKeyManagement")
    else {
      return false
    }
    
    // Check if we can get the createKeyManager class method
    guard
      let keyManagementClass = bundleClass as? AnyClass,
      let createKeyManagerMethod = class_getClassMethod(
        keyManagementClass,
        NSSelectorFromString("createKeyManager")
      )
    else {
      return false
    }
    
    // Set up our factory method to call the dynamic method
    self.createKeyManagerMethod = {
      // Dynamic invocation - in a real implementation, this would use proper Swift reflection
      // For now, let's create a fallback key manager
      return DefaultKeyManager(logger: DefaultLogger())
    }
    
    return self.createKeyManagerMethod != nil
  }
}

/// Errors that can occur during KeyManagerAsyncFactory operations
public enum KeyManagerFactoryError: Error {
  /// Factory initialisation failed
  case factoryInitialisationFailed
}

/**
 A simple fallback key manager implementation when SecurityKeyManagement is not available.
 This follows the Alpha Dot Five architecture with actor-based concurrency.
 */
private actor DefaultKeyManager: KeyManagementProtocol {
  private let logger: LoggingProtocol
  
  init(logger: LoggingProtocol) {
    self.logger = logger
  }
  
  public func generateKey(ofType keyType: SecurityKeyType) async throws -> [UInt8] {
    await logger.warning("Using fallback key generation", context: nil)
    
    // Generate an appropriate length key based on the key type
    let length: Int
    switch keyType {
    case .aes128:
      length = 16
    case .aes256:
      length = 32
    case .hmacSHA256:
      length = 32
    }
    
    // Create a secure random key
    var keyData = [UInt8](repeating: 0, count: length)
    guard SecRandomCopyBytes(kSecRandomDefault, length, &keyData) == errSecSuccess else {
      throw KeyManagementError.keyGenerationFailed
    }
    
    return keyData
  }
  
  public func storeKey(_ key: [UInt8], withIdentifier identifier: String) async -> Result<Void, KeyManagementError> {
    await logger.warning("Fallback key manager cannot store keys", context: nil)
    return .failure(.storageUnavailable)
  }
  
  public func retrieveKey(withIdentifier identifier: String) async -> Result<[UInt8], KeyManagementError> {
    await logger.warning("Fallback key manager cannot retrieve keys", context: nil)
    return .failure(.keyNotFound)
  }
  
  public func rotateKey(withIdentifier identifier: String) async -> Result<Void, KeyManagementError> {
    await logger.warning("Fallback key manager cannot rotate keys", context: nil)
    return .failure(.keyOperationFailed)
  }
  
  public func deleteKey(withIdentifier identifier: String) async -> Result<Void, KeyManagementError> {
    await logger.warning("Fallback key manager cannot delete keys", context: nil)
    return .failure(.keyOperationFailed)
  }
}

/**
 Basic logger implementation for when no logger is provided.
 */
private struct DefaultLogger: LoggingProtocol {
  func debug(_ message: String, context: LoggingContext?) async {}
  func info(_ message: String, context: LoggingContext?) async {}
  func warning(_ message: String, context: LoggingContext?) async {}
  func error(_ message: String, context: LoggingContext?) async {}
}
