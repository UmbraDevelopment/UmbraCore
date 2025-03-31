import Foundation

import UmbraErrorsCore

/// Domain identifier for repository errors
public enum RepositoryErrorDomain: String, CaseIterable, Sendable {
  /// Domain identifier
  public static let domain="Repository"

  // Error codes within the repository domain
  case notFoundError="NOT_FOUND"
  case accessDeniedError="ACCESS_DENIED"
  case lockedError="LOCKED"
  case corruptError="CORRUPT"
  case connectionError="CONNECTION_ERROR"
  case notAccessibleError="NOT_ACCESSIBLE"
  case timeoutError="TIMEOUT"
  case unsupportedOperationError="UNSUPPORTED_OPERATION"
  case generalError="GENERAL_ERROR"
}

/// Enhanced implementation of a RepositoryError
public struct RepositoryError: UmbraError {
  /// Domain identifier
  public let domain: String=RepositoryErrorDomain.domain

  /// The type of repository error
  public enum ErrorType: Sendable, Equatable {
    /// Repository not found
    case notFound
    /// Access denied to repository
    case accessDenied
    /// Repository is locked
    case locked
    /// Repository is corrupt
    case corrupt
    /// Connection error with repository
    case connectionError
    /// Repository not accessible
    case notAccessible
    /// Repository operation timed out
    case timeout
    /// Unsupported operation attempted
    case unsupportedOperation
    /// General error
    case general
  }

  /// The specific error type
  public let type: ErrorType

  /// Error code used for serialisation and identification
  public let code: String

  /// Human-readable description of the error
  public let description: String

  /// Additional context information about the error
  public let context: UmbraErrorsCore.ErrorContext

  /// The underlying error, if any
  public let underlyingError: Error?

  /// Source information about where the error occurred
  public let source: ErrorSource?

  /// Human-readable description of the error (UmbraError protocol requirement)
  public var errorDescription: String {
    if let details=context.typedValue(for: "details") as String?, !details.isEmpty {
      return "\(description): \(details)"
    }
    return description
  }

  /// Creates a formatted description of the error
  public var localizedDescription: String {
    if let details=context.typedValue(for: "details") as String?, !details.isEmpty {
      return "\(description): \(details)"
    }
    return description
  }

  /// Creates a new RepositoryError
  /// - Parameters:
  ///   - type: The error type
  ///   - code: The error code
  ///   - description: Human-readable description
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  ///   - source: Optional source information
  public init(
    type: ErrorType,
    code: String,
    description: String,
    context: UmbraErrorsCore.ErrorContext=UmbraErrorsCore.ErrorContext(),
    underlyingError: Error?=nil,
    source: ErrorSource?=nil
  ) {
    self.type=type
    self.code=code
    self.description=description
    self.context=context
    self.underlyingError=underlyingError
    self.source=source
  }

  /// Creates a new instance of the error with additional context
  public func with(context: UmbraErrorsCore.ErrorContext) -> RepositoryError {
    RepositoryError(
      type: type,
      code: code,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }

  /// Creates a new instance of the error with a specified underlying error
  public func with(underlyingError: Error) -> RepositoryError {
    RepositoryError(
      type: type,
      code: code,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }

  /// Creates a new instance of the error with source information
  public func with(source: ErrorSource) -> RepositoryError {
    RepositoryError(
      type: type,
      code: code,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }
}

/// Convenience functions for creating specific repository errors
extension RepositoryError {
  /// Creates a not found error
  /// - Parameters:
  ///   - repoId: Repository identifier
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured RepositoryError
  public static func notFound(
    repoID: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> RepositoryError {
    var contextDict=context
    contextDict["repoId"]=repoID
    contextDict["details"]="Repository with ID '\(repoID)' not found"

    let errorContext=UmbraErrorsCore.ErrorContext(contextDict)

    return RepositoryError(
      type: .notFound,
      code: RepositoryErrorDomain.notFoundError.rawValue,
      description: "Repository not found",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates an access denied error
  /// - Parameters:
  ///   - repoId: Repository identifier
  ///   - operation: Operation that was denied
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured RepositoryError
  public static func accessDenied(
    repoID: String,
    operation: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> RepositoryError {
    var contextDict=context
    contextDict["repoId"]=repoID
    contextDict["operation"]=operation
    contextDict["details"]="Access denied for operation '\(operation)' on repository '\(repoID)'"

    let errorContext=UmbraErrorsCore.ErrorContext(contextDict)

    return RepositoryError(
      type: .accessDenied,
      code: RepositoryErrorDomain.accessDeniedError.rawValue,
      description: "Repository access denied",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a locked repository error
  /// - Parameters:
  ///   - repoId: Repository identifier
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured RepositoryError
  public static func locked(
    repoID: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> RepositoryError {
    var contextDict=context
    contextDict["repoId"]=repoID
    contextDict["details"]="Repository '\(repoID)' is locked"

    let errorContext=UmbraErrorsCore.ErrorContext(contextDict)

    return RepositoryError(
      type: .locked,
      code: RepositoryErrorDomain.lockedError.rawValue,
      description: "Repository locked",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a corrupt repository error
  /// - Parameters:
  ///   - repoId: Repository identifier
  ///   - reason: The reason the repository is corrupt
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured RepositoryError
  public static func corrupt(
    repoID: String,
    reason: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> RepositoryError {
    var contextDict=context
    contextDict["repoId"]=repoID
    contextDict["reason"]=reason
    contextDict["details"]="Repository '\(repoID)' is corrupt: \(reason)"

    let errorContext=UmbraErrorsCore.ErrorContext(contextDict)

    return RepositoryError(
      type: .corrupt,
      code: RepositoryErrorDomain.corruptError.rawValue,
      description: "Repository corrupt",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a connection error
  /// - Parameters:
  ///   - repoId: Repository identifier
  ///   - reason: The reason for the connection failure
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured RepositoryError
  public static func connectionError(
    repoID: String,
    reason: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> RepositoryError {
    var contextDict=context
    contextDict["repoId"]=repoID
    contextDict["reason"]=reason
    contextDict["details"]="Connection error with repository '\(repoID)': \(reason)"

    let errorContext=UmbraErrorsCore.ErrorContext(contextDict)

    return RepositoryError(
      type: .connectionError,
      code: RepositoryErrorDomain.connectionError.rawValue,
      description: "Repository connection error",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a not accessible error
  /// - Parameters:
  ///   - repoId: Repository identifier
  ///   - reason: The reason the repository is not accessible
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured RepositoryError
  public static func notAccessible(
    repoID: String,
    reason: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> RepositoryError {
    var contextDict=context
    contextDict["repoId"]=repoID
    contextDict["reason"]=reason
    contextDict["details"]="Repository '\(repoID)' is not accessible: \(reason)"

    let errorContext=UmbraErrorsCore.ErrorContext(contextDict)

    return RepositoryError(
      type: .notAccessible,
      code: RepositoryErrorDomain.notAccessibleError.rawValue,
      description: "Repository not accessible",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a timeout error
  /// - Parameters:
  ///   - repoId: Repository identifier
  ///   - operation: The operation that timed out
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured RepositoryError
  public static func timeout(
    repoID: String,
    operation: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> RepositoryError {
    var contextDict=context
    contextDict["repoId"]=repoID
    contextDict["operation"]=operation
    contextDict["details"]="Operation '\(operation)' on repository '\(repoID)' timed out"

    let errorContext=UmbraErrorsCore.ErrorContext(contextDict)

    return RepositoryError(
      type: .timeout,
      code: RepositoryErrorDomain.timeoutError.rawValue,
      description: "Repository operation timeout",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates an unsupported operation error
  /// - Parameters:
  ///   - repoId: Repository identifier
  ///   - operation: The unsupported operation
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured RepositoryError
  public static func unsupportedOperation(
    repoID: String,
    operation: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> RepositoryError {
    var contextDict=context
    contextDict["repoId"]=repoID
    contextDict["operation"]=operation
    contextDict["details"]="Operation '\(operation)' is not supported on repository '\(repoID)'"

    let errorContext=UmbraErrorsCore.ErrorContext(contextDict)

    return RepositoryError(
      type: .unsupportedOperation,
      code: RepositoryErrorDomain.unsupportedOperationError.rawValue,
      description: "Unsupported repository operation",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a general repository error
  /// - Parameters:
  ///   - repoId: Repository identifier
  ///   - message: A descriptive message about the error
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured RepositoryError
  public static func generalError(
    repoID: String?,
    message: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> RepositoryError {
    var contextDict=context
    if let repoID {
      contextDict["repoId"]=repoID
    }
    contextDict["details"]=message

    let errorContext=UmbraErrorsCore.ErrorContext(contextDict)

    return RepositoryError(
      type: .general,
      code: RepositoryErrorDomain.generalError.rawValue,
      description: "Repository error",
      context: errorContext,
      underlyingError: underlyingError
    )
  }
}
