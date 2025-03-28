import CryptoInterfaces
import CryptoTypes
import Foundation
import SecurityTypes

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
  private var encryptionResults: [String: SecureBytes]

  /// Dictionary of predetermined decryption results
  private var decryptionResults: [String: SecureBytes]

  /// Dictionary of predetermined key derivation results
  private var keyDerivationResults: [String: SecureBytes]

  /// Dictionary of predetermined random key results
  private var randomKeyResults: [Int: SecureBytes]

  /// Dictionary of predetermined HMAC results
  private var hmacResults: [String: SecureBytes]

  /// Record of all method calls for verification
  private(set) var callHistory: [String]=[]

  /// Initialises a mock service with default empty result sets
  public init() {
    encryptionResults=[:]
    decryptionResults=[:]
    keyDerivationResults=[:]
    randomKeyResults=[:]
    hmacResults=[:]
  }

  /// Initialises a mock service with predefined results
  public init(
    encryptionResults: [String: SecureBytes]=[:],
    decryptionResults: [String: SecureBytes]=[:],
    keyDerivationResults: [String: SecureBytes]=[:],
    randomKeyResults: [Int: SecureBytes]=[:],
    hmacResults: [String: SecureBytes]=[:]
  ) {
    self.encryptionResults=encryptionResults
    self.decryptionResults=decryptionResults
    self.keyDerivationResults=keyDerivationResults
    self.randomKeyResults=randomKeyResults
    self.hmacResults=hmacResults
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
    for data: SecureBytes,
    key: SecureBytes,
    iv: SecureBytes,
    result: SecureBytes
  ) {
    let key=makeEncryptionKey(data: data, key: key, iv: iv)
    encryptionResults[key]=result
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
    for data: SecureBytes,
    key: SecureBytes,
    iv: SecureBytes,
    result: SecureBytes
  ) {
    let key=makeEncryptionKey(data: data, key: key, iv: iv)
    decryptionResults[key]=result
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
    salt: SecureBytes,
    iterations: Int,
    result: SecureBytes
  ) {
    let key="\(password)_\(salt.hashValue)_\(iterations)"
    keyDerivationResults[key]=result
  }

  /**
   Sets a predefined result for random key generation.

   - Parameters:
     - length: The key length to match
     - result: The predefined result to return
   */
  public func setRandomKeyResult(
    for length: Int,
    result: SecureBytes
  ) {
    randomKeyResults[length]=result
  }

  /**
   Sets a predefined result for HMAC generation.

   - Parameters:
     - data: The data to match
     - key: The key to match
     - result: The predefined result to return
   */
  public func setHMACResult(
    for data: SecureBytes,
    key: SecureBytes,
    result: SecureBytes
  ) {
    let key="\(data.hashValue)_\(key.hashValue)"
    hmacResults[key]=result
  }

  /**
   Mock implementation of encryption operation.

   - Parameters:
     - data: Data to encrypt
     - key: Encryption key
     - iv: Initialisation vector
   - Returns: Encrypted data as SecureBytes
   - Throws: CryptoError if no mock result is configured
   */
  public func encrypt(
    _ data: SecureBytes,
    using key: SecureBytes,
    iv: SecureBytes
  ) async throws -> SecureBytes {
    callHistory
      .append("encrypt(data: \(data.count) bytes, key: \(key.count) bytes, iv: \(iv.count) bytes)")

    let lookupKey=makeEncryptionKey(data: data, key: key, iv: iv)

    if let result=encryptionResults[lookupKey] {
      return result
    }

    // Default behaviour if no mock is configured
    if let fallback=encryptionResults["default"] {
      return fallback
    }

    // Generate a predictable result based on inputs
    let mockResult=SecureBytes(bytes: Array(repeating: 0xAA, count: data.count + 16))
    return mockResult
  }

  /**
   Mock implementation of decryption operation.

   - Parameters:
     - data: Data to decrypt
     - key: Decryption key
     - iv: Initialisation vector
   - Returns: Decrypted data as SecureBytes
   - Throws: CryptoError if no mock result is configured
   */
  public func decrypt(
    _ data: SecureBytes,
    using key: SecureBytes,
    iv: SecureBytes
  ) async throws -> SecureBytes {
    callHistory
      .append("decrypt(data: \(data.count) bytes, key: \(key.count) bytes, iv: \(iv.count) bytes)")

    let lookupKey=makeEncryptionKey(data: data, key: key, iv: iv)

    if let result=decryptionResults[lookupKey] {
      return result
    }

    // Default behaviour if no mock is configured
    if let fallback=decryptionResults["default"] {
      return fallback
    }

    // Simulate decryption failure with wrong key
    if key.count < 32 {
      throw CryptoError.invalidKey(reason: "Mock decryption requires a 32-byte key")
    }

    // Generate a predictable result based on inputs
    let mockResult=SecureBytes(bytes: Array(repeating: 0xBB, count: data.count - 16))
    return mockResult
  }

  /**
   Mock implementation of key derivation.

   - Parameters:
     - password: Password to derive key from
     - salt: Salt for key derivation
     - iterations: Number of iterations for key derivation
   - Returns: Derived key as SecureBytes
   - Throws: CryptoError if no mock result is configured
   */
  public func deriveKey(
    from password: String,
    salt: SecureBytes,
    iterations: Int
  ) async throws -> SecureBytes {
    callHistory
      .append(
        "deriveKey(password: \(password.count) chars, salt: \(salt.count) bytes, iterations: \(iterations))"
      )

    let lookupKey="\(password)_\(salt.hashValue)_\(iterations)"

    if let result=keyDerivationResults[lookupKey] {
      return result
    }

    // Default behaviour if no mock is configured
    if let fallback=keyDerivationResults["default"] {
      return fallback
    }

    // Generate a predictable result based on inputs
    let mockResult=SecureBytes(bytes: Array(repeating: 0xCC, count: 32))
    return mockResult
  }

  /**
   Mock implementation of random key generation.

   - Parameter length: Length of the key in bytes
   - Returns: Generated key as SecureBytes
   - Throws: CryptoError if no mock result is configured
   */
  public func generateSecureRandomKey(length: Int) async throws -> SecureBytes {
    callHistory.append("generateSecureRandomKey(length: \(length))")

    if let result=randomKeyResults[length] {
      return result
    }

    // Default behaviour if no mock is configured
    if let fallback=randomKeyResults[0] {
      return fallback
    }

    // Generate a predictable "random" key
    let mockResult=SecureBytes(bytes: Array(repeating: 0xDD, count: length))
    return mockResult
  }

  /**
   Mock implementation of HMAC generation.

   - Parameters:
     - data: Data to authenticate
     - key: Authentication key
   - Returns: Authentication code as SecureBytes
   - Throws: CryptoError if no mock result is configured
   */
  public func generateHMAC(
    for data: SecureBytes,
    using key: SecureBytes
  ) async throws -> SecureBytes {
    callHistory.append("generateHMAC(data: \(data.count) bytes, key: \(key.count) bytes)")

    let lookupKey="\(data.hashValue)_\(key.hashValue)"

    if let result=hmacResults[lookupKey] {
      return result
    }

    // Default behaviour if no mock is configured
    if let fallback=hmacResults["default"] {
      return fallback
    }

    // Generate a predictable HMAC result
    let mockResult=SecureBytes(bytes: Array(repeating: 0xEE, count: 32))
    return mockResult
  }

  /**
   Resets the call history for verification in tests.
   */
  public func resetCallHistory() {
    callHistory=[]
  }

  // MARK: - Private Helpers

  /// Creates a lookup key for encryption/decryption operations
  private func makeEncryptionKey(data: SecureBytes, key: SecureBytes, iv: SecureBytes) -> String {
    "\(data.hashValue)_\(key.hashValue)_\(iv.hashValue)"
  }
}
