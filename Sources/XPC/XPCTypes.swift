/// XPC Module
///
/// Provides secure inter-process communication types and services for UmbraCore.
/// This module implements a robust security model for XPC services, ensuring
/// safe and efficient communication between the main application and privileged
/// helper processes.
///
/// # Security Model
///
/// ## Process Isolation
/// The XPC architecture maintains strict process isolation:
/// - Main process: Handles user interface and coordination
/// - Helper process: Performs privileged operations
/// - Separate security contexts
///
/// ## Authentication
/// Services implement multi-layer authentication:
/// 1. Code signing verification
/// 2. Entitlement validation
/// 3. Connection validation
///
/// ## Data Protection
/// Secure data handling across process boundaries:
/// - Memory isolation
/// - Encrypted communication
/// - Sanitised inputs
///
/// # Module Organisation
///
/// ## Core Types
/// ```swift
/// XPCConnection
/// XPCService
/// XPCError
/// ```
///
/// ## Security Types
/// ```swift
/// XPCAuthentication
/// XPCEntitlements
/// XPCValidation
/// ```
///
/// ## Service Types
/// ```swift
/// CryptoXPCService
/// KeychainXPCService
/// ```
///
/// # Cryptographic Implementation
///
/// ## Cross-Process Encryption
/// Uses CryptoSwift for XPC operations:
/// - Platform-independent implementation
/// - Suitable for cross-process communication
/// - No hardware-backed requirements
///
/// ## Key Management
/// - Ephemeral session keys
/// - Secure key exchange
/// - Regular key rotation
///
/// # Error Handling
/// XPC errors are categorised into:
/// - Connection errors
/// - Authentication failures
/// - Protocol violations
/// - Service errors
///
/// # Usage Example
/// ```swift
/// let service = CryptoXPCService()
/// try await service.connect()
/// let result = try await service.encrypt(data)
/// ```
///
/// # Thread Safety
/// All XPC types are designed for concurrent use:
/// - Actor-based service implementations
/// - Async/await API design
/// - Safe state management
public enum XPCTypes {
  /// Current version of the XPC module
  public static let version="1.0.0"

  /// Initialise XPC services with default configuration
  public static func initialize() {
    // Configure XPC services
  }
}
