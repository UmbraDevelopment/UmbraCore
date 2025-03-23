import CoreDTOs
import ErrorHandling
import ErrorHandlingDomains
import Foundation
import SecurityBridgeTypes
import UmbraCoreTypes

/// Protocol for bookmark service DTOs, providing Foundation-independent bookmark operations
public protocol BookmarkServiceDTOProtocol {
  /// Create a bookmark for a file path
  /// - Parameter path: The path to create a bookmark for
  /// - Returns: A result containing the bookmark or an error
  func createBookmark(for path: FilePathDTO) -> OperationResultDTO<BookmarkDTO>

  /// Resolve a bookmark to a file path
  /// - Parameter bookmark: The bookmark to resolve
  /// - Returns: A result containing the resolved path and whether the bookmark was stale
  func resolveBookmark(_ bookmark: BookmarkDTO) -> OperationResultDTO<FileSystemResolvedBookmarkDTO>

  /// Start accessing the resource at the given path
  /// - Parameter path: The path to the resource
  /// - Returns: Result indicating success or failure
  func startAccessing(_ path: FilePathDTO) -> OperationResultDTO<Bool>

  /// Stop accessing the resource at the given path
  /// - Parameter path: The path to the resource
  /// - Returns: Result indicating success or failure
  func stopAccessing(_ path: FilePathDTO) -> OperationResultDTO<Bool>
}

/// Bookmark service protocol for the security layer
public protocol BookmarkServiceType {
  /// Create a bookmark for a URL
  /// - Parameter url: The URL to create a bookmark for
  /// - Throws: An error if the bookmark creation fails
  /// - Returns: Data representation of the bookmark
  func createBookmark(for url: URL) throws -> Data

  /// Resolve a bookmark to a URL
  /// - Parameter bookmarkData: The bookmark data to resolve
  /// - Throws: An error if the bookmark resolution fails
  /// - Returns: The resolved URL and whether the bookmark was stale
  func resolveBookmark(_ bookmarkData: Data) throws -> (URL, Bool)

  /// Start accessing the security-scoped resource at the given URL
  /// - Parameter url: The security-scoped URL
  /// - Throws: An error if access cannot be started
  /// - Returns: Whether access was successfully started
  func startAccessing(_ url: URL) throws -> Bool

  /// Stop accessing the security-scoped resource at the given URL
  /// - Parameter url: The security-scoped URL
  /// - Throws: An error if access cannot be stopped
  func stopAccessing(_ url: URL) throws
}

/// Custom struct for resolved bookmark result that conforms to Equatable and Sendable
public struct FileSystemResolvedBookmarkDTO: Equatable, Sendable {
  public let path: FilePathDTO
  public let wasStale: Bool

  public init(path: FilePathDTO, wasStale: Bool) {
    self.path=path
    self.wasStale=wasStale
  }
}

/// Adapter for BookmarkService that provides a Foundation-independent interface
public final class BookmarkServiceDTOAdapter: BookmarkServiceDTOProtocol {
  // MARK: - Properties

  /// The underlying bookmark service
  private let bookmarkService: BookmarkServiceType

  // MARK: - Initialization

  /// Initialize with a bookmark service
  /// - Parameter bookmarkService: The bookmark service to adapt
  public init(bookmarkService: BookmarkServiceType) {
    self.bookmarkService=bookmarkService
  }

  // MARK: - BookmarkServiceDTOProtocol Implementation

  /// Create a bookmark for a file path
  /// - Parameter path: The path to create a bookmark for
  /// - Returns: A result containing the bookmark or an error
  public func createBookmark(for path: FilePathDTO) -> OperationResultDTO<BookmarkDTO> {
    do {
      // Convert the DTO path to a URL
      guard let url=URL(string: path.path) else {
        let errorDTO=SecurityErrorDTO.invalidPath(
          path: path.path
        )
        return .failure(
          errorCode: Int32(errorDTO.code),
          errorMessage: errorDTO.message,
          details: errorDTO.details
        )
      }

      // Create the bookmark
      let bookmarkData=try bookmarkService.createBookmark(for: url)

      // Create the BookmarkDTO
      let bookmarkDTO=BookmarkDTO(
        data: [UInt8](bookmarkData),
        displayPath: path.path,
        hasSecurityScope: true
      )

      return .success(bookmarkDTO)
    } catch let error as UmbraErrors.GeneralSecurity.Core {
      let errorDTO=mapCoreError(error)
      return .failure(
        errorCode: Int32(errorDTO.code),
        errorMessage: errorDTO.message,
        details: errorDTO.details
      )
    } catch {
      let errorDTO=SecurityErrorDTO.bookmarkCreationFailed(
        path: path.path,
        details: ["error": error.localizedDescription]
      )
      return .failure(
        errorCode: Int32(errorDTO.code),
        errorMessage: errorDTO.message,
        details: errorDTO.details
      )
    }
  }

  /// Resolve a bookmark to a file path
  /// - Parameter bookmark: The bookmark to resolve
  /// - Returns: A result containing the resolved path and whether the bookmark was stale
  public func resolveBookmark(_ bookmark: BookmarkDTO)
  -> OperationResultDTO<FileSystemResolvedBookmarkDTO> {
    do {
      // Resolve the bookmark
      let (url, wasStale)=try bookmarkService.resolveBookmark(Data(bookmark.data))

      // Create a FilePathDTO from the resolved URL
      let pathDTO=FilePathDTO(
        path: url.path,
        fileName: url.lastPathComponent,
        directoryPath: url.deletingLastPathComponent().path,
        resourceType: determineResourceType(url),
        isAbsolute: true
      )

      // Create a FileSystemResolvedBookmarkDTO
      let resolvedBookmarkDTO=FileSystemResolvedBookmarkDTO(path: pathDTO, wasStale: wasStale)

      return .success(resolvedBookmarkDTO)
    } catch let error as UmbraErrors.GeneralSecurity.Core {
      let errorDTO=mapCoreError(error)
      return .failure(
        errorCode: Int32(errorDTO.code),
        errorMessage: errorDTO.message,
        details: errorDTO.details
      )
    } catch {
      let errorDTO=SecurityErrorDTO.bookmarkResolutionFailed(
        details: ["error": error.localizedDescription]
      )
      return .failure(
        errorCode: Int32(errorDTO.code),
        errorMessage: errorDTO.message,
        details: errorDTO.details
      )
    }
  }

  /// Start accessing the resource at the given path
  /// - Parameter path: The path to the resource
  /// - Returns: Result indicating success or failure
  public func startAccessing(_ path: FilePathDTO) -> OperationResultDTO<Bool> {
    do {
      // Convert the DTO path to a URL
      guard let url=URL(string: path.path) else {
        let errorDTO=SecurityErrorDTO.invalidPath(
          path: path.path
        )
        return .failure(
          errorCode: Int32(errorDTO.code),
          errorMessage: errorDTO.message,
          details: errorDTO.details
        )
      }

      // Start accessing the resource
      let success=try bookmarkService.startAccessing(url)
      return .success(success)
    } catch let error as UmbraErrors.GeneralSecurity.Core {
      let errorDTO=mapCoreError(error)
      return .failure(
        errorCode: Int32(errorDTO.code),
        errorMessage: errorDTO.message,
        details: errorDTO.details
      )
    } catch {
      let errorDTO=SecurityErrorDTO.accessError(
        message: "Failed to start accessing resource at \(path.path)",
        details: ["error": error.localizedDescription]
      )
      return .failure(
        errorCode: Int32(errorDTO.code),
        errorMessage: errorDTO.message,
        details: errorDTO.details
      )
    }
  }

  /// Stop accessing the resource at the given path
  /// - Parameter path: The path to the resource
  /// - Returns: Result indicating success or failure
  public func stopAccessing(_ path: FilePathDTO) -> OperationResultDTO<Bool> {
    do {
      // Convert the DTO path to a URL
      guard let url=URL(string: path.path) else {
        let errorDTO=SecurityErrorDTO.invalidPath(
          path: path.path
        )
        return .failure(
          errorCode: Int32(errorDTO.code),
          errorMessage: errorDTO.message,
          details: errorDTO.details
        )
      }

      // Stop accessing the resource
      try bookmarkService.stopAccessing(url)
      return .success(true)
    } catch let error as UmbraErrors.GeneralSecurity.Core {
      let errorDTO=mapCoreError(error)
      return .failure(
        errorCode: Int32(errorDTO.code),
        errorMessage: errorDTO.message,
        details: errorDTO.details
      )
    } catch {
      let errorDTO=SecurityErrorDTO.accessError(
        message: "Failed to stop accessing resource at \(path.path)",
        details: ["error": error.localizedDescription]
      )
      return .failure(
        errorCode: Int32(errorDTO.code),
        errorMessage: errorDTO.message,
        details: errorDTO.details
      )
    }
  }

  // MARK: - Helper Methods

  /// Determine the resource type of a URL
  /// - Parameter url: The URL to check
  /// - Returns: The resource type
  private func determineResourceType(_ url: URL) -> FilePathDTO.ResourceType {
    var isDirectory: ObjCBool=false
    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
      if isDirectory.boolValue {
        return .directory
      } else {
        // Check if it's a symbolic link
        do {
          let attributes=try FileManager.default.attributesOfItem(atPath: url.path)
          if attributes[.type] as? FileAttributeType == .typeSymbolicLink {
            return .symbolicLink
          }
        } catch {
          // Ignore errors
        }
        return .file
      }
    }
    return .unknown
  }

  /// Maps a core security error to a security error DTO
  /// - Parameter error: The core error to map
  /// - Returns: A security error DTO
  private func mapCoreError(_ error: UmbraErrors.GeneralSecurity.Core) -> SecurityErrorDTO {
    switch error {
      case let .encryptionFailed(reason):
        return SecurityErrorDTO(
          code: 1001,
          domain: "security.encryption",
          message: "Encryption failed",
          details: ["reason": reason]
        )
      case let .decryptionFailed(reason):
        return SecurityErrorDTO(
          code: 1002,
          domain: "security.encryption",
          message: "Decryption failed",
          details: ["reason": reason]
        )
      case let .keyGenerationFailed(reason):
        return SecurityErrorDTO(
          code: 1003,
          domain: "security.keys",
          message: "Key generation failed",
          details: ["reason": reason]
        )
      case let .invalidKey(reason):
        return SecurityErrorDTO(
          code: 1004,
          domain: "security.keys",
          message: "Invalid key",
          details: ["reason": reason]
        )
      case let .hashVerificationFailed(reason):
        return SecurityErrorDTO(
          code: 1005,
          domain: "security.hash",
          message: "Hash verification failed",
          details: ["reason": reason]
        )
      case let .randomGenerationFailed(reason):
        return SecurityErrorDTO(
          code: 1006,
          domain: "security.random",
          message: "Random generation failed",
          details: ["reason": reason]
        )
      case let .invalidInput(reason):
        return SecurityErrorDTO(
          code: 1007,
          domain: "security.input",
          message: "Invalid input",
          details: ["reason": reason]
        )
      case let .storageOperationFailed(reason):
        return SecurityErrorDTO(
          code: 1008,
          domain: "security.storage",
          message: "Storage operation failed",
          details: ["reason": reason]
        )
      case let .timeout(operation):
        return SecurityErrorDTO(
          code: 1009,
          domain: "security.timeout",
          message: "Security operation timed out",
          details: ["operation": operation]
        )
      case let .serviceError(code, reason):
        return SecurityErrorDTO(
          code: Int32(code),
          domain: "security.service",
          message: "Security service error",
          details: ["reason": reason]
        )
      case let .internalError(message):
        return SecurityErrorDTO(
          code: 1010,
          domain: "security.internal",
          message: "Internal security error",
          details: ["message": message]
        )
      case let .notImplemented(feature):
        return SecurityErrorDTO(
          code: 1011,
          domain: "security.feature",
          message: "Security feature not implemented",
          details: ["feature": feature]
        )
      @unknown default:
        return SecurityErrorDTO(
          code: 9999,
          domain: "security.unknown",
          message: "Unknown security error",
          details: ["description": error.localizedDescription]
        )
    }
  }
}

// MARK: - Factory Methods for SecurityErrorDTO

extension SecurityErrorDTO {
  /// Create an error for invalid path
  /// - Parameters:
  ///   - path: The invalid path
  ///   - details: Additional details
  /// - Returns: A security error DTO
  public static func invalidPath(
    path: String,
    details: [String: String]=[:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: 2001,
      domain: "security.bookmark",
      message: "Invalid path: \(path)",
      details: details
    )
  }

  /// Create an error for bookmark creation failure
  /// - Parameters:
  ///   - path: The path that failed
  ///   - details: Additional details
  /// - Returns: A security error DTO
  public static func bookmarkCreationFailed(
    path: String,
    details: [String: String]=[:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: 2002,
      domain: "security.bookmark",
      message: "Failed to create bookmark for path: \(path)",
      details: details
    )
  }

  /// Create an error for bookmark resolution failure
  /// - Parameters:
  ///   - details: Additional details
  /// - Returns: A security error DTO
  public static func bookmarkResolutionFailed(
    details: [String: String]=[:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: 2003,
      domain: "security.bookmark",
      message: "Failed to resolve bookmark",
      details: details
    )
  }

  /// Create an error for access failure
  /// - Parameters:
  ///   - message: The error message
  ///   - details: Additional details
  /// - Returns: A security error DTO
  public static func accessError(
    message: String,
    details: [String: String]=[:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: 2004,
      domain: "security.bookmark",
      message: message,
      details: details
    )
  }
}
