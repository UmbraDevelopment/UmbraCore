import CoreInterfaces
import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 # Security Provider Adapter

 This actor implements the adapter pattern to bridge between the CoreSecurityProviderProtocol
 and the full SecurityProviderProtocol implementation.

 ## Purpose

 - Provides a simplified interface for core modules to access security functionality
 - Delegates operations to the actual security implementation
 - Converts between data types as necessary
 - Ensures thread safety through the actor concurrency model

 ## Design Pattern

 This adapter follows the classic adapter design pattern, where it implements
 one interface (CoreSecurityProviderProtocol) while wrapping an instance of another
 interface (SecurityProviderProtocol).
 */
public actor SecurityProviderAdapter: CoreSecurityProviderProtocol {
  // MARK: - Properties

  /**
   The underlying security provider implementation

   This is the adaptee in the adapter pattern.
   */
  private let securityProvider: SecurityProviderProtocol

  /**
   Domain-specific logger for security operations

   Used for privacy-aware logging of security operations.
   */
  private let logger: DomainLogger

  // MARK: - Initialisation

  /**
   Creates a new security provider adapter with the provided implementation

   - Parameter securityProvider: The security provider implementation to adapt
   */
  public init(securityProvider: SecurityProviderProtocol) {
    self.securityProvider=securityProvider
    // Create a domain logger for security operations
    logger=LoggerFactory.createSecurityLogger(source: "SecurityProviderAdapter")

    Task {
      await logInitialisation()
    }
  }

  /**
   Log the initialisation of the adapter
   */
  private func logInitialisation() async {
    let context=CoreLogContext.initialisation(
      source: "SecurityProviderAdapter.init"
    )

    await logger.info("Security provider adapter initialised", context: context)
  }

  // MARK: - CoreSecurityProviderProtocol Implementation

  /**
   Initialises the security provider

   This method ensures the underlying security provider is properly initialised.
   With actor-based implementations, this may redirect to the underlying provider's
   initialize() method.

   - Throws: SecurityError if initialisation fails
   */
  public func initialise() async throws {
    let context=CoreLogContext.initialisation(
      source: "SecurityProviderAdapter.initialise"
    )

    await logger.debug("Initialising security provider", context: context)

    do {
      try await securityProvider.initialize()
      await logger.debug("Security provider initialised successfully", context: context)
    } catch {
      let loggableError=LoggableErrorDTO(
        error: error,
        message: "Failed to initialise security provider",
        details: "Initialisation failed in the underlying provider"
      )

      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )

      throw adaptError(error)
    }
  }

  /**
   Encrypts data with the provided key

   Delegates to the underlying security provider implementation.

   - Parameters:
     - data: The data to encrypt
     - key: The encryption key
   - Returns: The encrypted data
   - Throws: SecurityError if encryption fails
   */
  public func encrypt(data: Data, key: Data) async throws -> Data {
    let context=CoreLogContext(
      source: "SecurityProviderAdapter.encrypt",
      metadata: {
        var metadata=LogMetadataDTOCollection()
        metadata=metadata.withPrivate(key: "dataSize", value: String(data.count))
        metadata=metadata.withPrivate(key: "keySize", value: String(key.count))
        return metadata
      }()
    )

    await logger.debug("Encrypting data", context: context)

    do {
      // Create the secure bytes from data
      let secureData=SendableCryptoMaterial(bytes: [UInt8](data))
      let secureKey=SendableCryptoMaterial(bytes: [UInt8](key))

      // Create the configuration for encryption
      let config=SecurityConfigDTO(
        operation: .encrypt,
        key: secureKey,
        data: secureData,
        algorithm: "AES",
        mode: "GCM"
      )

      // Perform encryption
      let result=try await securityProvider.encrypt(config: config)

      // Return the encrypted data
      let encryptedData=result.processedData.extractUnderlyingData()

      await logger.debug("Data encrypted successfully", context: context)
      return encryptedData
    } catch {
      let loggableError=LoggableErrorDTO(
        error: error,
        message: "Failed to encrypt data",
        details: "Encryption operation failed in adapter"
      )

      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )

      throw adaptError(error)
    }
  }

  /**
   Decrypts data with the provided key

   Delegates to the underlying security provider implementation.

   - Parameters:
     - data: The data to decrypt
     - key: The decryption key
   - Returns: The decrypted data
   - Throws: SecurityError if decryption fails
   */
  public func decrypt(data: Data, key: Data) async throws -> Data {
    let context=CoreLogContext(
      source: "SecurityProviderAdapter.decrypt",
      metadata: {
        var metadata=LogMetadataDTOCollection()
        metadata=metadata.withPrivate(key: "dataSize", value: String(data.count))
        metadata=metadata.withPrivate(key: "keySize", value: String(key.count))
        return metadata
      }()
    )

    await logger.debug("Decrypting data", context: context)

    do {
      // Create the secure bytes from data
      let secureData=SendableCryptoMaterial(bytes: [UInt8](data))
      let secureKey=SendableCryptoMaterial(bytes: [UInt8](key))

      // Create the configuration for decryption
      let config=SecurityConfigDTO(
        operation: .decrypt,
        key: secureKey,
        data: secureData,
        algorithm: "AES",
        mode: "GCM"
      )

      // Perform decryption
      let result=try await securityProvider.decrypt(config: config)

      // Return the decrypted data
      let decryptedData=result.processedData.extractUnderlyingData()

      await logger.debug("Data decrypted successfully", context: context)
      return decryptedData
    } catch {
      let loggableError=LoggableErrorDTO(
        error: error,
        message: "Failed to decrypt data",
        details: "Decryption operation failed in adapter"
      )

      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )

      throw adaptError(error)
    }
  }

  /**
   Generates a secure random key of the specified length

   Delegates to the underlying security provider implementation.

   - Parameter length: The length of the key in bytes
   - Returns: A secure random key
   - Throws: SecurityError if key generation fails
   */
  public func generateKey(length: Int) async throws -> Data {
    let context=CoreLogContext(
      source: "SecurityProviderAdapter.generateKey",
      metadata: {
        var metadata=LogMetadataDTOCollection()
        metadata=metadata.withPublic(key: "keyLength", value: String(length))
        return metadata
      }()
    )

    await logger.debug("Generating secure random key", context: context)

    do {
      let result=try await securityProvider.generateEncryptionKey(keySize: length * 8)
      let keyData=result.processedData.extractUnderlyingData()

      await logger.debug("Secure random key generated successfully", context: context)
      return keyData
    } catch {
      let loggableError=LoggableErrorDTO(
        error: error,
        message: "Failed to generate key",
        details: "Key generation failed in adapter"
      )

      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )

      throw adaptError(error)
    }
  }

  /**
   Stores a key securely

   Delegates to the underlying security provider implementation.

   - Parameters:
     - key: The key to store
     - identifier: The identifier for retrieving the key
   - Throws: SecurityError if key storage fails
   */
  public func storeKey(_ key: Data, identifier: String) async throws {
    let context=CoreLogContext(
      source: "SecurityProviderAdapter.storeKey",
      metadata: {
        var metadata=LogMetadataDTOCollection()
        metadata=metadata.withPrivate(key: "keySize", value: String(key.count))
        metadata=metadata.withPublic(key: "identifier", value: identifier)
        return metadata
      }()
    )

    await logger.debug("Storing key securely", context: context)

    do {
      let secureKey=SendableCryptoMaterial(bytes: [UInt8](key))
      let result=await securityProvider.storeKey(secureKey, withIdentifier: identifier)

      if case let .failure(error)=result {
        let loggableError=LoggableErrorDTO(
          error: error,
          message: "Failed to store key",
          details: "Key storage operation failed in adapter"
        )

        await logger.error(
          loggableError,
          context: context,
          privacyLevel: .private
        )

        throw SecurityError.keyStorageFailed(message: error.localizedDescription)
      }

      await logger.debug("Key stored successfully", context: context)
    } catch {
      let loggableError=LoggableErrorDTO(
        error: error,
        message: "Failed to store key",
        details: "Key storage failed in adapter"
      )

      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )

      throw adaptError(error)
    }
  }

  /**
   Retrieves a stored key by its identifier

   Delegates to the underlying security provider implementation.

   - Parameter identifier: The identifier of the key to retrieve
   - Returns: The retrieved key
   - Throws: SecurityError if key retrieval fails
   */
  public func retrieveKey(identifier: String) async throws -> Data {
    let context=CoreLogContext(
      source: "SecurityProviderAdapter.retrieveKey",
      metadata: {
        var metadata=LogMetadataDTOCollection()
        metadata=metadata.withPublic(key: "identifier", value: identifier)
        return metadata
      }()
    )

    await logger.debug("Retrieving stored key", context: context)

    do {
      let result=await securityProvider.retrieveKey(withIdentifier: identifier)

      switch result {
        case let .success(key):
          let keyData=key.extractUnderlyingData()
          await logger.debug("Key retrieved successfully", context: context)
          return keyData
        case let .failure(error):
          let loggableError=LoggableErrorDTO(
            error: error,
            message: "Failed to retrieve key",
            details: "Key retrieval operation failed in adapter"
          )

          await logger.error(
            loggableError,
            context: context,
            privacyLevel: .private
          )

          throw SecurityError.keyRetrievalFailed(message: error.localizedDescription)
      }
    } catch {
      let loggableError=LoggableErrorDTO(
        error: error,
        message: "Failed to retrieve key",
        details: "Key retrieval failed in adapter"
      )

      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )

      throw adaptError(error)
    }
  }

  /**
   Authenticates a user using the provided identifier and credentials

   Delegates to the underlying security provider implementation.

   - Parameters:
       - identifier: User identifier
       - credentials: Authentication credentials
   - Returns: True if authentication is successful, false otherwise
   - Throws: SecurityError if authentication fails
   */
  public func authenticate(identifier: String, credentials: Data) async throws -> Bool {
    let context=CoreLogContext(
      source: "SecurityProviderAdapter.authenticate",
      metadata: {
        var metadata=LogMetadataDTOCollection()
        metadata=metadata.withPublic(key: "identifier", value: identifier)
        // Never log credentials, even privately
        return metadata
      }()
    )

    await logger.debug("Authenticating user", context: context)

    do {
      let result=try await securityProvider.authenticate(
        identifier: identifier,
        credentials: credentials
      )

      await logger.debug("Authentication completed", context: context)
      return result
    } catch {
      let loggableError=LoggableErrorDTO(
        error: error,
        message: "Authentication failed",
        details: "User authentication operation failed in adapter"
      )

      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )

      throw adaptError(error)
    }
  }

  /**
   Authorises access to a resource at the specified access level

   Delegates to the underlying security provider implementation.

   - Parameters:
       - resource: The resource identifier
       - accessLevel: The requested access level
   - Returns: True if authorisation is granted, false otherwise
   - Throws: SecurityError if authorisation fails
   */
  public func authorise(resource: String, accessLevel: String) async throws -> Bool {
    let context=CoreLogContext(
      source: "SecurityProviderAdapter.authorise",
      metadata: {
        var metadata=LogMetadataDTOCollection()
        metadata=metadata.withPublic(key: "resource", value: resource)
        metadata=metadata.withPublic(key: "accessLevel", value: accessLevel)
        return metadata
      }()
    )

    await logger.debug("Authorising access to resource", context: context)

    do {
      let result=try await securityProvider.authorise(resource: resource, level: accessLevel)

      await logger.debug("Authorisation completed", context: context)
      return result
    } catch {
      let loggableError=LoggableErrorDTO(
        error: error,
        message: "Authorisation failed",
        details: "Resource authorisation operation failed in adapter"
      )

      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )

      throw adaptError(error)
    }
  }

  // MARK: - Private Methods

  /**
   Adapts domain-specific errors to the core error domain

   - Parameter error: The original error to adapt
   - Returns: A CoreError representing the adapted error
   */
  private func adaptError(_ error: Error) -> Error {
    // If it's already a CoreError, return it directly
    if let coreError=error as? CoreError {
      return coreError
    }

    // Map domain-specific errors to core errors
    if let securityError=error as? SecurityError {
      switch securityError {
        case let .initialisation(message):
          return CoreError.initialisation(message: "Security initialisation failed: \(message)")
        case let .keyStorageFailed(message):
          return CoreError.initialisation(message: "Key storage failed: \(message)")
        case let .keyRetrievalFailed(message):
          return CoreError.initialisation(message: "Key retrieval failed: \(message)")
        case let .authenticationFailed(message):
          return CoreError.authorisation(message: "Authentication failed: \(message)")
        case let .authorisationFailed(message):
          return CoreError.authorisation(message: "Authorisation failed: \(message)")
        case let .invalidKey(message):
          return CoreError.invalidState(
            message: "Invalid key: \(message)",
            currentState: .error
          )
      }
    }

    // For any other error, wrap it in a generic message
    return CoreError.initialisation(
      message: "Security operation failed: \(error.localizedDescription)"
    )
  }
}

/**
 # Security Error

 Domain-specific errors for security operations.
 */
public enum SecurityError: Error {
  case initialisation(message: String)
  case keyStorageFailed(message: String)
  case keyRetrievalFailed(message: String)
  case authenticationFailed(message: String)
  case authorisationFailed(message: String)
  case invalidKey(message: String)
}
