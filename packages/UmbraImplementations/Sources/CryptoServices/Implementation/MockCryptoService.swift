import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
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
  public let secureStorage: SecureStorageProtocol

  /// Record of all method calls for verification
  private(set) var callHistory: [String]=[]

  /// Initialises a mock service with a new secure storage instance
  public init(secureStorage: SecureStorageProtocol?=nil) {
    self.secureStorage=secureStorage ?? SecureStorage()
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
    options _: EncryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    callHistory
      .append("encrypt(dataIdentifier: \(dataIdentifier), keyIdentifier: \(keyIdentifier))")

    // For mock purposes, just return the data as-is with a new identifier
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case let .success(data):
        // Create a mock result identifier
        let resultIdentifier="mock-encrypted-\(UUID().uuidString)"
        // Store the same data under the new identifier (this is a mock!)
        let storeResult=await secureStorage.storeData(data, withIdentifier: resultIdentifier)

        switch storeResult {
          case .success:
            return .success(resultIdentifier)
          case let .failure(error):
            return .failure(error)
        }
      case let .failure(error):
        return .failure(error)
    }
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
    options _: DecryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    callHistory
      .append(
        "decrypt(encryptedDataIdentifier: \(encryptedDataIdentifier), keyIdentifier: \(keyIdentifier))"
      )

    // For mock purposes, just return the data as-is with a new identifier
    let dataResult=await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)

    switch dataResult {
      case let .success(data):
        // Create a mock result identifier
        let resultIdentifier="mock-decrypted-\(UUID().uuidString)"
        // Store the same data under the new identifier (this is a mock!)
        let storeResult=await secureStorage.storeData(data, withIdentifier: resultIdentifier)

        switch storeResult {
          case .success:
            return .success(resultIdentifier)
          case let .failure(error):
            return .failure(error)
        }
      case let .failure(error):
        return .failure(error)
    }
  }

  /// Computes a cryptographic hash of data in secure storage (mock implementation).
  /// - Parameter dataIdentifier: Identifier of the data to hash in secure storage.
  /// - Returns: Identifier for the hash in secure storage, or an error.
  public func hash(
    dataIdentifier: String,
    options _: HashingOptions?
  ) async -> Result<String, SecurityProtocolError> {
    callHistory.append("hash(dataIdentifier: \(dataIdentifier))")

    // For mock purposes, just create a fixed mock hash
    let mockHash: [UInt8]=[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    let hashIdentifier="mock-hash-\(UUID().uuidString)"

    let storeResult=await secureStorage.storeData(mockHash, withIdentifier: hashIdentifier)

    switch storeResult {
      case .success:
        return .success(hashIdentifier)
      case let .failure(error):
        return .failure(error)
    }
  }

  /// Verifies a cryptographic hash against the expected value (mock implementation).
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to verify in secure storage.
  ///   - hashIdentifier: Identifier of the expected hash in secure storage.
  /// - Returns: Always returns true for mock purposes, or an error if identifiers are invalid.
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options _: HashingOptions?
  ) async -> Result<Bool, SecurityProtocolError> {
    callHistory
      .append("verifyHash(dataIdentifier: \(dataIdentifier), hashIdentifier: \(hashIdentifier))")

    // Check if the identifiers exist
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    let hashResult=await secureStorage.retrieveData(withIdentifier: hashIdentifier)

    switch (dataResult, hashResult) {
      case (.success, .success):
        // For mock purposes, always return true
        return .success(true)
      case let (.failure(error), _):
        return .failure(error)
      case let (_, .failure(error)):
        return .failure(error)
    }
  }

  /// Generates a cryptographic key and stores it securely (mock implementation).
  /// - Parameters:
  ///   - length: The length of the key to generate in bytes.
  ///   - options: Optional key generation configuration.
  /// - Returns: Identifier for the generated key in secure storage, or an error.
  public func generateKey(
    length: Int,
    options _: KeyGenerationOptions?
  ) async -> Result<String, SecurityProtocolError> {
    callHistory.append("generateKey(length: \(length))")

    // Create a mock key of the requested length
    let mockKey=Array(repeating: UInt8(0), count: length)
    let keyIdentifier="mock-key-\(UUID().uuidString)"

    let storeResult=await secureStorage.storeData(mockKey, withIdentifier: keyIdentifier)

    switch storeResult {
      case .success:
        return .success(keyIdentifier)
      case let .failure(error):
        return .failure(error)
    }
  }

  /// Imports data into secure storage for cryptographic operations (mock implementation).
  /// - Parameters:
  ///   - data: The raw data to store securely.
  ///   - customIdentifier: Optional custom identifier for the data.
  /// - Returns: The identifier for the data in secure storage, or an error.
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityProtocolError> {
    let identifier=customIdentifier ?? "mock-import-\(UUID().uuidString)"
    callHistory
      .append(
        "importData(bytes: \(data.count), customIdentifier: \(String(describing: customIdentifier)))"
      )

    let storeResult=await secureStorage.storeData(data, withIdentifier: identifier)

    switch storeResult {
      case .success:
        return .success(identifier)
      case let .failure(error):
        return .failure(error)
    }
  }

  /// Exports data from secure storage (mock implementation).
  /// - Parameter identifier: The identifier of the data to export.
  /// - Returns: The raw data, or an error.
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityProtocolError> {
    callHistory.append("exportData(identifier: \(identifier))")

    return await secureStorage.retrieveData(withIdentifier: identifier)
  }
}
