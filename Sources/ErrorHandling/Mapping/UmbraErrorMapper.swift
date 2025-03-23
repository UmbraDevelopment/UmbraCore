import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Application domain
  public static let application = "Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain = domain
    self.code = code
    self.description = description
  }
}

/// Central error mapper for the UmbraCore framework
///
/// This class provides a unified interface for mapping between different error types
/// across the UmbraCore framework.
public final class UmbraErrorMapper: @unchecked Sendable {
  /// Shared instance for convenient access
  @MainActor
  public static let shared = UmbraErrorMapper()

  /// Security error mapper instance
  private let securityMapper = SecurityErrorMapper()

  /// Private initialiser to enforce singleton pattern
  private init() {}

  // MARK: - Security Error Mapping

  /// Maps from UmbraErrors.GeneralSecurity.Core to SecurityError
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapSecurityError(_ error: UmbraErrors.GeneralSecurity.Core) -> ErrorHandlingTypes
  .SecurityError {
    securityMapper.mapError(error)
  }

  /// Maps from UmbraErrors.Security.Protocols to SecurityError
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapSecurityProtocolsError(
    _ error: UmbraErrors.Security
      .Protocols
  ) -> ErrorHandlingTypes.SecurityError {
    .domainProtocolError(error)
  }

  /// Maps from UmbraErrors.Security.XPC to SecurityError
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapSecurityXPCError(_ error: UmbraErrors.Security.XPC) -> ErrorHandlingTypes
  .SecurityError {
    .domainXPCError(error)
  }

  /// Maps from SecurityError to UmbraErrors.GeneralSecurity.Core
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapToSecurityCore(_ error: ErrorHandlingTypes.SecurityError) -> UmbraErrors
  .GeneralSecurity.Core {
    securityMapper.mapBtoA(error)
  }

  /// Maps any error to SecurityError if applicable
  /// - Parameter error: Any error
  /// - Returns: The mapped error if conversion is possible, nil otherwise
  public func mapToSecurityError(_ error: Error) -> ErrorHandlingTypes.SecurityError? {
    securityMapper.mapToSecurityError(error)
  }

  // MARK: - Storage Error Mapping

  /// Maps from UmbraErrors.Storage.Database to StorageError
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapDatabaseStorageError(_ error: UmbraErrors.Storage.Database) -> ErrorHandlingTypes
  .StorageError {
    switch error {
      case let .queryFailed(reason):
        return .queryFailed(reason: reason)
      case let .connectionFailed(reason):
        return .internalError(reason: "Connection failed: \(reason)")
      case let .schemaIncompatible(expected, found):
        return .invalidFormat(reason: "Schema incompatible: expected \(expected), found \(found)")
      case let .migrationFailed(reason):
        return .internalError(reason: "Migration failed: \(reason)")
      case let .transactionFailed(reason):
        return .transactionFailed(reason: reason)
      case let .constraintViolation(constraint, reason):
        return .internalError(reason: "Constraint violation \(constraint): \(reason)")
      case let .databaseLocked(reason):
        return .internalError(reason: "Database locked: \(reason)")
      case let .internalError(reason):
        return .internalError(reason: reason)
      @unknown default:
        return .unknown(reason: "Unknown database error")
    }
  }

  /// Maps from UmbraErrors.Storage.FileSystem to StorageError
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapFileSystemStorageError(
    _ error: UmbraErrors.Storage
      .FileSystem
  ) -> ErrorHandlingTypes.StorageError {
    switch error {
      case let .fileNotFound(path):
        return .resourceNotFound(path: path)
      case let .directoryNotFound(path):
        return .resourceNotFound(path: path)
      case let .directoryCreationFailed(path, reason):
        return .writeFailed(reason: "Directory creation failed at \(path): \(reason)")
      case let .renameFailed(source, destination, reason):
        return .internalError(reason: "Rename failed from \(source) to \(destination): \(reason)")
      case let .copyFailed(source, destination, reason):
        return .copyFailed(source: source, destination: destination, reason: reason)
      case let .permissionDenied(path):
        return .accessDenied(reason: "Permission denied for \(path)")
      case let .invalidPath(path):
        return .invalidFormat(reason: "Invalid path: \(path)")
      case let .readOnlyFileSystem(path):
        return .accessDenied(reason: "Filesystem is read-only at \(path)")
      case let .fileInUse(path):
        return .internalError(reason: "File in use: \(path)")
      case let .unsupportedOperation(operation, filesystem):
        return .internalError(
          reason: "Unsupported operation \(operation) on filesystem \(filesystem)"
        )
      case .filesystemFull:
        return .insufficientSpace(required: 1, available: 0)
      case let .internalError(reason):
        return .internalError(reason: reason)
      @unknown default:
        return .unknown(reason: "Unknown filesystem error")
    }
  }

  // MARK: - Network Error Mapping

  /// Maps from UmbraErrors.Network.Core to NetworkError
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapNetworkError(_ error: UmbraErrors.Network.Core) -> ErrorHandlingTypes
  .NetworkError {
    // Use string descriptions to avoid pattern matching errors with non-existent enum members
    let errorDescription = String(describing: error)

    if errorDescription.contains("connectionFailed") {
      return .connectionFailed(reason: "Connection failed: \(errorDescription)")
    } else if errorDescription.contains("hostUnreachable") {
      return .connectionFailed(reason: "Host unreachable: \(errorDescription)")
    } else if errorDescription.contains("timeout") {
      return .timeout(operation: "Network operation", durationMs: 30_000)
    } else if errorDescription.contains("interrupted") {
      return .interrupted(reason: "Connection interrupted: \(errorDescription)")
    } else if errorDescription.contains("invalidRequest") {
      return .invalidRequest(reason: "Invalid request: \(errorDescription)")
    } else if errorDescription.contains("serviceUnavailable") {
      return .serviceUnavailable(service: "Unknown service", reason: errorDescription)
    } else if errorDescription.contains("certificate") {
      return .certificateError(reason: "Certificate error: \(errorDescription)")
    } else {
      return .internalError(reason: "Network error: \(errorDescription)")
    }
  }

  /// Maps NetworkError to UmbraErrors.Network.Core
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapToNetworkCore(_ error: ErrorHandlingTypes.NetworkError) -> Error {
    // Return a generic error to avoid issues with UmbraErrors.Network.Core members
    let description: String

    // Simplify the conditional statements by using a direct string description
    let errorDescription = String(describing: error)

    if errorDescription.contains("connectionFailed") {
      description = "Connection failed: \(errorDescription)"
    } else if errorDescription.contains("timeout") {
      description = "Operation timed out: \(errorDescription)"
    } else if errorDescription.contains("interrupted") {
      description = "Connection interrupted: \(errorDescription)"
    } else if errorDescription.contains("invalidRequest") {
      description = "Invalid request: \(errorDescription)"
    } else if errorDescription.contains("requestRejected") {
      description = "Request rejected: \(errorDescription)"
    } else if errorDescription.contains("invalidResponse") {
      description = "Invalid response: \(errorDescription)"
    } else if errorDescription.contains("parsingFailed") {
      description = "Parsing failed: \(errorDescription)"
    } else if errorDescription.contains("certificateError") {
      description = "Certificate error: \(errorDescription)"
    } else if errorDescription.contains("serviceUnavailable") {
      description = "Service unavailable: \(errorDescription)"
    } else if errorDescription.contains("requestTooLarge") {
      description = "Request too large: \(errorDescription)"
    } else if errorDescription.contains("responseTooLarge") {
      description = "Response too large: \(errorDescription)"
    } else if errorDescription.contains("rateLimitExceeded") {
      description = "Rate limit exceeded: \(errorDescription)"
    } else if errorDescription.contains("dataCorruption") {
      description = "Data corruption: \(errorDescription)"
    } else if errorDescription.contains("untrustedHost") {
      description = "Untrusted host: \(errorDescription)"
    } else if errorDescription.contains("internalError") {
      description = "Internal error: \(errorDescription)"
    } else {
      description = "Unknown network error: \(errorDescription)"
    }

    return NSError(
      domain: "UmbraCore.NetworkError.Core",
      code: 0,
      userInfo: [NSLocalizedDescriptionKey: description]
    )
  }

  /// Maps from NetworkError to UmbraErrors.Network.Base
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapNetworkBaseError(_ error: ErrorHandlingTypes.NetworkError) -> Error {
    // Return a generic error to avoid issues with UmbraErrors.Network.Base members
    let description = String(describing: error)
    return NSError(
      domain: "UmbraCore.NetworkError.Base",
      code: 0,
      userInfo: [NSLocalizedDescriptionKey: "Network error: \(description)"]
    )
  }

  // MARK: - Network HTTP Error Mapping

  /// Maps from UmbraErrors.Network.HTTP to NetworkError
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapHTTPError(_ error: UmbraErrors.Network.HTTP) -> ErrorHandlingTypes.NetworkError {
    // Convert HTTP domain errors to network errors using string descriptions
    let errorDescription = String(describing: error)

    if errorDescription.contains("badRequest") {
      return .invalidRequest(reason: "Bad request: \(errorDescription)")
    } else if errorDescription.contains("unauthorised") {
      return .requestRejected(code: 401, reason: "Unauthorised: \(errorDescription)")
    } else if errorDescription.contains("forbidden") {
      return .requestRejected(code: 403, reason: "Forbidden: \(errorDescription)")
    } else if errorDescription.contains("notFound") {
      return .requestRejected(code: 404, reason: "Not found: \(errorDescription)")
    } else if errorDescription.contains("timeout") || errorDescription.contains("requestTimeout") {
      return .timeout(operation: "HTTP request", durationMs: 30_000)
    } else {
      return .invalidRequest(reason: "HTTP error: \(errorDescription)")
    }
  }

  /// Maps from NetworkError to UmbraErrors.Network.HTTP
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapToHTTPError(_ error: ErrorHandlingTypes.NetworkError) -> Error {
    // Return a generic error since we're having issues with HTTP error types
    let description: String
    let errorDescription = String(describing: error)

    // Handle all possible NetworkError cases
    if errorDescription.contains("connectionFailed") {
      description = "Connection failed: \(errorDescription)"
    } else if errorDescription.contains("timeout") {
      description = "Timeout: \(errorDescription)"
    } else if errorDescription.contains("interrupted") {
      description = "Connection interrupted: \(errorDescription)"
    } else if errorDescription.contains("invalidRequest") {
      description = "Invalid request: \(errorDescription)"
    } else if errorDescription.contains("requestRejected") {
      description = "Request rejected: \(errorDescription)"
    } else if errorDescription.contains("invalidResponse") {
      description = "Invalid response: \(errorDescription)"
    } else if errorDescription.contains("parsingFailed") {
      description = "Parsing failed: \(errorDescription)"
    } else if errorDescription.contains("certificateError") {
      description = "Certificate error: \(errorDescription)"
    } else if errorDescription.contains("serviceUnavailable") {
      description = "Service unavailable: \(errorDescription)"
    } else if errorDescription.contains("requestTooLarge") {
      description = "Request too large: \(errorDescription)"
    } else if errorDescription.contains("responseTooLarge") {
      description = "Response too large: \(errorDescription)"
    } else if errorDescription.contains("rateLimitExceeded") {
      description = "Rate limit exceeded: \(errorDescription)"
    } else if errorDescription.contains("dataCorruption") {
      description = "Data corruption: \(errorDescription)"
    } else if errorDescription.contains("untrustedHost") {
      description = "Untrusted host: \(errorDescription)"
    } else if errorDescription.contains("internalError") {
      description = "Internal error: \(errorDescription)"
    } else {
      description = "Unknown network error: \(errorDescription)"
    }

    return NSError(
      domain: "UmbraCore.NetworkError.HTTP",
      code: 0,
      userInfo: [NSLocalizedDescriptionKey: description]
    )
  }

  // MARK: - Application Error Mapping

  /// Maps from UmbraErrors.Application.Core to ApplicationError
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapApplicationError(_ error: UmbraErrors.Application.Core) -> ErrorHandlingTypes
  .ApplicationError {
    let errorDescription = String(describing: error)

    if errorDescription.contains("configurationError") {
      return .invalidConfiguration(reason: "Configuration error: \(errorDescription)")
    } else if errorDescription.contains("initializationError") {
      return .initialisationFailed(reason: "Initialisation error: \(errorDescription)")
    } else if errorDescription.contains("resourceNotFound") {
      return .resourceMissing(resource: "Resource not found: \(errorDescription)")
    } else if errorDescription.contains("resourceAlreadyExists") {
      return .internalError(reason: "Resource already exists: \(errorDescription)")
    } else if errorDescription.contains("operationTimeout") {
      return .operationTimeout(operation: "Operation", durationMs: 0)
    } else if errorDescription.contains("invalidState") {
      return .invalidState(current: "Current state", expected: "Expected state")
    } else {
      return .internalError(reason: "Application error: \(errorDescription)")
    }
  }

  /// Maps from UmbraErrors.Application.UI to ApplicationError
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapUIApplicationError(_ error: UmbraErrors.Application.UI) -> ErrorHandlingTypes
  .ApplicationError {
    // Use string descriptions to avoid pattern matching errors
    let errorDescription = String(describing: error)

    if errorDescription.contains("viewNotFound") {
      return .resourceMissing(resource: "View not found: \(errorDescription)")
    } else if errorDescription.contains("invalidViewState") {
      return .invalidState(current: "Current state", expected: "Valid state")
    } else if errorDescription.contains("renderingError") {
      return .internalError(reason: "Rendering error: \(errorDescription)")
    } else if errorDescription.contains("inputValidationError") {
      // Changed to use internalError instead of invalidInput which doesn't exist
      return .internalError(reason: "Validation error: \(errorDescription)")
    } else {
      return .internalError(reason: "UI error: \(errorDescription)")
    }
  }

  /// Maps from UmbraErrors.Application.Lifecycle to ApplicationError
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapLifecycleApplicationError(
    _ error: UmbraErrors.Application
      .Lifecycle
  ) -> ErrorHandlingTypes.ApplicationError {
    let errorDescription = String(describing: error)
    return .internalError(reason: "Lifecycle error: \(errorDescription)")
  }

  // MARK: - Repository Error Mapping

  /// Maps from RepositoryError to Error
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapRepositoryError(_ error: UmbraErrors.Repository.Core) -> Error {
    // Simplify to a generic error since we're having issues with the RepositoryErrorType
    NSError(
      domain: "UmbraCore.RepositoryError",
      code: 0,
      userInfo: [
        NSLocalizedDescriptionKey: "Repository error: \(error)"
      ]
    )
  }

  // MARK: - Resource File Error Mapping

  /// Maps from UmbraErrors.Resource.File to a generic Error
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapResourceFileError(_ error: UmbraErrors.Resource.File) -> Error {
    // Simplify to return a basic error with description since ResourceErrorType doesn't exist
    NSError(
      domain: "UmbraCore.ResourceError",
      code: 0,
      userInfo: [NSLocalizedDescriptionKey: "Resource file error: \(error)"]
    )
  }

  // MARK: - Resource Pool Error Mapping

  /// Maps from UmbraErrors.Resource.Pool to a generic Error
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapResourcePoolError(_ error: UmbraErrors.Resource.Pool) -> Error {
    // Simplify to return a basic error with description since ResourceErrorType doesn't exist
    NSError(
      domain: "UmbraCore.ResourceError",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Resource pool error: \(error)"]
    )
  }

  // MARK: - Logging Error Mapping

  /// Maps from UmbraErrors.Logging.Core to Error
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapLoggingError(_ error: UmbraErrors.Logging.Core) -> Error {
    // Return a generic error since LoggingError doesn't exist in ErrorHandlingTypes
    NSError(
      domain: "UmbraCore.LoggingError",
      code: 0,
      userInfo: [
        NSLocalizedDescriptionKey: "Logging error: \(error)"
      ]
    )
  }

  /// Maps from UmbraErrors.Bookmark.Core to Error
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapBookmarkError(_ error: UmbraErrors.Bookmark.Core) -> Error {
    // Return a generic error since BookmarkError doesn't exist in ErrorHandlingTypes
    NSError(
      domain: "UmbraCore.BookmarkError",
      code: 0,
      userInfo: [
        NSLocalizedDescriptionKey: "Bookmark error: \(error)"
      ]
    )
  }

  /// Maps from UmbraErrors.XPC.Core to Error
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapXPCCoreError(_ error: UmbraErrors.XPC.Core) -> Error {
    // Return a generic error since XPCError doesn't exist in ErrorHandlingTypes
    NSError(
      domain: "UmbraCore.XPCError",
      code: 0,
      userInfo: [
        NSLocalizedDescriptionKey: "XPC error: \(error)"
      ]
    )
  }

  // MARK: - Crypto Error Mapping

  /// Maps from UmbraErrors.Crypto.Core to Error
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapCryptoError(_ error: UmbraErrors.Crypto.Core) -> Error {
    // Simplify to a generic error since we're having issues with the specific CryptoError type
    NSError(
      domain: "UmbraCore.CryptoError",
      code: 0,
      userInfo: [
        NSLocalizedDescriptionKey: "Crypto error: \(error)"
      ]
    )
  }

  /// Maps NetworkError to a security domain error
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapFromNetworkError(_ error: ErrorHandlingTypes.NetworkError) -> Error {
    // Return a generic error instead of a specific SecurityError type to avoid ambiguity
    let description = switch error {
      case let .connectionFailed(reason):
        "Connection failed: \(reason)"
      case let .serviceUnavailable(service, reason):
        "Service unavailable: \(service) - \(reason)"
      case let .timeout(operation, durationMs):
        "Timeout during \(operation) after \(durationMs)ms"
      case let .interrupted(reason):
        "Connection interrupted: \(reason)"
      case let .invalidRequest(reason):
        "Invalid request: \(reason)"
      case let .requestRejected(code, reason):
        "Request rejected (\(code)): \(reason)"
      case let .invalidResponse(reason):
        "Invalid response: \(reason)"
      case let .parsingFailed(reason):
        "Parsing failed: \(reason)"
      case let .certificateError(reason):
        "Certificate error: \(reason)"
      case let .requestTooLarge(sizeByte, maxSizeByte):
        "Request too large: \(sizeByte)/\(maxSizeByte) bytes"
      case let .rateLimitExceeded(limitPerHour, retryAfterMs):
        "Rate limit exceeded (\(limitPerHour)/hour). Retry after \(retryAfterMs)ms"
      case let .responseTooLarge(sizeByte, maxSizeByte):
        "Response too large: \(sizeByte)/\(maxSizeByte) bytes"
      case let .dataCorruption(reason):
        "Data corruption: \(reason)"
      case let .untrustedHost(hostname):
        "Untrusted host: \(hostname)"
      case let .internalError(reason):
        "Internal error: \(reason)"
      case let .unknown(reason):
        "Unknown network error: \(reason)"
      @unknown default:
        "Unknown network error"
    }

    return NSError(
      domain: "UmbraCore.SecurityError",
      code: 0,
      userInfo: [NSLocalizedDescriptionKey: description]
    )
  }
}
