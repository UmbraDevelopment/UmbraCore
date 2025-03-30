import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

#if canImport(CryptoKit)
  import CryptoKit

  /**
   # AppleSecurityProvider

   Native Apple security provider implementation using the CryptoKit framework.

   This provider offers high-performance cryptographic operations optimised for
   Apple platforms, with hardware acceleration on supported devices. It provides
   modern cryptographic algorithms and follows Apple's security best practices.

   ## Security Features

   - Uses AES-GCM for authenticated encryption
   - Provides secure key generation and management
   - Utilises hardware acceleration where available
   - Uses modern cryptographic hash functions

   ## Platform Support

   This provider is only available on Apple platforms that support CryptoKit:
   - macOS 10.15+
   - iOS 13.0+
   - tvOS 13.0+
   - watchOS 6.0+
   */
  public actor AppleSecurityProvider: CryptoServiceProtocol, AsyncServiceInitializable {
    /// The type of provider implementation (accessible from any actor context)
    public nonisolated let providerType: SecurityProviderType = .apple

    /// Initialises a new Apple security provider
    public init() {}
    
    /// Initializes the service, performing any necessary setup
    public func initialize() async throws {
      // No additional setup needed for CryptoKit
    }

    /**
     Encrypts data using AES-GCM via CryptoKit.

     - Parameters:
        - data: Data to encrypt
        - key: Encryption key
     - Returns: Result with encrypted data or error
     */
    public func encrypt(
      data: SecureBytes,
      using key: SecureBytes
    ) async -> Result<SecureBytes, Error> {
      do {
        // Generate a random nonce for encryption
        let nonce = try AES.GCM.Nonce()
        
        // Convert SecureBytes to CryptoKit key format
        let cryptoKitKey = try getCryptoKitSymmetricKey(from: key)
        
        // Perform the encryption
        let sealedBox = try AES.GCM.seal(data.data, using: cryptoKitKey, nonce: nonce)
        
        // Combine nonce and sealed data for storage/transmission
        // Format: [Nonce][Tag][Ciphertext]
        guard let combined = sealedBox.combined else {
          throw SecurityErrorDomain.cryptographicError(
            reason: "Failed to generate combined ciphertext output"
          )
        }
        
        return .success(SecureBytes(data: combined))
      } catch {
        return .failure(mapToSecurityErrorDomain(error))
      }
    }

    /**
     Decrypts data using AES-GCM via CryptoKit.

     - Parameters:
        - data: Data to decrypt (must include nonce, tag, and ciphertext)
        - key: Decryption key
     - Returns: Result with decrypted data or error
     */
    public func decrypt(
      data: SecureBytes,
      using key: SecureBytes
    ) async -> Result<SecureBytes, Error> {
      do {
        // Create a sealed box from the combined format
        let sealedBox = try AES.GCM.SealedBox(combined: data.data)
        
        // Convert SecureBytes to CryptoKit key format
        let cryptoKitKey = try getCryptoKitSymmetricKey(from: key)
        
        // Perform the decryption
        let decryptedData = try AES.GCM.open(sealedBox, using: cryptoKitKey)
        
        return .success(SecureBytes(data: decryptedData))
      } catch {
        return .failure(mapToSecurityErrorDomain(error))
      }
    }

    /**
     Generates a cryptographic key of the specified size.

     - Parameter size: Key size in bits (128, 192, or 256)
     - Returns: Result with generated key or error
     */
    public func generateKey(size: Int) async -> Result<SecureBytes, Error> {
      do {
        // Convert bits to bytes
        let keySize = size / 8
        
        // CryptoKit supports 128, 192, and 256-bit keys for AES
        switch keySize {
        case 16: // 128 bits
          let key = SymmetricKey(size: .bits128)
          return .success(SecureBytes(data: key.withUnsafeBytes { Data($0) }))
        case 24: // 192 bits
          let key = SymmetricKey(size: .bits192)
          return .success(SecureBytes(data: key.withUnsafeBytes { Data($0) }))
        case 32: // 256 bits
          let key = SymmetricKey(size: .bits256)
          return .success(SecureBytes(data: key.withUnsafeBytes { Data($0) }))
        default:
          throw SecurityErrorDomain.invalidInput(
            reason: "Invalid key size, must be 128, 192, or 256 bits"
          )
        }
      } catch {
        return .failure(mapToSecurityErrorDomain(error))
      }
    }

    /**
     Computes a cryptographic hash of the provided data.

     - Parameter data: Data to hash (default algorithm: SHA-256)
     - Returns: Result with hash value or error
     */
    public func hash(data: SecureBytes) async -> Result<SecureBytes, Error> {
      do {
        // Default to SHA-256
        let hashData = SHA256.hash(data: data.data)
        return .success(SecureBytes(data: Data(hashData)))
      } catch {
        return .failure(mapToSecurityErrorDomain(error))
      }
    }
    
    // MARK: - Helper Methods
    
    /**
     Converts a SecureBytes key to a CryptoKit SymmetricKey.
     
     - Parameter key: The key as SecureBytes
     - Returns: A CryptoKit SymmetricKey
     - Throws: SecurityErrorDomain if key conversion fails
     */
    private func getCryptoKitSymmetricKey(from key: SecureBytes) throws -> SymmetricKey {
      let keySize = key.count * 8
      
      // Validate key size
      switch keySize {
      case 128, 192, 256:
        return SymmetricKey(data: key.data)
      default:
        throw SecurityErrorDomain.invalidInput(
          reason: "Invalid key size: \(keySize) bits. Must be 128, 192, or 256 bits."
        )
      }
    }
    
    /**
     Maps any error to the appropriate SecurityErrorDomain case
     
     - Parameter error: The original error
     - Returns: A SecurityErrorDomain error
     */
    private func mapToSecurityErrorDomain(_ error: Error) -> Error {
      if let securityError = error as? SecurityErrorDomain {
        return securityError
      }
      
      // CryptoKit specific error handling
      if let cryptoKitError = error as? CryptoKitError {
        switch cryptoKitError {
        case .incorrectKeySize:
          return SecurityErrorDomain.invalidKey(
            reason: "CryptoKit error: incorrect key size"
          )
        case .incorrectParameterSize:
          return SecurityErrorDomain.invalidInput(
            reason: "CryptoKit error: incorrect parameter size"
          )
        case .authenticationFailure:
          return SecurityErrorDomain.cryptographicError(
            reason: "CryptoKit error: authentication failure during decryption"
          )
        case .underlyingCoreCryptoError(let status):
          return SecurityErrorDomain.cryptographicError(
            reason: "CryptoKit underlying CoreCrypto error: \(status)"
          )
        @unknown default:
          return SecurityErrorDomain.cryptographicError(
            reason: "Unknown CryptoKit error: \(cryptoKitError.localizedDescription)"
          )
        }
      }
      
      return SecurityErrorDomain.operationFailed(
        reason: "Apple CryptoKit operation failed: \(error.localizedDescription)"
      )
    }
  }
#else
  // Empty placeholder for when CryptoKit is not available
  public actor AppleSecurityProvider: CryptoServiceProtocol, AsyncServiceInitializable {
    public nonisolated let providerType: SecurityProviderType = .apple

    public init() {}
    
    public func initialize() async throws {
      throw SecurityErrorDomain.unsupportedOperation(
        name: "Apple CryptoKit is not available on this platform"
      )
    }

    public func encrypt(data: SecureBytes, using key: SecureBytes) async -> Result<SecureBytes, Error> {
      return .failure(SecurityErrorDomain.unsupportedOperation(
        name: "Apple CryptoKit encryption is not available on this platform"
      ))
    }

    public func decrypt(data: SecureBytes, using key: SecureBytes) async -> Result<SecureBytes, Error> {
      return .failure(SecurityErrorDomain.unsupportedOperation(
        name: "Apple CryptoKit decryption is not available on this platform"
      ))
    }

    public func generateKey(size: Int) async -> Result<SecureBytes, Error> {
      return .failure(SecurityErrorDomain.unsupportedOperation(
        name: "Apple CryptoKit key generation is not available on this platform"
      ))
    }

    public func hash(data: SecureBytes) async -> Result<SecureBytes, Error> {
      return .failure(SecurityErrorDomain.unsupportedOperation(
        name: "Apple CryptoKit hashing is not available on this platform"
      ))
    }
  }
#endif
