import Foundation

import UmbraErrorsCore

/// Domain identifier for resource errors
public enum ResourceErrorDomain: String, CaseIterable, Sendable {
  /// Domain identifier
  public static let domain="Resource"

  // Error codes within the resource domain
  case notFoundError="NOT_FOUND"
  case notAvailableError="NOT_AVAILABLE"
  case limitExceededError="LIMIT_EXCEEDED"
  case alreadyExistsError="ALREADY_EXISTS"
  case invalidResourceError="INVALID_RESOURCE"
  case resourceExpiredError="RESOURCE_EXPIRED"
  case resourceInUseError="RESOURCE_IN_USE"
  case generalError="GENERAL_ERROR"
}

/// Enhanced implementation of a ResourceError
public struct ResourceError: UmbraError {
  /// Domain identifier
  public let domain: String=ResourceErrorDomain.domain

  /// The type of resource error
  public enum ErrorType: Sendable, Equatable {
    /// Resource not found
    case notFound
    /// Resource not available
    case notAvailable
    /// Resource limit exceeded
    case limitExceeded
    /// Resource already exists
    case alreadyExists
    /// Invalid resource
    case invalidResource
    /// Resource expired
    case resourceExpired
    /// Resource is in use
    case resourceInUse
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
  public let context: ErrorContext

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

  /// Creates a new ResourceError
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
    context: ErrorContext=ErrorContext(),
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
  public func with(context: ErrorContext) -> ResourceError {
    ResourceError(
      type: type,
      code: code,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }

  /// Creates a new instance of the error with a specified underlying error
  public func with(underlyingError: Error) -> ResourceError {
    ResourceError(
      type: type,
      code: code,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }

  /// Creates a new instance of the error with source information
  public func with(source: ErrorSource) -> ResourceError {
    ResourceError(
      type: type,
      code: code,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }
}

/// Convenience functions for creating specific resource errors
extension ResourceError {
  /// Creates a not found error
  /// - Parameters:
  ///   - resourceId: Resource identifier
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured ResourceError
  public static func notFound(
    resourceID: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> ResourceError {
    var contextDict=context
    contextDict["resourceId"]=resourceID
    contextDict["details"]="Resource with ID '\(resourceID)' not found"

    let errorContext=ErrorContext(contextDict)

    return ResourceError(
      type: .notFound,
      code: ResourceErrorDomain.notFoundError.rawValue,
      description: "Resource not found",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a not available error
  /// - Parameters:
  ///   - resourceId: Resource identifier
  ///   - reason: The reason the resource is not available
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured ResourceError
  public static func notAvailable(
    resourceID: String,
    reason: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> ResourceError {
    var contextDict=context
    contextDict["resourceId"]=resourceID
    contextDict["reason"]=reason
    contextDict["details"]="Resource '\(resourceID)' is not available: \(reason)"

    let errorContext=ErrorContext(contextDict)

    return ResourceError(
      type: .notAvailable,
      code: ResourceErrorDomain.notAvailableError.rawValue,
      description: "Resource not available",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a limit exceeded error
  /// - Parameters:
  ///   - resourceType: Type of resource
  ///   - limit: The limit that was exceeded
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured ResourceError
  public static func limitExceeded(
    resourceType: String,
    limit: Int,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> ResourceError {
    var contextDict=context
    contextDict["resourceType"]=resourceType
    contextDict["limit"]=limit
    contextDict["details"]="Resource limit exceeded for '\(resourceType)' (limit: \(limit))"

    let errorContext=ErrorContext(contextDict)

    return ResourceError(
      type: .limitExceeded,
      code: ResourceErrorDomain.limitExceededError.rawValue,
      description: "Resource limit exceeded",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates an already exists error
  /// - Parameters:
  ///   - resourceId: Resource identifier
  ///   - resourceType: Type of resource
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured ResourceError
  public static func alreadyExists(
    resourceID: String,
    resourceType: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> ResourceError {
    var contextDict=context
    contextDict["resourceId"]=resourceID
    contextDict["resourceType"]=resourceType
    contextDict["details"]="Resource '\(resourceID)' of type '\(resourceType)' already exists"

    let errorContext=ErrorContext(contextDict)

    return ResourceError(
      type: .alreadyExists,
      code: ResourceErrorDomain.alreadyExistsError.rawValue,
      description: "Resource already exists",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates an invalid resource error
  /// - Parameters:
  ///   - resourceId: Resource identifier
  ///   - reason: The reason the resource is invalid
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured ResourceError
  public static func invalidResource(
    resourceID: String,
    reason: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> ResourceError {
    var contextDict=context
    contextDict["resourceId"]=resourceID
    contextDict["reason"]=reason
    contextDict["details"]="Invalid resource '\(resourceID)': \(reason)"

    let errorContext=ErrorContext(contextDict)

    return ResourceError(
      type: .invalidResource,
      code: ResourceErrorDomain.invalidResourceError.rawValue,
      description: "Invalid resource",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a resource expired error
  /// - Parameters:
  ///   - resourceId: Resource identifier
  ///   - expiredAt: When the resource expired
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured ResourceError
  public static func resourceExpired(
    resourceID: String,
    expiredAt: Date,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> ResourceError {
    var contextDict=context
    contextDict["resourceId"]=resourceID
    contextDict["expiredAt"]=expiredAt

    let formatter=DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    let formattedDate=formatter.string(from: expiredAt)

    contextDict["details"]="Resource '\(resourceID)' expired at \(formattedDate)"

    let errorContext=ErrorContext(contextDict)

    return ResourceError(
      type: .resourceExpired,
      code: ResourceErrorDomain.resourceExpiredError.rawValue,
      description: "Resource expired",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a resource in use error
  /// - Parameters:
  ///   - resourceId: Resource identifier
  ///   - usedBy: Information about what is using the resource
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured ResourceError
  public static func resourceInUse(
    resourceID: String,
    usedBy: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> ResourceError {
    var contextDict=context
    contextDict["resourceId"]=resourceID
    contextDict["usedBy"]=usedBy
    contextDict["details"]="Resource '\(resourceID)' is in use by \(usedBy)"

    let errorContext=ErrorContext(contextDict)

    return ResourceError(
      type: .resourceInUse,
      code: ResourceErrorDomain.resourceInUseError.rawValue,
      description: "Resource in use",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a general resource error
  /// - Parameters:
  ///   - message: A descriptive message about the error
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured ResourceError
  public static func generalError(
    message: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> ResourceError {
    var contextDict=context
    contextDict["details"]=message

    let errorContext=ErrorContext(contextDict)

    return ResourceError(
      type: .general,
      code: ResourceErrorDomain.generalError.rawValue,
      description: "Resource error",
      context: errorContext,
      underlyingError: underlyingError
    )
  }
}
