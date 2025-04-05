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

 This implementation focuses on providing a simplified interface for bookmark
 management with sensible defaults for most operations.

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
    storageIdentifier: String?=nil
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

      // Convert Data to [UInt8]
      let bookmarkBytes=[UInt8](bookmarkData)

      // Use provided identifier or generate a unique one
      let identifier=storageIdentifier ?? "bookmark_\(UUID().uuidString)"

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
      let bookmarkError=error as? UmbraErrors.Security.Bookmark ??
        UmbraErrors.Security.Bookmark.cannotCreateBookmark(
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

   - Parameter storageIdentifier: The identifier of the bookmark to resolve

   - Returns: Result with URL and staleness indicator or error
   */
  public func resolveBookmark(withIdentifier storageIdentifier: String) async
  -> Result<(URL, Bool), UmbraErrors.Security.Bookmark> {
    // Call our enhanced implementation with default parameters
    await resolveBookmark(
      withIdentifier: storageIdentifier,
      startAccess: false,
      recreateIfStale: false
    )
  }

  /**
   Resolves a security-scoped bookmark to its URL.

   - Parameter storageIdentifier: The identifier of the bookmark to resolve
   - Parameter startAccess: Whether to start accessing the resource after resolving
   - Parameter recreateIfStale: Whether to recreate the bookmark if stale

   - Returns: Result with URL and staleness indicator or error
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
          var isStale=false

          // Convert [UInt8] to Data
          let bookmarkData=Data(bookmarkBytes)

          let url=try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
          )

          var successMetadata=LogMetadataDTOCollection()
          successMetadata=successMetadata.withSensitive(key: "url", value: url.path)
          successMetadata=successMetadata.withPublic(key: "isStale", value: String(isStale))

          // Handle stale bookmark if needed
          if isStale && recreateIfStale {
            await bookmarkLogger.logOperationWarning(
              operation: "resolveBookmark",
              message: "Bookmark is stale, attempting to recreate",
              additionalContext: successMetadata
            )

            // Try to recreate the bookmark
            let recreateResult=await createBookmark(
              for: url,
              readOnly: false,
              storageIdentifier: storageIdentifier
            )

            switch recreateResult {
              case .success:
                await bookmarkLogger.logOperationSuccess(
                  operation: "resolveBookmark",
                  additionalContext: successMetadata
                )

              case let .failure(error):
                await bookmarkLogger.logOperationWarning(
                  operation: "resolveBookmark",
                  message: "Failed to recreate stale bookmark: \(error)",
                  additionalContext: successMetadata
                )
            }
          }

          // Start accessing if requested
          if startAccess {
            let accessResult=await startAccessing(url)

            switch accessResult {
              case .success:
                await bookmarkLogger.logOperationSuccess(
                  operation: "resolveBookmark",
                  additionalContext: successMetadata
                )

              case let .failure(error):
                await bookmarkLogger.logOperationWarning(
                  operation: "resolveBookmark",
                  message: "Failed to start accessing resource: \(error)",
                  additionalContext: successMetadata
                )
            }
          } else {
            await bookmarkLogger.logOperationSuccess(
              operation: "resolveBookmark",
              additionalContext: successMetadata
            )
          }

          return .success((url, isStale))
        } catch {
          let bookmarkError=UmbraErrors.Security.Bookmark.invalidBookmark(
            "Failed to resolve security-scoped bookmark: \(error.localizedDescription)"
          )

          await bookmarkLogger.logOperationError(
            operation: "resolveBookmark",
            error: bookmarkError
          )

          return .failure(bookmarkError)
        }

      case let .failure(error):
        let bookmarkError=UmbraErrors.Security.Bookmark.cannotResolveURL(
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
   Starts accessing a security-scoped resource.

   - Parameter url: URL of the security-scoped resource
   - Returns: Result indicating success or error
   */
  public func startAccessing(_ url: URL) async -> Result<Bool, UmbraErrors.Security.Bookmark> {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withSensitive(key: "url", value: url.path)

    await bookmarkLogger.logOperationStart(
      operation: "startAccessing",
      additionalContext: metadata
    )

    if url.startAccessingSecurityScopedResource() {
      let currentCount=activeResources[url] ?? 0
      activeResources[url]=currentCount + 1

      var successMetadata=LogMetadataDTOCollection()
      successMetadata=successMetadata.withPublic(key: "count", value: "\(currentCount + 1)")

      await bookmarkLogger.logOperationSuccess(
        operation: "startAccessing",
        additionalContext: successMetadata
      )

      return .success(true)
    } else {
      let bookmarkError=UmbraErrors.Security.Bookmark.operationFailed(
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

   - Parameter url: URL of the security-scoped resource
   - Returns: Result with remaining access count or error
   */
  public func stopAccessing(_ url: URL) async -> Result<Int, UmbraErrors.Security.Bookmark> {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withSensitive(key: "url", value: url.path)

    await bookmarkLogger.logOperationStart(
      operation: "stopAccessing",
      additionalContext: metadata
    )

    // Check if currently accessing
    guard let currentCount=activeResources[url], currentCount > 0 else {
      let bookmarkError=UmbraErrors.Security.Bookmark.notAccessing(
        "Not currently accessing this security-scoped resource"
      )

      await bookmarkLogger.logOperationError(
        operation: "stopAccessing",
        error: bookmarkError
      )

      return .failure(bookmarkError)
    }

    // Decrement the access count
    let newCount=currentCount - 1

    // If the count reaches zero, stop accessing
    if newCount <= 0 {
      url.stopAccessingSecurityScopedResource()
      activeResources.removeValue(forKey: url)

      var successMetadata=LogMetadataDTOCollection()
      successMetadata=successMetadata.withPublic(key: "count", value: "0")
      successMetadata=successMetadata.withPublic(key: "released", value: "true")

      await bookmarkLogger.logOperationSuccess(
        operation: "stopAccessing",
        additionalContext: successMetadata
      )
    } else {
      activeResources[url]=newCount

      var successMetadata=LogMetadataDTOCollection()
      successMetadata=successMetadata.withPublic(key: "count", value: "\(newCount)")
      successMetadata=successMetadata.withPublic(key: "released", value: "false")

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
      - storageIdentifier: The identifier of the bookmark to validate
      - recreateIfStale: Whether to recreate if stale

   - Returns: Result with validation details or error
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

    // First resolve the bookmark
    let resolveResult=await resolveBookmark(
      withIdentifier: storageIdentifier,
      startAccess: false,
      recreateIfStale: recreateIfStale
    )

    switch resolveResult {
      case let .success((url, isStale)):
        // Validate that the file still exists
        let fileExists=FileManager.default.fileExists(atPath: url.path)

        // If bookmark was recreated and is stale, get the updated bookmark data
        var updatedBookmarkBytes: [UInt8]?
        if recreateIfStale && isStale {
          // Retrieve the updated bookmark data from secure storage
          let retrieveResult=await secureStorage.retrieveData(withIdentifier: storageIdentifier)
          if case let .success(bookmarkData)=retrieveResult {
            updatedBookmarkBytes=bookmarkData
          }
        }

        let validationResult=BookmarkValidationResultDTO(
          isValid: fileExists,
          isStale: isStale,
          updatedBookmark: updatedBookmarkBytes,
          url: url
        )

        var successMetadata=LogMetadataDTOCollection()
        successMetadata=successMetadata.withPublic(key: "isValid", value: String(fileExists))
        successMetadata=successMetadata.withPublic(key: "isStale", value: String(isStale))

        await bookmarkLogger.logOperationSuccess(
          operation: "validateBookmark",
          additionalContext: successMetadata
        )

        return .success(validationResult)

      case let .failure(error):
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
    let metadata=LogMetadataDTOCollection()

    await bookmarkLogger.logOperationStart(
      operation: "verifyAllResourcesReleased",
      additionalContext: metadata
    )

    let allReleased=activeResources.isEmpty

    var successMetadata=LogMetadataDTOCollection()
    successMetadata=successMetadata.withPublic(key: "allReleased", value: String(allReleased))
    successMetadata=successMetadata.withPrivate(
      key: "activeCount",
      value: String(activeResources.count)
    )

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

    var successMetadata=LogMetadataDTOCollection()
    successMetadata=successMetadata.withPublic(key: "releasedCount", value: String(count))

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
private struct BookmarkLogger {
  private let logger: PrivacyAwareLoggingProtocol

  init(logger: PrivacyAwareLoggingProtocol) {
    self.logger=logger
  }

  func logOperationStart(
    operation: String,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "operation", value: operation)
    if let additionalContext {
      metadata=metadata.merging(with: additionalContext)
    }

    await logger.debug(
      "Starting bookmark operation: \(operation)",
      metadata: metadata.toPrivacyMetadata(),
      source: "SecurityBookmark"
    )
  }

  func logOperationSuccess(
    operation: String,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "operation", value: operation)
    metadata=metadata.withPublic(key: "status", value: "success")
    if let additionalContext {
      metadata=metadata.merging(with: additionalContext)
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
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "operation", value: operation)
    metadata=metadata.withPublic(key: "status", value: "error")

    // Add error information
    if let loggableError=error as? LoggableErrorProtocol {
      let errorMetadata=loggableError.getPrivacyMetadata()

      // Extract privacy-aware metadata
      for key in errorMetadata.keys {
        if let value=errorMetadata[key] {
          metadata=metadata.withPrivate(key: key, value: value.valueString)
        }
      }
    } else {
      metadata=metadata.withPrivate(key: "errorMessage", value: error.localizedDescription)
    }

    if let additionalContext {
      metadata=metadata.merging(with: additionalContext)
    }

    await logger.error(
      "Failed bookmark operation: \(operation)",
      metadata: metadata.toPrivacyMetadata(),
      source: "SecurityBookmark"
    )
  }

  func logOperationWarning(
    operation: String,
    message: String,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "operation", value: operation)
    metadata=metadata.withPublic(key: "warning", value: message)

    if let additionalContext {
      metadata=metadata.merging(with: additionalContext)
    }

    await logger.warning(
      "Warning during bookmark operation: \(operation) - \(message)",
      metadata: metadata.toPrivacyMetadata(),
      source: "SecurityBookmark"
    )
  }
}
