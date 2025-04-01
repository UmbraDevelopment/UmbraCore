import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/// Actor implementation of the SecurityProviderProtocol that provides thread-safe
/// access to security services with proper domain separation.
///
/// This implementation follows the Alpha Dot Five architecture principles:
/// - Actor-based concurrency for thread safety
/// - Provider-based abstraction for multiple implementation strategies
/// - Privacy-aware logging for sensitive operations
/// - Strong type safety with proper error handling
/// - Clear domain separation between security policy and cryptographic operations
public actor SecurityServiceActor: SecurityProviderProtocol, AsyncServiceInitializable {
  // MARK: - Private Properties

  /// The crypto service used for cryptographic operations
  private let cryptoService: any CryptoServiceProtocol

  /// The logger used for logging security events
  private let logger: LoggingInterfaces.LoggingProtocol

  /// The configuration for this security service
  private var configuration: SecurityConfigurationDTO

  /// Flag indicating if service has been initialised
  private var isInitialised: Bool=false

  /// Internal store for event subscribers
  private var eventSubscribers: [UUID: AsyncStream<SecurityEventDTO>.Continuation]=[:]

  /// Unique identifier for this security service instance
  private let serviceIdentifier: UUID = .init()

  // MARK: - Initialisation

  /// Creates a new security service actor with the specified dependencies
  /// - Parameters:
  ///   - cryptoService: The crypto service to use for cryptographic operations
  ///   - logger: The logger to use for logging security events
  public init(
    cryptoService: any CryptoServiceProtocol,
    logger: LoggingInterfaces.LoggingProtocol
  ) {
    self.cryptoService=cryptoService
    self.logger=logger
    configuration = .default
    isInitialised=false
  }

  /// Initialises the security service
  /// - Throws: SecurityError if initialisation fails
  public func initialise() async throws {
    guard !isInitialised else {
      throw UmbraErrors.SecurityError.alreadyInitialised
    }

    // Log initialisation event with privacy controls
    await logger.debug(
      "Initialising security service",
      metadata: PrivacyMetadata([
        "operation": (value: "initialise", privacy: .public)
      ]),
      source: "SecurityServiceActor.initialise"
    )

    // Validate that crypto service is available
    guard await cryptoService.isAvailable() else {
      throw UmbraErrors.SecurityError.serviceUnavailable
    }

    // Mark as initialised
    isInitialised=true

    await logger.info(
      "Security service initialised successfully",
      metadata: PrivacyMetadata([
        "status": (value: "success", privacy: .public)
      ]),
      source: "SecurityServiceActor.initialise"
    )
  }

  /// Initialize the security service (American spelling for AsyncServiceInitializable conformance)
  /// - Throws: SecurityError if initialization fails
  public func initialize() async throws {
    try await initialise()
  }

  /// Secures data according to the security policy defined in the security context
  /// - Parameters:
  ///   - data: The data to secure
  ///   - context: The security context defining how the data should be secured
  /// - Returns: The secured data
  /// - Throws: SecurityError if the operation fails
  public func secureData(
    _ data: [UInt8],
    securityContext: SecurityContextDTO
  ) async throws -> [UInt8] {
    try validateInitialisation()

    // Log security operation with privacy controls
    await logger.debug(
      "Securing data using \(securityContext.operationType.rawValue) operation",
      metadata: [
        "operation_type": securityContext.operationType.rawValue,
        "security_level": securityContext.securityLevel.rawValue,
        "data_length": String(data.count)
      ]
    )

    switch securityContext.operationType {
      case .encryption:
        // Delegate to crypto service for encryption
        let result=await cryptoService.encrypt(
          data: data,
          keyIdentifier: securityContext.keyIdentifier,
          options: securityContext.cryptoOptions
        )

        switch result {
          case let .success(encryptedData):
            // Log success
            await logger.debug(
              "Data secured successfully",
              metadata: [
                "operation_type": securityContext.operationType.rawValue,
                "result_length": String(encryptedData.count)
              ]
            )

            return encryptedData

          case let .failure(error):
            // Log error and convert to security domain error
            await logger.error(
              "Data security operation failed: \(error.localizedDescription)",
              metadata: [
                "operation_type": securityContext.operationType.rawValue,
                "error": error.localizedDescription
              ]
            )

            throw UmbraErrors.SecurityError.encryptionFailed(
              reason: "Encryption failed: \(error.localizedDescription)"
            )
        }

      default:
        throw UmbraErrors.SecurityError.invalidOperation(
          reason: "Operation type \(securityContext.operationType.rawValue) not supported for securing data"
        )
    }
  }

  /// Retrieves secured data according to the security policy defined in the security context
  /// - Parameters:
  ///   - securedData: The secured data to retrieve
  ///   - context: The security context defining how the data should be retrieved
  /// - Returns: The original data
  /// - Throws: SecurityError if the operation fails
  public func retrieveSecuredData(
    _ securedData: [UInt8],
    securityContext: SecurityContextDTO
  ) async throws -> [UInt8] {
    try validateInitialisation()

    // Log security operation with privacy controls
    await logger.debug(
      "Retrieving secured data using \(securityContext.operationType.rawValue) operation",
      metadata: [
        "operation_type": securityContext.operationType.rawValue,
        "security_level": securityContext.securityLevel.rawValue,
        "data_length": String(securedData.count)
      ]
    )

    switch securityContext.operationType {
      case .decryption:
        // Delegate to crypto service for decryption
        let result=await cryptoService.decrypt(
          encryptedData: securedData,
          keyIdentifier: securityContext.keyIdentifier,
          options: securityContext.cryptoOptions
        )

        switch result {
          case let .success(decryptedData):
            // Log success
            await logger.debug(
              "Secured data retrieved successfully",
              metadata: [
                "operation_type": securityContext.operationType.rawValue,
                "result_length": String(decryptedData.count)
              ]
            )

            return decryptedData

          case let .failure(error):
            // Log error and convert to security domain error
            await logger.error(
              "Data retrieval operation failed: \(error.localizedDescription)",
              metadata: [
                "operation_type": securityContext.operationType.rawValue,
                "error": error.localizedDescription
              ]
            )

            throw UmbraErrors.SecurityError.decryptionFailed(
              reason: "Decryption failed: \(error.localizedDescription)"
            )
        }

      default:
        throw UmbraErrors.SecurityError.invalidOperation(
          reason: "Operation type \(securityContext.operationType.rawValue) not supported for retrieving secured data"
        )
    }
  }

  /// Creates a secure bookmark for the given URL
  /// - Parameter url: The URL to create a bookmark for
  /// - Returns: The bookmark data
  /// - Throws: SecurityError if bookmark creation fails
  public func createBookmark(for url: URL) async throws -> [UInt8] {
    try validateInitialisation()

    // Log bookmark creation with privacy controls
    await logger.debug(
      "Creating security-scoped bookmark",
      metadata: [
        "url_path": url.path
      ]
    )

    do {
      // Create the security-scoped bookmark
      let bookmarkData=try url.bookmarkData(
        options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )

      // Convert to UInt8 array
      let bytes=[UInt8](bookmarkData)

      // Log success
      await logger.debug(
        "Security-scoped bookmark created successfully",
        metadata: [
          "bookmark_size": String(bytes.count)
        ]
      )

      return bytes
    } catch {
      // Log error
      await logger.error(
        "Failed to create security-scoped bookmark: \(error.localizedDescription)",
        metadata: [
          "error": error.localizedDescription
        ]
      )

      throw UmbraErrors.SecurityError.bookmarkCreationFailed(
        reason: "Failed to create bookmark: \(error.localizedDescription)"
      )
    }
  }

  /// Resolves a secure bookmark to a URL
  /// - Parameter bookmarkData: The bookmark data to resolve
  /// - Returns: The resolved URL and a flag indicating whether the bookmark needs to be recreated
  /// - Throws: SecurityError if bookmark resolution fails
  public func resolveBookmark(_ bookmarkData: [UInt8]) async throws -> (URL, Bool) {
    try validateInitialisation()

    // Log bookmark resolution with privacy controls
    await logger.debug(
      "Resolving security-scoped bookmark",
      metadata: [
        "bookmark_size": String(bookmarkData.count)
      ]
    )

    do {
      // Convert UInt8 array to Data
      let data=Data(bookmarkData)

      // Resolve the bookmark
      var isStale=false
      let url=try URL(
        resolvingBookmarkData: data,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      // Log success
      await logger.debug(
        "Security-scoped bookmark resolved successfully",
        metadata: [
          "url_path": url.path,
          "is_stale": String(isStale)
        ]
      )

      return (url, isStale)
    } catch {
      // Log error
      await logger.error(
        "Failed to resolve security-scoped bookmark: \(error.localizedDescription)",
        metadata: [
          "error": error.localizedDescription
        ]
      )

      throw UmbraErrors.SecurityError.bookmarkResolutionFailed(
        reason: "Failed to resolve bookmark: \(error.localizedDescription)"
      )
    }
  }

  /// Verifies the integrity of data according to the security policy defined in the security
  /// context
  /// - Parameters:
  ///   - data: The data to verify
  ///   - verification: The verification data (hash, signature, etc.)
  ///   - context: The security context defining how the verification should be performed
  /// - Returns: True if the data is valid, false otherwise
  /// - Throws: SecurityError if verification fails
  public func verifyDataIntegrity(
    _ data: [UInt8],
    verification: [UInt8],
    context: SecurityContextDTO
  ) async throws -> Bool {
    try validateInitialisation()

    // Log verification with privacy controls
    await logger.debug(
      "Verifying data integrity using \(context.operationType.rawValue)",
      metadata: [
        "operation_type": context.operationType.rawValue,
        "data_length": String(data.count),
        "verification_length": String(verification.count)
      ]
    )

    switch context.operationType {
      case .verification:
        if let verificationType=context.metadata["verification_type"] {
          switch verificationType {
            case "signature":
              // Delegate to crypto service for signature verification
              let result=await cryptoService.verify(
                signature: verification,
                data: data,
                keyIdentifier: context.keyIdentifier,
                options: nil
              )

              switch result {
                case let .success(isValid):
                  // Log result
                  await logger.debug(
                    "Signature verification completed: \(isValid ? "valid" : "invalid")",
                    metadata: [
                      "is_valid": String(isValid)
                    ]
                  )

                  return isValid

                case let .failure(error):
                  // Log error and convert to security domain error
                  await logger.error(
                    "Signature verification failed: \(error.localizedDescription)",
                    metadata: [
                      "error": error.localizedDescription
                    ]
                  )

                  throw UmbraErrors.SecurityError.verificationFailed(
                    reason: "Signature verification failed: \(error.localizedDescription)"
                  )
              }

            case "hash":
              // Delegate to crypto service for hash verification
              let hashAlgorithm=context.metadata["hash_algorithm"]
                .map { HashAlgorithm(rawValue: $0) } ?? .sha256

              let hashResult=await cryptoService.hash(
                data: data,
                algorithm: hashAlgorithm
              )

              switch hashResult {
                case let .success(computedHash):
                  // Compare the computed hash with the provided hash
                  let match=constantTimeCompare(computedHash, verification)

                  // Log result
                  await logger.debug(
                    "Hash verification completed: \(match ? "valid" : "invalid")",
                    metadata: [
                      "is_match": String(match)
                    ]
                  )

                  return match

                case let .failure(error):
                  // Log error and convert to security domain error
                  await logger.error(
                    "Hash computation failed: \(error.localizedDescription)",
                    metadata: [
                      "error": error.localizedDescription
                    ]
                  )

                  throw UmbraErrors.SecurityError.hashingFailed(
                    reason: "Hash computation failed: \(error.localizedDescription)"
                  )
              }

            default:
              throw UmbraErrors.SecurityError.invalidOperation(
                reason: "Verification type \(verificationType) not supported"
              )
          }
        } else {
          throw UmbraErrors.SecurityError.invalidInput(
            reason: "Verification type not specified in context metadata"
          )
        }

      default:
        throw UmbraErrors.SecurityError.invalidOperation(
          reason: "Operation type \(context.operationType.rawValue) not supported for data verification"
        )
    }
  }

  /// Updates the configuration of the security service with new settings
  /// - Parameter configuration: The new configuration to apply
  /// - Throws: SecurityError if update fails
  public func updateConfiguration(_ configuration: SecurityConfigurationDTO) async throws {
    try validateInitialisation()
    self.configuration=configuration

    // Log configuration update
    await logger.debug(
      "Security service configuration updated to \(configuration.securityLevel.rawValue) security level"
    )
  }

  /// Returns version information about the security service
  /// - Returns: Version information as a DTO
  public func getVersion() async -> SecurityVersionDTO {
    SecurityVersionDTO(
      semanticVersion: "2.0.0",
      majorVersion: 2,
      minorVersion: 0,
      patchVersion: 0,
      buildIdentifier: nil,
      minimumSupportedPlatformVersion: "macOS 14.0",
      providerImplementationName: "SecurityServiceActor",
      cryptographicLibraries: ["CryptoKit", "CommonCrypto"]
    )
  }

  /// Subscribes to security events matching the given filter
  /// - Parameter filter: Filter criteria for events
  /// - Returns: An async stream of security events
  public func subscribeToEvents(filter: SecurityEventFilterDTO) -> AsyncStream<SecurityEventDTO> {
    var continuation: AsyncStream<SecurityEventDTO>.Continuation!

    let stream=AsyncStream<SecurityEventDTO> { newContinuation in
      continuation=newContinuation

      // Log subscription with privacy controls
      self.logger.debug(
        "New security event subscriber added",
        metadata: [
          "min_severity": filter.minimumSeverityLevel?.rawValue ?? "None",
          "include_sensitive": String(filter.includeSensitiveInformation)
        ]
      )
    }

    // Store the continuation for later event publication
    let subscriptionID=UUID()
    eventSubscribers[subscriptionID]=continuation

    // Set up cancellation
    continuation.onTermination={ [weak self] _ in
      Task { [weak self] in
        await self?.removeSubscriber(id: subscriptionID)
      }
    }

    return stream
  }

  // MARK: - Event Publication

  /// Removes a subscriber from the event system
  /// - Parameter id: The subscriber ID to remove
  private func removeSubscriber(id: UUID) {
    eventSubscribers[id]=nil
  }

  /// Publishes an event to all subscribers
  /// - Parameter event: The event to publish
  private func publishEvent(_ event: SecurityEventDTO) {
    for (_, continuation) in eventSubscribers {
      continuation.yield(event)
    }
  }

  // MARK: - Helper Methods

  /// Validates that the service has been initialised
  /// - Throws: SecurityError if not initialised
  private func validateInitialisation() throws {
    guard isInitialised else {
      throw UmbraErrors.SecurityError.notInitialised
    }
  }

  /// Performs constant-time comparison of two byte arrays to prevent timing attacks
  /// - Parameters:
  ///   - a: First byte array
  ///   - b: Second byte array
  /// - Returns: True if arrays are equal, false otherwise
  private func constantTimeCompare(_ a: [UInt8], _ b: [UInt8]) -> Bool {
    guard a.count == b.count else {
      return false
    }

    var result: UInt8=0
    for i in 0..<a.count {
      result |= a[i] ^ b[i]
    }

    return result == 0
  }

  // MARK: - SecurityProviderProtocol Implementation

  /// Access to cryptographic service implementation
  public func cryptoService() async -> CryptoServiceProtocol {
    cryptoService
  }

  /// Access to key management service implementation
  public func keyManager() async -> SecurityCoreInterfaces.KeyManagementProtocol {
    throw UmbraErrors.SecurityError.serviceUnavailable
  }

  /// Encrypts data with the specified configuration
  public func encrypt(config _: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try validateInitialisation()

    // Implementation would go here
    // For now, we'll throw an error since this is a stub
    throw SecurityProtocolError
      .notImplemented(message: "Encryption not implemented in this version")
  }

  /// Decrypts data with the specified configuration
  public func decrypt(config _: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try validateInitialisation()

    // Implementation would go here
    // For now, we'll throw an error since this is a stub
    throw SecurityProtocolError
      .notImplemented(message: "Decryption not implemented in this version")
  }

  /// Generates a cryptographic key with the specified configuration
  public func generateKey(config _: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try validateInitialisation()

    // Implementation would go here
    // For now, we'll throw an error since this is a stub
    throw SecurityProtocolError
      .notImplemented(message: "Key generation not implemented in this version")
  }

  /// Securely stores data with the specified configuration
  public func secureStore(config _: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try validateInitialisation()

    // Implementation would go here
    // For now, we'll throw an error since this is a stub
    throw SecurityProtocolError
      .notImplemented(message: "Secure storage not implemented in this version")
  }

  /// Retrieves securely stored data with the specified configuration
  public func secureRetrieve(config _: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try validateInitialisation()

    // Implementation would go here
    // For now, we'll throw an error since this is a stub
    throw SecurityProtocolError
      .notImplemented(message: "Secure retrieval not implemented in this version")
  }

  /// Deletes securely stored data with the specified configuration
  public func secureDelete(config _: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try validateInitialisation()

    // Implementation would go here
    // For now, we'll throw an error since this is a stub
    throw SecurityProtocolError
      .notImplemented(message: "Secure deletion not implemented in this version")
  }

  /// Creates a digital signature for data with the specified configuration
  public func sign(config _: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try validateInitialisation()

    // Implementation would go here
    // For now, we'll throw an error since this is a stub
    throw SecurityProtocolError
      .notImplemented(message: "Digital signing not implemented in this version")
  }

  /// Verifies a digital signature with the specified configuration
  public func verify(config _: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try validateInitialisation()

    // Implementation would go here
    // For now, we'll throw an error since this is a stub
    throw SecurityProtocolError
      .notImplemented(message: "Signature verification not implemented in this version")
  }

  /// Performs a hash operation with the specified configuration
  public func hash(config _: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try validateInitialisation()

    // Implementation would go here
    // For now, we'll throw an error since this is a stub
    throw SecurityProtocolError.notImplemented(message: "Hashing not implemented in this version")
  }

  /// Generates a secure random value
  public func secureRandom(config _: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try validateInitialisation()

    // Implementation would go here
    // For now, we'll throw an error since this is a stub
    throw SecurityProtocolError
      .notImplemented(message: "Random generation not implemented in this version")
  }

  /// Performs a secure operation with the specified configuration
  public func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async throws -> SecurityResultDTO {
    try validateInitialisation()

    switch operation {
      case .encrypt:
        return try await encrypt(config: config)
      case .decrypt:
        return try await decrypt(config: config)
      case .hash:
        return try await hash(config: config)
      case .secureRandom:
        return try await secureRandom(config: config)
      case .generateKey:
        return try await generateKey(config: config)
      case .secureStore:
        return try await secureStore(config: config)
      case .secureRetrieve:
        return try await secureRetrieve(config: config)
      case .secureDelete:
        return try await secureDelete(config: config)
      case .sign:
        return try await sign(config: config)
      case .verify:
        return try await verify(config: config)
      default:
        throw SecurityProtocolError
          .notImplemented(message: "Operation \(operation) not implemented")
    }
  }
}
