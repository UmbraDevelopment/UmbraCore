import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation

/**
 # Mock Crypto Service

 A test implementation of the CryptoServiceProtocol that can be used in unit tests
 without requiring actual cryptographic operations.

 This implementation allows predetermined responses to be configured, making test
 results predictable and consistent. It follows the Alpha Dot Five architecture
 with proper British spelling and Sendable conformance.
 */
public actor MockCryptoService: CryptoServiceProtocol {
  /// Dictionary of predetermined encryption results
  private var encryptionResults: [String: Data]

  /// Dictionary of predetermined decryption results
  private var decryptionResults: [String: Data]

  /// Dictionary of predetermined key derivation results
  private var keyDerivationResults: [String: Data]

  /// Dictionary of predetermined random key results
  private var randomKeyResults: [Int: Data]

  /// Dictionary of predetermined HMAC results
  private var hmacResults: [String: Data]

  /// Record of all method calls for verification
  private(set) var callHistory: [String] = []

  /// Initialises a mock service with default empty result sets
  public init() {
    encryptionResults = [:]
    decryptionResults = [:]
    keyDerivationResults = [:]
    randomKeyResults = [:]
    hmacResults = [:]
  }

  /// Initialises a mock service with predefined results
  public init(
    encryptionResults: [String: Data] = [:],
    decryptionResults: [String: Data] = [:],
    keyDerivationResults: [String: Data] = [:],
    randomKeyResults: [Int: Data] = [:],
    hmacResults: [String: Data] = [:]
  ) {
    self.encryptionResults = encryptionResults
    self.decryptionResults = decryptionResults
    self.keyDerivationResults = keyDerivationResults
    self.randomKeyResults = randomKeyResults
    self.hmacResults = hmacResults
  }

  /**
   Sets a predefined result for encryption operations.

   - Parameters:
     - data: The input data to match
     - key: The key to match
     - iv: The IV to match
     - result: The predefined result to return
   */
  public func setEncryptionResult(
    for data: Data,
    key: Data,
    iv: Data,
    result: Data
  ) {
    let key = makeEncryptionKey(data: data, key: key, iv: iv)
    encryptionResults[key] = result
  }

  /**
   Sets a predefined result for decryption operations.

   - Parameters:
     - data: The input data to match
     - key: The key to match
     - iv: The IV to match
     - result: The predefined result to return
   */
  public func setDecryptionResult(
    for data: Data,
    key: Data,
    iv: Data,
    result: Data
  ) {
    let key = makeEncryptionKey(data: data, key: key, iv: iv)
    decryptionResults[key] = result
  }

  /**
   Sets a predefined result for key derivation operations.

   - Parameters:
     - password: The password to match
     - salt: The salt to match
     - iterations: The iterations to match
     - result: The predefined result to return
   */
  public func setKeyDerivationResult(
    for password: String,
    salt: Data,
    iterations: Int,
    result: Data
  ) {
    let key = "\(password)_\(salt.hashValue)_\(iterations)"
    keyDerivationResults[key] = result
  }

  /**
   Sets a predefined result for key generation operations.

   - Parameters:
     - length: The length to match
     - result: The predefined result to return
   */
  public func setRandomKeyResult(
    for length: Int,
    result: Data
  ) {
    randomKeyResults[length] = result
  }

  /**
   Sets a predefined result for HMAC generation operations.

   - Parameters:
     - data: The input data to match
     - key: The key to match
     - result: The predefined result to return
   */
  public func setHMACResult(
    for data: Data,
    key: Data,
    result: Data
  ) {
    let key = "\(data.hashValue)_\(key.hashValue)"
    hmacResults[key] = result
  }

  /**
   Encrypts data using the pre-configured results.

   - Parameters:
     - data: Data to encrypt
     - key: Encryption key
     - iv: Initialisation vector
     - cryptoOptions: Optional encryption configuration
   - Returns: Encrypted data from the preconfigured results
   - Throws: CryptoError if no mock result is configured
   */
  public func encrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    callHistory
      .append("encrypt(data: \(data.count) bytes, key: \(key.count) bytes, iv: \(iv.count) bytes)")

    let lookupKey = makeEncryptionKey(data: data, key: key, iv: iv)

    guard let result = encryptionResults[lookupKey] else {
      throw CryptoError.encryptionFailed(
        reason: "No mock encryption result for data: \(data.count) bytes, key: \(key.count) bytes"
      )
    }

    return result
  }

  /**
   Decrypts data using the pre-configured results.

   - Parameters:
     - data: Data to decrypt
     - key: Decryption key
     - iv: Initialisation vector
     - cryptoOptions: Optional decryption configuration
   - Returns: Decrypted data from the preconfigured results
   - Throws: CryptoError if no mock result is configured
   */
  public func decrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    callHistory
      .append("decrypt(data: \(data.count) bytes, key: \(key.count) bytes, iv: \(iv.count) bytes)")

    let lookupKey = makeEncryptionKey(data: data, key: key, iv: iv)

    guard let result = decryptionResults[lookupKey] else {
      throw CryptoError.decryptionFailed(
        reason: "No mock decryption result for data: \(data.count) bytes, key: \(key.count) bytes"
      )
    }

    return result
  }

  /**
   Derives a key using the pre-configured results.

   - Parameters:
     - password: Password to derive the key from
     - salt: Salt value for the derivation
     - iterations: Number of iterations for the derivation
     - derivationOptions: Optional key derivation configuration
   - Returns: Derived key from the preconfigured results
   - Throws: CryptoError if no mock result is configured
   */
  public func deriveKey(
    from password: String,
    salt: Data,
    iterations: Int,
    derivationOptions: KeyDerivationOptions?
  ) async throws -> Data {
    callHistory
      .append(
        "deriveKey(password: \(password.count) chars, salt: \(salt.count) bytes, iterations: \(iterations))"
      )

    let lookupKey = "\(password)_\(salt.hashValue)_\(iterations)"

    guard let result = keyDerivationResults[lookupKey] else {
      throw CryptoError.keyDerivationFailed(
        reason: "No mock key derivation result for password: \(password.count) chars, salt: \(salt.count) bytes"
      )
    }

    return result
  }

  /**
   Generates a key using the pre-configured results.

   - Parameters:
     - length: Length of the key to generate
     - keyOptions: Optional key generation configuration
   - Returns: Generated key from the preconfigured results
   - Throws: CryptoError if no mock result is configured
   */
  public func generateKey(length: Int, keyOptions: KeyGenerationOptions?) async throws -> Data {
    callHistory.append("generateKey(length: \(length))")

    guard let result = randomKeyResults[length] else {
      throw CryptoError.keyGenerationFailed(
        reason: "No mock random key result for length: \(length)"
      )
    }

    return result
  }

  /**
   Generates an HMAC using the pre-configured results.

   - Parameters:
     - data: Data to authenticate
     - key: The authentication key
     - hmacOptions: Optional HMAC configuration
   - Returns: HMAC from the preconfigured results
   - Throws: CryptoError if no mock result is configured
   */
  public func generateHMAC(
    for data: Data,
    using key: Data,
    hmacOptions: HMACOptions?
  ) async throws -> Data {
    callHistory.append("generateHMAC(data: \(data.count) bytes, key: \(key.count) bytes)")
    
    let lookupKey = "\(data.hashValue)_\(key.hashValue)"
    
    guard let result = hmacResults[lookupKey] else {
      throw CryptoError.operationFailed(
        reason: "No mock HMAC result for data: \(data.count) bytes, key: \(key.count) bytes"
      )
    }
    
    return result
  }
  
  // MARK: - Private Helper Methods
  
  private func makeEncryptionKey(data: Data, key: Data, iv: Data) -> String {
    return "\(data.hashValue)_\(key.hashValue)_\(iv.hashValue)"
  }
}
