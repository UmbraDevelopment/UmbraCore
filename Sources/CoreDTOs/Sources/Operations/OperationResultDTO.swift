import UmbraCoreTypes

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

/// A simple error type for operation failures that doesn't depend on Foundation
public struct OperationError: Error, CustomStringConvertible, Sendable, Equatable {
  /// Error message
  public let message: String

  /// Error code
  public let code: Int32

  /// Initializer
  /// - Parameters:
  ///   - message: Error message
  ///   - code: Error code
  public init(message: String, code: Int32) {
    self.message = message
    self.code = code
  }

  /// Human-readable description
  public var description: String {
    "Operation failed: \(message) (code: \(code))"
  }
}

/// FoundationIndependent representation of an operation result.
/// This data transfer object encapsulates the outcome of an operation
/// without using any Foundation types.
public struct OperationResultDTO<T>: Sendable, Equatable where T: Sendable, T: Equatable {
  // MARK: - Types

  /// Represents the status of an operation
  public enum Status: String, Sendable, Equatable {
    /// Operation completed successfully
    case success
    /// Operation failed
    case failure
    /// Operation was cancelled
    case cancelled
  }

  // MARK: - Properties

  /// The status of the operation
  public let status: Status

  /// The result value if the operation was successful
  public let value: T?

  /// The error code if the operation failed
  public let errorCode: Int32?

  /// The error message if the operation failed
  public let errorMessage: String?

  /// Additional details about the operation
  public let details: [String: String]

  // MARK: - Initializers

  /// Create a successful operation result
  /// - Parameters:
  ///   - value: The result value
  ///   - details: Optional additional details
  public init(value: T, details: [String: String] = [:]) {
    status = .success
    self.value = value
    errorCode = nil
    errorMessage = nil
    self.details = details
  }

  /// Create a failed operation result
  /// - Parameters:
  ///   - errorCode: Error code
  ///   - errorMessage: Error message
  ///   - details: Optional additional details
  public init(errorCode: Int32, errorMessage: String, details: [String: String] = [:]) {
    status = .failure
    value = nil
    self.errorCode = errorCode
    self.errorMessage = errorMessage
    self.details = details
  }

  /// Create a cancelled operation result
  /// - Parameter details: Optional additional details
  public init(cancelled _: Bool = true, details: [String: String] = [:]) {
    status = .cancelled
    value = nil
    errorCode = nil
    errorMessage = "Operation cancelled"
    self.details = details
  }

  /// Create an operation result with the specified status
  /// - Parameters:
  ///   - status: The operation status
  ///   - value: The result value (for success)
  ///   - errorCode: Error code (for failure)
  ///   - errorMessage: Error message (for failure)
  ///   - details: Additional details
  public init(
    status: Status,
    value: T? = nil,
    errorCode: Int32? = nil,
    errorMessage: String? = nil,
    details: [String: String] = [:]
  ) {
    self.status = status
    self.value = value
    self.errorCode = errorCode
    self.errorMessage = errorMessage
    self.details = details
  }

  // MARK: - Methods

  /// Get the value or throw an error if the operation failed
  /// - Returns: The operation value
  /// - Throws: An error if the operation failed
  public func valueOrThrow() throws -> T {
    guard let value, status == .success else {
      throw OperationError(
        message: errorMessage ?? "Unknown error",
        code: errorCode ?? -1
      )
    }
    return value
  }

  /// Apply a transform function to the successful value
  /// - Parameter transform: A function to transform the value
  /// - Returns: A new OperationResultDTO with the transformed value, or the original error
  public func map<U>(_ transform: (T) -> U) -> OperationResultDTO<U> where U: Sendable,
  U: Equatable {
    switch status {
      case .success:
        guard let value else {
          return OperationResultDTO<U>(
            status: .failure,
            errorCode: -1,
            errorMessage: "Value is nil but status is success",
            details: details
          )
        }
        return OperationResultDTO<U>(
          status: .success,
          value: transform(value),
          details: details
        )
      case .failure:
        return OperationResultDTO<U>(
          status: .failure,
          errorCode: errorCode,
          errorMessage: errorMessage,
          details: details
        )
      case .cancelled:
        return OperationResultDTO<U>(
          status: .cancelled,
          errorCode: errorCode,
          errorMessage: errorMessage,
          details: details
        )
    }
  }

  /// Apply a transform function that may fail to the successful value
  /// - Parameter transform: A function that returns a Result
  /// - Returns: A new OperationResultDTO with the transformed value, or a new error
  public func flatMap<U>(_ transform: (T) -> OperationResultDTO<U>) -> OperationResultDTO<U>
  where U: Sendable, U: Equatable {
    switch status {
      case .success:
        guard let value else {
          return OperationResultDTO<U>(
            status: .failure,
            errorCode: -1,
            errorMessage: "Value is nil but status is success",
            details: details
          )
        }
        return transform(value)
      case .failure:
        return OperationResultDTO<U>(
          status: .failure,
          errorCode: errorCode,
          errorMessage: errorMessage,
          details: details
        )
      case .cancelled:
        return OperationResultDTO<U>(
          status: .cancelled,
          errorCode: errorCode,
          errorMessage: errorMessage,
          details: details
        )
    }
  }

  /// Add additional details to the result
  /// - Parameter additionalDetails: The details to add
  /// - Returns: A new OperationResultDTO with the added details
  public func withDetails(_ additionalDetails: [String: String]) -> OperationResultDTO<T> {
    var newDetails = details
    for (key, value) in additionalDetails {
      newDetails[key] = value
    }

    return OperationResultDTO<T>(
      status: status,
      value: value,
      errorCode: errorCode,
      errorMessage: errorMessage,
      details: newDetails
    )
  }

  // MARK: - Static Factory Methods

  /// Create a successful operation result
  /// - Parameters:
  ///   - value: The successful result value
  ///   - details: Additional details about the operation
  /// - Returns: An OperationResultDTO indicating success
  public static func success(_ value: T, details: [String: String] = [:]) -> OperationResultDTO<T> {
    OperationResultDTO(value: value, details: details)
  }

  /// Create a failure operation result
  /// - Parameters:
  ///   - errorCode: Error code for the failure
  ///   - errorMessage: Error message describing the failure
  ///   - details: Additional details about the operation
  /// - Returns: An OperationResultDTO indicating failure
  public static func failure(
    errorCode: Int32,
    errorMessage: String,
    details: [String: String] = [:]
  ) -> OperationResultDTO<T> {
    OperationResultDTO(
      errorCode: errorCode,
      errorMessage: errorMessage,
      details: details
    )
  }
}

// MARK: - VoidEquatable Wrapper

/// A wrapper for Void that conforms to Equatable
/// This allows OperationResultDTO to be used with Void as a type parameter
public struct VoidEquatable: Sendable, Equatable {
  /// Creates a new VoidEquatable
  public init() {}

  /// Equality check for VoidEquatable
  public static func == (_: VoidEquatable, _: VoidEquatable) -> Bool {
    true
  }
}
