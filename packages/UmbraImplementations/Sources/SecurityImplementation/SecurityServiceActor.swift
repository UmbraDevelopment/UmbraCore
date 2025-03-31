import Foundation
import LoggingInterfaces
import SecurityInterfaces
import UmbraErrors
import CryptoInterfaces
import CryptoTypes

/// Actor implementation of the SecurityServiceProtocol that provides thread-safe
/// access to security services with proper domain separation.
///
/// This implementation follows the Alpha Dot Five architecture principles:
/// - Actor-based concurrency for thread safety
/// - Provider-based abstraction for multiple implementation strategies
/// - Privacy-aware logging for sensitive operations
/// - Strong type safety with proper error handling
/// - Clear domain separation between security policy and cryptographic operations
public actor SecurityServiceActor: SecurityServiceProtocol {
    // MARK: - Private Properties
    
    /// The crypto service used for cryptographic operations
    private let cryptoService: CryptoXPCServiceProtocol
    
    /// The logger used for logging security events
    private let logger: LoggingProtocol
    
    /// The configuration for this security service
    private var configuration: SecurityConfigurationDTO
    
    /// Flag indicating whether the service has been initialised
    private var isInitialised: Bool = false
    
    /// Internal store for event subscribers
    private var eventSubscribers: [UUID: AsyncStream<SecurityEventDTO>.Continuation] = [:]
    
    /// Unique identifier for this security service instance
    private let serviceIdentifier: UUID = UUID()
    
    // MARK: - Initialisation
    
    /// Creates a new security service actor with the given crypto service and logger
    /// - Parameters:
    ///   - cryptoService: The crypto service to use for cryptographic operations
    ///   - logger: The logger to use for logging security events
    public init(cryptoService: CryptoXPCServiceProtocol, logger: LoggingProtocol) {
        self.cryptoService = cryptoService
        self.logger = logger
        self.configuration = .default
    }
    
    // MARK: - SecurityServiceProtocol Implementation
    
    /// Initialises the security service with the given configuration
    /// - Parameter configuration: Configuration options for the security service
    /// - Throws: SecurityError if initialisation fails
    public func initialise(configuration: SecurityConfigurationDTO) async throws {
        guard !isInitialised else {
            throw UmbraErrors.SecurityError.alreadyInitialised
        }
        
        self.configuration = configuration
        
        // Log initialisation event with privacy controls
        logger.log(
            level: .information,
            message: "Security service initialised with \(configuration.securityLevel.rawValue) security level",
            metadata: [
                "security_level": .string(configuration.securityLevel.rawValue),
                "service_id": .string(serviceIdentifier.uuidString)
            ],
            privacy: .public
        )
        
        // Publish initialisation event
        let initialisationEvent = SecurityEventDTO(
            eventIdentifier: UUID().uuidString,
            eventType: .initialisation,
            timestampISO8601: ISO8601DateFormatter().string(from: Date()),
            severityLevel: .informational,
            eventMessage: "Security service initialised",
            contextInformation: [
                "security_level": configuration.securityLevel.rawValue,
                "service_id": serviceIdentifier.uuidString
            ],
            containsSensitiveInformation: false,
            sourceComponent: "SecurityService"
        )
        publishEvent(initialisationEvent)
        
        isInitialised = true
    }
    
    /// Secures data according to the security policy defined in the security context
    /// - Parameters:
    ///   - data: The data to secure
    ///   - context: The security context defining how the data should be secured
    /// - Returns: The secured data
    /// - Throws: SecurityError if the operation fails
    public func secureData(_ data: [UInt8], securityContext: SecurityContextDTO) async throws -> [UInt8] {
        try validateInitialisation()
        
        // Log security operation with privacy controls
        logger.log(
            level: .debug,
            message: "Securing data using \(securityContext.operationType.rawValue) operation",
            metadata: [
                "operation_type": .string(securityContext.operationType.rawValue),
                "security_level": .string(securityContext.securityLevel.rawValue),
                "data_length": .int(data.count)
            ],
            privacy: .private
        )
        
        switch securityContext.operationType {
        case .encryption:
            // Delegate to crypto service for encryption
            let secureBytes = SecureBytes(bytes: data)
            let result = await cryptoService.encrypt(
                data: secureBytes,
                keyIdentifier: securityContext.keyIdentifier,
                options: securityContext.cryptoOptions
            )
            
            switch result {
            case .success(let encryptedData):
                // Log success
                logger.log(
                    level: .debug,
                    message: "Data secured successfully",
                    metadata: [
                        "operation_type": .string(securityContext.operationType.rawValue),
                        "result_length": .int(encryptedData.bytes.count)
                    ],
                    privacy: .private
                )
                
                return encryptedData.bytes
                
            case .failure(let error):
                // Log error and convert to security domain error
                logger.log(
                    level: .error,
                    message: "Data security operation failed: \(error.localizedDescription)",
                    metadata: [
                        "operation_type": .string(securityContext.operationType.rawValue),
                        "error": .string(error.localizedDescription)
                    ],
                    privacy: .private
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
    public func retrieveSecuredData(_ securedData: [UInt8], securityContext: SecurityContextDTO) async throws -> [UInt8] {
        try validateInitialisation()
        
        // Log security operation with privacy controls
        logger.log(
            level: .debug,
            message: "Retrieving secured data using \(securityContext.operationType.rawValue) operation",
            metadata: [
                "operation_type": .string(securityContext.operationType.rawValue),
                "security_level": .string(securityContext.securityLevel.rawValue),
                "data_length": .int(securedData.count)
            ],
            privacy: .private
        )
        
        switch securityContext.operationType {
        case .decryption:
            // Delegate to crypto service for decryption
            let encryptedBytes = SecureBytes(bytes: securedData)
            let result = await cryptoService.decrypt(
                encryptedData: encryptedBytes,
                keyIdentifier: securityContext.keyIdentifier,
                options: securityContext.cryptoOptions
            )
            
            switch result {
            case .success(let decryptedData):
                // Log success
                logger.log(
                    level: .debug,
                    message: "Secured data retrieved successfully",
                    metadata: [
                        "operation_type": .string(securityContext.operationType.rawValue),
                        "result_length": .int(decryptedData.bytes.count)
                    ],
                    privacy: .private
                )
                
                return decryptedData.bytes
                
            case .failure(let error):
                // Log error and convert to security domain error
                logger.log(
                    level: .error,
                    message: "Data retrieval operation failed: \(error.localizedDescription)",
                    metadata: [
                        "operation_type": .string(securityContext.operationType.rawValue),
                        "error": .string(error.localizedDescription)
                    ],
                    privacy: .private
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
        logger.log(
            level: .debug,
            message: "Creating security-scoped bookmark",
            metadata: [
                "url_path": .string(url.path)
            ],
            privacy: .private
        )
        
        do {
            // Create the security-scoped bookmark
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            // Convert to UInt8 array
            let bytes = [UInt8](bookmarkData)
            
            // Log success
            logger.log(
                level: .debug,
                message: "Security-scoped bookmark created successfully",
                metadata: [
                    "bookmark_size": .int(bytes.count)
                ],
                privacy: .private
            )
            
            return bytes
        } catch {
            // Log error
            logger.log(
                level: .error,
                message: "Failed to create security-scoped bookmark: \(error.localizedDescription)",
                metadata: [
                    "error": .string(error.localizedDescription)
                ],
                privacy: .private
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
        logger.log(
            level: .debug,
            message: "Resolving security-scoped bookmark",
            metadata: [
                "bookmark_size": .int(bookmarkData.count)
            ],
            privacy: .private
        )
        
        do {
            // Convert UInt8 array to Data
            let data = Data(bookmarkData)
            
            // Resolve the bookmark
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            // Log success
            logger.log(
                level: .debug,
                message: "Security-scoped bookmark resolved successfully",
                metadata: [
                    "url_path": .string(url.path),
                    "is_stale": .bool(isStale)
                ],
                privacy: .private
            )
            
            return (url, isStale)
        } catch {
            // Log error
            logger.log(
                level: .error,
                message: "Failed to resolve security-scoped bookmark: \(error.localizedDescription)",
                metadata: [
                    "error": .string(error.localizedDescription)
                ],
                privacy: .private
            )
            
            throw UmbraErrors.SecurityError.bookmarkResolutionFailed(
                reason: "Failed to resolve bookmark: \(error.localizedDescription)"
            )
        }
    }
    
    /// Verifies the integrity of data according to the security policy defined in the security context
    /// - Parameters:
    ///   - data: The data to verify
    ///   - verification: The verification data (hash, signature, etc.)
    ///   - context: The security context defining how the verification should be performed
    /// - Returns: True if the data is valid, false otherwise
    /// - Throws: SecurityError if verification fails
    public func verifyDataIntegrity(_ data: [UInt8], verification: [UInt8], context: SecurityContextDTO) async throws -> Bool {
        try validateInitialisation()
        
        // Log verification with privacy controls
        logger.log(
            level: .debug,
            message: "Verifying data integrity using \(context.operationType.rawValue)",
            metadata: [
                "operation_type": .string(context.operationType.rawValue),
                "data_length": .int(data.count),
                "verification_length": .int(verification.count)
            ],
            privacy: .private
        )
        
        switch context.operationType {
        case .verification:
            if let verificationType = context.metadata["verification_type"] {
                switch verificationType {
                case "signature":
                    // Delegate to crypto service for signature verification
                    let dataBytes = SecureBytes(bytes: data)
                    let signatureBytes = SecureBytes(bytes: verification)
                    
                    let result = await cryptoService.verify(
                        signature: signatureBytes,
                        data: dataBytes,
                        keyIdentifier: context.keyIdentifier,
                        options: nil
                    )
                    
                    switch result {
                    case .success(let isValid):
                        // Log result
                        logger.log(
                            level: .debug,
                            message: "Signature verification completed: \(isValid ? "valid" : "invalid")",
                            privacy: .private
                        )
                        
                        return isValid
                        
                    case .failure(let error):
                        // Log error and convert to security domain error
                        logger.log(
                            level: .error,
                            message: "Signature verification failed: \(error.localizedDescription)",
                            metadata: [
                                "error": .string(error.localizedDescription)
                            ],
                            privacy: .private
                        )
                        
                        throw UmbraErrors.SecurityError.verificationFailed(
                            reason: "Signature verification failed: \(error.localizedDescription)"
                        )
                    }
                    
                case "hash":
                    // Delegate to crypto service for hash verification
                    let dataBytes = SecureBytes(bytes: data)
                    let hashAlgorithm = context.metadata["hash_algorithm"].map { HashAlgorithm(rawValue: $0) } ?? .sha256
                    
                    let hashResult = await cryptoService.hash(
                        data: dataBytes,
                        algorithm: hashAlgorithm
                    )
                    
                    switch hashResult {
                    case .success(let computedHash):
                        // Compare the computed hash with the provided hash
                        let match = constantTimeCompare(computedHash.bytes, verification)
                        
                        // Log result
                        logger.log(
                            level: .debug,
                            message: "Hash verification completed: \(match ? "valid" : "invalid")",
                            privacy: .private
                        )
                        
                        return match
                        
                    case .failure(let error):
                        // Log error and convert to security domain error
                        logger.log(
                            level: .error,
                            message: "Hash computation failed: \(error.localizedDescription)",
                            metadata: [
                                "error": .string(error.localizedDescription)
                            ],
                            privacy: .private
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
    
    /// Returns version information about the security service
    /// - Returns: Version information as a DTO
    public func getVersion() async -> SecurityVersionDTO {
        return SecurityVersionDTO(
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
        
        let stream = AsyncStream<SecurityEventDTO> { newContinuation in
            continuation = newContinuation
            
            // Log subscription with privacy controls
            self.logger.log(
                level: .debug,
                message: "New security event subscriber added",
                metadata: [
                    "min_severity": .string(filter.minimumSeverityLevel?.rawValue ?? "None"),
                    "include_sensitive": .bool(filter.includeSensitiveInformation)
                ],
                privacy: .public
            )
        }
        
        // Store the continuation for later event publication
        let subscriptionId = UUID()
        eventSubscribers[subscriptionId] = continuation
        
        // Set up cancellation
        continuation.onTermination = { [weak self] _ in
            Task { [weak self] in
                await self?.removeSubscriber(id: subscriptionId)
            }
        }
        
        return stream
    }
    
    // MARK: - Event Publication
    
    /// Removes a subscriber from the event system
    /// - Parameter id: The subscriber ID to remove
    private func removeSubscriber(id: UUID) {
        eventSubscribers[id] = nil
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
    
    /// Performs a constant-time comparison of two byte arrays
    /// - Parameters:
    ///   - lhs: First byte array
    ///   - rhs: Second byte array
    /// - Returns: True if the arrays are equal
    private func constantTimeCompare(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
        // If lengths don't match, arrays are not equal
        guard lhs.count == rhs.count else {
            return false
        }
        
        // Constant-time comparison to prevent timing attacks
        var result: UInt8 = 0
        for i in 0..<lhs.count {
            result |= lhs[i] ^ rhs[i]
        }
        
        return result == 0
    }
}
