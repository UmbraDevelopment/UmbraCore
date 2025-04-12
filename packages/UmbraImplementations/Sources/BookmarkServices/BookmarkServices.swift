/**
 # BookmarkServices Module

 This module provides services for managing security-scoped bookmarks in sandboxed
 applications, following the Alpha Dot Five architecture principles with
 actor-based concurrency.

 Security-scoped bookmarks allow sandboxed applications to maintain access to files
 and directories that users have explicitly granted access to, even after the application
 restarts. This module provides a secure way to create, store, and use these bookmarks.

 ## Components

 - **SecurityBookmarkActor**: Actor-based implementation for bookmark management
   - Thread-safe operations through actor isolation
   - Proper error handling and logging
   - Access counting for security-scoped resources

 ## Usage

 ```swift
 // Create a bookmark service
 let secureStorage = await CryptoServiceRegistry.createService(
     type: .standard
 )
 let bookmarkService = SecurityBookmarkActor(logger: logger, secureStorage: secureStorage)

 // Create a bookmark for a user-selected file
 let createResult = await bookmarkService.createBookmark(for: fileURL, readOnly: false)

 // Later, resolve and access the bookmark
 let resolveResult = await bookmarkService.resolveBookmark(
     withIdentifier: bookmarkID,
     startAccess: true
 )
 ```
 */

// Export Foundation types needed by this module
@_exported import Foundation

// Export dependencies
@_exported import CoreDTOs
@_exported import DomainSecurityTypes
@_exported import ErrorCoreTypes
@_exported import LoggingInterfaces
@_exported import SecurityCoreInterfaces
