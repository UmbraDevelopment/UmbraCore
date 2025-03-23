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

/// Additional context information about an error
public struct ErrorContext: Sendable, Equatable {
  /// The source of the error (e.g., component name, module)
  public let source: String

  /// Specific error code for the error
  public let code: String?

  /// Additional message about the error
  public let message: String

  /// Additional metadata about the error
  /// Uses a Sendable-compatible dictionary type (only string keys and values)
  public let metadata: [String: String]

  /// Storage for optional number values
  public let numberValues: [String: Double]

  /// Storage for optional boolean values
  public let boolValues: [String: Bool]

  /// Creates a new ErrorContext instance
  /// - Parameters:
  ///   - source: The source of the error (e.g., component name, module)
  ///   - code: Optional specific error code
  ///   - message: Additional message about the error
  ///   - metadata: Optional additional string metadata
  ///   - numberValues: Optional numeric metadata
  ///   - boolValues: Optional boolean metadata
  public init(
    source: String,
    code: String?=nil,
    message: String,
    metadata: [String: String]=[:],
    numberValues: [String: Double]=[:],
    boolValues: [String: Bool]=[:]
  ) {
    self.source=source
    self.code=code
    self.message=message
    self.metadata=metadata
    self.numberValues=numberValues
    self.boolValues=boolValues
  }

  /// Creates a new ErrorContext by copying this context and adding additional metadata
  /// - Parameter metadata: Additional string metadata to add to the context
  /// - Returns: A new ErrorContext instance with combined metadata
  public func with(metadata additionalMetadata: [String: String]) -> ErrorContext {
    var combinedMetadata=metadata

    // Add the new metadata
    for (key, value) in additionalMetadata {
      combinedMetadata[key]=value
    }

    return ErrorContext(
      source: source,
      code: code,
      message: message,
      metadata: combinedMetadata,
      numberValues: numberValues,
      boolValues: boolValues
    )
  }

  /// Creates a new ErrorContext by copying this context and adding additional numeric values
  /// - Parameter values: Additional numeric values to add to the context
  /// - Returns: A new ErrorContext instance with combined values
  public func with(numberValues additionalValues: [String: Double]) -> ErrorContext {
    var combinedValues=numberValues

    // Add the new values
    for (key, value) in additionalValues {
      combinedValues[key]=value
    }

    return ErrorContext(
      source: source,
      code: code,
      message: message,
      metadata: metadata,
      numberValues: combinedValues,
      boolValues: boolValues
    )
  }

  /// Creates a new ErrorContext by copying this context and adding additional boolean values
  /// - Parameter values: Additional boolean values to add to the context
  /// - Returns: A new ErrorContext instance with combined values
  public func with(boolValues additionalValues: [String: Bool]) -> ErrorContext {
    var combinedValues=boolValues

    // Add the new values
    for (key, value) in additionalValues {
      combinedValues[key]=value
    }

    return ErrorContext(
      source: source,
      code: code,
      message: message,
      metadata: metadata,
      numberValues: numberValues,
      boolValues: combinedValues
    )
  }

  /// A human-readable description of the error context
  public var description: String {
    var result="[\(source)]"

    if let code {
      result += " [\(code)]"
    }

    result += ": \(message)"

    if !metadata.isEmpty {
      result += "\nMetadata:"
      for (key, value) in metadata.keys.sorted().map({ ($0, metadata[$0]!) }) {
        result += "\n  \(key): \(value)"
      }
    }

    if !numberValues.isEmpty {
      result += "\nNumber Values:"
      for (key, value) in numberValues.keys.sorted().map({ ($0, numberValues[$0]!) }) {
        result += "\n  \(key): \(value)"
      }
    }

    if !boolValues.isEmpty {
      result += "\nBoolean Values:"
      for (key, value) in boolValues.keys.sorted().map({ ($0, boolValues[$0]!) }) {
        result += "\n  \(key): \(value)"
      }
    }

    return result
  }

  /// Gets a value from the context using the specified key
  /// - Parameter key: The key to look up
  /// - Returns: The value if found, or nil if the key doesn't exist
  public func value(for key: String) -> Any? {
    metadata[key] ?? numberValues[key] ?? boolValues[key]
  }

  /// Gets a strongly typed value from the context
  /// - Parameters:
  ///   - key: The key to look up
  ///   - type: The expected type of the value
  /// - Returns: The value cast to the specified type, or nil if not found or wrong type
  public func typedValue<T>(for key: String, as _: T.Type=T.self) -> T? {
    if let value=metadata[key] as? T {
      return value
    } else if let value=numberValues[key] as? T {
      return value
    } else if let value=boolValues[key] as? T {
      return value
    }
    return nil
  }

  /// Creates a new context with the specified key-value pair added
  /// - Parameters:
  ///   - key: The key to add
  ///   - value: The value to associate with the key
  /// - Returns: A new ErrorContext instance with the added key-value pair
  public func adding(key: String, value: Any) -> ErrorContext {
    if let value=value as? String {
      return with(metadata: [key: value])
    } else if let value=value as? Double {
      return with(numberValues: [key: value])
    } else if let value=value as? Bool {
      return with(boolValues: [key: value])
    }
    return self
  }

  /// Creates a new context with multiple key-value pairs added
  /// - Parameter additionalMetadata: Dictionary of key-value pairs to add
  /// - Returns: A new ErrorContext instance with the added key-value pairs
  public func adding(metadata additionalMetadata: [String: Any]) -> ErrorContext {
    var newMetadata=metadata
    var newNumberValues=numberValues
    var newBoolValues=boolValues

    for (key, value) in additionalMetadata {
      if let value=value as? String {
        newMetadata[key]=value
      } else if let value=value as? Double {
        newNumberValues[key]=value
      } else if let value=value as? Bool {
        newBoolValues[key]=value
      }
    }

    return ErrorContext(
      source: source,
      code: code,
      message: message,
      metadata: newMetadata,
      numberValues: newNumberValues,
      boolValues: newBoolValues
    )
  }

  /// Creates a new context by merging with another context
  /// - Parameter other: Another ErrorContext to merge with
  /// - Returns: A new ErrorContext with values from both contexts (the other context takes
  /// precedence)
  public func merging(with other: ErrorContext) -> ErrorContext {
    // For a merged context, we keep our source/code/message unless the other one has non-nil values
    let mergedSource=other.source.isEmpty ? source : other.source
    let mergedCode=other.code ?? code
    let mergedMessage=other.message.isEmpty ? message : other.message

    return ErrorContext(
      source: mergedSource,
      code: mergedCode,
      message: mergedMessage,
      metadata: adding(metadata: other.metadata).metadata,
      numberValues: adding(metadata: other.numberValues).numberValues,
      boolValues: adding(metadata: other.boolValues).boolValues
    )
  }

  /// Equality check
  public static func == (lhs: ErrorContext, rhs: ErrorContext) -> Bool {
    lhs.source == rhs.source &&
      lhs.code == rhs.code &&
      lhs.message == rhs.message &&
      lhs.metadata == rhs.metadata &&
      lhs.numberValues == rhs.numberValues &&
      lhs.boolValues == rhs.boolValues
  }
}

/// Extension to add conveniences for common context values
extension ErrorContext {
  /// Creates a context with a message
  /// - Parameters:
  ///   - source: The source of the error
  ///   - message: The error message
  /// - Returns: A new error context
  public static func withMessage(source: String, message: String) -> ErrorContext {
    ErrorContext(source: source, message: message)
  }

  /// Creates a context for a validation error
  /// - Parameters:
  ///   - source: The source of the error
  ///   - field: The field that failed validation
  ///   - reason: The reason for the validation failure
  /// - Returns: A new error context
  public static func validationError(
    source: String,
    field: String,
    reason: String
  ) -> ErrorContext {
    ErrorContext(
      source: source,
      code: "validation_error",
      message: "\(field) validation failed: \(reason)",
      metadata: ["field": field, "reason": reason]
    )
  }

  /// Creates a context for a network error
  /// - Parameters:
  ///   - source: The source of the error
  ///   - endpoint: The endpoint that was being accessed
  ///   - statusCode: The HTTP status code
  ///   - message: The error message
  /// - Returns: A new error context
  public static func networkError(
    source: String,
    endpoint: String,
    statusCode: Int,
    message: String
  ) -> ErrorContext {
    ErrorContext(
      source: source,
      code: "network_error",
      message: message,
      metadata: ["endpoint": endpoint],
      numberValues: ["statusCode": Double(statusCode)]
    )
  }

  /// Creates a context for a database error
  /// - Parameters:
  ///   - source: The source of the error
  ///   - operation: The database operation being performed
  ///   - message: The error message
  /// - Returns: A new error context
  public static func databaseError(
    source: String,
    operation: String,
    message: String
  ) -> ErrorContext {
    ErrorContext(
      source: source,
      code: "database_error",
      message: message,
      metadata: ["operation": operation]
    )
  }
}

/// Default error context for empty initialisation
extension ErrorContext {
  /// An empty error context
  public static var empty: ErrorContext {
    ErrorContext(source: "", message: "")
  }
}
