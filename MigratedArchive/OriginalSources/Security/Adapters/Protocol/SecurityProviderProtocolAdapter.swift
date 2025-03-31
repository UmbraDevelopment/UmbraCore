import Errors
import Protocols
import SecurityInterfaces
import Types
import UmbraCoreTypes

/// Bridge protocol that connects security providers to Foundation-free interfaces
/// This helps break circular dependencies between security modules
public protocol SecurityProviderBridge: Sendable {
  /// Protocol identifier - used for protocol negotiation
  static var protocolIdentifier: String { get }

  /// Encrypt data using the provider's encryption mechanism
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Encrypted data
  /// - Throws: Error if encryption fails
  func encrypt(_ data: SecureBytes, key: SecureBytes) async throws -> SecureBytes

  /// Decrypt data using the provider's decryption mechanism
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Decrypted data
  /// - Throws: Error if decryption fails
  func decrypt(_ data: SecureBytes, key: SecureBytes) async throws -> SecureBytes

  /// Generate a cryptographically secure random key
  /// - Parameter sizeInBytes: Size of the key to generate
  /// - Returns: Generated key
  /// - Throws: Error if key generation fails
  func generateKey(sizeInBytes: Int) async throws -> SecureBytes

  /// Hash data using the provider's hashing mechanism
  /// - Parameter data: Data to hash
  /// - Returns: Hash of the data
  /// - Throws: Error if hashing fails
  func hash(_ data: SecureBytes) async throws -> SecureBytes
}

/// Adapter that connects a foundation-free security provider to a Foundation-based interface
/// Implementing the SecurityProviderProtocol while delegating to a foundation-free bridge
public final class SecurityProviderProtocolAdapter: SecurityProviderProtocol {
  /// The underlying bridge implementation
  private let adapter: any SecurityProviderBridge

  /// The crypto service implementation required by SecurityProviderProtocol
  public let cryptoService: CryptoServiceProtocol

  /// The key manager implementation required by SecurityProviderProtocol
  public let keyManager: KeyManagementProtocol

  /// Protocol identifier
  public static var protocolIdentifier: String {
    "com.umbra.security.provider.adapter"
  }

  /// Wrap any error into a SecurityProtocolError
  private func wrapError(_ error: Error) throws -> Never {
    // Use our centralised error mapping to get a consistent error description
    let errorDescription="Security operation failed: \(error)"
    throw SecurityProtocolError.internalError(errorDescription)
  }

  /// Create a new adapter with the given bridge
  /// - Parameters:
  ///   - bridge: The security provider bridge implementation
  ///   - cryptoService: The crypto service implementation
  ///   - keyManager: The key manager implementation
  public init(
    bridge: any SecurityProviderBridge,
    cryptoService: CryptoServiceProtocol,
    keyManager: KeyManagementProtocol
  ) {
    adapter=bridge
    self.cryptoService=cryptoService
    self.keyManager=keyManager
  }

  /// Encrypt data using the provider's encryption
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Encrypted data
  /// - Throws: SecurityProtocolError if encryption fails
  public func encrypt(
    _ data: SecureBytes,
    key: SecureBytes
  ) async throws -> SecureBytes {
    do {
      let result=try await adapter.encrypt(data, key: key)
      return result
    } catch {
      try wrapError(error)
    }
  }

  /// Decrypt data using the provider's decryption
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Decrypted data
  /// - Throws: SecurityProtocolError if decryption fails
  public func decrypt(
    _ data: SecureBytes,
    key: SecureBytes
  ) async throws -> SecureBytes {
    do {
      let result=try await adapter.decrypt(data, key: key)
      return result
    } catch {
      try wrapError(error)
    }
  }

  /// Generate a cryptographically secure random key
  /// - Parameter sizeInBytes: Size of the key to generate
  /// - Returns: Generated key
  /// - Throws: SecurityProtocolError if key generation fails
  public func generateKey(sizeInBytes: Int) async throws -> SecureBytes {
    do {
      return try await adapter.generateKey(sizeInBytes: sizeInBytes)
    } catch {
      try wrapError(error)
    }
  }

  /// Hash data using the provider's hashing mechanism
  /// - Parameter data: Data to hash
  /// - Returns: Hash of the data
  /// - Throws: SecurityProtocolError if hashing fails
  public func hash(_ data: SecureBytes) async throws -> SecureBytes {
    do {
      return try await adapter.hash(data)
    } catch {
      try wrapError(error)
    }
  }

  /// Create a secure configuration with appropriate defaults
  /// - Parameter options: Optional dictionary of configuration options
  /// - Returns: A properly configured SecurityConfigDTO
  public func createSecureConfig(options: [String: Any]?) -> SecurityConfigDTO {
    // Default values
    var keySize=256
    var algorithm: SecurityConfigDTO.Algorithm = .aes
    var mode: SecurityConfigDTO.Mode? = .gcm
    var hashAlgorithm: HashAlgorithm = .sha256
    var authData: SecureBytes?
    var configOptions: [String: String]=[:]

    // Apply user-provided options
    if let options {
      // Extract key size if provided
      if let size=options["keySize"] as? Int {
        keySize=size
      }

      // Extract algorithm if provided
      if let algoStr=options["algorithm"] as? String {
        if algoStr.lowercased().contains("aes") {
          algorithm = .aes
        } else if algoStr.lowercased().contains("rsa") {
          algorithm = .rsa
        } else if algoStr.lowercased().contains("chacha") {
          algorithm = .chacha20
        }
      }

      // Extract mode if provided
      if let modeStr=options["mode"] as? String {
        if modeStr.lowercased().contains("gcm") {
          mode = .gcm
        } else if modeStr.lowercased().contains("cbc") {
          mode = .cbc
        } else if modeStr.lowercased().contains("ctr") {
          mode = .ctr
        }
      }

      // Extract hash algorithm if provided
      if let hashStr=options["hashAlgorithm"] as? String {
        if hashStr.lowercased().contains("256") {
          hashAlgorithm = .sha256
        } else if hashStr.lowercased().contains("384") {
          hashAlgorithm = .sha384
        } else if hashStr.lowercased().contains("512") {
          hashAlgorithm = .sha512
        }
      }

      // Extract authentication data if provided
      if let data=options["authData"] as? SecureBytes {
        authData=data
      }

      // Extract all other options as string-string pairs
      for (key, value) in options where ![
        "keySize",
        "algorithm",
        "mode",
        "hashAlgorithm",
        "authData"
      ].contains(key) {
        configOptions[key]=String(describing: value)
      }
    }

    // Create the configuration with the extracted values
    return SecurityConfigDTO(
      keySize: keySize,
      algorithm: algorithm,
      mode: mode,
      hashAlgorithm: hashAlgorithm,
      authenticationData: authData,
      options: configOptions
    )
  }

  /// Perform a secure operation with appropriate error handling
  /// - Parameters:
  ///   - operation: The security operation to perform
  ///   - config: Configuration options
  /// - Returns: Result of the operation
  public func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Map the operation to the appropriate underlying service call
    switch operation {
      case .encrypt:
        // For encryption, we need to extract the data and key from options
        guard
          let data=SecureBytes(base64Encoded: config.options["inputData"] ?? ""),
          let key=SecureBytes(base64Encoded: config.options["key"] ?? "")
        else {
          return SecurityResultDTO(
            status: .failure,
            error: SecurityProtocolError
              .invalidInput("Missing required data or key for encryption"),
            metadata: ["operation": "encrypt"]
          )
        }

        do {
          let result=try await encrypt(data, key: key)
          return SecurityResultDTO(
            status: .success,
            data: result,
            metadata: ["operation": "encrypt"]
          )
        } catch let error as SecurityProtocolError {
          return SecurityResultDTO(
            status: .failure,
            error: error,
            metadata: ["operation": "encrypt"]
          )
        } catch {
          return SecurityResultDTO(
            status: .failure,
            error: SecurityProtocolError.internalError("Encryption failed: \(error)"),
            metadata: ["operation": "encrypt"]
          )
        }

      case .decrypt:
        // For decryption, we need to extract the data and key from options
        guard
          let data=SecureBytes(base64Encoded: config.options["inputData"] ?? ""),
          let key=SecureBytes(base64Encoded: config.options["key"] ?? "")
        else {
          return SecurityResultDTO(
            status: .failure,
            error: SecurityProtocolError
              .invalidInput("Missing required data or key for decryption"),
            metadata: ["operation": "decrypt"]
          )
        }

        do {
          let result=try await decrypt(data, key: key)
          return SecurityResultDTO(
            status: .success,
            data: result,
            metadata: ["operation": "decrypt"]
          )
        } catch let error as SecurityProtocolError {
          return SecurityResultDTO(
            status: .failure,
            error: error,
            metadata: ["operation": "decrypt"]
          )
        } catch {
          return SecurityResultDTO(
            status: .failure,
            error: SecurityProtocolError.internalError("Decryption failed: \(error)"),
            metadata: ["operation": "decrypt"]
          )
        }

      case .hash:
        // For hashing, we need to extract the data from options
        guard let data=SecureBytes(base64Encoded: config.options["inputData"] ?? "") else {
          return SecurityResultDTO(
            status: .failure,
            error: SecurityProtocolError.invalidInput("Missing required data for hashing"),
            metadata: ["operation": "hash"]
          )
        }

        do {
          let result=try await hash(data)
          return SecurityResultDTO(
            status: .success,
            data: result,
            metadata: ["operation": "hash"]
          )
        } catch let error as SecurityProtocolError {
          return SecurityResultDTO(
            status: .failure,
            error: error,
            metadata: ["operation": "hash"]
          )
        } catch {
          return SecurityResultDTO(
            status: .failure,
            error: SecurityProtocolError.internalError("Hashing failed: \(error)"),
            metadata: ["operation": "hash"]
          )
        }

      case .generateKey:
        // Use the keySize from the config
        let keySize=config.keySize / 8 // Convert bits to bytes

        do {
          let result=try await generateKey(sizeInBytes: keySize)
          return SecurityResultDTO(
            status: .success,
            data: result,
            metadata: ["operation": "generateKey", "keySize": String(keySize)]
          )
        } catch let error as SecurityProtocolError {
          return SecurityResultDTO(
            status: .failure,
            error: error,
            metadata: ["operation": "generateKey"]
          )
        } catch {
          return SecurityResultDTO(
            status: .failure,
            error: SecurityProtocolError.internalError("Key generation failed: \(error)"),
            metadata: ["operation": "generateKey"]
          )
        }

      default:
        return SecurityResultDTO(
          status: .failure,
          error: SecurityProtocolError.unsupportedOperation(name: "\(operation)"),
          metadata: ["operation": "\(operation)"]
        )
    }
  }
}
