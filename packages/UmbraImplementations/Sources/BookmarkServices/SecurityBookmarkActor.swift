import CoreDTOs
import DomainSecurityTypes
import ErrorCoreTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCore
import SecurityCoreInterfaces
import SecurityInterfaces
import SecurityInterfacesProtocols
import SecurityInterfacesDTOs
import UmbraErrors
import UmbraErrorsDomains

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
public actor SecurityBookmarkActor: SecurityInterfacesProtocols.SecurityBookmarkProtocol {
  /// Logger for recording operations and errors
  private let logger: PrivacyAwareLoggingProtocol
  
  /// Domain-specific logger for bookmark operations
  private let bookmarkLogger: BookmarkLogger
  
  /// Secure storage service for handling bookmark data
  private let secureStorage: any SecureStorageProtocol
  
  /// Currently active security-scoped resources
  private var activeResources: [URL: Int]=[:]
  
  /**
   Initialises a new security bookmark actor.
   
   - Parameters:
      - logger: Logger for recording operations and errors
      - secureStorage: Secure storage service for bookmark data
   */
  public init(logger: PrivacyAwareLoggingProtocol, secureStorage: any SecureStorageProtocol) {
    self.logger=logger
    bookmarkLogger=BookmarkLogger(logger: logger)
    self.secureStorage=secureStorage
  }
  
  /**
   Creates a security-scoped bookmark for the provided URL.
   
   - Parameters:
      - url: The URL to create a bookmark for
      - readOnly: Whether the bookmark should be read-only
      - storageIdentifier: Optional identifier for storing the bookmark data. If nil, an identifier will be generated.
   
   - Returns: Result with the bookmark identifier or error
   */
  public func createBookmark(
    for url: URL,
    readOnly: Bool,
    storageIdentifier: String? = nil
  ) async -> Result<String, UmbraErrors.Security.Bookmark> {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withSensitive(key: "url", value: url.path)
    metadata=metadata.withPublic(key: "readOnly", value: String(readOnly))
    
    await bookmarkLogger.logOperationStart(
      operation: "createBookmark",
      additionalContext: metadata
    )
    
    do {
      let options: URL.BookmarkCreationOptions=readOnly
        ? [.withSecurityScope, .securityScopeAllowOnlyReadAccess]
        : [.withSecurityScope]
      
      let bookmarkData=try url.bookmarkData(
        options: options,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      
      // Use provided identifier or generate a unique one
      let identifier = storageIdentifier ?? "bookmark_\(UUID().uuidString)"
      
      // Convert to byte array for secure storage
      let bookmarkBytes=[UInt8](bookmarkData)
      
      // Store the bookmark data securely
      let storeResult=await secureStorage.storeData(
        bookmarkBytes,
        withIdentifier: identifier
      )
      
      switch storeResult {
        case .success:
          var successMetadata=LogMetadataDTOCollection()
          successMetadata=successMetadata.withPrivate(
            key: "dataSize",
            value: String(bookmarkData.count)
          )
          successMetadata=successMetadata.withPrivate(key: "identifier", value: identifier)
          
          await bookmarkLogger.logOperationSuccess(
            operation: "createBookmark",
            additionalContext: successMetadata
          )
          
          return .success(identifier)
          
        case let .failure(error):
          throw UmbraErrors.Security.Bookmark.cannotCreateBookmark(
            "Failed to store bookmark data: \(error)"
          )
      }
    } catch {
      let bookmarkError = error as? UmbraErrors.Security.Bookmark ?? 
        UmbraErrors.Security.Bookmark.cannotCreateBookmark(
          "Failed to create security-scoped bookmark: \(error.localizedDescription)"
        )
      
      await bookmarkLogger.logOperationError(
        operation: "createBookmark",
        error: bookmarkError,
        additionalContext: metadata
      )
      
      return .failure(bookmarkError)
    }
  }
  
  /**
   Resolves a security-scoped bookmark using its identifier.
   
   - Parameters:
      - storageIdentifier: The identifier of the bookmark to resolve
      - startAccess: Whether to start accessing the resource immediately
      - recreateIfStale: Whether to attempt recreating the bookmark if it's stale
   
   - Returns: Result with the resolved URL and stale status
   */
  public func resolveBookmark(
    withIdentifier storageIdentifier: String,
    startAccess: Bool=false,
    recreateIfStale: Bool=false
  ) async -> Result<(URL, Bool), UmbraErrors.Security.Bookmark> {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPrivate(key: "identifier", value: storageIdentifier)
    
    await bookmarkLogger.logOperationStart(
      operation: "resolveBookmark",
      additionalContext: metadata
    )
    
    // Retrieve the bookmark data from secure storage
    let retrieveResult=await secureStorage.retrieveData(
      withIdentifier: storageIdentifier
    )
    
    switch retrieveResult {
      case let .success(bookmarkBytes):
        do {
          let bookmarkData=Data(bookmarkBytes)
          
          var isStale=false
          let resolvedURL=try URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
          )
          
          var successMetadata=LogMetadataDTOCollection()
          successMetadata=successMetadata.withSensitive(key: "url", value: resolvedURL.path)
          successMetadata=successMetadata.withPublic(key: "isStale", value: String(isStale))
          
          // Handle stale bookmark
          if isStale && recreateIfStale {
            await bookmarkLogger.logOperationWarning(
              operation: "resolveBookmark",
              message: "Bookmark is stale, attempting to recreate",
              additionalContext: successMetadata
            )
            
            // Try to recreate the bookmark
            let recreateResult=await createBookmark(
              for: resolvedURL,
              readOnly: false,
              storageIdentifier: storageIdentifier
            )
            
            switch recreateResult {
              case .success:
                // Bookmark recreated successfully, continue with resolved URL
                await bookmarkLogger.logOperationSuccess(
                  operation: "resolveBookmark",
                  additionalContext: successMetadata
                )
                
              case let .failure(error):
                // Log warning but continue with stale bookmark
                await bookmarkLogger.logOperationWarning(
                  operation: "resolveBookmark",
                  message: "Failed to recreate stale bookmark: \(error)",
                  additionalContext: successMetadata
                )
            }
          } else {
            await bookmarkLogger.logOperationSuccess(
              operation: "resolveBookmark",
              additionalContext: successMetadata
            )
          }
          
          // Start accessing the resource if requested
          if startAccess {
            let accessResult=await startAccessing(resolvedURL)
            if case let .failure(error)=accessResult {
              await bookmarkLogger.logOperationWarning(
                operation: "resolveBookmark",
                message: "Resolved bookmark but failed to start access: \(error)",
                additionalContext: successMetadata
              )
            }
          }
          
          return .success((resolvedURL, isStale))
        } catch {
          let bookmarkError = UmbraErrors.Security.Bookmark.cannotResolveURL(
            "Failed to resolve security-scoped bookmark: \(error.localizedDescription)"
          )
          
          await bookmarkLogger.logOperationError(
            operation: "resolveBookmark",
            error: bookmarkError,
            additionalContext: metadata
          )
          
          return .failure(bookmarkError)
        }
        
      case let .failure(error):
        let bookmarkError = UmbraErrors.Security.Bookmark.invalidBookmark(
          "Failed to retrieve bookmark data: \(error)"
        )
        
        await bookmarkLogger.logOperationError(
          operation: "resolveBookmark",
          error: bookmarkError,
          additionalContext: metadata
        )
        
        return .failure(bookmarkError)
    }
  }
  
  /**
   Resolves a security-scoped bookmark to its URL.
   
   - Parameter storageIdentifier: The identifier of the bookmark to resolve
   - Returns: Result with the resolved URL and stale status
   */
  public func resolveBookmark(withIdentifier storageIdentifier: String) async -> Result<(URL, Bool), UmbraErrors.Security.Bookmark> {
    // Call our enhanced implementation with default parameters
    return await resolveBookmark(
      withIdentifier: storageIdentifier,
      startAccess: false,
      recreateIfStale: false
    )
  }
  
  /**
   Validates a security-scoped bookmark.
   
   - Parameters:
      - storageIdentifier: The identifier of the bookmark to validate
      - recreateIfStale: Whether to attempt recreating the bookmark if it's stale
   
   - Returns: Result with the validation result or error
   */
  public func validateBookmark(
    withIdentifier storageIdentifier: String,
    recreateIfStale: Bool=true
  ) async -> Result<BookmarkValidationResultDTO, UmbraErrors.Security.Bookmark> {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPrivate(key: "identifier", value: storageIdentifier)
    metadata=metadata.withPublic(key: "recreateIfStale", value: String(recreateIfStale))
    
    await bookmarkLogger.logOperationStart(
      operation: "validateBookmark",
      additionalContext: metadata
    )
    
    // Resolve the bookmark
    let resolveResult=await resolveBookmark(
      withIdentifier: storageIdentifier,
      startAccess: false,
      recreateIfStale: recreateIfStale
    )
    
    switch resolveResult {
      case let .success((resolvedURL, isStale)):
        // Check if URL exists
        let fileExists=FileManager.default.fileExists(atPath: resolvedURL.path)
        
        // Get the updated bookmark data if it was recreated
        var updatedBookmarkData: [UInt8]? = nil
        if recreateIfStale && isStale {
          // Retrieve bookmark data after recreation
          let retrieveResult = await secureStorage.retrieveData(withIdentifier: storageIdentifier)
          if case .success(let bookmarkBytes) = retrieveResult {
            updatedBookmarkData = bookmarkBytes
          }
        }
        
        // Create validation result
        let validationResult = BookmarkValidationResultDTO(
          isValid: fileExists,
          isStale: isStale,
          updatedBookmark: updatedBookmarkData,
          url: resolvedURL
        )
        
        var resultMetadata=LogMetadataDTOCollection()
        resultMetadata=resultMetadata.withSensitive(key: "url", value: resolvedURL.path)
        resultMetadata=resultMetadata.withPublic(key: "isValid", value: String(fileExists))
        resultMetadata=resultMetadata.withPublic(key: "isStale", value: String(isStale))
        
        if fileExists {
          await bookmarkLogger.logOperationSuccess(
            operation: "validateBookmark",
            additionalContext: resultMetadata
          )
        } else {
          await bookmarkLogger.logOperationWarning(
            operation: "validateBookmark",
            message: "Bookmark URL no longer exists",
            additionalContext: resultMetadata
          )
        }
        
        return .success(validationResult)
        
      case .failure(let error):
        await bookmarkLogger.logOperationError(
          operation: "validateBookmark",
          error: error,
          additionalContext: metadata
        )
        
        return .failure(error)
    }
  }
  
  /**
   Starts accessing a security-scoped resource.
   
   - Parameter url: The URL of the resource to access
   - Returns: Result with the number of active accessors or error
   */
  public func startAccessing(_ url: URL) async -> Result<Bool, UmbraErrors.Security.Bookmark> {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withSensitive(key: "url", value: url.path)
    
    await bookmarkLogger.logOperationStart(
      operation: "startAccessing",
      additionalContext: metadata
    )
    
    // Try to start accessing the resource
    guard url.startAccessingSecurityScopedResource() else {
      let error = UmbraErrors.Security.Bookmark.accessDenied(
        "Failed to start accessing security-scoped resource"
      )
      
      await bookmarkLogger.logOperationError(
        operation: "startAccessing",
        error: error,
        additionalContext: metadata
      )
      
      return .failure(error)
    }
    
    // Update access count
    let currentCount=activeResources[url] ?? 0
    let newCount=currentCount + 1
    activeResources[url]=newCount
    
    var resultMetadata=LogMetadataDTOCollection()
    resultMetadata=resultMetadata.withSensitive(key: "url", value: url.path)
    resultMetadata=resultMetadata.withPublic(key: "accessCount", value: String(newCount))
    
    await bookmarkLogger.logOperationSuccess(
      operation: "startAccessing",
      additionalContext: resultMetadata
    )
    
    return .success(true)
  }
  
  /**
   Stops accessing a security-scoped resource.
   
   - Parameter url: The URL of the resource to stop accessing
   - Returns: Result with the remaining number of active accessors or error
   */
  public func stopAccessing(_ url: URL) async -> Result<Int, UmbraErrors.Security.Bookmark> {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withSensitive(key: "url", value: url.path)
    
    await bookmarkLogger.logOperationStart(
      operation: "stopAccessing",
      additionalContext: metadata
    )
    
    // Check if we're tracking this resource
    guard let currentCount=activeResources[url], currentCount > 0 else {
      let error = UmbraErrors.Security.Bookmark.notAccessing(
        "Not currently accessing security-scoped resource"
      )
      
      await bookmarkLogger.logOperationError(
        operation: "stopAccessing",
        error: error,
        additionalContext: metadata
      )
      
      return .failure(error)
    }
    
    // Update access count
    let newCount=currentCount - 1
    if newCount > 0 {
      activeResources[url]=newCount
    } else {
      activeResources.removeValue(forKey: url)
      url.stopAccessingSecurityScopedResource()
    }
    
    var resultMetadata=LogMetadataDTOCollection()
    resultMetadata=resultMetadata.withSensitive(key: "url", value: url.path)
    resultMetadata=resultMetadata.withPublic(key: "accessCount", value: String(newCount))
    
    await bookmarkLogger.logOperationSuccess(
      operation: "stopAccessing",
      additionalContext: resultMetadata
    )
    
    return .success(newCount)
  }
  
  /**
   Checks if all resources have been properly released.
   
   - Returns: True if all resources have been released, false otherwise
   */
  public func verifyAllResourcesReleased() async -> Bool {
    return activeResources.isEmpty
  }
  
  /**
   Forces release of all security-scoped resources.
   This should only be used during application termination or in emergency situations.
   
   - Returns: Number of resources that were released
   */
  public func forceReleaseAllResources() async -> Int {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPrivate(key: "activeCount", value: String(activeResources.count))
    
    await bookmarkLogger.logOperationStart(
      operation: "forceReleaseAllResources",
      additionalContext: metadata
    )
    
    let count=activeResources.count
    for url in activeResources.keys {
      url.stopAccessingSecurityScopedResource()
    }
    activeResources.removeAll()
    
    await bookmarkLogger.logOperationSuccess(
      operation: "forceReleaseAllResources",
      additionalContext: metadata
    )
    
    return count
  }
}

// MARK: - Extension for LogMetadataDTOCollection to convert to PrivacyMetadata

extension LogMetadataDTOCollection {
  /// Converts LogMetadataDTOCollection to PrivacyMetadata for use with PrivacyAwareLoggingProtocol
  ///
  /// This extension allows for seamless integration between the DTO-based metadata system
  /// and the logging protocol's expected types.
  func toPrivacyMetadata() -> PrivacyMetadata {
    var result=PrivacyMetadata()
    
    for entry in entries {
      // Map the privacy level from LogMetadataDTO to LogPrivacyLevel
      let privacyLevel: LogPrivacyLevel=switch entry.privacyLevel {
        case .public:
          .public
        case .private:
          .private
        case .sensitive:
          .sensitive
        case .hash:
          .hash
        case .auto:
          // For auto privacy classification, default to private for safety
          .private
      }
      
      // Create PrivacyMetadataValue with correct parameter labels
      result[entry.key]=PrivacyMetadataValue(value: entry.value, privacy: privacyLevel)
    }
    
    return result
  }
}

/**
 * BookmarkLogger - Helper for logging security bookmark operations
 * with proper privacy controls and context handling.
 */
class BookmarkLogger {
  /// The underlying logger for recording operations
  private let logger: PrivacyAwareLoggingProtocol
  private let source: String="BookmarkServices"
  
  init(logger: PrivacyAwareLoggingProtocol) {
    self.logger=logger
  }
  
  /// Log the start of an operation
  func logOperationStart(
    operation: String,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    let message=PrivacyString(stringLiteral: "Starting bookmark operation: \(operation)")
    await logger.log(
      .debug,
      message,
      metadata: additionalContext?.toPrivacyMetadata(),
      source: source
    )
  }
  
  /// Log the successful completion of an operation
  func logOperationSuccess(
    operation: String,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    let message=PrivacyString(
      stringLiteral: "Bookmark operation completed successfully: \(operation)"
    )
    await logger.log(
      .debug,
      message,
      metadata: additionalContext?.toPrivacyMetadata(),
      source: source
    )
  }
  
  /// Log a warning during an operation
  func logOperationWarning(
    operation: String,
    message: String,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    var context=additionalContext ?? LogMetadataDTOCollection()
    context=context.withPrivate(key: "warning", value: message)
    
    let logMessage=PrivacyString(stringLiteral: "Bookmark operation warning: \(operation)")
    await logger.log(
      .warning,
      logMessage,
      metadata: context.toPrivacyMetadata(),
      source: source
    )
  }
  
  /// Log an error during an operation
  func logOperationError(
    operation: String,
    error: Error,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    var context=additionalContext ?? LogMetadataDTOCollection()
    context=context.withPrivate(key: "error", value: "\(error)")
    
    let logMessage=PrivacyString(stringLiteral: "Bookmark operation failed: \(operation)")
    await logger.log(
      .error,
      logMessage,
      metadata: context.toPrivacyMetadata(),
      source: source
    )
  }
}
