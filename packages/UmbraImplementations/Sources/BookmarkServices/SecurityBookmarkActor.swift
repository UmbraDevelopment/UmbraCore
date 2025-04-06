import CoreDTOs
import DomainSecurityTypes
import ErrorCoreTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCore
import SecurityCoreInterfaces
import SecurityInterfaces
import SecurityInterfacesDTOs
import SecurityInterfacesProtocols
import UmbraErrors
import UmbraErrorsDomains
import BookmarkLogger
import BookmarkModel

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
   Creates a new security bookmark actor with dependencies injected.

   - Parameters:
     - logger: The logger to use for operations
     - secureStorage: The secure storage service to use for bookmark data
   */
  public init(
    logger: PrivacyAwareLoggingProtocol,
    secureStorage: SecureStorageProtocol
  ) {
    self.logger=logger
    self.secureStorage=secureStorage
    self.bookmarkLogger=BookmarkLogger(logger: logger)
  }

  /**
   Creates a new security-scoped bookmark for the given URL.

   This bookmark allows access to user-selected files and directories
   even after the app is restarted, functioning similar to a capability
   in capability-based security systems.

   - Parameters:
     - url: The URL to create a bookmark for
     - storageIdentifier: The identifier to store the bookmark under
     - options: Optional bookmark creation options

   - Returns: A Result containing either success (Bool indicating if it was a new bookmark)
     or a domain-specific error
   */
  public func createBookmark(
    for url: URL,
    withIdentifier storageIdentifier: String,
    options: BookmarkCreationOptions?=nil
  ) async -> Result<Bool, UmbraErrors.Security.Bookmark> {
    let context = BookmarkLogContext(
      operation: "createBookmark",
      identifier: storageIdentifier,
      status: "started",
      metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
    )
    
    await bookmarkLogger.info("Creating security bookmark", context: context)
    
    // Create the bookmark data
    let createResult=createBookmarkData(for: url, options: options)
    
    switch createResult {
      case .success(let bookmarkData):
        // Convert Data to [UInt8]
        let bookmarkBytes = [UInt8](bookmarkData)
        
        // Store the bookmark data securely
        let storeResult = await secureStorage.storeData(
          bookmarkBytes,
          withIdentifier: storageIdentifier
        )
        
        switch storeResult {
          case .success:
            let successContext = BookmarkLogContext(
              operation: "createBookmark",
              identifier: storageIdentifier,
              status: "success",
              metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
            )
            
            await bookmarkLogger.info("Security bookmark created successfully", context: successContext)
            return .success(true)
            
          case .failure(let error):
            let errorContext = BookmarkLogContext(
              operation: "createBookmark",
              identifier: storageIdentifier,
              status: "error",
              metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
            )
            
            await bookmarkLogger.logError(error, context: errorContext)
            return .failure(.operationFailed("Storage operation failed: \(error.localizedDescription)"))
        }
        
      case .failure(let error):
        let errorContext = BookmarkLogContext(
          operation: "createBookmark",
          identifier: storageIdentifier,
          status: "error",
          metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
        )
        
        await bookmarkLogger.logError(error, context: errorContext)
        return .failure(.cannotCreateBookmark("Failed to create bookmark data: \(error.localizedDescription)"))
    }
  }

  /**
   Creates bookmark data for a URL.

   - Parameters:
     - url: The URL to create a bookmark for
     - options: Options for creating the bookmark

   - Returns: A Result containing either the bookmark data or an error
   */
  private func createBookmarkData(
    for url: URL,
    options: BookmarkCreationOptions?
  ) -> Result<Data, UmbraErrors.Security.Bookmark> {
    do {
      // Use the provided options or default to read-write
      let bookmarkOptions = options ?? BookmarkCreationOptions.default
      
      // Apply standard options plus any custom options
      var creationOptions: URL.BookmarkCreationOptions = []
      
      if bookmarkOptions.readOnly {
        creationOptions.insert(.securityScopeAllowOnlyReadAccess)
      }
      
      if let customOptions = bookmarkOptions.options {
        creationOptions.formUnion(customOptions)
      }
      
      // Always include security scope
      creationOptions.insert(.withSecurityScope)
      
      // Create the bookmark data
      let data = try url.bookmarkData(options: creationOptions, includingResourceValuesForKeys: nil, relativeTo: nil)
      
      return .success(data)
    } catch {
      return .failure(.cannotCreateBookmark("Error creating bookmark data: \(error.localizedDescription)"))
    }
  }

  /**
   Resolves a previously created security-scoped bookmark.

   This allows the app to access the resource that the bookmark was created for,
   even if the app has been restarted since creation.

   - Parameters:
     - storageIdentifier: The identifier the bookmark was stored under
     - startAccessingImmediately: Whether to immediately start accessing the resource

   - Returns: A Result containing either the URL and a Boolean indicating if the bookmark was stale,
     or a domain-specific error
   */
  public func resolveBookmark(
    withIdentifier storageIdentifier: String,
    startAccessingImmediately: Bool=false
  ) async -> Result<(URL, Bool), UmbraErrors.Security.Bookmark> {
    let context = BookmarkLogContext(
      operation: "resolveBookmark",
      identifier: storageIdentifier,
      status: "started"
    )
    
    await bookmarkLogger.info("Resolving security bookmark", context: context)
    
    // Retrieve the bookmark data
    let retrieveResult = await secureStorage.retrieveData(
      withIdentifier: storageIdentifier
    )
    
    switch retrieveResult {
      case .success(let bookmarkBytes):
        // Convert [UInt8] to Data
        let bookmarkData = Data(bookmarkBytes)
        
        // Resolve the bookmark data
        let resolveResult = resolveBookmarkData(bookmarkData)
        
        switch resolveResult {
          case .success(let resolveInfo):
            let (url, isStale) = resolveInfo
            
            let successContext = BookmarkLogContext(
              operation: "resolveBookmark",
              identifier: storageIdentifier,
              status: "success",
              metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
            )
            
            await bookmarkLogger.info("Bookmark resolved successfully", context: successContext)
            return .success((url, isStale))
          
          case .failure(let error):
            let errorContext = BookmarkLogContext(
              operation: "resolveBookmark",
              identifier: storageIdentifier,
              status: "error"
            )
            
            await bookmarkLogger.logError(error, context: errorContext)
            return .failure(.cannotResolveURL("Failed to resolve bookmark: \(error.localizedDescription)"))
        }
      
      case .failure(let error):
        let errorContext = BookmarkLogContext(
          operation: "resolveBookmark",
          identifier: storageIdentifier,
          status: "error"
        )
        
        await bookmarkLogger.logError(error, context: errorContext)
        return .failure(.invalidBookmark("Failed to retrieve bookmark data: \(error.localizedDescription)"))
    }
  }

  /**
   Resolves bookmark data to a URL.

   - Parameter bookmarkData: The bookmark data to resolve

   - Returns: A Result containing either the URL and a Boolean indicating if the bookmark was stale,
     or a domain-specific error
   */
  private func resolveBookmarkData(_ bookmarkData: Data) -> Result<(URL, Bool), Error> {
    do {
      var isStale = false
      let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
      
      return .success((url, isStale))
    } catch {
      return .failure(error)
    }
  }

  /**
   Validates that a security bookmark is still valid and can be resolved.

   - Parameters:
     - storageIdentifier: The identifier the bookmark was stored under
     - recreateIfStale: Whether to automatically recreate the bookmark if it's stale

   - Returns: A Result containing either a validation result or a domain-specific error
   */
  public func validateBookmark(
    withIdentifier storageIdentifier: String,
    recreateIfStale: Bool=false
  ) async -> Result<BookmarkValidationResultDTO, UmbraErrors.Security.Bookmark> {
    let context = BookmarkLogContext(
      operation: "validateBookmark",
      identifier: storageIdentifier,
      status: "started"
    )
    
    await bookmarkLogger.info("Validating security bookmark", context: context)
    
    // First, resolve the bookmark
    let resolveResult = await resolveBookmark(
      withIdentifier: storageIdentifier,
      startAccessingImmediately: false
    )

    switch resolveResult {
      case .success(let resolveInfo):
        let (url, isStale) = resolveInfo
        
        // If the bookmark is stale and we should recreate it
        if isStale && recreateIfStale {
          let warningContext = BookmarkLogContext(
            operation: "validateBookmark",
            identifier: storageIdentifier,
            status: "warning",
            metadata: LogMetadataDTOCollection()
              .withSensitive(key: "url", value: url.path)
              .withPublic(key: "isStale", value: "true")
          )
          
          await bookmarkLogger.warning("Bookmark is stale, recreating", context: warningContext)
          
          // Recreate the bookmark
          let recreateResult = await createBookmark(
            for: url,
            withIdentifier: storageIdentifier
          )
          
          switch recreateResult {
            case .success:
              let successContext = BookmarkLogContext(
                operation: "validateBookmark",
                identifier: storageIdentifier,
                status: "success",
                metadata: LogMetadataDTOCollection()
                  .withSensitive(key: "url", value: url.path)
                  .withPublic(key: "recreated", value: "true")
              )
              
              await bookmarkLogger.info("Stale bookmark recreated successfully", context: successContext)
              return .success(
                BookmarkValidationResultDTO(
                  isValid: true,
                  isStale: true,
                  updatedBookmark: nil,
                  url: url
                )
              )
            
            case .failure(let error):
              let errorContext = BookmarkLogContext(
                operation: "validateBookmark",
                identifier: storageIdentifier,
                status: "error",
                metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
              )
              
              await bookmarkLogger.logError(error, context: errorContext)
              return .failure(.staleBookmark("Unable to recreate stale bookmark: \(error.localizedDescription)"))
          }
        } else {
          // Bookmark is valid (possibly stale but we're not recreating)
          let successContext = BookmarkLogContext(
            operation: "validateBookmark",
            identifier: storageIdentifier,
            status: "success",
            metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
          )
          
          await bookmarkLogger.info("Bookmark validation successful", context: successContext)
          return .success(
            BookmarkValidationResultDTO(
              isValid: true,
              isStale: isStale,
              updatedBookmark: nil,
              url: url
            )
          )
        }
      
      case .failure(let error):
        let errorContext = BookmarkLogContext(
          operation: "validateBookmark",
          identifier: storageIdentifier,
          status: "error"
        )
        
        await bookmarkLogger.logError(error, context: errorContext)
        return .failure(.invalidBookmark("Bookmark validation failed: \(error.localizedDescription)"))
    }
  }

  /**
   Start accessing a security-scoped resource.

   This must be called before attempting to access the resource, and should
   be balanced with a call to stopAccessing when done.

   - Parameter url: The URL to start accessing
   - Returns: A Result containing either the access count or a domain-specific error
   */
  public func startAccessing(_ url: URL) async -> Result<Bool, UmbraErrors.Security.Bookmark> {
    let context = BookmarkLogContext(
      operation: "startAccessing",
      status: "started",
      metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
    )
    
    await bookmarkLogger.info("Starting access to security-scoped resource", context: context)
    
    // Try to start accessing the security-scoped resource
    if !url.startAccessingSecurityScopedResource() {
      let errorContext = BookmarkLogContext(
        operation: "startAccessing",
        status: "error",
        metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
      )
      
      let error = UmbraErrors.Security.Bookmark.accessDenied("Failed to start accessing security-scoped resource")
      
      await bookmarkLogger.logError(error, context: errorContext)
      return .failure(error)
    }
    
    // Update the access count
    let currentCount = activeResources[url] ?? 0
    let newCount = currentCount + 1
    activeResources[url] = newCount
    
    let successContext = BookmarkLogContext(
      operation: "startAccessing",
      status: "success",
      metadata: LogMetadataDTOCollection()
        .withSensitive(key: "url", value: url.path)
        .withPublic(key: "accessCount", value: String(newCount))
    )
    
    await bookmarkLogger.info("Started accessing security-scoped resource", context: successContext)
    return .success(true)
  }

  /**
   Stop accessing a security-scoped resource.

   This should be called when done with the resource, to balance a previous
   call to startAccessing.

   - Parameter url: The URL to stop accessing
   - Returns: A Result containing either the remaining access count or a domain-specific error
   */
  public func stopAccessing(_ url: URL) async -> Result<Int, UmbraErrors.Security.Bookmark> {
    let context = BookmarkLogContext(
      operation: "stopAccessing",
      status: "started",
      metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
    )
    
    await bookmarkLogger.info("Stopping access to security-scoped resource", context: context)
    
    // Get the current access count for this URL
    guard let currentCount = activeResources[url], currentCount > 0 else {
      let warningContext = BookmarkLogContext(
        operation: "stopAccessing",
        status: "warning",
        metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
      )
      
      await bookmarkLogger.warning("No active accesses found for URL", context: warningContext)
      return .success(0)
    }

    // Update the access count
    let newCount = currentCount - 1
    if newCount > 0 {
      activeResources[url] = newCount
    } else {
      // If access count is now zero, remove from tracking and stop accessing
      activeResources.removeValue(forKey: url)
      url.stopAccessingSecurityScopedResource()
    }

    let successContext = BookmarkLogContext(
      operation: "stopAccessing",
      status: "success",
      metadata: LogMetadataDTOCollection()
        .withSensitive(key: "url", value: url.path)
        .withPublic(key: "accessCount", value: String(newCount))
    )
    
    await bookmarkLogger.info("Stopped accessing security-scoped resource", context: successContext)
    return .success(newCount)
  }

  /**
   Removes a security bookmark from storage.

   - Parameter storageIdentifier: The identifier the bookmark was stored under
   - Returns: A Result indicating success or a domain-specific error
   */
  public func removeBookmark(
    withIdentifier storageIdentifier: String
  ) async -> Result<Void, UmbraErrors.Security.Bookmark> {
    let context = BookmarkLogContext(
      operation: "removeBookmark",
      identifier: storageIdentifier,
      status: "started"
    )
    
    await bookmarkLogger.info("Removing security bookmark", context: context)
    
    let removeResult = await secureStorage.deleteData(
      withIdentifier: storageIdentifier
    )
    
    switch removeResult {
      case .success:
        let successContext = BookmarkLogContext(
          operation: "removeBookmark",
          identifier: storageIdentifier,
          status: "success"
        )
        
        await bookmarkLogger.info("Security bookmark removed successfully", context: successContext)
        return .success(())
        
      case .failure(let error):
        let errorContext = BookmarkLogContext(
          operation: "removeBookmark",
          identifier: storageIdentifier,
          status: "error"
        )
        
        await bookmarkLogger.logError(error, context: errorContext)
        return .failure(.operationFailed("Failed to remove bookmark: \(error.localizedDescription)"))
    }
  }
}
