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
      data: [UInt8],
      using key: [UInt8]
    ) async -> Result<[UInt8], Error> {
      do {
        // Generate a random nonce for encryption
        let nonce = try AES.GCM.Nonce()

        // Convert byte array to CryptoKit key format
        let cryptoKitKey = try getCryptoKitSymmetricKey(from: key)

        // Perform the encryption
        let sealedBox = try AES.GCM.seal(Data(data), using: cryptoKitKey, nonce: nonce)

        // Combine nonce and sealed data for storage/transmission
        // Format: [Nonce][Tag][Ciphertext]
        guard let combined = sealedBox.combined else {
          throw SecurityErrorDomain.cryptographicError(
            reason: "Failed to generate combined ciphertext output"
          )
        }

        return .success([UInt8](combined))
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
      data: [UInt8],
      using key: [UInt8]
    ) async -> Result<[UInt8], Error> {
      do {
        // Create a sealed box from the combined format
        let sealedBox = try AES.GCM.SealedBox(combined: Data(data))

        // Convert byte array to CryptoKit key format
        let cryptoKitKey = try getCryptoKitSymmetricKey(from: key)

        // Perform the decryption
        let decryptedData = try AES.GCM.open(sealedBox, using: cryptoKitKey)

        return .success([UInt8](decryptedData))
      } catch {
        return .failure(mapToSecurityErrorDomain(error))
      }
    }

    /**
     Generates a cryptographic key of the specified size.

     - Parameter size: Key size in bits (128, 192, or 256)
     - Returns: Result with generated key or error
     */
    public func generateKey(size: Int) async -> Result<[UInt8], Error> {
      do {
        // Convert bits to bytes
        let keySize = size / 8

        // CryptoKit supports 128, 192, and 256-bit keys for AES
        switch keySize {
          case 16: // 128 bits
            let key = SymmetricKey(size: .bits128)
            return .success(key.withUnsafeBytes { [UInt8]($0) })
          case 24: // 192 bits
            let key = SymmetricKey(size: .bits192)
            return .success(key.withUnsafeBytes { [UInt8]($0) })
          case 32: // 256 bits
            let key = SymmetricKey(size: .bits256)
            return .success(key.withUnsafeBytes { [UInt8]($0) })
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
    public func hash(data: [UInt8]) async -> Result<[UInt8], Error> {
      do {
        // Default to SHA-256
        let hashData = SHA256.hash(data: Data(data))
        return .success([UInt8](Data(hashData)))
      } catch {
        return .failure(mapToSecurityErrorDomain(error))
      }
    }

    // MARK: - Helper Methods

    /**
     Converts a byte array key to a CryptoKit SymmetricKey.

     - Parameter key: The key as byte array
     - Returns: A CryptoKit SymmetricKey
     - Throws: SecurityErrorDomain if key conversion fails
     */
    private func getCryptoKitSymmetricKey(from key: [UInt8]) throws -> SymmetricKey {
      let keySize = key.count * 8

      // Validate key size
      switch keySize {
        case 128, 192, 256:
          return SymmetricKey(data: Data(key))
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
            return SecurityErrorDomain.authenticationFailure(
              reason: "CryptoKit error: authentication tag verification failed"
            )
          case .underlyingCoreCryptoError:
            return SecurityErrorDomain.cryptographicError(
              reason: "CryptoKit error: underlying CoreCrypto operation failed"
            )
          @unknown default:
            return SecurityErrorDomain.cryptographicError(
              reason: "Unknown CryptoKit error: \(cryptoKitError)"
            )
        }
      }

      // Handle other error types
      return SecurityErrorDomain.cryptographicError(
        reason: "Cryptographic operation failed: \(error.localizedDescription)"
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
        reason: "CryptoKit is not available on this platform"
      )
    }

    public func encrypt(
      data: [UInt8],
      using key: [UInt8]
    ) async -> Result<[UInt8], Error> {
      return .failure(SecurityErrorDomain.unsupportedOperation(
        reason: "CryptoKit is not available on this platform"
      ))
    }

    public func decrypt(
      data: [UInt8],
      using key: [UInt8]
    ) async -> Result<[UInt8], Error> {
      return .failure(SecurityErrorDomain.unsupportedOperation(
        reason: "CryptoKit is not available on this platform"
      ))
    }

    public func generateKey(size: Int) async -> Result<[UInt8], Error> {
      return .failure(SecurityErrorDomain.unsupportedOperation(
        reason: "CryptoKit is not available on this platform"
      ))
    }

    public func hash(data: [UInt8]) async -> Result<[UInt8], Error> {
      return .failure(SecurityErrorDomain.unsupportedOperation(
        reason: "CryptoKit is not available on this platform"
      ))
    }
  }
#endif
