import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
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
    self.domain=domain
    self.code=code
    self.description=description
  }
}

/// A simple test function to verify that GenericError conforms to UmbraError
@MainActor
public func testGenericErrorConformance() {
  // Create an interface error source
  let source=ErrorHandlingInterfaces.ErrorSource(
    file: #file,
    line: #line,
    function: #function
  )

  // Create an interface error context
  let context=ErrorHandlingInterfaces.ErrorContext(
    source: "TestModule",
    operation: "testOperation",
    details: "Testing GenericError conformance"
  )

  // Create a generic error
  let error=GenericError(
    domain: "Test",
    code: "TEST_ERROR",
    message: "Test error message",
    details: [:],
    source: source,
    underlyingError: nil,
    context: context
  )

  // Test the with methods
  let errorWithNewContext=error.with(context: ErrorHandlingInterfaces.ErrorContext(
    source: "NewSource",
    operation: "newOperation",
    details: "New details"
  ))

  let errorWithUnderlyingError=error.with(underlyingError: NSError(
    domain: "NSError",
    code: 123,
    userInfo: nil
  ))

  let errorWithSource=error.with(source: ErrorHandlingInterfaces.ErrorSource(
    file: "NewFile.swift",
    line: 42,
    function: "newFunction()"
  ))

  // Print results to verify
  print("Original error: \(error)")
  print("Error with new context: \(errorWithNewContext)")
  print("Error with underlying error: \(errorWithUnderlyingError)")
  print("Error with new source: \(errorWithSource)")
}

/// A generic error implementation that conforms to UmbraError
private struct GenericError: ErrorHandlingInterfaces.UmbraError {
  let domain: String
  let code: String
  let message: String
  let details: [String: String] // Changed from [String: Any] to [String: String] for Sendable
  // compatibility
  let source: ErrorHandlingInterfaces.ErrorSource?
  var underlyingError: Error?
  var context: ErrorHandlingInterfaces.ErrorContext

  /// Initialiser with all properties
  init(
    domain: String,
    code: String,
    message: String,
    details: [String: String], // Changed from [String: Any] to [String: String]
    source: ErrorHandlingInterfaces.ErrorSource?,
    underlyingError: Error?,
    context: ErrorHandlingInterfaces.ErrorContext
  ) {
    self.domain=domain
    self.code=code
    self.message=message
    self.details=details
    self.source=source
    self.underlyingError=underlyingError
    self.context=context
  }

  /// Conform to CustomStringConvertible
  var description: String {
    message
  }

  /// A user-friendly error message (required by UmbraError)
  var errorDescription: String {
    message
  }

  /// Create a new instance with additional context
  func with(context: ErrorHandlingInterfaces.ErrorContext) -> Self {
    var newError=self
    newError.context=context
    return newError
  }

  /// Create a new instance with an underlying error
  func with(underlyingError: Error) -> Self {
    var newError=self
    newError.underlyingError=underlyingError
    return newError
  }

  /// Create a new instance with source information
  func with(source: ErrorHandlingInterfaces.ErrorSource) -> Self {
    GenericError(
      domain: domain,
      code: code,
      message: message,
      details: details,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }

  /// Create a new instance with additional user info
  func with(userInfo: [String: Any]) -> Self {
    var updatedDetails=details
    for (key, value) in userInfo {
      // Convert Any values to String for Sendable compatibility
      updatedDetails[key]=String(describing: value)
    }

    return GenericError(
      domain: domain,
      code: code,
      message: message,
      details: updatedDetails,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }
}
