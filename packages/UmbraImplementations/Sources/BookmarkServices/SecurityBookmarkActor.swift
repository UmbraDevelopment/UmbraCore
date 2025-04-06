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
    storageIdentifier: String,
    options: BookmarkCreationOptions?=nil
  ) async -> Result<Bool, UmbraErrors.Security.Bookmark> {
    let context = BookmarkLogContext(
      operation: "createBookmark",
      identifier: storageIdentifier,
      status: "started"
    )
    await bookmarkLogger.info("Creating security bookmark", context: context)

    // Get bookmark data for the URL
    let bookmarkResult=createBookmarkData(for: url, options: options)
    switch bookmarkResult {
      case .success(let bookmarkData):
        // Store the bookmark data securely
        let storeResult=await secureStorage.store(
          data: bookmarkData,
          identifier: storageIdentifier,
          itemClass: .bookmark
        )

        switch storeResult {
          case .success(let wasNewItem):
            let successContext = BookmarkLogContext(
              operation: "createBookmark",
              identifier: storageIdentifier,
              status: "success"
            )
            await bookmarkLogger.info("Bookmark created and stored successfully", context: successContext)
            return .success(wasNewItem)

          case .failure(let error):
            let errorContext = BookmarkLogContext(
              operation: "createBookmark",
              identifier: storageIdentifier,
              status: "error"
            )
            await bookmarkLogger.logError(error, context: errorContext)
            return .failure(.storageError(underlying: error))
        }

      case .failure(let error):
        let errorContext = BookmarkLogContext(
          operation: "createBookmark",
          identifier: storageIdentifier,
          status: "error"
        )
        await bookmarkLogger.logError(error, context: errorContext)
        return .failure(.creationFailed(underlying: error))
    }
  }

  /**
   Creates security bookmark data for the given URL.

   - Parameters:
     - url: The URL to create bookmark data for
     - options: Optional bookmark creation options

   - Returns: A Result containing either the bookmark data or a domain-specific error
   */
  private func createBookmarkData(
    for url: URL,
    options: BookmarkCreationOptions?
  ) -> Result<Data, UmbraErrors.Security.Bookmark> {
    do {
      // Apply bookmark creation options or use defaults
      let bookmarkOptions: URL.BookmarkCreationOptions
      if let options {
        bookmarkOptions=options.toFoundationOptions()
      } else {
        bookmarkOptions=[.withSecurityScope, .securityScopeAllowOnlyReadAccess]
      }

      // Create the bookmark data
      let data=try url.bookmarkData(
        options: bookmarkOptions,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      return .success(data)
    } catch {
      return .failure(.creationFailed(underlying: error))
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
    storageIdentifier: String,
    startAccessingImmediately: Bool=false
  ) async -> Result<(URL, Bool), UmbraErrors.Security.Bookmark> {
    let context = BookmarkLogContext(
      operation: "resolveBookmark",
      identifier: storageIdentifier,
      status: "started"
    )
    await bookmarkLogger.info("Resolving security bookmark", context: context)

    // Retrieve the bookmark data
    let retrieveResult=await secureStorage.retrieve(
      identifier: storageIdentifier,
      itemClass: .bookmark
    )

    switch retrieveResult {
      case .success(let bookmarkData):
        // Resolve the bookmark to a URL
        let resolveResult=resolveBookmarkData(bookmarkData)
        switch resolveResult {
          case .success(let (url, wasStale)):
            // Optionally start accessing the resource immediately
            if startAccessingImmediately {
              let accessResult=await startAccessing(url)
              switch accessResult {
                case .success:
                  let successContext = BookmarkLogContext(
                    operation: "resolveBookmark",
                    identifier: storageIdentifier,
                    status: "success"
                  )
                  await bookmarkLogger.info("Bookmark resolved and access started", context: successContext)
                  return .success((url, wasStale))

                case .failure(let error):
                  let errorContext = BookmarkLogContext(
                    operation: "resolveBookmark",
                    identifier: storageIdentifier,
                    status: "error"
                  )
                  await bookmarkLogger.logError(error, context: errorContext)
                  return .failure(.accessFailed(underlying: error))
              }
            } else {
              let successContext = BookmarkLogContext(
                operation: "resolveBookmark",
                identifier: storageIdentifier,
                status: "success"
              )
              await bookmarkLogger.info("Bookmark resolved successfully", context: successContext)
              return .success((url, wasStale))
            }

          case .failure(let error):
            let errorContext = BookmarkLogContext(
              operation: "resolveBookmark",
              identifier: storageIdentifier,
              status: "error"
            )
            await bookmarkLogger.logError(error, context: errorContext)
            return .failure(error)
        }

      case .failure(let error):
        let errorContext = BookmarkLogContext(
          operation: "resolveBookmark",
          identifier: storageIdentifier,
          status: "error"
        )
        await bookmarkLogger.logError(error, context: errorContext)
        return .failure(.retrievalFailed(underlying: error))
    }
  }

  /**
   Resolves bookmark data to a URL.

   - Parameter bookmarkData: The bookmark data to resolve
   - Returns: A Result containing either the URL and a Boolean indicating if the bookmark was stale,
     or a domain-specific error
   */
  private func resolveBookmarkData(
    _ bookmarkData: Data
  ) -> Result<(URL, Bool), UmbraErrors.Security.Bookmark> {
    do {
      var isStale=false
      let url=try URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      return .success((url, isStale))
    } catch {
      return .failure(.resolutionFailed(underlying: error))
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
    storageIdentifier: String,
    recreateIfStale: Bool=false
  ) async -> Result<BookmarkValidationResultDTO, UmbraErrors.Security.Bookmark> {
    let context = BookmarkLogContext(
      operation: "validateBookmark",
      identifier: storageIdentifier,
      status: "started"
    )
    await bookmarkLogger.info("Validating security bookmark", context: context)

    // First resolve the bookmark to see if it's valid
    let resolveResult=await resolveBookmark(
      storageIdentifier: storageIdentifier,
      startAccessingImmediately: false
    )

    switch resolveResult {
      case .success(let (url, isStale)):
        // If the bookmark is stale and we should recreate it
        if isStale && recreateIfStale {
          let warningContext = BookmarkLogContext(
            operation: "validateBookmark",
            identifier: storageIdentifier,
            status: "warning"
          )
          await bookmarkLogger.warning("Bookmark is stale, attempting to recreate", context: warningContext)

          // Try to recreate the bookmark
          let recreateResult=await createBookmark(
            for: url,
            storageIdentifier: storageIdentifier
          )

          switch recreateResult {
            case .success:
              let successContext = BookmarkLogContext(
                operation: "validateBookmark",
                identifier: storageIdentifier,
                status: "success"
              )
              await bookmarkLogger.info("Stale bookmark recreated successfully", context: successContext)
              return .success(
                BookmarkValidationResultDTO(
                  isValid: true,
                  wasStale: true,
                  wasRecreated: true,
                  url: url
                )
              )

            case .failure(let error):
              let errorContext = BookmarkLogContext(
                operation: "validateBookmark",
                identifier: storageIdentifier,
                status: "error"
              )
              await bookmarkLogger.logError(error, context: errorContext)
              return .failure(.validationFailed(underlying: error))
          }
        } else {
          // Bookmark is valid (possibly stale but we're not recreating)
          let successContext = BookmarkLogContext(
            operation: "validateBookmark",
            identifier: storageIdentifier,
            status: "success"
          )
          await bookmarkLogger.info("Bookmark validation successful", context: successContext)
          return .success(
            BookmarkValidationResultDTO(
              isValid: true,
              wasStale: isStale,
              wasRecreated: false,
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
        return .failure(.validationFailed(underlying: error))
    }
  }

  /**
   Start accessing a security-scoped resource.

   This must be called before attempting to access the resource, and should
   be balanced with a call to stopAccessing when done.

   - Parameter url: The URL to start accessing
   - Returns: A Result containing either the access count or a domain-specific error
   */
  public func startAccessing(_ url: URL) async -> Result<Int, UmbraErrors.Security.Bookmark> {
    let context = BookmarkLogContext(
      operation: "startAccessing",
      status: "started",
      metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
    )
    await bookmarkLogger.info("Starting security-scoped resource access", context: context)

    // Try to start accessing the security-scoped resource
    if !url.startAccessingSecurityScopedResource() {
      let errorContext = BookmarkLogContext(
        operation: "startAccessing",
        status: "error",
        metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
      )
      let error = UmbraErrors.Security.Bookmark.accessFailed(
        underlying: NSError(
          domain: "SecurityBookmarkActor",
          code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Could not start accessing security-scoped resource"]
        )
      )
      await bookmarkLogger.logError(error, context: errorContext)
      return .failure(error)
    }

    // Update the access count for this URL
    let currentCount=activeResources[url] ?? 0
    let newCount=currentCount + 1
    activeResources[url]=newCount

    let successContext = BookmarkLogContext(
      operation: "startAccessing",
      status: "success",
      metadata: LogMetadataDTOCollection()
        .withSensitive(key: "url", value: url.path)
        .withPublic(key: "accessCount", value: String(newCount))
    )
    await bookmarkLogger.info("Started accessing security-scoped resource", context: successContext)
    return .success(newCount)
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
    await bookmarkLogger.info("Stopping security-scoped resource access", context: context)

    // Get the current access count for this URL
    guard let currentCount=activeResources[url], currentCount > 0 else {
      let warningContext = BookmarkLogContext(
        operation: "stopAccessing",
        status: "warning",
        metadata: LogMetadataDTOCollection().withSensitive(key: "url", value: url.path)
      )
      await bookmarkLogger.warning("No active accesses found for URL", context: warningContext)
      return .success(0)
    }

    // Update the access count
    let newCount=currentCount - 1
    if newCount > 0 {
      activeResources[url]=newCount
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
    storageIdentifier: String
  ) async -> Result<Void, UmbraErrors.Security.Bookmark> {
    let context = BookmarkLogContext(
      operation: "removeBookmark",
      identifier: storageIdentifier,
      status: "started"
    )
    await bookmarkLogger.info("Removing security bookmark", context: context)

    let removeResult=await secureStorage.remove(
      identifier: storageIdentifier,
      itemClass: .bookmark
    )

    switch removeResult {
      case .success:
        let successContext = BookmarkLogContext(
          operation: "removeBookmark",
          identifier: storageIdentifier,
          status: "success"
        )
        await bookmarkLogger.info("Bookmark removed successfully", context: successContext)
        return .success(())

      case .failure(let error):
        let errorContext = BookmarkLogContext(
          operation: "removeBookmark",
          identifier: storageIdentifier,
          status: "error"
        )
        await bookmarkLogger.logError(error, context: errorContext)
        return .failure(.removalFailed(underlying: error))
    }
  }
}
