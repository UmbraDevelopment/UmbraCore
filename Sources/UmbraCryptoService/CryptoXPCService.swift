import CommonCrypto
import Core
import CoreErrors
import CryptoSwiftFoundationIndependent
import CryptoTypes

// Temporarily removing import CryptoTypesServices until it's fixed
import ErrorHandlingDomains
import Foundation
import SecurityUtils
import UmbraCoreTypes
import UmbraXPC
import XPC
import XPCProtocolsCore

/// Custom GCM format for CryptoXPCService
/// Format: <iv (12 bytes)><ciphertext>
enum CryptoFormat {
  static let ivSize=12

  static func packEncryptedData(iv: [UInt8], ciphertext: [UInt8]) -> [UInt8] {
    iv + ciphertext
  }

  static func unpackEncryptedData(data: [UInt8]) -> (iv: [UInt8], ciphertext: [UInt8])? {
    guard data.count > ivSize else { return nil }
    let iv=Array(data[0..<ivSize])
    let ciphertext=Array(data[ivSize...])
    return (iv, ciphertext)
  }
}

/// XPC service for cryptographic operations
///
/// This service uses CryptoSwiftFoundationIndependent to provide platform-independent cryptographic
/// operations across process boundaries. It is specifically designed for:
/// - Cross-process encryption/decryption via XPC
/// - Platform-independent cryptographic operations
/// - Flexible implementation for XPC service requirements
///
/// Note: This implementation uses CryptoSwift instead of CryptoKit to ensure
/// reliable cross-process operations. For main app cryptographic operations,
/// use DefaultCryptoService which provides hardware-backed security.
@available(macOS 14.0, *)
@objc(CryptoXPCService)
public final class CryptoXPCService: NSObject, XPCServiceProtocolComplete,
XPCServiceProtocolStandard, @unchecked Sendable {
  /// Dependencies for the crypto service
  private let dependencies: CryptoXPCServiceDependencies

  /// Queue for cryptographic operations
  private let cryptoQueue=DispatchQueue(label: "com.umbracore.crypto", qos: .userInitiated)

  /// XPC connection for the service
  var connection: NSXPCConnection?

  /// Protocol identifier for XPC service
  public static var protocolIdentifier: String {
    "com.umbracore.xpc.crypto"
  }

  /// Initialize the crypto service with dependencies
  /// - Parameter dependencies: Dependencies required by the service
  public init(dependencies: CryptoXPCServiceDependencies) {
    self.dependencies=dependencies
    super.init()
  }

  // MARK: - XPCServiceProtocolBasic

  /// Basic ping method to test if service is responsive
  /// - Returns: True if service is available
  @objc
  public func ping() async -> Bool {
    true
  }

  /// Synchronize keys between XPC service and client
  /// - Parameter syncData: Secure bytes for key synchronization
  /// - Throws: ErrorHandlingDomains.UmbraErrors.Security.Protocols if synchronization fails
  public func synchroniseKeys(_ syncData: SecureBytes) async throws {
    // Basic implementation - no key synchronization needed in this service
    // Could be expanded if needed
    if syncData.isEmpty {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .invalidInput("Empty synchronization data")
    }
  }

  // MARK: - XPCServiceProtocolStandard

  /// Generate random data of specified length
  /// - Parameter length: Length in bytes of random data to generate
  /// - Returns: Result with SecureBytes on success or error on failure
  public func generateRandomData(length: Int) async
  -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let randomBytes=generateRandomBytes(count: length)
    return .success(SecureBytes(bytes: randomBytes))
  }

  /// Encrypt data using the service's encryption mechanism
  /// - Parameters:
  ///   - data: SecureBytes to encrypt
  ///   - keyIdentifier: Optional identifier for the key to use
  /// - Returns: Result with encrypted SecureBytes on success or error on failure
  public func encryptSecureData(
    _ data: SecureBytes,
    keyIdentifier: String?
  ) async
  -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    guard let keyID=keyIdentifier, !keyID.isEmpty else {
      return .failure(.invalidInput("Missing key identifier"))
    }

    // Get the key data
    let keyResult=await retrieveKeyData(identifier: keyID)
    if case let .failure(error)=keyResult {
      return .failure(error)
    }
    guard case let .success(keyData)=keyResult else {
      return .failure(.encryptionFailed("Failed to get key data"))
    }

    // Generate a random IV for AES-GCM
    let iv=generateRandomBytes(count: CryptoFormat.ivSize)

    do {
      // Perform AES-GCM encryption
      let ciphertext=try CryptoWrapper.encryptAES_GCM(
        data: data.bytes(),
        key: keyData,
        iv: iv
      )

      // Pack the IV and ciphertext together
      let packedData=CryptoFormat.packEncryptedData(iv: iv, ciphertext: ciphertext)

      return .success(SecureBytes(bytes: packedData))
    } catch {
      return .failure(.encryptionFailed(error.localizedDescription))
    }
  }

  /// Decrypt data using the service's decryption mechanism
  /// - Parameters:
  ///   - data: SecureBytes to decrypt
  ///   - keyIdentifier: Optional identifier for the key to use
  /// - Returns: Result with decrypted SecureBytes on success or error on failure
  public func decryptSecureData(
    _ data: SecureBytes,
    keyIdentifier: String?
  ) async
  -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    guard let keyID=keyIdentifier, !keyID.isEmpty else {
      return .failure(.invalidInput("Missing key identifier"))
    }

    let keyResult=await retrieveKeyData(identifier: keyID)
    switch keyResult {
      case let .success(keyData):
        // Unpack the IV and ciphertext
        guard let (iv, ciphertext)=CryptoFormat.unpackEncryptedData(data: data.bytes()) else {
          return .failure(.invalidFormat(reason: "Invalid encrypted data format"))
        }

        do {
          // Use AES-GCM decryption with the extracted IV
          let decrypted=try CryptoWrapper.decryptAES_GCM(
            data: ciphertext,
            key: keyData,
            iv: iv
          )

          return .success(SecureBytes(bytes: decrypted))
        } catch {
          return .failure(.serviceError(error.localizedDescription))
        }
      case let .failure(error):
        return .failure(.serviceError(error.localizedDescription))
    }
  }

  /// Sign data using the specified key
  /// - Parameters:
  ///   - data: Data to sign
  ///   - keyIdentifier: Identifier for the signing key
  /// - Returns: Result with signature as SecureBytes on success or error on failure
  public func sign(
    _ data: SecureBytes,
    keyIdentifier: String
  ) async
  -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // This is a simple implementation
    // In a real-world scenario, this would use proper signing algorithms

    // For demonstration purposes, we'll implement a basic signing mechanism
    let keyResult=await retrieveKeyData(identifier: keyIdentifier)
    switch keyResult {
      case let .success(keyData):
        let signature=createSignature(data: data.bytes(), key: keyData)
        return .success(SecureBytes(bytes: signature))
      case let .failure(error):
        return .failure(.serviceError(error.localizedDescription))
    }
  }

  /// Verify signature for data
  /// - Parameters:
  ///   - signature: SecureBytes containing the signature
  ///   - data: SecureBytes containing the data to verify
  ///   - keyIdentifier: Identifier for the verification key
  /// - Returns: Result with boolean indicating verification result or error on failure
  public func verify(
    signature: SecureBytes,
    for data: SecureBytes,
    keyIdentifier: String
  ) async
  -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Simple implementation for demonstration
    let keyResult=await retrieveKeyData(identifier: keyIdentifier)
    switch keyResult {
      case let .success(keyData):
        let result=verifySignature(signature: signature.bytes(), data: data.bytes(), key: keyData)

        return .success(result)
      case let .failure(error):
        return .failure(.serviceError(error.localizedDescription))
    }
  }

  /// Reset the security state of the service
  /// - Returns: Result with void on success or error on failure
  public func resetSecurity() async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // In a real implementation, this would reset internal state,
    // clear caches, and potentially rotate encryption keys
    .success(())
  }

  /// Get the service version
  /// - Returns: Result with version string on success or error on failure
  public func getServiceVersion() async
  -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success("1.0.0")
  }

  /// Get the hardware identifier
  /// - Returns: Result with identifier string on success or error on failure
  public func getHardwareIdentifier() async
  -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // In a real implementation, this would return a unique identifier for the hardware
    .success("crypto-xpc-service-hardware-id")
  }

  /// Get the service status
  /// - Returns: Result with status dictionary on success or error on failure
  public func status() async
  -> Result<[String: Any], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let statusInfo: [String: Any]=[
      "available": true,
      "version": "1.0.0",
      "protocol": Self.protocolIdentifier
    ]
    return .success(statusInfo)
  }

  // MARK: - XPCServiceProtocolComplete Methods

  /// Enhanced ping with detailed error reporting
  public func pingStandard() async
  -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(true)
  }

  /// Get diagnostic information about the service
  /// - Returns: Result with diagnostic string or error
  public func getDiagnosticInfo() async
  -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let info="""
      CryptoXPCService Diagnostics:
      - Version: 1.0.0
      - Protocol: \(Self.protocolIdentifier)
      - Status: Active
      - Dependencies: All available
      """
    return .success(info)
  }

  /// Get service version with modern interface
  /// - Returns: Result with version string or error
  public func getVersion() async
  -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success("1.0.0")
  }

  /// Get metrics about service performance
  /// - Returns: Result with metrics dictionary or error
  public func getMetrics() async
  -> Result<[String: Any], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // In a real implementation, this would track performance metrics
    let metrics: [String: Any]=[
      "operations_count": 0,
      "errors_count": 0,
      "average_operation_time_ms": 0.0
    ]
    return .success(metrics)
  }

  /// Generate a key with the specified algorithm and size
  /// - Parameters:
  ///   - algorithm: The encryption algorithm
  ///   - keySize: Size of the key in bits
  ///   - metadata: Optional metadata to associate with the key
  /// - Returns: Result with the key identifier or error
  public func generateKey(
    algorithm _: String,
    keySize: Int,
    metadata _: [String: String]?
  ) async
  -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let keyID="key-\(UUID().uuidString)"
    let bytes=keySize / 8
    let keyData=generateRandomBytes(count: bytes)

    // Store the key in the keychain
    let result=await storeKeyData(keyData, identifier: keyID)
    if case let .failure(error)=result {
      return .failure(error)
    }

    return .success(keyID)
  }

  /// Export a key by its identifier
  /// - Parameter keyIdentifier: The identifier of the key to export
  /// - Returns: Result with the key material as SecureBytes or error
  public func exportKey(keyIdentifier: String) async
  -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let keyResult=await retrieveKeyData(identifier: keyIdentifier)
    switch keyResult {
      case let .success(keyData):
        return .success(SecureBytes(bytes: keyData))
      case let .failure(error):
        return .failure(error)
    }
  }

  // MARK: - Legacy Helper Methods

  /// Validate the XPC connection
  /// - Parameter reply: Completion handler with validation result
  @objc
  public func validateConnection(withReply reply: @escaping (Bool, Error?) -> Void) {
    reply(true, nil)
  }

  /// Encrypt data using the specified key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - completion: Completion handler with encrypted data or error
  @objc
  public func encrypt(
    _ data: Data,
    key: Data,
    completion: @escaping (Data?, Error?) -> Void
  ) {
    cryptoQueue.async { [weak self] in
      guard self != nil else {
        completion(
          nil,
          ErrorHandlingDomains.UmbraErrors.Security.Protocols
            .invalidInput("Service is no longer available")
        )
        return
      }

      do {
        // Generate a random IV for AES-GCM
        let iv=self?.generateRandomBytes(count: CryptoFormat.ivSize) ?? []

        // Use AES-GCM encryption from CryptoSwiftFoundationIndependent
        let ciphertext=try CryptoWrapper.encryptAES_GCM(
          data: [UInt8](data),
          key: [UInt8](key),
          iv: iv
        )

        // Pack the IV and ciphertext together
        let packedData=CryptoFormat.packEncryptedData(iv: iv, ciphertext: ciphertext)

        completion(Data(packedData), nil)
      } catch {
        completion(
          nil,
          ErrorHandlingDomains.UmbraErrors.Security.Protocols
            .invalidInput("Encryption failed: \(error.localizedDescription)")
        )
      }
    }
  }

  /// Decrypt data using the specified key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - completion: Completion handler with decrypted data or error
  @objc
  public func decrypt(
    _ data: Data,
    key: Data,
    completion: @escaping (Data?, Error?) -> Void
  ) {
    cryptoQueue.async { [weak self] in
      guard self != nil else {
        completion(
          nil,
          ErrorHandlingDomains.UmbraErrors.Security.Protocols
            .invalidInput("Service is no longer available")
        )
        return
      }

      do {
        let dataBytes=[UInt8](data)

        // Unpack the IV and ciphertext
        guard let (iv, ciphertext)=CryptoFormat.unpackEncryptedData(data: dataBytes) else {
          completion(
            nil,
            ErrorHandlingDomains.UmbraErrors.Security.Protocols
              .invalidInput("Invalid encrypted data format")
          )
          return
        }

        // Use AES-GCM decryption with the extracted IV
        let decrypted=try CryptoWrapper.decryptAES_GCM(
          data: ciphertext,
          key: [UInt8](key),
          iv: iv
        )

        completion(Data(decrypted), nil)
      } catch {
        completion(
          nil,
          ErrorHandlingDomains.UmbraErrors.Security.Protocols
            .invalidInput("Decryption failed: \(error.localizedDescription)")
        )
      }
    }
  }

  /// Generate a cryptographic key of the specified bit length
  /// - Parameters:
  ///   - bits: Key length in bits (typically 128, 256)
  ///   - completion: Completion handler with generated key data or error
  @objc
  public func generateKey(bits: Int, completion: @escaping (Data?, Error?) -> Void) {
    let bytes=bits / 8
    let key=generateRandomBytes(count: bytes)
    completion(Data(key), nil)
  }

  /// Generate random data of the specified length
  /// - Parameters:
  ///   - length: Length of random data in bytes
  ///   - completion: Completion handler with random data or error
  @objc
  public func generateRandomData(length: Int, completion: @escaping (Data?, Error?) -> Void) {
    let data=generateRandomBytes(count: length)
    completion(Data(data), nil)
  }

  /// Store a key in the keychain
  /// - Parameters:
  ///   - key: Key data to store
  ///   - identifier: Key identifier
  ///   - completion: Completion handler with status or error
  @objc
  public func storeKey(
    _ key: Data,
    identifier: String,
    completion: @escaping (Bool, Error?) -> Void
  ) {
    guard !identifier.isEmpty else {
      completion(
        false,
        ErrorHandlingDomains.UmbraErrors.Security.Protocols.invalidInput("Empty identifier")
      )
      return
    }

    // Convert Data to base64 string for storage
    let keyString=key.base64EncodedString()

    do {
      try dependencies.keychain.storePassword(keyString, for: identifier)
      completion(true, nil)
    } catch {
      completion(
        false,
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Keychain storage failed: \(error.localizedDescription)")
      )
    }
  }

  /// Retrieve a key from the keychain
  /// - Parameters:
  ///   - identifier: Key identifier
  ///   - completion: Completion handler with key data or error
  @objc
  public func retrieveKey(identifier: String, completion: @escaping (Data?, Error?) -> Void) {
    guard !identifier.isEmpty else {
      completion(
        nil,
        ErrorHandlingDomains.UmbraErrors.Security.Protocols.invalidInput("Empty identifier")
      )
      return
    }

    do {
      let keyString=try dependencies.keychain.retrievePassword(for: identifier)
      if let keyData=Data(base64Encoded: keyString) {
        completion(keyData, nil)
      } else {
        completion(
          nil,
          ErrorHandlingDomains.UmbraErrors.Security.Protocols
            .invalidInput("Invalid key data format")
        )
      }
    } catch {
      completion(
        nil,
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Keychain retrieval failed: \(error.localizedDescription)")
      )
    }
  }

  /// Delete a key from the keychain
  /// - Parameters:
  ///   - identifier: Key identifier
  ///   - completion: Completion handler with status or error
  @objc
  public func deleteKey(identifier: String, completion: @escaping (Bool, Error?) -> Void) {
    guard !identifier.isEmpty else {
      completion(
        false,
        ErrorHandlingDomains.UmbraErrors.Security.Protocols.invalidInput("Empty identifier")
      )
      return
    }

    do {
      try dependencies.keychain.deletePassword(for: identifier)
      completion(true, nil)
    } catch {
      completion(
        false,
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Keychain deletion failed: \(error.localizedDescription)")
      )
    }
  }

  // MARK: - Private Helpers

  /// Compute SHA-256 hash of byte array
  /// - Parameter data: Input bytes to hash
  /// - Returns: SHA-256 hash of the input
  fileprivate func sha256Hash(_ data: [UInt8]) -> [UInt8] {
    var digest=[UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    _=CC_SHA256(data, CC_LONG(data.count), &digest)
    return digest
  }

  /// Create a simple HMAC-like signature by combining a key with data
  /// - Parameters:
  ///   - data: Data to sign
  ///   - key: Key to use for signing
  /// - Returns: Signature bytes
  fileprivate func createSignature(data: [UInt8], key: [UInt8]) -> [UInt8] {
    // Simple implementation: concatenate key and data, then hash
    var combined=key
    combined.append(contentsOf: data)
    return sha256Hash(combined)
  }

  /// Verify a signature against data and key
  /// - Parameters:
  ///   - signature: Signature to verify
  ///   - data: Original data
  ///   - key: Key used for signing
  /// - Returns: True if signature is valid
  fileprivate func verifySignature(signature: [UInt8], data: [UInt8], key: [UInt8]) -> Bool {
    let expectedSignature=createSignature(data: data, key: key)
    return expectedSignature == signature
  }

  /// Store key data in the keychain
  /// - Parameters:
  ///   - keyData: Key data as array of bytes
  ///   - identifier: Identifier for the key
  /// - Returns: Result with success or error
  private func storeKeyData(
    _ keyData: [UInt8],
    identifier: String
  ) async -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    do {
      let keyString=Data(keyData).base64EncodedString()
      try dependencies.keychain.storePassword(keyString, for: identifier)
      return .success(())
    } catch {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Keychain storage failed: \(error.localizedDescription)")
      )
    }
  }

  /// Retrieve key data from the keychain
  /// - Parameter identifier: Identifier for the key
  /// - Returns: Result with key data or error
  private func retrieveKeyData(identifier: String) async
  -> Result<[UInt8], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    if identifier.isEmpty {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .invalidInput("Empty identifier")
      )
    }

    do {
      let keyString=try dependencies.keychain.retrievePassword(for: identifier)
      guard let keyData=Data(base64Encoded: keyString) else {
        return .failure(
          ErrorHandlingDomains.UmbraErrors.Security.Protocols
            .invalidInput("Invalid key data format")
        )
      }
      return .success([UInt8](keyData))
    } catch let error as ErrorHandlingDomains.UmbraErrors.Security.Protocols {
      return .failure(error)
    } catch {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Keychain retrieval failed: \(error.localizedDescription)")
      )
    }
  }

  // MARK: - Crypto Utilities

  /// Generate secure random bytes
  /// - Parameter count: Number of random bytes to generate
  /// - Returns: Array of random bytes
  fileprivate func generateRandomBytes(count: Int) -> [UInt8] {
    var bytes=[UInt8](repeating: 0, count: count)
    _=SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    return bytes
  }

  // MARK: - Default Implementation Methods

  public func encrypt(data: SecureBytes) async
  -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Generate a key for this operation
    let key=SecureBytes(bytes: generateRandomBytes(count: 32))

    do {
      // Generate a random IV for AES-GCM
      let iv=generateRandomBytes(count: CryptoFormat.ivSize)

      // Use AES-GCM encryption from CryptoSwiftFoundationIndependent
      let ciphertext=try CryptoWrapper.encryptAES_GCM(
        data: data.bytes(),
        key: key.bytes(),
        iv: iv
      )

      // Pack the IV and ciphertext together
      let packedData=CryptoFormat.packEncryptedData(iv: iv, ciphertext: ciphertext)
      return .success(SecureBytes(bytes: packedData))
    } catch {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .encryptionFailed(error.localizedDescription)
      )
    }
  }

  public func decrypt(data _: SecureBytes) async
  -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Without a key, we can't decrypt
    .failure(
      ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .invalidInput("Key required for decryption")
    )
  }

  public func hash(data: SecureBytes) async
  -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let hashedData=sha256Hash(data.bytes())
    return .success(SecureBytes(bytes: hashedData))
  }

  public func generateKey() async
  -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let keyData=generateRandomBytes(count: 32)
    return .success(SecureBytes(bytes: keyData))
  }

  public func deriveKey(
    from _: String,
    salt _: SecureBytes,
    iterations _: Int,
    keyLength _: Int,
    targetKeyIdentifier _: String?
  ) async -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // This would typically use PBKDF2 or similar
    .failure(
      ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .notImplemented("Key derivation not implemented")
    )
  }

  public func generateKey(
    keyType: XPCProtocolTypeDefs.KeyType,
    keyIdentifier: String?,
    metadata _: [String: String]?
  ) async -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let actualKeyID=keyIdentifier ?? "key-\(UUID().uuidString)"
    let keySize=keyType == .symmetric ? 256 : 128

    // Generate a key using the built-in functionality
    if keyType == .symmetric {
      // Generate a random symmetric key and store it
      let keyData=generateRandomBytes(count: keySize / 8)
      let result=await storeKeyData(keyData, identifier: actualKeyID)
      if case let .failure(error)=result {
        return .failure(error)
      }
    } else {
      // For asymmetric keys, we'd typically use SecKey APIs
      // This is a simplified implementation
      let privateKeyData=generateRandomBytes(count: keySize / 8)
      let publicKeyData=generateRandomBytes(count: keySize / 8)

      // Store both keys with different prefixes
      let privateResult=await storeKeyData(privateKeyData, identifier: "private-\(actualKeyID)")
      if case let .failure(error)=privateResult {
        return .failure(error)
      }

      let publicResult=await storeKeyData(publicKeyData, identifier: "public-\(actualKeyID)")
      if case let .failure(error)=publicResult {
        return .failure(error)
      }
    }
    return .success(actualKeyID)
  }
}
