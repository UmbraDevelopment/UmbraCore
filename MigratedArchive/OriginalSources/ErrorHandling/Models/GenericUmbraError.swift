import Foundation
import Interfaces
import UmbraErrorsCore

/**
 * This file provides a legacy implementation of GenericUmbraError for backward compatibility
 * with existing code. New code should use UmbraErrorsCore.UmbraError directly.
 *
 * The implementation maps to UmbraErrorsCore types and provides conversion utilities
 * to integrate with the newer error structure.
 */

// MARK: - GenericUmbraError Implementation

/// A generic implementation of UmbraError for use in application code
public struct GenericUmbraError: Error, Sendable {
  /// Domain identifier (eg: "Security", "Network", "Application")
  public let domain: String

  /// Error code string (eg: "AUTHENTICATION_FAILED", "NETWORK_TIMEOUT")
  public let code: String

  /// Human-readable description of the error
  public let errorDescription: String

  /// Optional underlying error that caused this error
  public let underlyingError: Error?

  /// Optional source of the error (eg: file, function)
  public let source: ErrorSource?

  /// Additional context for the error
  public let context: UmbraErrorsCore.ErrorContext

  /// Creates a new GenericUmbraError instance
  /// - Parameters:
  ///   - domain: The domain identifier
  ///   - code: The error code string
  ///   - errorDescription: Human-readable description
  ///   - underlyingError: Optional underlying error
  ///   - source: Optional source information
  ///   - context: Optional error context
  public init(
    domain: String,
    code: String,
    errorDescription: String,
    underlyingError: Error?=nil,
    source: ErrorSource?=nil,
    context: UmbraErrorsCore.ErrorContext?=nil
  ) {
    self.domain=domain
    self.code=code
    self.errorDescription=errorDescription
    self.underlyingError=underlyingError
    self.source=source

    // Create a default context if none provided
    if let context {
      self.context=context
    } else {
      let contextDict: [String: Any]=[
        "domain": domain,
        "code": code,
        "description": errorDescription
      ]

      self.context=UmbraErrorsCore.ErrorContext(
        contextDict,
        source: source?.description ?? "unknown",
        operation: "unknown",
        details: errorDescription
      )
    }
  }

  /// Creates a new instance of the error with additional context
  public func with(context: UmbraErrorsCore.ErrorContext) -> Self {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: errorDescription,
      underlyingError: underlyingError,
      source: source,
      context: context
    )
  }

  /// Creates a new instance of the error with additional underlying error
  public func with(underlyingError: Error) -> Self {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: errorDescription,
      underlyingError: underlyingError,
      source: source,
      context: context
    )
  }

  /// Creates a new instance of the error with source information
  public func with(source: ErrorSource) -> Self {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: errorDescription,
      underlyingError: underlyingError,
      source: source,
      context: context
    )
  }

  /// A readable string representation of the error
  public var description: String {
    let sourceInfo=source?.file ?? "unknown"
    let contextSource=context.source ?? "unknown"
    let contextOperation=context.operation ?? "unknown"

    return "\(domain).\(code) (\(sourceInfo)): \(errorDescription) [Context: \(contextSource).\(contextOperation)]"
  }
}

// MARK: - Equatable Conformance

extension GenericUmbraError: Equatable {
  public static func == (lhs: GenericUmbraError, rhs: GenericUmbraError) -> Bool {
    lhs.domain == rhs.domain &&
      lhs.code == rhs.code &&
      lhs.errorDescription == rhs.errorDescription &&
      lhs.source == rhs.source
    // Note: We don't compare underlyingError or context for equality
    // as Error doesn't conform to Equatable and context may contain non-equatable values
  }
}

// MARK: - ErrorSource

/// Source information for an error
public struct ErrorSource: Equatable, Sendable {
  /// File where the error occurred
  public let file: String

  /// Function where the error occurred
  public let function: String

  /// Line where the error occurred
  public let line: Int

  /// Creates a new ErrorSource
  /// - Parameters:
  ///   - file: File where the error occurred
  ///   - function: Function where the error occurred
  ///   - line: Line where the error occurred
  public init(
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    self.file=file
    self.function=function
    self.line=line
  }
}

extension ErrorSource: CustomStringConvertible {
  public var description: String {
    "\(file):\(line) - \(function)"
  }
}

// MARK: - UmbraErrorsCore Conversion

extension GenericUmbraError {
  /// Converts this error to an UmbraErrorsCore.UmbraError
  public var asUmbraError: GenericUmbraError {
    // We'll use the current UmbraError implementation in UmbraErrorsCore
    let contextDict: [String: Any]=[
      "domain": domain,
      "code": code,
      "description": errorDescription
    ]

    let errorContext=UmbraErrorsCore.ErrorContext(
      contextDict,
      source: source?.description ?? domain,
      operation: "error_operation",
      details: errorDescription,
      underlyingError: underlyingError
    )

    return GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: errorDescription,
      underlyingError: underlyingError,
      source: source,
      context: errorContext
    )
  }

  /// Creates a GenericUmbraError from an UmbraErrorsCore.UmbraError
  public static func from(_ umbraError: UmbraErrorsCore.UmbraError) -> GenericUmbraError {
    GenericUmbraError(
      domain: umbraError.domain,
      code: umbraError.code,
      errorDescription: umbraError.description,
      underlyingError: umbraError.underlyingError,
      context: umbraError.context
    )
  }
}

// MARK: - Factory Methods

extension GenericUmbraError {
  /// Creates a new error with the given domain, code, and description
  /// - Parameters:
  ///   - domain: The error domain
  ///   - code: The error code
  ///   - description: Human-readable description
  ///   - file: Source file (auto-filled)
  ///   - function: Source function (auto-filled)
  ///   - line: Source line (auto-filled)
  /// - Returns: A new GenericUmbraError
  public static func create(
    domain: String,
    code: String,
    description: String,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) -> GenericUmbraError {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: description,
      source: ErrorSource(file: file, function: function, line: line)
    )
  }

  /// Creates a security error with the given code and description
  /// - Parameters:
  ///   - code: The error code
  ///   - description: Human-readable description
  /// - Returns: A new GenericUmbraError instance
  public static func security(
    code: String,
    description: String
  ) -> GenericUmbraError {
    create(
      domain: "Security",
      code: code,
      description: description
    )
  }

  /// Creates a crypto error with the given code and description
  /// - Parameters:
  ///   - code: The error code
  ///   - description: Human-readable description
  /// - Returns: A new GenericUmbraError instance
  public static func crypto(
    code: String,
    description: String
  ) -> GenericUmbraError {
    create(
      domain: "Crypto",
      code: code,
      description: description
    )
  }
}
