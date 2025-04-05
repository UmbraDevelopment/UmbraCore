import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces
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
    public nonisolated let providerType: SecurityProviderType = .cryptoKit

    /// The secure storage used for handling sensitive data
    public let secureStorage: SecureStorageProtocol

    /// Default configuration for operations
    private let defaultConfig: SecurityConfigDTO

    /// Initialises a new Apple security provider
    public init(secureStorage: SecureStorageProtocol) {
      self.secureStorage=secureStorage
      defaultConfig=SecurityConfigDTO(
        encryptionAlgorithm: .aes128GCM,
        hashAlgorithm: .sha256,
        providerType: .cryptoKit,
        options: nil
      )
    }

    /// Initializes the service, performing any necessary setup
    public func initialize() async throws {
      // No additional setup needed for CryptoKit
    }

    // MARK: - CryptoServiceProtocol Implementation

    /// Encrypts binary data using a key from secure storage.
    /// - Parameters:
    ///   - dataIdentifier: Identifier of the data to encrypt in secure storage.
    ///   - keyIdentifier: Identifier of the encryption key in secure storage.
    ///   - options: Optional encryption configuration.
    /// - Returns: Identifier for the encrypted data in secure storage, or an error.
    public func encrypt(
      dataIdentifier: String,
      keyIdentifier: String,
      options _: EncryptionOptions?
    ) async -> Result<String, SecurityStorageError> {
      // Retrieve the data to encrypt
      let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)
      guard case let .success(data)=dataResult else {
        if case let .failure(error)=dataResult {
          return .failure(error)
        }
        return .failure(.dataNotFound)
      }

      // Retrieve the encryption key
      let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)
      guard case let .success(key)=keyResult else {
        if case let .failure(error)=keyResult {
          return .failure(error)
        }
        return .failure(.dataNotFound)
      }

      // Perform encryption
      let encryptResult=await encrypt(data: data, using: key)
      switch encryptResult {
        case let .success(encryptedData):
          // Generate a storage identifier for the encrypted data
          let encryptedIdentifier="encrypted_\(UUID().uuidString)"

          // Store the encrypted data
          let storeResult=await secureStorage.storeData(
            encryptedData,
            withIdentifier: encryptedIdentifier
          )
          switch storeResult {
            case .success:
              return .success(encryptedIdentifier)
            case let .failure(error):
              return .failure(error)
          }
        case let .failure(error):
          return .failure(.operationFailed(error.localizedDescription))
      }
    }

    /// Decrypts binary data using a key from secure storage.
    /// - Parameters:
    ///   - encryptedDataIdentifier: Identifier of the encrypted data in secure storage.
    ///   - keyIdentifier: Identifier of the decryption key in secure storage.
    ///   - options: Optional decryption configuration.
    /// - Returns: Identifier for the decrypted data in secure storage, or an error.
    public func decrypt(
      encryptedDataIdentifier: String,
      keyIdentifier: String,
      options _: DecryptionOptions?
    ) async -> Result<String, SecurityStorageError> {
      // Retrieve the encrypted data
      let encryptedDataResult=await secureStorage
        .retrieveData(withIdentifier: encryptedDataIdentifier)
      guard case let .success(encryptedData)=encryptedDataResult else {
        if case let .failure(error)=encryptedDataResult {
          return .failure(error)
        }
        return .failure(.dataNotFound)
      }

      // Retrieve the decryption key
      let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)
      guard case let .success(key)=keyResult else {
        if case let .failure(error)=keyResult {
          return .failure(error)
        }
        return .failure(.dataNotFound)
      }

      // Perform decryption
      let decryptResult=await decrypt(data: encryptedData, using: key)
      switch decryptResult {
        case let .success(decryptedData):
          // Generate a storage identifier for the decrypted data
          let decryptedIdentifier="decrypted_\(UUID().uuidString)"

          // Store the decrypted data
          let storeResult=await secureStorage.storeData(
            decryptedData,
            withIdentifier: decryptedIdentifier
          )
          switch storeResult {
            case .success:
              return .success(decryptedIdentifier)
            case let .failure(error):
              return .failure(error)
          }
        case let .failure(error):
          return .failure(.operationFailed(error.localizedDescription))
      }
    }

    /// Computes a cryptographic hash of data in secure storage.
    /// - Parameter dataIdentifier: Identifier of the data to hash in secure storage.
    /// - Returns: Identifier for the hash in secure storage, or an error.
    public func hash(
      dataIdentifier: String,
      options _: HashingOptions?
    ) async -> Result<String, SecurityStorageError> {
      // Retrieve the data to hash
      let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)
      guard case let .success(data)=dataResult else {
        if case let .failure(error)=dataResult {
          return .failure(error)
        }
        return .failure(.dataNotFound)
      }

      // Compute the hash
      let hashResult=await hash(data: data)
      switch hashResult {
        case let .success(hashValue):
          // Generate a storage identifier for the hash
          let hashIdentifier="hash_\(UUID().uuidString)"

          // Store the hash
          let storeResult=await secureStorage.storeData(hashValue, withIdentifier: hashIdentifier)
          switch storeResult {
            case .success:
              return .success(hashIdentifier)
            case let .failure(error):
              return .failure(error)
          }
        case let .failure(error):
          return .failure(.operationFailed(error.localizedDescription))
      }
    }

    /// Verifies a cryptographic hash against the expected value, both stored securely.
    /// - Parameters:
    ///   - dataIdentifier: Identifier of the data to verify in secure storage.
    ///   - hashIdentifier: Identifier of the expected hash in secure storage.
    /// - Returns: `true` if the hash matches, `false` if not, or an error.
    public func verifyHash(
      dataIdentifier: String,
      hashIdentifier: String,
      options _: HashingOptions?
    ) async -> Result<Bool, SecurityStorageError> {
      // Retrieve the data to verify
      let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)
      guard case let .success(data)=dataResult else {
        if case let .failure(error)=dataResult {
          return .failure(error)
        }
        return .failure(.dataNotFound)
      }

      // Retrieve the expected hash
      let expectedHashResult=await secureStorage.retrieveData(withIdentifier: hashIdentifier)
      guard case let .success(expectedHash)=expectedHashResult else {
        if case let .failure(error)=expectedHashResult {
          return .failure(error)
        }
        return .failure(.dataNotFound)
      }

      // Compute the hash of the data
      let hashResult=await hash(data: data)
      switch hashResult {
        case let .success(computedHash):
          // Compare the hashes
          let match=(computedHash == expectedHash)
          return .success(match)
        case let .failure(error):
          return .failure(.operationFailed(error.localizedDescription))
      }
    }

    /// Generates a cryptographic key and stores it securely.
    /// - Parameters:
    ///   - length: The length of the key to generate in bytes.
    ///   - options: Optional key generation configuration.
    /// - Returns: Identifier for the generated key in secure storage, or an error.
    public func generateKey(
      length: Int,
      options _: KeyGenerationOptions?
    ) async -> Result<String, SecurityStorageError> {
      // Generate the key (convert length from bytes to bits)
      let keyResult=await generateKey(size: length * 8)
      switch keyResult {
        case let .success(keyData):
          // Generate a storage identifier for the key
          let keyIdentifier="key_\(UUID().uuidString)"

          // Store the key
          let storeResult=await secureStorage.storeData(keyData, withIdentifier: keyIdentifier)
          switch storeResult {
            case .success:
              return .success(keyIdentifier)
            case let .failure(error):
              return .failure(error)
          }
        case let .failure(error):
          return .failure(.operationFailed(error.localizedDescription))
      }
    }

    /// Imports data into secure storage for use with cryptographic operations.
    /// - Parameters:
    ///   - data: The raw data to store securely.
    ///   - customIdentifier: Optional custom identifier for the data. If nil, a random identifier
    /// is generated.
    /// - Returns: The identifier for the data in secure storage, or an error.
    public func importData(
      _ data: [UInt8],
      customIdentifier: String?
    ) async -> Result<String, SecurityStorageError> {
      // Generate an identifier if none provided
      let identifier=customIdentifier ?? "imported_\(UUID().uuidString)"

      // Store the data
      let storeResult=await secureStorage.storeData(data, withIdentifier: identifier)
      switch storeResult {
        case .success:
          return .success(identifier)
        case let .failure(error):
          return .failure(error)
      }
    }

    /// Exports data from secure storage.
    /// - Parameter identifier: The identifier of the data to export.
    /// - Returns: The raw data, or an error.
    /// - Warning: Use with caution as this exposes sensitive data.
    public func exportData(
      identifier: String
    ) async -> Result<[UInt8], SecurityStorageError> {
      // Retrieve the data
      await secureStorage.retrieveData(withIdentifier: identifier)
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
        let nonce=AES.GCM.Nonce()

        // Convert byte array to CryptoKit key format
        let cryptoKitKey=try getCryptoKitSymmetricKey(from: key)

        // Perform the encryption
        let sealedBox=try AES.GCM.seal(Data(data), using: cryptoKitKey, nonce: nonce)

        // Combine nonce and sealed data for storage/transmission
        // Format: [Nonce][Tag][Ciphertext]
        guard let combined=sealedBox.combined else {
          throw CoreSecurityError.cryptoError(
            "Failed to generate combined ciphertext output"
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
        let sealedBox=try AES.GCM.SealedBox(combined: Data(data))

        // Convert byte array to CryptoKit key format
        let cryptoKitKey=try getCryptoKitSymmetricKey(from: key)

        // Perform the decryption
        let decryptedData=try AES.GCM.open(sealedBox, using: cryptoKitKey)

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
        let keySize=size / 8

        // CryptoKit supports 128, 192, and 256-bit keys for AES
        switch keySize {
          case 16: // 128 bits
            let key=SymmetricKey(size: .bits128)
            return .success(key.withUnsafeBytes { [UInt8]($0) })
          case 24: // 192 bits
            let key=SymmetricKey(size: .bits192)
            return .success(key.withUnsafeBytes { [UInt8]($0) })
          case 32: // 256 bits
            let key=SymmetricKey(size: .bits256)
            return .success(key.withUnsafeBytes { [UInt8]($0) })
          default:
            throw CoreSecurityError.invalidInput(
              "Invalid key size, must be 128, 192, or 256 bits"
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
      // Default to SHA-256
      let hashData=SHA256.hash(data: Data(data))
      return .success([UInt8](Data(hashData)))
    }

    // MARK: - Helper Methods

    /**
     Converts a byte array key to a CryptoKit SymmetricKey.

     - Parameter key: The key as byte array
     - Returns: A CryptoKit SymmetricKey
     - Throws: CoreSecurityError if key conversion fails
     */
    private func getCryptoKitSymmetricKey(from key: [UInt8]) throws -> SymmetricKey {
      let keySize=key.count * 8

      // Validate key size
      switch keySize {
        case 128, 192, 256:
          return SymmetricKey(data: Data(key))
        default:
          throw CoreSecurityError.invalidInput(
            "Invalid key size: \(keySize) bits. Must be 128, 192, or 256 bits."
          )
      }
    }

    /**
     Maps errors to the security error domain for consistent error handling
     */
    private func mapToSecurityErrorDomain(_ error: Error) -> Error {
      if let securityError=error as? CoreSecurityError {
        return securityError
      }

      // Map CryptoKit errors
      let nsError=error as NSError
      if nsError.domain == "CryptoKit" {
        switch nsError.code {
          case -1:
            return CoreSecurityError.invalidInput(
              "CryptoKit error: invalid input parameters"
            )
          case -2:
            return CoreSecurityError.keyManagementError(
              "CryptoKit error: key generation failed"
            )
          case -3:
            return CoreSecurityError.authenticationFailed(
              "CryptoKit error: authentication tag verification failed"
            )
          default:
            return CoreSecurityError.cryptoError(
              "CryptoKit error: \(nsError.localizedDescription)"
            )
        }
      }

      return CoreSecurityError.unknownError(
        "Unrecognized error: \(error.localizedDescription)"
      )
    }
  }
#else
  // Empty placeholder for when CryptoKit is not available
  public actor AppleSecurityProvider: CryptoServiceProtocol, AsyncServiceInitializable {
    public nonisolated let providerType: SecurityProviderType = .cryptoKit

    /// The secure storage used for handling sensitive data
    public let secureStorage: SecureStorageProtocol

    /// Initialises a new Apple security provider
    public init(secureStorage: SecureStorageProtocol) {
      self.secureStorage=secureStorage
    }

    /// Initializes the service
    public func initialize() async throws {
      // No initialization needed for non-CryptoKit implementation
    }

    public func encrypt(
      dataIdentifier _: String,
      keyIdentifier _: String,
      options _: EncryptionOptions?
    ) async -> Result<String, SecurityStorageError> {
      .failure(.operationFailed(
        "CryptoKit is not available on this platform"
      ))
    }

    public func decrypt(
      encryptedDataIdentifier _: String,
      keyIdentifier _: String,
      options _: DecryptionOptions?
    ) async -> Result<String, SecurityStorageError> {
      .failure(.operationFailed(
        "CryptoKit is not available on this platform"
      ))
    }

    public func hash(
      dataIdentifier _: String,
      options _: HashingOptions?
    ) async -> Result<String, SecurityStorageError> {
      .failure(.operationFailed(
        "CryptoKit is not available on this platform"
      ))
    }

    public func verifyHash(
      dataIdentifier _: String,
      hashIdentifier _: String,
      options _: HashingOptions?
    ) async -> Result<Bool, SecurityStorageError> {
      .failure(.operationFailed(
        "CryptoKit is not available on this platform"
      ))
    }

    public func generateKey(
      length _: Int,
      options _: KeyGenerationOptions?
    ) async -> Result<String, SecurityStorageError> {
      .failure(.operationFailed(
        "CryptoKit is not available on this platform"
      ))
    }

    public func importData(
      _: [UInt8],
      customIdentifier _: String?
    ) async -> Result<String, SecurityStorageError> {
      .failure(.operationFailed(
        "CryptoKit is not available on this platform"
      ))
    }

    public func exportData(
      identifier _: String
    ) async -> Result<[UInt8], SecurityStorageError> {
      .failure(.operationFailed(
        "CryptoKit is not available on this platform"
      ))
    }

    public func encrypt(
      data _: [UInt8],
      using _: [UInt8]
    ) async -> Result<[UInt8], Error> {
      .failure(CoreSecurityError.cryptoError(
        "CryptoKit is not available on this platform"
      ))
    }

    public func decrypt(
      data _: [UInt8],
      using _: [UInt8]
    ) async -> Result<[UInt8], Error> {
      .failure(CoreSecurityError.cryptoError(
        "CryptoKit is not available on this platform"
      ))
    }

    public func generateKey(size _: Int) async -> Result<[UInt8], Error> {
      .failure(CoreSecurityError.cryptoError(
        "CryptoKit is not available on this platform"
      ))
    }

    public func hash(data _: [UInt8]) async -> Result<[UInt8], Error> {
      .failure(CoreSecurityError.cryptoError(
        "CryptoKit is not available on this platform"
      ))
    }
  }
#endif
