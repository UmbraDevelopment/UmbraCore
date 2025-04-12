import BookmarkLogger
import BookmarkModel
import CoreDTOs
import DomainSecurityTypes
import ErrorCoreTypes
import FileSystemInterfaces
import FileSystemTypes
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

  /// File system service for handling file operations
  private let fileSystemService: any FileSystemServiceProtocol

  /// Currently active security-scoped resources
  private var activeResources: [FilePathDTO: Int]=[:]

  /**
   Creates a new security bookmark actor with dependencies injected.

   - Parameters:
     - logger: The logger to use for operations
     - secureStorage: The secure storage service for bookmark data
     - fileSystemService: The file system service for file operations
   */
  public init(
    logger: PrivacyAwareLoggingProtocol,
    secureStorage: any SecureStorageProtocol,
    fileSystemService: any FileSystemServiceProtocol
  ) {
    self.logger=logger
    bookmarkLogger=BookmarkLogger(logger: logger)
    self.secureStorage=secureStorage
    self.fileSystemService=fileSystemService
    activeResources=[:]
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
    // Convert URL to FilePathDTO
    let filePathDTO=FilePathDTO(path: url.path)

    return await createBookmark(
      for: filePathDTO,
      withIdentifier: storageIdentifier,
      options: options
    )
  }

  /**
   Creates a new security-scoped bookmark for the given file path.

   This bookmark allows access to user-selected files and directories
   even after the app is restarted, functioning similar to a capability
   in capability-based security systems.

   - Parameters:
     - path: The file path to create a bookmark for
     - storageIdentifier: The identifier to store the bookmark under
     - options: Optional bookmark creation options

   - Returns: A Result containing either success (Bool indicating if it was a new bookmark)
     or a domain-specific error
   */
  public func createBookmark(
    for path: FilePathDTO,
    withIdentifier storageIdentifier: String,
    options: BookmarkCreationOptions?=nil
  ) async -> Result<Bool, UmbraErrors.Security.Bookmark> {
    let context=BookmarkLogContext(
      domainName: "BookmarkServices",
      metadata: LogMetadataDTOCollection().withSensitive(key: "path", value: path.path),
      operation: "createBookmark",
      identifier: storageIdentifier,
      status: "started"
    )

    await bookmarkLogger.info("Creating security bookmark", context: context)

    // Create the bookmark data
    let createResult=await createBookmarkData(for: path, options: options)

    switch createResult {
      case let .success(bookmarkData):
        // Convert Data to [UInt8]
        let bookmarkBytes=[UInt8](bookmarkData)

        // Store the bookmark data securely
        let storeResult=await secureStorage.storeData(
          bookmarkBytes,
          withIdentifier: storageIdentifier
        )

        switch storeResult {
          case .success:
            let successContext=BookmarkLogContext(
              domainName: "BookmarkServices",
              metadata: LogMetadataDTOCollection().withSensitive(key: "path", value: path.path),
              operation: "createBookmark",
              identifier: storageIdentifier,
              status: "success"
            )

            await bookmarkLogger.info(
              "Security bookmark created successfully",
              context: successContext
            )
            return .success(true)

          case let .failure(error):
            let errorContext=BookmarkLogContext(
              domainName: "BookmarkServices",
              metadata: LogMetadataDTOCollection().withSensitive(key: "path", value: path.path),
              operation: "createBookmark",
              identifier: storageIdentifier,
              status: "error"
            )

            await bookmarkLogger.logError(error, context: errorContext)
            return .failure(
              .operationFailed("Storage operation failed: \(error.localizedDescription)")
            )
        }

      case let .failure(error):
        let errorContext=BookmarkLogContext(
          domainName: "BookmarkServices",
          metadata: LogMetadataDTOCollection().withSensitive(key: "path", value: path.path),
          operation: "createBookmark",
          identifier: storageIdentifier,
          status: "error"
        )

        await bookmarkLogger.logError(error, context: errorContext)
        return .failure(
          .cannotCreateBookmark("Failed to create bookmark data: \(error.localizedDescription)")
        )
    }
  }

  /**
   Creates a security-scoped bookmark for the URL.

   - Parameters:
     - url: The URL to create a bookmark for
     - readOnly: Whether the bookmark should be read-only
     - storageIdentifier: Optional identifier for storing the bookmark data

   - Returns: Result with storage identifier for the bookmark data or error
   */
  public func createBookmark(
    for url: URL,
    readOnly: Bool,
    storageIdentifier: String?=nil
  ) async -> Result<String, UmbraErrors.Security.Bookmark> {
    // Convert URL to FilePathDTO
    let filePathDTO=FilePathDTO(path: url.path)

    return await createBookmark(
      for: filePathDTO,
      readOnly: readOnly,
      storageIdentifier: storageIdentifier
    )
  }

  /**
   Creates a security-scoped bookmark for the file path.

   - Parameters:
     - path: The file path to create a bookmark for
     - readOnly: Whether the bookmark should be read-only
     - storageIdentifier: Optional identifier for storing the bookmark data

   - Returns: Result with storage identifier for the bookmark data or error
   */
  public func createBookmark(
    for path: FilePathDTO,
    readOnly: Bool,
    storageIdentifier: String?=nil
  ) async -> Result<String, UmbraErrors.Security.Bookmark> {
    let identifier=storageIdentifier ?? UUID().uuidString

    let context=BookmarkLogContext(
      domainName: "BookmarkServices",
      metadata: LogMetadataDTOCollection().withSensitive(key: "path", value: path.path),
      operation: "createBookmark",
      identifier: identifier,
      status: "started"
    )

    await bookmarkLogger.info("Creating security bookmark", context: context)

    // Create options with the requested read-only setting
    let options=BookmarkCreationOptions(readOnly: readOnly)

    // Create the bookmark data
    let createResult=await createBookmarkData(for: path, options: options)

    switch createResult {
      case let .success(bookmarkData):
        // Convert Data to [UInt8]
        let bookmarkBytes=[UInt8](bookmarkData)

        // Store the bookmark data securely
        let storeResult=await secureStorage.storeData(
          bookmarkBytes,
          withIdentifier: identifier
        )

        switch storeResult {
          case .success:
            let successContext=BookmarkLogContext(
              domainName: "BookmarkServices",
              metadata: LogMetadataDTOCollection().withSensitive(key: "path", value: path.path),
              operation: "createBookmark",
              identifier: identifier,
              status: "success"
            )

            await bookmarkLogger.info(
              "Security bookmark created successfully",
              context: successContext
            )
            return .success(identifier)

          case let .failure(error):
            let errorContext=BookmarkLogContext(
              domainName: "BookmarkServices",
              metadata: LogMetadataDTOCollection().withSensitive(key: "path", value: path.path),
              operation: "createBookmark",
              identifier: identifier,
              status: "error"
            )

            await bookmarkLogger.logError(error, context: errorContext)
            return .failure(
              .operationFailed("Storage operation failed: \(error.localizedDescription)")
            )
        }

      case let .failure(error):
        let errorContext=BookmarkLogContext(
          domainName: "BookmarkServices",
          metadata: LogMetadataDTOCollection().withSensitive(key: "path", value: path.path),
          operation: "createBookmark",
          identifier: identifier,
          status: "error"
        )

        await bookmarkLogger.logError(error, context: errorContext)
        return .failure(
          .cannotCreateBookmark("Failed to create bookmark data: \(error.localizedDescription)")
        )
    }
  }

  /**
   Creates bookmark data for a file path.

   - Parameters:
     - path: The file path to create a bookmark for
     - options: Options for creating the bookmark

   - Returns: A Result containing either the bookmark data or an error
   */
  private func createBookmarkData(
    for path: FilePathDTO,
    options: BookmarkCreationOptions?=nil
  ) async -> Result<Data, UmbraErrors.Security.Bookmark> {
    do {
      // Use the provided options or default to read-write
      let bookmarkOptions=options ?? BookmarkCreationOptions.default

      // Create the bookmark data using our abstracted file system service
      let bookmarkData=try await fileSystemService.createSecurityBookmark(
        for: path,
        readOnly: bookmarkOptions.readOnly
      )

      return .success(bookmarkData)
    } catch {
      return .failure(
        .cannotCreateBookmark("Error creating bookmark data: \(error.localizedDescription)")
      )
    }
  }

  /**
   Resolves a security-scoped bookmark to its file path.

   - Parameters:
     - storageIdentifier: The identifier for the stored bookmark data

   - Returns: Result with file path and staleness indicator or error
   */
  public func resolveBookmark(
    withIdentifier storageIdentifier: String
  ) async -> Result<(URL, Bool), UmbraErrors.Security.Bookmark> {
    let context=BookmarkLogContext(
      domainName: "BookmarkServices",
      metadata: LogMetadataDTOCollection(),
      operation: "resolveBookmark",
      identifier: storageIdentifier,
      status: "started"
    )

    await bookmarkLogger.info("Resolving security bookmark", context: context)

    // Retrieve the bookmark data
    let retrieveResult=await secureStorage.retrieveData(withIdentifier: storageIdentifier)

    switch retrieveResult {
      case let .success(bookmarkBytes):
        // Convert [UInt8] to Data
        let bookmarkData=Data(bookmarkBytes)

        do {
          // Resolve the bookmark data to a file path using our file system service
          let (filePathDTO, isStale)=try await fileSystemService
            .resolveSecurityBookmark(bookmarkData)

          // Convert FilePathDTO to URL for backward compatibility
          let url=URL(fileURLWithPath: filePathDTO.path)

          if isStale {
            let warningContext=BookmarkLogContext(
              domainName: "BookmarkServices",
              metadata: LogMetadataDTOCollection().withSensitive(
                key: "path",
                value: filePathDTO.path
              ),
              operation: "resolveBookmark",
              identifier: storageIdentifier,
              status: "warning"
            )

            await bookmarkLogger.warning(
              "Resolved bookmark is stale and should be recreated",
              context: warningContext
            )
          }

          let successContext=BookmarkLogContext(
            domainName: "BookmarkServices",
            metadata: LogMetadataDTOCollection()
              .withSensitive(key: "path", value: filePathDTO.path)
              .withPublic(key: "isStale", value: String(isStale)),
            operation: "resolveBookmark",
            identifier: storageIdentifier,
            status: "success"
          )

          await bookmarkLogger.info(
            "Security bookmark resolved successfully",
            context: successContext
          )
          return .success((url, isStale))

        } catch {
          let errorContext=BookmarkLogContext(
            domainName: "BookmarkServices",
            metadata: LogMetadataDTOCollection(),
            operation: "resolveBookmark",
            identifier: storageIdentifier,
            status: "error"
          )

          await bookmarkLogger.logError(error, context: errorContext)
          return .failure(
            .invalidBookmark("Failed to resolve bookmark data: \(error.localizedDescription)")
          )
        }

      case let .failure(error):
        let errorContext=BookmarkLogContext(
          domainName: "BookmarkServices",
          metadata: LogMetadataDTOCollection(),
          operation: "resolveBookmark",
          identifier: storageIdentifier,
          status: "error"
        )

        await bookmarkLogger.logError(error, context: errorContext)
        return .failure(
          .invalidBookmark("Failed to retrieve bookmark data: \(error.localizedDescription)")
        )
    }
  }

  /**
   Resolves a security-scoped bookmark to its file path.

   - Parameters:
     - storageIdentifier: The identifier for the stored bookmark data

   - Returns: Result with file path and staleness indicator or error
   */
  public func resolveBookmarkToFilePath(
    withIdentifier storageIdentifier: String
  ) async -> Result<(FilePathDTO, Bool), UmbraErrors.Security.Bookmark> {
    let context=BookmarkLogContext(
      domainName: "BookmarkServices",
      metadata: LogMetadataDTOCollection(),
      operation: "resolveBookmarkToFilePath",
      identifier: storageIdentifier,
      status: "started"
    )

    await bookmarkLogger.info("Resolving security bookmark to file path", context: context)

    // Retrieve the bookmark data
    let retrieveResult=await secureStorage.retrieveData(withIdentifier: storageIdentifier)

    switch retrieveResult {
      case let .success(bookmarkBytes):
        // Convert [UInt8] to Data
        let bookmarkData=Data(bookmarkBytes)

        do {
          // Resolve the bookmark data to a file path using our file system service
          let (filePathDTO, isStale)=try await fileSystemService
            .resolveSecurityBookmark(bookmarkData)

          if isStale {
            let warningContext=BookmarkLogContext(
              domainName: "BookmarkServices",
              metadata: LogMetadataDTOCollection().withSensitive(
                key: "path",
                value: filePathDTO.path
              ),
              operation: "resolveBookmarkToFilePath",
              identifier: storageIdentifier,
              status: "warning"
            )

            await bookmarkLogger.warning(
              "Resolved bookmark is stale and should be recreated",
              context: warningContext
            )
          }

          let successContext=BookmarkLogContext(
            domainName: "BookmarkServices",
            metadata: LogMetadataDTOCollection()
              .withSensitive(key: "path", value: filePathDTO.path)
              .withPublic(key: "isStale", value: String(isStale)),
            operation: "resolveBookmarkToFilePath",
            identifier: storageIdentifier,
            status: "success"
          )

          await bookmarkLogger.info(
            "Security bookmark resolved successfully",
            context: successContext
          )
          return .success((filePathDTO, isStale))

        } catch {
          let errorContext=BookmarkLogContext(
            domainName: "BookmarkServices",
            metadata: LogMetadataDTOCollection(),
            operation: "resolveBookmarkToFilePath",
            identifier: storageIdentifier,
            status: "error"
          )

          await bookmarkLogger.logError(error, context: errorContext)
          return .failure(
            .invalidBookmark("Failed to resolve bookmark data: \(error.localizedDescription)")
          )
        }

      case let .failure(error):
        let errorContext=BookmarkLogContext(
          domainName: "BookmarkServices",
          metadata: LogMetadataDTOCollection(),
          operation: "resolveBookmarkToFilePath",
          identifier: storageIdentifier,
          status: "error"
        )

        await bookmarkLogger.logError(error, context: errorContext)
        return .failure(
          .invalidBookmark("Failed to retrieve bookmark data: \(error.localizedDescription)")
        )
    }
  }

  /**
   Validates a security bookmark.

   This method checks if a bookmark is still valid and can be used to access
   the file or directory it points to. If the bookmark is stale and the
   recreateIfStale flag is true, it will attempt to recreate the bookmark.

   - Parameters:
     - storageIdentifier: The identifier the bookmark was stored under
     - recreateIfStale: Whether to recreate the bookmark if it's stale
   - Returns: Result with validation result or error
   */
  public func validateBookmark(
    withIdentifier storageIdentifier: String,
    recreateIfStale: Bool
  ) async -> Result<BookmarkValidationResultDTO, UmbraErrors.Security.Bookmark> {
    let context=BookmarkLogContext(
      domainName: "BookmarkServices",
      metadata: LogMetadataDTOCollection(),
      operation: "validateBookmark",
      identifier: storageIdentifier,
      status: "started"
    )

    await bookmarkLogger.info("Validating security bookmark", context: context)

    // First, try to resolve the bookmark to get the URL
    let resolveResult=await resolveBookmark(withIdentifier: storageIdentifier)

    switch resolveResult {
      case let .success(resolvedData):
        let (url, isStale)=resolvedData

        // Check if the file or directory exists
        let fileManager=FileManager.default
        let exists=fileManager.fileExists(atPath: url.path)

        // If the bookmark is stale and we're asked to recreate it, do so
        var updatedBookmarkData: [UInt8]?

        if isStale && recreateIfStale {
          // Try to recreate the bookmark
          // Convert URL to FilePathDTO
          let filePathDTO=FilePathDTO(path: url.path)
          let recreateResult=await createBookmarkData(for: filePathDTO, options: nil)

          switch recreateResult {
            case let .success(newBookmarkData):
              // Convert Data to [UInt8]
              let bookmarkBytes=[UInt8](newBookmarkData)

              // Store the new bookmark data
              let storeResult=await secureStorage.storeData(
                bookmarkBytes,
                withIdentifier: storageIdentifier
              )

              if case .success=storeResult {
                // Store the converted bytes for the result
                updatedBookmarkData=bookmarkBytes

                let successContext=BookmarkLogContext(
                  domainName: "BookmarkServices",
                  metadata: LogMetadataDTOCollection(),
                  operation: "validateBookmark",
                  identifier: storageIdentifier,
                  status: "recreated"
                )
                await bookmarkLogger.info(
                  "Successfully recreated stale bookmark",
                  context: successContext
                )
              } else {
                let failureContext=BookmarkLogContext(
                  domainName: "BookmarkServices",
                  metadata: LogMetadataDTOCollection(),
                  operation: "validateBookmark",
                  identifier: storageIdentifier,
                  status: "recreate_failed"
                )
                await bookmarkLogger.warning(
                  "Failed to store recreated bookmark",
                  context: failureContext
                )
              }

            case let .failure(error):
              let failureContext=BookmarkLogContext(
                domainName: "BookmarkServices",
                metadata: LogMetadataDTOCollection(),
                operation: "validateBookmark",
                identifier: storageIdentifier,
                status: "recreate_failed"
              )
              await bookmarkLogger.warning(
                "Failed to recreate stale bookmark: \(error.localizedDescription)",
                context: failureContext
              )
          }
        }

        // Create the validation result
        let validationResult=BookmarkValidationResultDTO(
          isValid: exists,
          isStale: isStale,
          updatedBookmark: updatedBookmarkData,
          url: url
        )

        let completedContext=BookmarkLogContext(
          domainName: "BookmarkServices",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "isValid", value: String(exists))
            .withPublic(key: "isStale", value: String(isStale))
            .withPublic(key: "wasRecreated", value: String(updatedBookmarkData != nil)),
          operation: "validateBookmark",
          identifier: storageIdentifier,
          status: "completed"
        )

        await bookmarkLogger.info("Bookmark validation completed", context: completedContext)

        return .success(validationResult)

      case let .failure(error):
        let failureContext=BookmarkLogContext(
          domainName: "BookmarkServices",
          metadata: LogMetadataDTOCollection(),
          operation: "validateBookmark",
          identifier: storageIdentifier,
          status: "failed"
        )

        await bookmarkLogger.logError(error, context: failureContext)

        return .failure(error)
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
    // Convert URL to FilePathDTO
    let filePathDTO=FilePathDTO(path: url.path)

    return await startAccessing(filePathDTO)
  }

  /**
   Start accessing a security-scoped resource.

   This must be called before attempting to access the resource, and should
   be balanced with a call to stopAccessing when done.

   - Parameter path: The file path to start accessing
   - Returns: A Result containing either the access count or a domain-specific error
   */
  public func startAccessing(_ path: FilePathDTO) async
  -> Result<Bool, UmbraErrors.Security.Bookmark> {
    let context=BookmarkLogContext(
      domainName: "BookmarkServices",
      metadata: LogMetadataDTOCollection().withSensitive(key: "path", value: path.path),
      operation: "startAccessing",
      status: "started"
    )

    await bookmarkLogger.info("Starting access to security-scoped resource", context: context)

    // Try to start accessing the security-scoped resource
    do {
      let accessGranted=try await fileSystemService.startAccessingSecurityScopedResource(at: path)

      if !accessGranted {
        let errorContext=BookmarkLogContext(
          domainName: "BookmarkServices",
          metadata: LogMetadataDTOCollection().withSensitive(key: "path", value: path.path),
          operation: "startAccessing",
          status: "error"
        )

        let error=UmbraErrors.Security.Bookmark
          .accessDenied("Failed to start accessing security-scoped resource")

        await bookmarkLogger.logError(error, context: errorContext)
        return .failure(error)
      }

      // Update the access count
      let currentCount=activeResources[path] ?? 0
      let newCount=currentCount + 1
      activeResources[path]=newCount

      let successContext=BookmarkLogContext(
        domainName: "BookmarkServices",
        metadata: LogMetadataDTOCollection()
          .withSensitive(key: "path", value: path.path)
          .withPublic(key: "accessCount", value: String(newCount)),
        operation: "startAccessing",
        status: "success"
      )

      await bookmarkLogger.info(
        "Started accessing security-scoped resource",
        context: successContext
      )
      return .success(true)
    } catch {
      let errorContext=BookmarkLogContext(
        domainName: "BookmarkServices",
        metadata: LogMetadataDTOCollection().withSensitive(key: "path", value: path.path),
        operation: "startAccessing",
        status: "error"
      )

      let bookmarkError=UmbraErrors.Security.Bookmark
        .accessDenied(
          "Failed to start accessing security-scoped resource: \(error.localizedDescription)"
        )

      await bookmarkLogger.logError(bookmarkError, context: errorContext)
      return .failure(bookmarkError)
    }
  }

  /**
   Stop accessing a security-scoped resource.

   This should be called when done with the resource, to balance a previous
   call to startAccessing.

   - Parameter url: The URL to stop accessing
   - Returns: A Result containing either the remaining access count or a domain-specific error
   */
  public func stopAccessing(_ url: URL) async -> Result<Int, UmbraErrors.Security.Bookmark> {
    // Convert URL to FilePathDTO
    let filePathDTO=FilePathDTO(path: url.path)

    return await stopAccessing(filePathDTO)
  }

  /**
   Stop accessing a security-scoped resource.

   This should be called when done with the resource, to balance a previous
   call to startAccessing.

   - Parameter path: The file path to stop accessing
   - Returns: A Result containing either the remaining access count or a domain-specific error
   */
  public func stopAccessing(_ path: FilePathDTO) async
  -> Result<Int, UmbraErrors.Security.Bookmark> {
    let context=BookmarkLogContext(
      domainName: "BookmarkServices",
      metadata: LogMetadataDTOCollection().withSensitive(key: "path", value: path.path),
      operation: "stopAccessing",
      status: "started"
    )

    await bookmarkLogger.info("Stopping access to security-scoped resource", context: context)

    // Get the current access count for this path
    guard let currentCount=activeResources[path], currentCount > 0 else {
      let warningContext=BookmarkLogContext(
        domainName: "BookmarkServices",
        metadata: LogMetadataDTOCollection().withSensitive(key: "path", value: path.path),
        operation: "stopAccessing",
        status: "warning"
      )

      await bookmarkLogger.warning("No active accesses found for path", context: warningContext)
      return .success(0)
    }

    // Update the access count
    let newCount=currentCount - 1
    if newCount > 0 {
      activeResources[path]=newCount
    } else {
      // If access count is now zero, remove from tracking and stop accessing
      activeResources.removeValue(forKey: path)

      // Use our file system service to stop accessing
      await fileSystemService.stopAccessingSecurityScopedResource(at: path)
    }

    let successContext=BookmarkLogContext(
      domainName: "BookmarkServices",
      metadata: LogMetadataDTOCollection()
        .withSensitive(key: "path", value: path.path)
        .withPublic(key: "accessCount", value: String(newCount)),
      operation: "stopAccessing",
      status: "success"
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
    let context=BookmarkLogContext(
      domainName: "BookmarkServices",
      metadata: LogMetadataDTOCollection(),
      operation: "removeBookmark",
      identifier: storageIdentifier,
      status: "started"
    )

    await bookmarkLogger.info("Removing security bookmark", context: context)

    let removeResult=await secureStorage.deleteData(
      withIdentifier: storageIdentifier
    )

    switch removeResult {
      case .success:
        let successContext=BookmarkLogContext(
          domainName: "BookmarkServices",
          metadata: LogMetadataDTOCollection(),
          operation: "removeBookmark",
          identifier: storageIdentifier,
          status: "success"
        )

        await bookmarkLogger.info("Security bookmark removed successfully", context: successContext)
        return .success(())

      case let .failure(error):
        let errorContext=BookmarkLogContext(
          domainName: "BookmarkServices",
          metadata: LogMetadataDTOCollection(),
          operation: "removeBookmark",
          identifier: storageIdentifier,
          status: "error"
        )

        await bookmarkLogger.logError(error, context: errorContext)
        return .failure(
          .operationFailed("Failed to remove bookmark: \(error.localizedDescription)")
        )
    }
  }

  /**
   Checks if all security-scoped resources have been properly released.

   This helps detect resource leaks where security-scoped resources
   are being accessed but not released.

   - Returns: True if all resources have been released, false otherwise
   */
  public func verifyAllResourcesReleased() async -> Bool {
    let context=BookmarkLogContext(
      domainName: "BookmarkServices",
      metadata: LogMetadataDTOCollection().withPublic(
        key: "activeCount",
        value: String(activeResources.count)
      ),
      operation: "verifyAllResourcesReleased",
      status: "started"
    )

    await bookmarkLogger.info(
      "Verifying all security-scoped resources are released",
      context: context
    )

    let resourceCount=activeResources.count

    let successContext=BookmarkLogContext(
      domainName: "BookmarkServices",
      metadata: LogMetadataDTOCollection().withPublic(
        key: "activeCount",
        value: String(resourceCount)
      ),
      operation: "verifyAllResourcesReleased",
      status: "success"
    )

    await bookmarkLogger.info("Verified resource release status", context: successContext)
    return resourceCount == 0
  }

  /**
   Forces release of all security-scoped resources.

   This method should only be used during application termination
   or error recovery to ensure all resources are properly released.

   - Returns: The number of resources that were forcibly released
   */
  public func forceReleaseAllResources() async -> Int {
    let context=BookmarkLogContext(
      domainName: "BookmarkServices",
      metadata: LogMetadataDTOCollection().withPublic(
        key: "activeCount",
        value: String(activeResources.count)
      ),
      operation: "forceReleaseAllResources",
      status: "started"
    )

    await bookmarkLogger.info("Forcibly releasing all security-scoped resources", context: context)

    let resourceCount=activeResources.count

    // Stop accessing all resources
    for path in activeResources.keys {
      await fileSystemService.stopAccessingSecurityScopedResource(at: path)
    }

    // Clear the tracking dictionary
    activeResources.removeAll()

    let successContext=BookmarkLogContext(
      domainName: "BookmarkServices",
      metadata: LogMetadataDTOCollection().withPublic(
        key: "releasedCount",
        value: String(resourceCount)
      ),
      operation: "forceReleaseAllResources",
      status: "success"
    )

    await bookmarkLogger.info("Forcibly released all resources", context: successContext)
    return resourceCount
  }
}
