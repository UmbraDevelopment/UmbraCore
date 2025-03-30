import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

/**
 # Standardised Security Interface

 This module provides a unified, consistent interface for security operations
 across the UmbraCore platform. By standardising the interaction patterns,
 error handling, and operation lifecycle, it simplifies integration while
 maintaining strict security controls.

 ## Design Philosophy

 The design follows these core principles:

 1. **Separation of Concerns**: Each operation is encapsulated in its own type,
    with clear responsibilities and boundaries.

 2. **Operation Categorisation**: Operations are organised into logical categories
    with appropriate security levels for access control.

 3. **Uniform Interface**: All operations present the same interface, simplifying
    client integration and enabling composition.

 4. **Security-First**: The implementation prioritises security controls, including
    validation, error handling, and proper resource management.

 ## Usage Patterns

 The typical usage pattern involves:

 1. Creating operation instances through the `StandardSecurityInterface` factory methods
 2. Configuring operations with appropriate parameters
 3. Validating operations before execution (optional but recommended)
 4. Executing operations using the common `perform` method
 5. Handling results and errors in a consistent way

 This approach balances flexibility with security and consistency.
 */

/**
 Protocol defining the standard interface for all security operations.

 This protocol establishes a consistent contract that all security operations must
 implement, enabling uniform handling of different cryptographic operations through
 a common interface.
 */
public protocol StandardSecurityOperation {
  /**
   A unique identifier for the operation.

   This identifier should be globally unique and consistent across application
   restarts. It typically follows a hierarchical format such as:
   "category.operation.variant" (e.g., "encryption.aes.gcm").
   */
  var operationIdentifier: String { get }

  /**
   Human-readable descriptive name of the operation.

   This name is suitable for displaying in logs, user interfaces, or diagnostic
   messages. It should clearly communicate the purpose of the operation to both
   technical and non-technical users.
   */
  var operationName: String { get }

  /**
   The category to which this operation belongs.

   Categorisation enables grouping related operations for access control,
   logging, monitoring, and organisational purposes.
   */
  var category: OperationCategory { get }

  /**
   The security level required for this operation.

   The security level determines the sensitivity of the operation and may
   influence access control decisions, additional verification requirements,
   or special handling procedures.
   */
  var securityLevel: SecurityLevel { get }

  /**
   Executes the security operation with the provided input.

   This method represents the core functionality of the security operation,
   transforming the input data according to the operation's purpose.

   - Parameter input: The input data for the operation
   - Returns: The result of the operation
   - Throws: Operation-specific errors or standard security errors
   */
  func perform(with input: SecureBytes) async throws -> SecureBytes

  /**
   Validates that the operation can be performed with its current configuration.

   Validation should be performed before executing an operation to ensure that all
   prerequisites are met and that the operation parameters are valid. This can
   prevent security issues caused by misconfiguration.

   - Returns: `true` if the operation is valid and can be performed, `false` otherwise
   */
  func validate() -> Bool
}

/**
 Defines the categories of security operations supported by the system.

 Categorisation helps organise operations logically and can be used for
 access control, monitoring, and auditing purposes.
 */
public enum OperationCategory: String, Sendable, Equatable, CaseIterable {
  /// Operations that transform plaintext into ciphertext
  case encryption = "Encryption"
  
  /// Operations that transform ciphertext back into plaintext
  case decryption = "Decryption"
  
  /// Operations that generate or verify digital signatures
  case signature = "Digital Signature"
  
  /// Operations for one-way transformations like hashing
  case hash = "Hash"
  
  /// Operations related to key management (generation, derivation, etc.)
  case keyManagement = "Key Management"
  
  /// Operations for verifying data
  case verification = "Verification"
}

/**
 Defines the security levels for operations, which can be used for access control
 and to determine appropriate handling procedures.

 Security levels provide a way to categorise operations by their sensitivity
 and potential impact if misused.
 */
public enum SecurityLevel: Int, Sendable, Equatable, Comparable, CaseIterable {
  /// Basic security operations with minimal risk
  case low = 0

  /// Standard security operations with moderate risk
  case medium = 1

  /// Sensitive security operations that require careful handling
  case high = 2

  /// Highly sensitive operations that may require additional approvals or controls
  case critical = 3

  public static func < (lhs: SecurityLevel, rhs: SecurityLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

/// Base abstract class for security operations that contains common functionality
public class AbstractSecurityOperation: StandardSecurityOperation {
  public let operationIdentifier: String
  public let operationName: String
  public let category: OperationCategory
  public let securityLevel: SecurityLevel

  public init(
    identifier: String,
    name: String,
    category: OperationCategory,
    securityLevel: SecurityLevel
  ) {
    operationIdentifier = identifier
    operationName = name
    self.category = category
    self.securityLevel = securityLevel
  }

  public func perform(with _: SecureBytes) async throws -> SecureBytes {
    // Abstract method that should be overridden by subclasses
    fatalError("Subclasses must implement perform(with:)")
  }

  public func validate() -> Bool {
    // Default implementation always returns true
    // Subclasses should override this with proper validation
    true
  }
}

/// Custom error type for standardised security operations
public enum StandardSecurityError: Error, LocalizedError {
  case operationFailed(String)
  case validationFailed(String)
  case invalidInput(String)
  case invalidConfiguration(String)

  public var errorDescription: String? {
    switch self {
      case let .operationFailed(message):
        "Operation failed: \(message)"
      case let .validationFailed(message):
        "Validation failed: \(message)"
      case let .invalidInput(message):
        "Invalid input: \(message)"
      case let .invalidConfiguration(message):
        "Invalid configuration: \(message)"
    }
  }
}

/// Standard interface provider that wraps the SecurityProviderProtocol
public actor StandardSecurityInterface {
  private let securityProvider: SecurityProviderProtocol

  /// Initialize with a security provider
  /// - Parameter provider: The security provider to use
  public init(provider: SecurityProviderProtocol) {
    securityProvider = provider
  }
  
  /// Ensure the security provider is properly initialized
  public func initialize() async throws {
    try await securityProvider.initialize()
  }

  /// Create a standard encryption operation
  /// - Parameters:
  ///   - key: The encryption key
  ///   - algorithm: The algorithm to use (e.g., "AES", "RSA")
  ///   - mode: The mode of operation (e.g., "GCM", "CBC")
  /// - Returns: A StandardSecurityOperation for encryption
  public func createEncryptionOperation(
    key: SecureBytes,
    algorithm: String = "AES",
    mode: String = "GCM"
  ) -> StandardSecurityOperation {
    EncryptionOperation(
      provider: securityProvider,
      key: key,
      algorithm: algorithm,
      mode: mode
    )
  }

  /// Create a standard decryption operation
  /// - Parameters:
  ///   - key: The decryption key
  ///   - algorithm: The algorithm to use (e.g., "AES", "RSA")
  ///   - mode: The mode of operation (e.g., "GCM", "CBC")
  /// - Returns: A StandardSecurityOperation for decryption
  public func createDecryptionOperation(
    key: SecureBytes,
    algorithm: String = "AES",
    mode: String = "GCM"
  ) -> StandardSecurityOperation {
    DecryptionOperation(
      provider: securityProvider,
      key: key,
      algorithm: algorithm,
      mode: mode
    )
  }

  /// Create a standard hashing operation
  /// - Parameter algorithm: The hash algorithm to use (e.g., "SHA256", "SHA512")
  /// - Returns: A StandardSecurityOperation for hashing
  public func createHashingOperation(
    algorithm: String = "SHA256"
  ) -> StandardSecurityOperation {
    HashingOperation(
      provider: securityProvider,
      algorithm: algorithm
    )
  }

  /// Create a standard key generation operation
  /// - Parameters:
  ///   - keySize: The size of the key in bits
  ///   - algorithm: The algorithm for which the key will be used (e.g., "AES", "RSA")
  /// - Returns: A StandardSecurityOperation for key generation
  public func createKeyGenerationOperation(
    keySize: Int = 256,
    algorithm: String = "AES"
  ) -> StandardSecurityOperation {
    KeyGenerationOperation(
      provider: securityProvider,
      keySize: keySize,
      algorithm: algorithm
    )
  }
}

/// Concrete implementation of encryption operation
private class EncryptionOperation: AbstractSecurityOperation {
  private let provider: SecurityProviderProtocol
  private let key: SecureBytes
  private let algorithm: String
  private let mode: String

  init(
    provider: SecurityProviderProtocol,
    key: SecureBytes,
    algorithm: String,
    mode: String
  ) {
    self.provider = provider
    self.key = key
    self.algorithm = algorithm
    self.mode = mode

    super.init(
      identifier: "encryption.\(algorithm).\(mode)",
      name: "Encryption (\(algorithm)-\(mode))",
      category: .encryption,
      securityLevel: .high
    )
  }

  public override func perform(with input: SecureBytes) async throws -> SecureBytes {
    // Create configuration with appropriate options and data
    let config = await createConfig(with: input)

    // Perform the encryption operation
    let result = try await provider.encrypt(config: config)

    // Successful result already contains data
    return result.data ?? input
  }
  
  /// Creates a security configuration with the input data
  /// - Parameter input: The input data to encrypt
  /// - Returns: A configured SecurityConfigDTO
  private func createConfig(with input: SecureBytes) async -> SecurityConfigDTO {
    // Create options with all the data we need
    let options: [String: String] = [
      "key": key.base64EncodedString(),
      "data": input.base64EncodedString(),
      "algorithm": algorithm,
      "mode": mode,
      "keySize": "\(key.count * 8)"
    ]
    
    // Create a new configuration with all the required parameters
    return SecurityConfigDTO(
      algorithm: algorithm,
      keySize: key.count * 8,
      mode: mode,
      options: options
    )
  }

  public override func validate() -> Bool {
    !key.isEmpty
  }
}

/// Concrete implementation of decryption operation
private class DecryptionOperation: AbstractSecurityOperation {
  private let provider: SecurityProviderProtocol
  private let key: SecureBytes
  private let algorithm: String
  private let mode: String

  init(
    provider: SecurityProviderProtocol,
    key: SecureBytes,
    algorithm: String,
    mode: String
  ) {
    self.provider = provider
    self.key = key
    self.algorithm = algorithm
    self.mode = mode

    super.init(
      identifier: "decryption.\(algorithm).\(mode)",
      name: "Decryption (\(algorithm)-\(mode))",
      category: .decryption,
      securityLevel: .high
    )
  }

  public override func perform(with input: SecureBytes) async throws -> SecureBytes {
    // Create configuration with appropriate options and data
    let config = await createConfig(with: input)

    // Perform the decryption operation
    let result = try await provider.decrypt(config: config)

    // Successful result already contains data
    return result.data ?? input
  }
  
  /// Creates a security configuration with the input data
  /// - Parameter input: The input data to decrypt
  /// - Returns: A configured SecurityConfigDTO
  private func createConfig(with input: SecureBytes) async -> SecurityConfigDTO {
    // Create options with all the data we need
    let options: [String: String] = [
      "key": key.base64EncodedString(),
      "data": input.base64EncodedString(),
      "algorithm": algorithm,
      "mode": mode,
      "keySize": "\(key.count * 8)"
    ]
    
    // Create a new configuration with all the required parameters
    return SecurityConfigDTO(
      algorithm: algorithm,
      keySize: key.count * 8,
      mode: mode,
      options: options
    )
  }

  public override func validate() -> Bool {
    !key.isEmpty
  }
}

/// Concrete implementation of hashing operation
private class HashingOperation: AbstractSecurityOperation {
  private let provider: SecurityProviderProtocol
  private let algorithm: String

  init(
    provider: SecurityProviderProtocol,
    algorithm: String
  ) {
    self.provider = provider
    self.algorithm = algorithm

    super.init(
      identifier: "hash.\(algorithm)",
      name: "Hash (\(algorithm))",
      category: .hash,
      securityLevel: .medium
    )
  }

  public override func perform(with input: SecureBytes) async throws -> SecureBytes {
    // Get the crypto service from the provider
    let cryptoService = await provider.cryptoService()
    
    // Use the crypto service directly for hashing
    let result = await cryptoService.hash(data: input)
    
    // Check for success and return data
    switch result {
    case .success(let hash):
      return hash
    case .failure(let error):
      throw StandardSecurityError.operationFailed("Hash operation failed: \(error)")
    }
  }

  public override func validate() -> Bool {
    // Simply check if we have a valid algorithm
    ["SHA256", "SHA512", "SHA1", "MD5"].contains(algorithm)
  }
}

/// Concrete implementation of key generation operation
private class KeyGenerationOperation: AbstractSecurityOperation {
  private let provider: SecurityProviderProtocol
  private let keySize: Int
  private let algorithm: String

  init(
    provider: SecurityProviderProtocol,
    keySize: Int,
    algorithm: String
  ) {
    self.provider = provider
    self.keySize = keySize
    self.algorithm = algorithm

    super.init(
      identifier: "generateKey.\(algorithm).\(keySize)",
      name: "Key Generation (\(algorithm) \(keySize)-bit)",
      category: .keyManagement,
      securityLevel: .high
    )
  }

  public override func perform(with input: SecureBytes) async throws -> SecureBytes {
    // Create configuration with appropriate options
    let config = await createConfig()

    // Perform the key generation operation
    let result = try await provider.generateKey(config: config)

    // Check for success
    guard let outputData = result.data else {
      throw StandardSecurityError.operationFailed("Key generation failed")
    }

    return outputData
  }
  
  /// Creates a security configuration for key generation
  /// - Returns: A configured SecurityConfigDTO
  private func createConfig() async -> SecurityConfigDTO {
    // Create a new configuration with the required parameters
    return SecurityConfigDTO(
      algorithm: algorithm,
      keySize: keySize,
      options: [
        "algorithm": algorithm,
        "keySize": "\(keySize)"
      ]
    )
  }

  public override func validate() -> Bool {
    // Validate key size is reasonable
    keySize >= 128 && keySize <= 4096
  }
}
