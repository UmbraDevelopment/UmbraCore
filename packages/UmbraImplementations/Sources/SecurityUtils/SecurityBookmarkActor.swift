import CoreDTOs
import DomainSecurityTypes
import LoggingInterfaces
import UmbraErrors
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
public actor SecurityBookmarkActor: SecurityBookmarkProtocol {
    /// Logger for recording operations and errors
    private let logger: LoggingProtocol
    
    /// Domain-specific logger for bookmark operations
    private let bookmarkLogger: BookmarkLogger
    
    /// Currently active security-scoped resources
    private var activeResources: [URL: Int] = [:]
    
    /**
     Initialises a new security bookmark actor.
     
     - Parameter logger: Logger for recording operations and errors
     */
    public init(logger: LoggingProtocol) {
        self.logger = logger
        self.bookmarkLogger = BookmarkLogger(logger: logger)
    }
    
    /**
     Creates a security-scoped bookmark for the provided URL.
     
     - Parameters:
        - url: The URL to create a bookmark for
        - readOnly: Whether the bookmark should be read-only
     
     - Returns: Result with bookmark data as SecureBytes or error
     */
    public func createBookmark(
        for url: URL,
        readOnly: Bool
    ) async -> Result<SecureBytes, UmbraErrors.Security.Bookmark> {
        await bookmarkLogger.logOperationStart(
            operation: "createBookmark",
            additionalContext: LogMetadataDTOCollection()
                .withSensitive(key: "url", value: url.path)
                .withPublic(key: "readOnly", value: String(readOnly))
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
            
            let secureData = SecureBytes(bytes: [UInt8](bookmarkData))
            
            await bookmarkLogger.logOperationSuccess(
                operation: "createBookmark",
                additionalContext: LogMetadataDTOCollection()
                    .withPrivate(key: "dataSize", value: String(secureData.bytes.count))
            )
            
            return .success(secureData)
        } catch {
            let bookmarkError = UmbraErrors.Security.Bookmark.creationFailed(
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
     
     - Parameter bookmarkData: The bookmark data to resolve as SecureBytes
     
     - Returns: Result with URL and staleness indicator or error
     */
    public func resolveBookmark(
        _ bookmarkData: SecureBytes
    ) async -> Result<(URL, Bool), UmbraErrors.Security.Bookmark> {
        await bookmarkLogger.logOperationStart(
            operation: "resolveBookmark",
            additionalContext: LogMetadataDTOCollection()
                .withPrivate(key: "dataSize", value: String(bookmarkData.bytes.count))
        )
        
        do {
            var isStale = false
            let data = Data(bookmarkData.bytes)
            
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            await bookmarkLogger.logOperationSuccess(
                operation: "resolveBookmark",
                additionalContext: LogMetadataDTOCollection()
                    .withSensitive(key: "url", value: url.path)
                    .withPublic(key: "isStale", value: String(isStale))
            )
            
            return .success((url, isStale))
        } catch {
            let bookmarkError = UmbraErrors.Security.Bookmark.resolutionFailed(
                "Failed to resolve security-scoped bookmark: \(error.localizedDescription)"
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
    ) async -> Result<Bool, UmbraErrors.Security.Bookmark> {
        await bookmarkLogger.logOperationStart(
            operation: "startAccessing",
            additionalContext: LogMetadataDTOCollection()
                .withSensitive(key: "url", value: url.path)
        )
        
        // Check if already accessing
        let currentCount = activeResources[url] ?? 0
        
        if currentCount > 0 {
            // Already accessing, increment count
            activeResources[url] = currentCount + 1
            
            await bookmarkLogger.logOperationSuccess(
                operation: "startAccessing",
                additionalContext: LogMetadataDTOCollection()
                    .withPrivate(key: "count", value: String(currentCount + 1))
            )
            
            return .success(true)
        }
        
        // Start new access
        let result = url.startAccessingSecurityScopedResource()
        
        if result {
            activeResources[url] = 1
            
            await bookmarkLogger.logOperationSuccess(
                operation: "startAccessing",
                additionalContext: LogMetadataDTOCollection()
                    .withPrivate(key: "count", value: "1")
            )
            
            return .success(true)
        } else {
            let bookmarkError = UmbraErrors.Security.Bookmark.accessFailed(
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
     Stops accessing a security-scoped resource represented by the URL.
     
     This method balances calls to startAccessingSecurityScopedResource,
     only releasing the resource when all access requests have been released.
     
     - Parameter url: The URL for which to stop resource access
     
     - Returns: Result with count of remaining accesses or error
     */
    public func stopAccessing(
        _ url: URL
    ) async -> Result<Int, UmbraErrors.Security.Bookmark> {
        await bookmarkLogger.logOperationStart(
            operation: "stopAccessing",
            additionalContext: LogMetadataDTOCollection()
                .withSensitive(key: "url", value: url.path)
        )
        
        // Check if currently accessing
        guard let currentCount = activeResources[url], currentCount > 0 else {
            let bookmarkError = UmbraErrors.Security.Bookmark.notAccessing(
                "Not currently accessing this security-scoped resource"
            )
            
            await bookmarkLogger.logOperationError(
                operation: "stopAccessing",
                error: bookmarkError
            )
            
            return .failure(bookmarkError)
        }
        
        let newCount = currentCount - 1
        
        // If this is the last access, release the resource
        if newCount == 0 {
            url.stopAccessingSecurityScopedResource()
            activeResources.removeValue(forKey: url)
            
            await bookmarkLogger.logOperationSuccess(
                operation: "stopAccessing",
                additionalContext: LogMetadataDTOCollection()
                    .withPrivate(key: "count", value: "0")
                    .withPublic(key: "released", value: "true")
            )
        } else {
            // Otherwise, decrement the count
            activeResources[url] = newCount
            
            await bookmarkLogger.logOperationSuccess(
                operation: "stopAccessing",
                additionalContext: LogMetadataDTOCollection()
                    .withPrivate(key: "count", value: String(newCount))
                    .withPublic(key: "released", value: "false")
            )
        }
        
        return .success(newCount)
    }
    
    /**
     Validates a security-scoped bookmark.
     
     This method checks if a bookmark is valid and not stale.
     If stale, it can optionally recreate the bookmark.
     
     - Parameters:
        - bookmarkData: The bookmark data to validate as SecureBytes
        - recreateIfStale: Whether to recreate the bookmark if stale
     
     - Returns: Result with validation result or error
     */
    public func validateBookmark(
        _ bookmarkData: SecureBytes,
        recreateIfStale: Bool
    ) async -> Result<BookmarkValidationResultDTO, UmbraErrors.Security.Bookmark> {
        await bookmarkLogger.logOperationStart(
            operation: "validateBookmark",
            additionalContext: LogMetadataDTOCollection()
                .withPrivate(key: "dataSize", value: String(bookmarkData.bytes.count))
                .withPublic(key: "recreateIfStale", value: String(recreateIfStale))
        )
        
        // Resolve the bookmark
        let resolveResult = await resolveBookmark(bookmarkData)
        
        switch resolveResult {
        case .success(let (url, isStale)):
            // If not stale, return valid
            if !isStale {
                await bookmarkLogger.logOperationSuccess(
                    operation: "validateBookmark",
                    additionalContext: LogMetadataDTOCollection()
                        .withPublic(key: "isValid", value: "true")
                        .withPublic(key: "isStale", value: "false")
                )
                
                return .success(BookmarkValidationResultDTO(
                    isValid: true,
                    isStale: false,
                    updatedBookmark: nil,
                    url: url
                ))
            }
            
            // If stale and recreateIfStale is true, recreate the bookmark
            if recreateIfStale {
                let recreateResult = await createBookmark(for: url, readOnly: false)
                
                switch recreateResult {
                case .success(let newBookmarkData):
                    await bookmarkLogger.logOperationSuccess(
                        operation: "validateBookmark",
                        additionalContext: LogMetadataDTOCollection()
                            .withPublic(key: "isValid", value: "true")
                            .withPublic(key: "isStale", value: "true")
                            .withPublic(key: "recreated", value: "true")
                    )
                    
                    return .success(BookmarkValidationResultDTO(
                        isValid: true,
                        isStale: true,
                        updatedBookmark: newBookmarkData,
                        url: url
                    ))
                    
                case .failure(let error):
                    await bookmarkLogger.logOperationError(
                        operation: "validateBookmark",
                        error: error
                    )
                    
                    return .failure(error)
                }
            }
            
            // If stale but don't recreate, return stale
            await bookmarkLogger.logOperationSuccess(
                operation: "validateBookmark",
                additionalContext: LogMetadataDTOCollection()
                    .withPublic(key: "isValid", value: "true")
                    .withPublic(key: "isStale", value: "true")
                    .withPublic(key: "recreated", value: "false")
            )
            
            return .success(BookmarkValidationResultDTO(
                isValid: true,
                isStale: true,
                updatedBookmark: nil,
                url: url
            ))
            
        case .failure(let error):
            await bookmarkLogger.logOperationError(
                operation: "validateBookmark",
                error: error
            )
            
            return .failure(error)
        }
    }
    
    /**
     Checks if all resources have been properly released.
     
     - Returns: True if all resources have been released, false otherwise
     */
    public func verifyAllResourcesReleased() async -> Bool {
        await bookmarkLogger.logOperationStart(
            operation: "verifyAllResourcesReleased"
        )
        
        let allReleased = activeResources.isEmpty
        
        await bookmarkLogger.logOperationSuccess(
            operation: "verifyAllResourcesReleased",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "allReleased", value: String(allReleased))
                .withPrivate(key: "activeCount", value: String(activeResources.count))
        )
        
        return allReleased
    }
    
    /**
     Forces release of all security-scoped resources.
     
     This method should only be used during application termination
     or error recovery to ensure all resources are properly released.
     
     - Returns: The number of resources that were released
     */
    public func forceReleaseAllResources() async -> Int {
        await bookmarkLogger.logOperationStart(
            operation: "forceReleaseAllResources",
            additionalContext: LogMetadataDTOCollection()
                .withPrivate(key: "activeCount", value: String(activeResources.count))
        )
        
        let count = activeResources.count
        
        // Release all resources
        for url in activeResources.keys {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Clear the tracking dictionary
        activeResources.removeAll()
        
        await bookmarkLogger.logOperationSuccess(
            operation: "forceReleaseAllResources",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "releasedCount", value: String(count))
        )
        
        return count
    }
}

/**
 # BookmarkLogger
 
 Domain-specific logger for security bookmark operations.
 
 This logger provides standardised logging for all bookmark operations
 with proper privacy controls and context handling.
 */
fileprivate struct BookmarkLogger {
    private let logger: LoggingProtocol
    
    init(logger: LoggingProtocol) {
        self.logger = logger
    }
    
    func logOperationStart(
        operation: String,
        additionalContext: LogMetadataDTOCollection? = nil
    ) async {
        await logger.log(
            level: .debug,
            message: "Starting bookmark operation: \(operation)",
            metadata: additionalContext
        )
    }
    
    func logOperationSuccess(
        operation: String,
        additionalContext: LogMetadataDTOCollection? = nil
    ) async {
        await logger.log(
            level: .debug,
            message: "Successfully completed bookmark operation: \(operation)",
            metadata: additionalContext
        )
    }
    
    func logOperationError(
        operation: String,
        error: Error,
        additionalContext: LogMetadataDTOCollection? = nil
    ) async {
        var context = additionalContext ?? LogMetadataDTOCollection()
        context = context.withPrivate(key: "error", value: "\(error)")
        
        await logger.log(
            level: .error,
            message: "Failed bookmark operation: \(operation)",
            metadata: context
        )
    }
}
