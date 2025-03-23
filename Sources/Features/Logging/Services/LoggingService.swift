import CoreErrors
import ErrorHandling
import ErrorHandlingDomains
import FeaturesLoggingErrors
import FeaturesLoggingModels
import FeaturesLoggingProtocols
import Foundation
import SecurityTypesProtocols
import UmbraCoreTypes
import XPCProtocolsCore

/// Service responsible for managing log files with security-scoped bookmarks
@available(macOS 14.0, *)
public actor LoggingService {
  /// Security provider for creating and resolving bookmarks
  private let securityProvider: DefaultSecurityProvider

  /// Path to the log file
  private var logFilePath: String?

  /// Initialises the logging service with a security provider
  /// - Parameter securityProvider: The security provider to use for bookmark operations
  public init(securityProvider: DefaultSecurityProvider) {
    self.securityProvider=securityProvider
  }

  /// Creates a log file bookmark for the provided path
  /// - Parameter path: Path to create a bookmark for
  /// - Returns: Result with bookmark data or error
  public func createLogBookmark(path: String) async
  -> Result<[UInt8], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let result=await securityProvider.createBookmark(for: path)

    switch result {
      case let .success(bookmark):
        return .success(bookmark.toArray())
      case let .failure(error):
        return .failure(mapError(error))
    }
  }

  /// Resolves a log file bookmark to a path
  /// - Parameter bookmarkData: The bookmark data to resolve
  /// - Returns: Result with resolved path or error
  public func resolveLogBookmark(_ bookmarkData: [UInt8]) async
  -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let secureBytes=SecureBytes(bytes: bookmarkData)
    let result=await securityProvider.resolveBookmark(secureBytes)

    switch result {
      case let .success(resolve):
        let (identifier, isStale)=resolve
        if isStale {
          // TODO: Handle stale bookmarks properly
          print("Warning: Bookmark is stale and may need to be recreated")
        }
        return .success(identifier)
      case let .failure(error):
        return .failure(mapError(error))
    }
  }

  /// Validates a log file bookmark
  /// - Parameter bookmarkData: The bookmark data to validate
  /// - Returns: Result with validation status or error
  public func validateLogBookmark(_ bookmarkData: [UInt8]) async
  -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let secureBytes=SecureBytes(bytes: bookmarkData)
    let result=await securityProvider.validateBookmark(secureBytes)

    switch result {
      case let .success(isValid):
        return .success(isValid)
      case let .failure(error):
        return .failure(mapError(error))
    }
  }

  /// Starts accessing a log file as a security-scoped resource
  /// - Parameter path: Path to the resource
  /// - Returns: Result with access status or error
  public func startAccessingLogResource(_ path: String) async
  -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let result=await securityProvider.startAccessingResource(identifier: path)

    switch result {
      case let .success(success):
        return .success(success)
      case let .failure(error):
        return .failure(mapError(error))
    }
  }

  /// Stops accessing a log file as a security-scoped resource
  /// - Parameter path: Path to the resource
  public func stopAccessingLogResource(_ path: String) async {
    await securityProvider.stopAccessingResource(identifier: path)
  }

  /// Stops accessing all security-scoped resources
  public func stopAccessingAllResources() async {
    await securityProvider.stopAccessingAllResources()
  }

  /// Maps security errors to XPC security errors
  /// - Returns: The mapped XPC security error
  private func mapError(
    _ error: ErrorHandlingDomains.UmbraErrors.GeneralSecurity
      .Core
  ) -> ErrorHandlingDomains.UmbraErrors.Security.Protocols {
    switch error {
      case let .storageOperationFailed(reason):
        .invalidInput("Bookmark error: \(reason)")
      case let .internalError(reason):
        .internalError(reason)
      case let .notImplemented(feature):
        .internalError("Feature not implemented: \(feature)")
      default:
        .internalError("Security error: \(error)")
    }
  }
}
