import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import SecurityCoreInterfaces
import UmbraErrors

/**
 # Mock Crypto Service

 A test implementation of the CryptoServiceProtocol that uses SecureStorage and
 is suitable for unit tests without requiring actual cryptographic operations.

 This implementation allows predetermined responses to be configured, making test
 results predictable and consistent. It follows the Alpha Dot Five architecture
 with proper British spelling and Sendable conformance.
 */
public actor MockCryptoService: CryptoServiceProtocol {
  /// The secure storage used for sensitive material
  public nonisolated let secureStorage: SecureStorageProtocol

  /// Record of all method calls for verification
  private(set) var callHistory: [String]=[]

  /// Logger for operations
  private let logger: LoggingProtocol

  /// Initialises a mock service with a new secure storage instance
  public init(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.logger = logger ?? EmptyLogger()
    self.secureStorage = secureStorage
  }
  
  /// A minimal empty logger for when none is provided
  private struct EmptyLogger: LoggingProtocol {
    func log(_ level: LogLevel, _ message: String, metadata: PrivacyMetadata?, source: String) async {}
    func trace(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
    func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
    func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
    func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
    func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
    func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
  }

  /// Encrypts binary data using a key from secure storage (mock implementation).
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to encrypt in secure storage.
  ///   - keyIdentifier: Identifier of the encryption key in secure storage.
  ///   - options: Optional encryption configuration.
  /// - Returns: Identifier for the encrypted data in secure storage, or an error.
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Record this call in the history
    callHistory.append("encrypt(\(dataIdentifier), \(keyIdentifier))")
    
    // For mock purposes, we'll return predictable results based on input
    if dataIdentifier.isEmpty {
      return .failure(.dataNotFound)
    }

    if keyIdentifier.isEmpty {
      return .failure(.keyNotFound)
    }

    // Convert our options to CryptoOperationOptionsDTO for full compatibility testing
    let _ = (options ?? SecurityCoreInterfaces.EncryptionOptions()).toCryptoOperationOptionsDTO()

    // Generate a mock encrypted identifier
    let mockEncryptedId = "encrypted-\(dataIdentifier)-with-\(keyIdentifier)"
    return .success(mockEncryptedId)
  }

  /// Decrypts binary data using a key from secure storage (mock implementation).
  /// - Parameters:
  ///   - encryptedDataIdentifier: Identifier of the encrypted data in secure storage.
  ///   - keyIdentifier: Identifier of the decryption key in secure storage.
  ///   - options: Optional decryption configuration.
  /// - Returns: Identifier for the decrypted data in secure storage, or an error.
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Record this call in the history
    callHistory.append("decrypt(\(encryptedDataIdentifier), \(keyIdentifier))")
    
    if encryptedDataIdentifier.isEmpty || keyIdentifier.isEmpty {
      return .failure(.operationFailed("Empty identifier"))
    }
    
    // Convert our options to CryptoOperationOptionsDTO for full compatibility testing
    let _ = (options ?? SecurityCoreInterfaces.DecryptionOptions()).toCryptoOperationOptionsDTO()
    
    // Generate a mock decrypted identifier
    let mockDecryptedId = "decrypted-\(encryptedDataIdentifier)-with-\(keyIdentifier)"
    
    // Mock success
    return .success(mockDecryptedId)
  }

  /// Computes a cryptographic hash of data in secure storage (mock implementation).
  /// - Parameter dataIdentifier: Identifier of the data to hash in secure storage.
  /// - Returns: Identifier for the hash in secure storage, or an error.
  public func hash(
    dataIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Record this call in the history
    callHistory.append("hash(\(dataIdentifier))")
    
    if dataIdentifier.isEmpty {
      return .failure(.operationFailed("Empty data identifier"))
    }
    
    // Mock success with an identifier that includes a hash code
    return .success("hash-\(dataIdentifier.hashValue)")
  }

  /// Verifies a cryptographic hash against the expected value (mock implementation).
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to verify in secure storage.
  ///   - hashIdentifier: Identifier of the expected hash in secure storage.
  /// - Returns: Always returns true for mock purposes, or an error if identifiers are invalid.
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    // Record this call in the history
    callHistory.append("verifyHash(\(dataIdentifier), \(hashIdentifier))")
    
    if dataIdentifier.isEmpty || hashIdentifier.isEmpty {
      return .failure(.operationFailed("Empty identifier"))
    }
    
    // Always return success for mocking purposes
    return .success(true)
  }

  /// Generates a cryptographic key and stores it securely (mock implementation).
  /// - Parameters:
  ///   - length: The length of the key to generate in bytes.
  ///   - options: Optional key generation configuration.
  /// - Returns: Identifier for the generated key in secure storage, or an error.
  public func generateKey(
    length: Int,
    options: SecurityCoreInterfaces.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Record this call in the history
    callHistory.append("generateKey(\(length))")
    
    if length <= 0 {
      return .failure(.operationFailed("Invalid key length"))
    }
    
    // Mock key generation
    let keyIdentifier = "key-\(UUID().uuidString.prefix(8))-\(length)"
    
    return .success(keyIdentifier)
  }

  /// Imports data into mock secure storage.
  /// - Parameters:
  ///   - data: The raw data to store securely.
  ///   - customIdentifier: Optional custom identifier for the data.
  /// - Returns: The identifier for the data in secure storage, or an error.
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Record this call in the history
    callHistory.append("importData(\(data.count) bytes)")
    
    if data.isEmpty {
      return .failure(.operationFailed("Empty data cannot be imported"))
    }

    let identifier = customIdentifier ?? "data-\(UUID().uuidString.prefix(8))"
    
    // Actually store in the secure storage for demonstration
    let storeResult = await secureStorage.storeData(data, withIdentifier: identifier)
    
    return storeResult.map { identifier }
  }

  /// Exports data from mock secure storage.
  /// - Parameter identifier: The identifier of the data to export.
  /// - Returns: The raw data, or an error.
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Record this call in the history
    callHistory.append("exportData(\(identifier))")
    
    if identifier.isEmpty {
      return .failure(.operationFailed("Empty identifier"))
    }
    
    // Try to retrieve from secure storage
    return await secureStorage.retrieveData(withIdentifier: identifier)
  }
}
