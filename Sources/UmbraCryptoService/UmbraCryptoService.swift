/// UmbraCryptoService Module
///
/// Provides cryptographic services for UmbraCore, implementing both
/// hardware-backed and software-based cryptographic operations.
///
/// # Key Features
/// - Hardware security integration
/// - Key management
/// - Encryption operations
/// - Secure storage
///
/// # Module Organisation
///
/// ## Core Types
/// ```swift
/// CryptoService
/// KeyManager
/// EncryptionContext
/// ```
///
/// ## Operations
/// ```swift
/// Encryptor
/// Decryptor
/// KeyGenerator
/// ```
///
/// ## Security
/// ```swift
/// SecurityProvider
/// SecureEnclave
/// KeychainAccess
/// ```
///
/// # Cryptographic Operations
///
/// ## Encryption
/// Encryption capabilities:
/// - AES-256-GCM
/// - ChaCha20-Poly1305
/// - RSA encryption
///
/// ## Key Generation
/// Key generation features:
/// - Secure key generation
/// - Key derivation
/// - Key rotation
///
/// # Hardware Integration
///
/// ## Secure Enclave
/// Hardware security:
/// - Key storage
/// - Biometric auth
/// - Secure operations
///
/// ## Performance
/// Hardware acceleration:
/// - AES acceleration
/// - SHA acceleration
/// - Secure random
///
/// # Key Management
///
/// ## Storage
/// Secure key storage:
/// - Keychain storage
/// - Secure enclave
/// - Memory protection
///
/// ## Lifecycle
/// Key lifecycle management:
/// - Key creation
/// - Key rotation
/// - Key deletion
///
/// # Usage Example
/// ```swift
/// let service = CryptoService.shared
///
/// let encrypted = try await service.encrypt(
///     data: data,
///     using: .aes256gcm
/// )
/// ```
///
/// # Security Considerations
///
/// ## Key Protection
/// Key security measures:
/// - Access control
/// - Usage limits
/// - Audit logging
///
/// ## Memory Safety
/// Secure memory handling:
/// - Secure memory
/// - Zero-fill
/// - Memory locking
///
/// # Thread Safety
/// Cryptographic operations are thread-safe:
/// - Concurrent operations
/// - Context isolation
/// - Resource protection
public enum UmbraCryptoService {
  /// Current version of the UmbraCryptoService module
  public static let version = "1.0.0"

  /// Initialise UmbraCryptoService with default configuration
  public static func initialize() {
    // Configure crypto service
  }
}
