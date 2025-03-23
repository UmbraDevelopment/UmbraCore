import ErrorHandlingCore
import ErrorHandlingDomains
import ErrorHandlingInterfaces
import ErrorHandlingMapping
import Foundation
import UmbraCoreTypes
import XPCProtocolsCore

/// Base protocol for all XPC services
///
/// **Migration Notice:**
/// This protocol is deprecated and will be removed in a future release.
/// Please use `XPCServiceProtocolBasic` from the XPCProtocolsCore module instead.
///
/// See `XPCProtocolMigrationGuide` for comprehensive migration guidance.
@available(*, deprecated, message: "Use XPCServiceProtocolBasic from XPCProtocolsCore instead")
@objc
public protocol XPCServiceProtocol {
  /// Validates the connection with the service
  func validateConnection(withReply reply: @escaping (Bool, Error?) -> Void)

  /// Gets the service version
  func getServiceVersion(withReply reply: @escaping (String) -> Void)
}

/// Modern crypto XPC service protocol that conforms to XPCServiceProtocolStandard
/// Uses Objective-C compatible method signatures with completion handlers
///
/// **Migration Notice:**
/// This protocol is deprecated and will be removed in a future release.
/// Please use `XPCServiceProtocolStandard` or `XPCServiceProtocolComplete` from
/// the XPCProtocolsCore module instead.
///
/// See `XPCProtocolMigrationGuide` for comprehensive migration guidance.
@available(*, deprecated, message: "Use XPCServiceProtocolComplete from XPCProtocolsCore instead")
@objc(ModernCryptoXPCServiceProtocol)
public protocol ModernCryptoXPCServiceProtocol: XPCServiceProtocol {
  /// Encrypts data using the specified key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - completion: Completion handler with encrypted data or error
  func encrypt(_ data: Data, key: Data, completion: @escaping (Data?, Error?) -> Void)

  /// Decrypts data using the specified key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - completion: Completion handler with decrypted data or error
  func decrypt(_ data: Data, key: Data, completion: @escaping (Data?, Error?) -> Void)

  /// Generates a cryptographic key of the specified bit length
  /// - Parameters:
  ///   - bits: Key length in bits (typically 128, 256)
  ///   - completion: Completion handler with generated key data or error
  func generateKey(bits: Int, completion: @escaping (Data?, Error?) -> Void)

  /// Generates secure random data of the specified length
  /// - Parameters:
  ///   - length: Length of random data in bytes
  ///   - completion: Completion handler with random data or error
  func generateSecureRandomData(length: Int, completion: @escaping (Data?, Error?) -> Void)

  /// Stores a credential securely
  /// - Parameters:
  ///   - credential: Credential data to store
  ///   - identifier: Unique identifier for the credential
  ///   - completion: Completion handler with success or error
  func storeSecurely(_ credential: Data, identifier: String, completion: @escaping (Error?) -> Void)

  /// Retrieves a credential stored securely
  /// - Parameters:
  ///   - identifier: Unique identifier for the credential
  ///   - completion: Completion handler with retrieved credential data or error
  func retrieveSecurely(identifier: String, completion: @escaping (Data?, Error?) -> Void)

  /// Deletes a securely stored credential
  /// - Parameters:
  ///   - identifier: Unique identifier for the credential
  ///   - completion: Completion handler with success or error
  func deleteSecurely(identifier: String, completion: @escaping (Error?) -> Void)

  /// Validate the connection to the XPC service
  func validateConnection(completion: @escaping (Bool, Error?) -> Void)

  /// Get the version of the XPC service
  func getServiceVersion(completion: @escaping (String, Error?) -> Void)
}

/// Extension to provide async/await wrappers for the Objective-C compatible methods
#if swift(>=5.0)
  @available(*, deprecated, message: "Use XPCServiceProtocolComplete from XPCProtocolsCore instead")
#endif
extension ModernCryptoXPCServiceProtocol {
  /// Async wrapper for encrypt
  public func encrypt(
    _ data: Data,
    key: Data
  ) async -> Result<Data, ErrorHandlingDomains.SecurityError> {
    await withCheckedContinuation { continuation in
      encrypt(data, key: key) { data, error in
        if let error=error as? ErrorHandlingDomains.SecurityError {
          continuation.resume(returning: .failure(error))
        } else if let error {
          continuation
            .resume(returning: .failure(
              ErrorHandlingCore.Error
                .internalError(description: error.localizedDescription)
            ))
        } else if let data {
          continuation.resume(returning: .success(data))
        } else {
          continuation
            .resume(returning: .failure(
              ErrorHandlingCore.Error
                .internalError(description: "Unknown error in encrypt")
            ))
        }
      }
    }
  }

  /// Async wrapper for decrypt
  public func decrypt(
    _ data: Data,
    key: Data
  ) async -> Result<Data, ErrorHandlingDomains.SecurityError> {
    await withCheckedContinuation { continuation in
      decrypt(data, key: key) { data, error in
        if let error=error as? ErrorHandlingDomains.SecurityError {
          continuation.resume(returning: .failure(error))
        } else if let error {
          continuation
            .resume(returning: .failure(
              ErrorHandlingCore.Error
                .internalError(description: error.localizedDescription)
            ))
        } else if let data {
          continuation.resume(returning: .success(data))
        } else {
          continuation
            .resume(returning: .failure(
              ErrorHandlingCore.Error
                .internalError(description: "Unknown error in decrypt")
            ))
        }
      }
    }
  }

  /// Async wrapper for generateKey
  public func generateKey(bits: Int) async -> Result<Data, ErrorHandlingDomains.SecurityError> {
    await withCheckedContinuation { continuation in
      generateKey(bits: bits) { data, error in
        if let error=error as? ErrorHandlingDomains.SecurityError {
          continuation.resume(returning: .failure(error))
        } else if let error {
          continuation
            .resume(returning: .failure(
              ErrorHandlingCore.Error
                .internalError(description: error.localizedDescription)
            ))
        } else if let data {
          continuation.resume(returning: .success(data))
        } else {
          continuation
            .resume(
              returning: .failure(
                ErrorHandlingCore.Error
                  .internalError(description: "Unknown error in generateKey")
              )
            )
        }
      }
    }
  }

  /// Async wrapper for generateSecureRandomData
  public func generateSecureRandomData(length: Int) async
  -> Result<Data, ErrorHandlingDomains.SecurityError> {
    await withCheckedContinuation { continuation in
      generateSecureRandomData(length: length) { data, error in
        if let error=error as? ErrorHandlingDomains.SecurityError {
          continuation.resume(returning: .failure(error))
        } else if let error {
          continuation
            .resume(returning: .failure(
              ErrorHandlingCore.Error
                .internalError(description: error.localizedDescription)
            ))
        } else if let data {
          continuation.resume(returning: .success(data))
        } else {
          continuation
            .resume(
              returning: .failure(
                ErrorHandlingCore.Error
                  .internalError(description: "Unknown error in generateSecureRandomData")
              )
            )
        }
      }
    }
  }

  /// Async wrapper for storeSecurely
  public func storeSecurely(
    _ credential: Data,
    identifier: String
  ) async -> Result<Void, ErrorHandlingDomains.SecurityError> {
    await withCheckedContinuation { continuation in
      storeSecurely(credential, identifier: identifier) { error in
        if let error=error as? ErrorHandlingDomains.SecurityError {
          continuation.resume(returning: .failure(error))
        } else if let error {
          continuation
            .resume(returning: .failure(
              ErrorHandlingCore.Error
                .internalError(description: error.localizedDescription)
            ))
        } else {
          continuation.resume(returning: .success(()))
        }
      }
    }
  }

  /// Async wrapper for retrieveSecurely
  public func retrieveSecurely(identifier: String) async
  -> Result<Data, ErrorHandlingDomains.SecurityError> {
    await withCheckedContinuation { continuation in
      retrieveSecurely(identifier: identifier) { data, error in
        if let error=error as? ErrorHandlingDomains.SecurityError {
          continuation.resume(returning: .failure(error))
        } else if let error {
          continuation
            .resume(returning: .failure(
              ErrorHandlingCore.Error
                .internalError(description: error.localizedDescription)
            ))
        } else if let data {
          continuation.resume(returning: .success(data))
        } else {
          continuation
            .resume(
              returning: .failure(
                ErrorHandlingCore.Error
                  .internalError(description: "Unknown error in retrieveSecurely")
              )
            )
        }
      }
    }
  }

  /// Async wrapper for deleteSecurely
  public func deleteSecurely(identifier: String) async
  -> Result<Void, ErrorHandlingDomains.SecurityError> {
    await withCheckedContinuation { continuation in
      deleteSecurely(identifier: identifier) { error in
        if let error=error as? ErrorHandlingDomains.SecurityError {
          continuation.resume(returning: .failure(error))
        } else if let error {
          continuation
            .resume(returning: .failure(
              ErrorHandlingCore.Error
                .internalError(description: error.localizedDescription)
            ))
        } else {
          continuation.resume(returning: .success(()))
        }
      }
    }
  }

  /// Async wrapper for validateConnection
  public func validateConnection() async -> Result<Bool, ErrorHandlingDomains.SecurityError> {
    await withCheckedContinuation { continuation in
      validateConnection { isValid, error in
        if let error=error as? ErrorHandlingDomains.SecurityError {
          continuation.resume(returning: .failure(error))
        } else if let error {
          continuation
            .resume(returning: .failure(
              ErrorHandlingCore.Error
                .internalError(description: error.localizedDescription)
            ))
        } else {
          continuation.resume(returning: .success(isValid))
        }
      }
    }
  }

  /// Async wrapper for getServiceVersion
  public func getServiceVersion() async -> Result<String, ErrorHandlingDomains.SecurityError> {
    await withCheckedContinuation { continuation in
      getServiceVersion { version, error in
        if let error=error as? ErrorHandlingDomains.SecurityError {
          continuation.resume(returning: .failure(error))
        } else if let error {
          continuation
            .resume(returning: .failure(
              ErrorHandlingCore.Error
                .internalError(description: error.localizedDescription)
            ))
        } else {
          continuation.resume(returning: .success(version))
        }
      }
    }
  }
}

/// Security XPC service protocol that provides ObjC compatibility for security bookmarks
/// Note: This doesn't inherit from XPCServiceProtocolStandard to avoid @objc compatibility issues
///
/// **Migration Notice:**
/// This protocol is deprecated and will be removed in a future release.
/// Please use `XPCServiceProtocolComplete` from the XPCProtocolsCore module instead,
/// which provides equivalent functionality with improved error handling.
///
/// See `XPCProtocolMigrationGuide` for comprehensive migration guidance.
@available(*, deprecated, message: "Use XPCServiceProtocolComplete from XPCProtocolsCore instead")
@objc(SecurityXPCServiceProtocol)
public protocol SecurityXPCServiceProtocol: NSObjectProtocol {
  /// Creates a security-scoped bookmark
  func createBookmark(
    forPath path: String,
    withReply reply: @escaping ([UInt8]?, Error?) -> Void
  )

  /// Resolves a security-scoped bookmark
  func resolveBookmark(
    _ bookmarkData: [UInt8],
    withReply reply: @escaping (String?, Bool, Error?) -> Void
  )

  /// Validates a security-scoped bookmark
  func validateBookmark(
    _ bookmarkData: [UInt8],
    withReply reply: @escaping (Bool, Error?) -> Void
  )

  /// Validate the connection to the XPC service
  func validateConnection(completion: @escaping (Bool, Error?) -> Void)

  /// Gets the version of the XPC service
  func getServiceVersion(completion: @escaping (String?, Error?) -> Void)

  func validateAccess(forResource resource: String) async throws -> Bool
  func requestPermission(forResource resource: String) async throws -> Bool
  func revokePermission(forResource resource: String) async throws
  func getCurrentPermissions() async throws -> [String: Bool]
}

/// Adapter to bridge between SecurityXPCServiceProtocol and XPCServiceProtocolStandard
///
/// **Migration Notice:**
/// This adapter is designed to aid in the migration from legacy SecurityXPCServiceProtocol
/// to modern XPCServiceProtocolComplete implementations. For new code, use
/// ModernXPCService from XPCProtocolsCore directly instead of this adapter.
///
/// Example usage:
/// ```swift
/// // Legacy code:
/// let legacyService = obtainLegacySecurityXPCService()
///
/// // Migration step:
/// let modernService = XPCProtocolMigrationFactory.createCompleteAdapter()
/// let adapter = SecurityXPCServiceAdapter(standardService: modernService)
///
/// // Future code:
/// let modernService = ModernXPCService()
/// ```
@available(*, deprecated, message: "Use ModernXPCService from XPCProtocolsCore directly")
public class SecurityXPCServiceAdapter {
  private let standardService: any XPCServiceProtocolStandard

  public init(standardService: any XPCServiceProtocolStandard) {
    self.standardService=standardService
  }

  /// Creates a modern service implementation using the factory
  ///
  /// This is the recommended way to create a new instance for migration
  public static func createModernServiceAdapter() -> SecurityXPCServiceAdapter {
    let modernService=XPCProtocolMigrationFactory.createStandardAdapter()
    return SecurityXPCServiceAdapter(standardService: modernService)
  }

  // Bridge implementations between the protocols can be added here
}

/// Extension adding support for Swift concurrency to the legacy objective-C compatible protocol
#if swift(>=5.0)
  @available(*, deprecated, message: "Use XPCServiceProtocolComplete from XPCProtocolsCore instead")
#endif
extension SecurityXPCServiceProtocol {
  public func createBookmarkAsync(forPath path: String) async throws -> [UInt8] {
    try await withCheckedThrowingContinuation { continuation in
      createBookmark(forPath: path) { data, error in
        if let error {
          continuation.resume(throwing: error)
        } else if let data {
          continuation.resume(returning: data)
        } else {
          continuation.resume(throwing: NSError(
            domain: "SecurityXPCService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Unknown error creating bookmark"]
          ))
        }
      }
    }
  }

  public func resolveBookmarkAsync(_ bookmarkData: [UInt8]) async throws
  -> (path: String, isStale: Bool) {
    try await withCheckedThrowingContinuation { continuation in
      resolveBookmark(bookmarkData) { path, isStale, error in
        if let error {
          continuation.resume(throwing: error)
        } else if let path {
          continuation.resume(returning: (path, isStale))
        } else {
          continuation.resume(throwing: NSError(
            domain: "SecurityXPCService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Unknown error resolving bookmark"]
          ))
        }
      }
    }
  }

  public func validateBookmarkAsync(_ bookmarkData: [UInt8]) async throws -> Bool {
    try await withCheckedThrowingContinuation { continuation in
      validateBookmark(bookmarkData) { isValid, error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: isValid)
        }
      }
    }
  }

  public func validateConnectionAsync() async throws -> Bool {
    try await withCheckedThrowingContinuation { continuation in
      validateConnection { isValid, error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: isValid)
        }
      }
    }
  }

  public func getServiceVersionAsync() async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
      getServiceVersion { version, error in
        if let error {
          continuation.resume(throwing: error)
        } else if let version {
          continuation.resume(returning: version)
        } else {
          continuation.resume(throwing: NSError(
            domain: "SecurityXPCService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Unknown error getting service version"]
          ))
        }
      }
    }
  }
}
