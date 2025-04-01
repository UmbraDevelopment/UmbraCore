import CoreDTOs
import DomainSecurityTypes
import LoggingTypes
import LoggingInterfaces
import SecurityCoreInterfaces
import ErrorCoreTypes
import Foundation

/**
 # SecurityBookmarkActor
 
 Actor for managing security-scoped bookmarks with proper isolation.
 
 This actor provides thread-safe operations for creating, resolving, and
 managing access to security-scoped bookmarks in sandboxed applications.
 
 Following the Alpha Dot Five architecture, it uses:
 - Foundation-independent DTOs for most operations
 - Domain-specific error types
 - Proper actor isolation for all mutable state
 */
public actor SecurityBookmarkActor {
    /// Logger for recording operations and errors
    private let logger: PrivacyAwareLoggingProtocol
    
    /// Domain-specific logger for bookmark operations
    private let bookmarkLogger: BookmarkLogger
    
    /// Secure storage service for handling bookmark data
    private let secureStorage: any SecureStorageProtocol
    
    /// Currently active security-scoped resources
    private var activeResources: [URL: Int] = [:]
    
    /**
     Initialises a new security bookmark actor.
     
     - Parameters:
        - logger: Logger for recording operations and errors
        - secureStorage: Secure storage service for bookmark data
     */
    public init(logger: PrivacyAwareLoggingProtocol, secureStorage: any SecureStorageProtocol) {
        self.logger = logger
        self.bookmarkLogger = BookmarkLogger(logger: logger)
        self.secureStorage = secureStorage
    }
    
    /**
     Creates a security-scoped bookmark for the provided URL.
     
     - Parameters:
        - url: The URL to create a bookmark for
        - readOnly: Whether the bookmark should be read-only
     
     - Returns: Result with the bookmark identifier or error
     */
    public func createBookmark(
        for url: URL,
        readOnly: Bool
    ) async -> Result<String, BookmarkError> {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withSensitive(key: "url", value: url.path)
        metadata = metadata.withPublic(key: "readOnly", value: String(readOnly))
        
        await bookmarkLogger.logOperationStart(
            operation: "createBookmark",
            additionalContext: metadata
        )
        
        do {
            let options: URL.BookmarkCreationOptions = readOnly
                ? [.withSecurityScope, .securityScopeAllowOnlyReadAccess]
                : [.withSecurityScope]
            
            let bookmarkData = try url.bookmarkData(
                options: options,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            // Generate a unique identifier for this bookmark
            let identifier = "bookmark_\(UUID().uuidString)"
            
            // Convert to byte array for secure storage
            let bookmarkBytes = [UInt8](bookmarkData)
            
            // Store the bookmark data securely
            let storeResult = await secureStorage.storeData(
                bookmarkBytes,
                withIdentifier: identifier
            )
            
            switch storeResult {
            case .success:
                var successMetadata = LogMetadataDTOCollection()
                successMetadata = successMetadata.withPrivate(key: "dataSize", value: String(bookmarkData.count))
                successMetadata = successMetadata.withPrivate(key: "identifier", value: identifier)
                
                await bookmarkLogger.logOperationSuccess(
                    operation: "createBookmark",
                    additionalContext: successMetadata
                )
                
                return .success(identifier)
                
            case .failure(let error):
                throw BookmarkError.creationFailed(
                    "Failed to store bookmark data: \(error)"
                )
            }
        } catch {
            let bookmarkError = BookmarkError.creationFailed(
                "Failed to create security-scoped bookmark: \(error.localizedDescription)"
            )
            
            await bookmarkLogger.logOperationError(
                operation: "createBookmark",
                error: bookmarkError
            )
            
            return .failure(bookmarkError)
        }
    }
    
    /**
     Resolves a security-scoped bookmark to its URL.
     
     - Parameter bookmarkIdentifier: The identifier of the bookmark to resolve
     
     - Returns: Result with URL and staleness indicator or error
     */
    public func resolveBookmark(
        _ bookmarkIdentifier: String
    ) async -> Result<(URL, Bool), BookmarkError> {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withPrivate(key: "identifier", value: bookmarkIdentifier)
        
        await bookmarkLogger.logOperationStart(
            operation: "resolveBookmark",
            additionalContext: metadata
        )
        
        // Retrieve the bookmark data from secure storage
        let retrieveResult = await secureStorage.retrieveData(
            withIdentifier: bookmarkIdentifier
        )
        
        switch retrieveResult {
        case .success(let bookmarkBytes):
            do {
                // Convert bytes to Data
                let bookmarkData = Data(bookmarkBytes)
                var isStale = false
                
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                
                var successMetadata = LogMetadataDTOCollection()
                successMetadata = successMetadata.withSensitive(key: "url", value: url.path)
                successMetadata = successMetadata.withPublic(key: "isStale", value: String(isStale))
                
                await bookmarkLogger.logOperationSuccess(
                    operation: "resolveBookmark",
                    additionalContext: successMetadata
                )
                
                return .success((url, isStale))
            } catch {
                let bookmarkError = BookmarkError.resolutionFailed(
                    "Failed to resolve security-scoped bookmark: \(error.localizedDescription)"
                )
                
                await bookmarkLogger.logOperationError(
                    operation: "resolveBookmark",
                    error: bookmarkError
                )
                
                return .failure(bookmarkError)
            }
            
        case .failure(let error):
            let bookmarkError = BookmarkError.resolutionFailed(
                "Failed to retrieve bookmark data: \(error)"
            )
            
            await bookmarkLogger.logOperationError(
                operation: "resolveBookmark",
                error: bookmarkError
            )
            
            return .failure(bookmarkError)
        }
    }
    
    /**
     Starts accessing a security-scoped resource represented by the URL.
     
     This method tracks active resources to ensure proper balancing of
     access calls. The resource will continue to be accessible until
     stopAccessingSecurityScopedResource is called with the same URL.
     
     - Parameter url: The URL for which to start resource access
     
     - Returns: Result with success indicator or error
     */
    public func startAccessing(
        _ url: URL
    ) async -> Result<Bool, BookmarkError> {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withSensitive(key: "url", value: url.path)
        
        await bookmarkLogger.logOperationStart(
            operation: "startAccessing",
            additionalContext: metadata
        )
        
        // Check if already accessing
        let currentCount = activeResources[url] ?? 0
        
        if currentCount > 0 {
            // Already accessing, increment count
            activeResources[url] = currentCount + 1
            
            var successMetadata = LogMetadataDTOCollection()
            successMetadata = successMetadata.withPrivate(key: "count", value: String(currentCount + 1))
            
            await bookmarkLogger.logOperationSuccess(
                operation: "startAccessing",
                additionalContext: successMetadata
            )
            
            return .success(true)
        }
        
        // Start new access
        let result = url.startAccessingSecurityScopedResource()
        
        if result {
            activeResources[url] = 1
            
            var successMetadata = LogMetadataDTOCollection()
            successMetadata = successMetadata.withPrivate(key: "count", value: "1")
            
            await bookmarkLogger.logOperationSuccess(
                operation: "startAccessing",
                additionalContext: successMetadata
            )
            
            return .success(true)
        } else {
            let bookmarkError = BookmarkError.accessFailed(
                "Failed to start accessing security-scoped resource"
            )
            
            await bookmarkLogger.logOperationError(
                operation: "startAccessing",
                error: bookmarkError
            )
            
            return .failure(bookmarkError)
        }
    }
    
    /**
     Stops accessing a security-scoped resource.
     
     This method decrements the access count for the URL. When the count
     reaches zero, it calls stopAccessingSecurityScopedResource.
     
     - Parameter url: The URL for which to stop resource access
     
     - Returns: Result with remaining access count or error
     */
    public func stopAccessing(
        _ url: URL
    ) async -> Result<Int, BookmarkError> {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withSensitive(key: "url", value: url.path)
        
        await bookmarkLogger.logOperationStart(
            operation: "stopAccessing",
            additionalContext: metadata
        )
        
        // Check if currently accessing
        guard let currentCount = activeResources[url], currentCount > 0 else {
            let bookmarkError = BookmarkError.notAccessing(
                "Not currently accessing this security-scoped resource"
            )
            
            await bookmarkLogger.logOperationError(
                operation: "stopAccessing",
                error: bookmarkError
            )
            
            return .failure(bookmarkError)
        }
        
        let newCount = currentCount - 1
        
        if newCount == 0 {
            // Last access is being released
            url.stopAccessingSecurityScopedResource()
            activeResources.removeValue(forKey: url)
            
            var successMetadata = LogMetadataDTOCollection()
            successMetadata = successMetadata.withPrivate(key: "count", value: "0")
            successMetadata = successMetadata.withPublic(key: "released", value: "true")
            
            await bookmarkLogger.logOperationSuccess(
                operation: "stopAccessing",
                additionalContext: successMetadata
            )
        } else {
            // Decrement count but keep accessing
            activeResources[url] = newCount
            
            var successMetadata = LogMetadataDTOCollection()
            successMetadata = successMetadata.withPrivate(key: "count", value: String(newCount))
            successMetadata = successMetadata.withPublic(key: "released", value: "false")
            
            await bookmarkLogger.logOperationSuccess(
                operation: "stopAccessing",
                additionalContext: successMetadata
            )
        }
        
        return .success(newCount)
    }
    
    /**
     Validates a security-scoped bookmark.
     
     - Parameters:
        - bookmarkIdentifier: The identifier of the bookmark to validate
        - recreateIfStale: Whether to recreate the bookmark if stale
     
     - Returns: Result with validation result or error
     */
    public func validateBookmark(
        _ bookmarkIdentifier: String,
        recreateIfStale: Bool
    ) async -> Result<BookmarkValidationResult, BookmarkError> {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withPrivate(key: "identifier", value: bookmarkIdentifier)
        metadata = metadata.withPublic(key: "recreateIfStale", value: String(recreateIfStale))
        
        await bookmarkLogger.logOperationStart(
            operation: "validateBookmark",
            additionalContext: metadata
        )
        
        // First, resolve the bookmark to check if it's valid
        let resolveResult = await resolveBookmark(bookmarkIdentifier)
        
        switch resolveResult {
        case .success((let url, let isStale)):
            // If not stale, return valid
            if !isStale {
                var successMetadata = LogMetadataDTOCollection()
                successMetadata = successMetadata.withPublic(key: "isValid", value: "true")
                successMetadata = successMetadata.withPublic(key: "isStale", value: "false")
                
                await bookmarkLogger.logOperationSuccess(
                    operation: "validateBookmark",
                    additionalContext: successMetadata
                )
                
                return .success(BookmarkValidationResult(
                    isValid: true,
                    isStale: false,
                    wasRecreated: false,
                    updatedIdentifier: nil
                ))
            }
            
            // If stale and recreate requested, create a new bookmark
            if recreateIfStale {
                let recreateResult = await createBookmark(for: url, readOnly: false)
                
                switch recreateResult {
                case .success(let newIdentifier):
                    var successMetadata = LogMetadataDTOCollection()
                    successMetadata = successMetadata.withPublic(key: "isValid", value: "true")
                    successMetadata = successMetadata.withPublic(key: "isStale", value: "true")
                    successMetadata = successMetadata.withPublic(key: "recreated", value: "true")
                    
                    await bookmarkLogger.logOperationSuccess(
                        operation: "validateBookmark",
                        additionalContext: successMetadata
                    )
                    
                    return .success(BookmarkValidationResult(
                        isValid: true,
                        isStale: true,
                        wasRecreated: true,
                        updatedIdentifier: newIdentifier
                    ))
                    
                case .failure(let error):
                    // Failed to recreate the bookmark
                    await bookmarkLogger.logOperationError(
                        operation: "validateBookmark",
                        error: error
                    )
                    
                    return .failure(error)
                }
            }
            
            // If stale but don't recreate, return stale
            var successMetadata = LogMetadataDTOCollection()
            successMetadata = successMetadata.withPublic(key: "isValid", value: "true")
            successMetadata = successMetadata.withPublic(key: "isStale", value: "true")
            successMetadata = successMetadata.withPublic(key: "recreated", value: "false")
            
            await bookmarkLogger.logOperationSuccess(
                operation: "validateBookmark",
                additionalContext: successMetadata
            )
            
            return .success(BookmarkValidationResult(
                isValid: true,
                isStale: true,
                wasRecreated: false,
                updatedIdentifier: nil
            ))
            
        case .failure(let error):
            // Bookmark couldn't be resolved
            await bookmarkLogger.logOperationError(
                operation: "validateBookmark",
                error: error
            )
            
            return .failure(error)
        }
    }
    
    /**
     Checks if all security-scoped resources have been released.
     
     This is useful for debugging and ensuring proper resource cleanup.
     
     - Returns: True if all resources have been released, false otherwise
     */
    public func verifyAllResourcesReleased() async -> Bool {
        let metadata = LogMetadataDTOCollection()
        
        await bookmarkLogger.logOperationStart(
            operation: "verifyAllResourcesReleased",
            additionalContext: metadata
        )
        
        let allReleased = activeResources.isEmpty
        
        var successMetadata = LogMetadataDTOCollection()
        successMetadata = successMetadata.withPublic(key: "allReleased", value: String(allReleased))
        successMetadata = successMetadata.withPrivate(key: "activeCount", value: String(activeResources.count))
        
        await bookmarkLogger.logOperationSuccess(
            operation: "verifyAllResourcesReleased",
            additionalContext: successMetadata
        )
        
        return allReleased
    }
    
    /**
     Forces the release of all active security-scoped resources.
     
     This is useful for cleanup before app termination.
     
     - Returns: The number of resources that were released
     */
    public func forceReleaseAllResources() async -> Int {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withPrivate(key: "activeCount", value: String(activeResources.count))
        
        await bookmarkLogger.logOperationStart(
            operation: "forceReleaseAllResources",
            additionalContext: metadata
        )
        
        let count = activeResources.count
        
        for url in activeResources.keys {
            url.stopAccessingSecurityScopedResource()
        }
        
        activeResources.removeAll()
        
        var successMetadata = LogMetadataDTOCollection()
        successMetadata = successMetadata.withPublic(key: "releasedCount", value: String(count))
        
        await bookmarkLogger.logOperationSuccess(
            operation: "forceReleaseAllResources",
            additionalContext: successMetadata
        )
        
        return count
    }
}

/**
 * BookmarkLogger - Helper for logging security bookmark operations
 * with proper privacy controls and context handling.
 */
fileprivate struct BookmarkLogger {
    private let logger: PrivacyAwareLoggingProtocol
    
    init(logger: PrivacyAwareLoggingProtocol) {
        self.logger = logger
    }
    
    func logOperationStart(
        operation: String,
        additionalContext: LogMetadataDTOCollection? = nil
    ) async {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withPublic(key: "operation", value: operation)
        if let additionalContext = additionalContext {
            metadata = metadata.merging(with: additionalContext)
        }
        
        await logger.debug(
            "Starting bookmark operation: \(operation)",
            metadata: metadata.toPrivacyMetadata(),
            source: "SecurityBookmark"
        )
    }
    
    func logOperationSuccess(
        operation: String,
        additionalContext: LogMetadataDTOCollection? = nil
    ) async {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withPublic(key: "operation", value: operation)
        metadata = metadata.withPublic(key: "status", value: "success")
        if let additionalContext = additionalContext {
            metadata = metadata.merging(with: additionalContext)
        }
        
        await logger.debug(
            "Successfully completed bookmark operation: \(operation)",
            metadata: metadata.toPrivacyMetadata(),
            source: "SecurityBookmark"
        )
    }
    
    func logOperationError(
        operation: String,
        error: Error,
        additionalContext: LogMetadataDTOCollection? = nil
    ) async {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withPublic(key: "operation", value: operation)
        metadata = metadata.withPublic(key: "status", value: "error")
        
        // Add error information
        if let loggableError = error as? LoggableErrorProtocol {
            let errorMetadata = loggableError.getPrivacyMetadata()
            
            // Extract privacy-aware metadata
            for key in errorMetadata.keys {
                if let value = errorMetadata[key] {
                    metadata = metadata.withPrivate(key: key, value: value.valueString)
                }
            }
        } else {
            metadata = metadata.withPrivate(key: "errorMessage", value: error.localizedDescription)
        }
        
        if let additionalContext = additionalContext {
            metadata = metadata.merging(with: additionalContext)
        }
        
        await logger.error(
            "Failed bookmark operation: \(operation)",
            metadata: metadata.toPrivacyMetadata(),
            source: "SecurityBookmark"
        )
    }
}

/**
 * Validation result for security bookmarks.
 */
public struct BookmarkValidationResult {
    /// Whether the bookmark is valid
    public let isValid: Bool
    
    /// Whether the bookmark is stale
    public let isStale: Bool
    
    /// Whether the bookmark was recreated
    public let wasRecreated: Bool
    
    /// Updated bookmark identifier if recreated
    public let updatedIdentifier: String?
    
    public init(isValid: Bool, isStale: Bool, wasRecreated: Bool, updatedIdentifier: String?) {
        self.isValid = isValid
        self.isStale = isStale
        self.wasRecreated = wasRecreated
        self.updatedIdentifier = updatedIdentifier
    }
}

/**
 * Domain-specific error type for security bookmark operations.
 */
public enum BookmarkError: Error, LoggableErrorProtocol {
    case creationFailed(String)
    case resolutionFailed(String)
    case accessFailed(String)
    case notAccessing(String)
    case validationFailed(String)
    
    public func getLogMessage() -> String {
        switch self {
        case .creationFailed(let message):
            return "Bookmark creation failed: \(message)"
        case .resolutionFailed(let message):
            return "Bookmark resolution failed: \(message)"
        case .accessFailed(let message):
            return "Security-scoped access failed: \(message)"
        case .notAccessing(let message):
            return "Not accessing resource: \(message)"
        case .validationFailed(let message):
            return "Bookmark validation failed: \(message)"
        }
    }
    
    public func getSource() -> String {
        return "SecurityBookmark"
    }
    
    public func getPrivacyMetadata() -> PrivacyMetadata {
        var metadata = PrivacyMetadata()
        metadata["errorType"] = PrivacyMetadataValue(value: String(describing: type(of: self)), privacy: .public)
        
        let errorDescription: String
        switch self {
        case .creationFailed(let message),
             .resolutionFailed(let message),
             .accessFailed(let message),
             .notAccessing(let message),
             .validationFailed(let message):
            errorDescription = message
        }
        
        metadata["errorMessage"] = PrivacyMetadataValue(value: errorDescription, privacy: .private)
        metadata["errorDomain"] = PrivacyMetadataValue(value: "Security", privacy: .public)
        return metadata
    }
}
