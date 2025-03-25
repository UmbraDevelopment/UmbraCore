import Foundation

/// A container for additional contextual information about an error
/// Using @unchecked Sendable due to the nature of the dictionary values
/// NOTE: This should be refactored to use a more specific and fully Sendable type in a future
/// update
public struct ErrorContext: @unchecked Sendable, Equatable, Codable, Hashable {
  /// The dictionary of key-value pairs containing contextual information
  private var storage: [String: Any]

  /// Source of the error (e.g., component name, module)
  public let source: String?

  /// Operation being performed when the error occurred
  public let operation: String?

  /// Additional details about the error
  public let details: String?

  /// File where the error occurred
  public let file: String

  /// Line number where the error occurred
  public let line: Int

  /// Function where the error occurred
  public let function: String

  /// Underlying error if any
  public var underlyingError: Error? {
    value(for: "underlyingError") as? Error
  }

  // Required for Codable conformance
  private enum CodingKeys: String, CodingKey {
    case source
    case operation
    case details
    case file
    case line
    case function
    // storage is handled separately
  }

  /// Creates a new ErrorContext instance
  /// - Parameters:
  ///   - context: Initial key-value pairs for the context
  ///   - source: Source of the error (e.g., component name, module)
  ///   - operation: Operation being performed when the error occurred
  ///   - details: Additional details about the error
  ///   - file: File where the error occurred (automatically included)
  ///   - line: Line number where the error occurred (automatically included)
  ///   - function: Function where the error occurred (automatically included)
  public init(
    _ context: [String: Any] = [:],
    source: String? = nil,
    operation: String? = nil,
    details: String? = nil,
    underlyingError: Error? = nil,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) {
    var initialStorage = context
    if let underlyingError {
      initialStorage["underlyingError"] = underlyingError
    }

    storage = initialStorage
    self.source = source
    self.operation = operation
    self.details = details
    self.file = file
    self.line = line
    self.function = function
  }

  /// Gets a value from the context using the specified key
  /// - Parameter key: The key to look up
  /// - Returns: The value if found, or nil if the key doesn't exist
  public func value(for key: String) -> Any? {
    storage[key]
  }

  /// Gets a strongly typed value from the context
  /// - Parameters:
  ///   - key: The key to look up
  ///   - type: The expected type of the value
  /// - Returns: The value cast to the specified type, or nil if not found or wrong type
  public func typedValue<T>(for key: String, as _: T.Type = T.self) -> T? {
    storage[key] as? T
  }

  /// Creates a new context with the specified key-value pair added
  /// - Parameters:
  ///   - key: The key to add
  ///   - value: The value to associate with the key
  /// - Returns: A new ErrorContext instance with the added key-value pair
  public func adding(key: String, value: Any) -> ErrorContext {
    var newContext = self
    newContext.storage[key] = value
    return newContext
  }

  /// Creates a new context with multiple key-value pairs added
  /// - Parameter context: Dictionary of key-value pairs to add
  /// - Returns: A new ErrorContext instance with the added key-value pairs
  public func adding(context: [String: Any]) -> ErrorContext {
    var newContext = self
    for (key, value) in context {
      newContext.storage[key] = value
    }
    return newContext
  }

  /// Creates a new context with the specified source
  /// - Parameter source: The source to set
  /// - Returns: A new ErrorContext with the updated source
  public func with(source: String) -> ErrorContext {
    ErrorContext(
      storage,
      source: source,
      operation: operation,
      details: details,
      file: file,
      line: line,
      function: function
    )
  }

  /// Creates a new context with the specified operation
  /// - Parameter operation: The operation to set
  /// - Returns: A new ErrorContext with the updated operation
  public func with(operation: String) -> ErrorContext {
    ErrorContext(
      storage,
      source: source,
      operation: operation,
      details: details,
      file: file,
      line: line,
      function: function
    )
  }

  /// Creates a new context with the specified details
  /// - Parameter details: The details to set
  /// - Returns: A new ErrorContext with the updated details
  public func with(details: String) -> ErrorContext {
    ErrorContext(
      storage,
      source: source,
      operation: operation,
      details: details,
      file: file,
      line: line,
      function: function
    )
  }

  /// Creates a new context with the specified underlying error
  /// - Parameter error: The underlying error to set
  /// - Returns: A new ErrorContext with the updated underlying error
  public func with(underlyingError error: Error) -> ErrorContext {
    var newStorage = storage
    newStorage["underlyingError"] = error

    return ErrorContext(
      newStorage,
      source: source,
      operation: operation,
      details: details,
      file: file,
      line: line,
      function: function
    )
  }

  /// Creates a new context by merging with another context
  /// - Parameter other: Another ErrorContext to merge with
  /// - Returns: A new ErrorContext with values from both contexts (the other context takes
  /// precedence)
  public func merging(with other: ErrorContext) -> ErrorContext {
    var combinedStorage = storage

    // Merge storage values, with other taking precedence
    for (key, value) in other.storage {
      combinedStorage[key] = value
    }

    // For a merged context, we keep our source/operation/details unless the other one has non-nil
    // values
    let mergedSource = other.source ?? source
    let mergedOperation = other.operation ?? operation
    let mergedDetails = other.details ?? details

    return ErrorContext(
      combinedStorage,
      source: mergedSource,
      operation: mergedOperation,
      details: mergedDetails,
      file: other.file, // Use the most recent file/line/function info
      line: other.line,
      function: other.function
    )
  }

  // MARK: - Codable Implementation

  /// Encodes this error context for serialisation
  ///
  /// This method enables `ErrorContext` to conform to `Encodable` despite
  /// containing an `Error` property that doesn't conform to `Encodable`.
  ///
  /// - Parameter encoder: The encoder to write data to
  /// - Throws: Any encoding errors that occur during the encoding process
  /// - Note: The `storage` dictionary is intentionally excluded from encoding as it may
  ///   contain non-encodable values
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encodeIfPresent(source, forKey: .source)
    try container.encodeIfPresent(operation, forKey: .operation)
    try container.encodeIfPresent(details, forKey: .details)
    try container.encode(file, forKey: .file)
    try container.encode(line, forKey: .line)
    try container.encode(function, forKey: .function)

    // Note: storage is not encoded as it contains Any values
  }

  /// Creates a new ErrorContext instance from a decoder
  /// - Parameter decoder: The decoder to read data from
  /// - Throws: Any decoding errors that occur during the decoding process
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    source = try container.decodeIfPresent(String.self, forKey: .source)
    operation = try container.decodeIfPresent(String.self, forKey: .operation)
    details = try container.decodeIfPresent(String.self, forKey: .details)
    file = try container.decode(String.self, forKey: .file)
    line = try container.decode(Int.self, forKey: .line)
    function = try container.decode(String.self, forKey: .function)

    // Initialize empty storage as we can't decode [String: Any]
    storage = [:]
  }

  // MARK: - Hashable Implementation

  /// Combines the values of this error context into the hasher
  ///
  /// This method provides a consistent hash value to support using `ErrorContext`
  /// in hashed collections like `Set` and as dictionary keys.
  ///
  /// - Parameter hasher: The hasher to use when combining field values
  /// - Note: The `storage` dictionary is intentionally excluded from hashing as it may
  ///   contain non-hashable values
  public func hash(into hasher: inout Hasher) {
    hasher.combine(source)
    hasher.combine(operation)
    hasher.combine(details)
    hasher.combine(file)
    hasher.combine(line)
    hasher.combine(function)
    // Note: storage is not included in hash as it may contain non-hashable values
  }

  // MARK: - Equatable Implementation

  /// Checks if two ErrorContext instances are equal
  ///
  /// This method compares the values of two `ErrorContext` instances to determine
  /// if they are equal. It excludes the `storage` dictionary from the comparison
  /// as it may contain non-equatable values.
  ///
  /// - Parameters:
  ///   - lhs: The first ErrorContext instance
  ///   - rhs: The second ErrorContext instance
  /// - Returns: True if the two instances are equal, false otherwise
  public static func == (lhs: ErrorContext, rhs: ErrorContext) -> Bool {
    lhs.source == rhs.source &&
      lhs.operation == rhs.operation &&
      lhs.details == rhs.details &&
      lhs.file == rhs.file &&
      lhs.line == rhs.line &&
      lhs.function == rhs.function
    // Note: storage is not compared as it may contain non-equatable values
  }
}

// MARK: - Convenience Extensions

extension ErrorContext {
  /// Creates a new ErrorContext with a message as details
  /// - Parameter message: The message to set as details
  /// - Returns: A new ErrorContext with the message as details
  public static func withMessage(
    _ message: String,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) -> ErrorContext {
    ErrorContext(details: message, file: file, line: line, function: function)
  }

  /// Creates a new ErrorContext that captures the current call site
  /// - Returns: A new ErrorContext with the current call site information
  public static func currentCallSite(
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) -> ErrorContext {
    ErrorContext(file: file, line: line, function: function)
  }
}

// MARK: - Error Domain Definitions

/// Common error domains used throughout the system
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Application domain
  public static let application = "Application"
  /// Repository domain
  public static let repository = "Repository"
  /// Resource domain
  public static let resource = "Resource"
  /// Service domain
  public static let service = "Service"
  /// Logging domain
  public static let logging = "Logging"
  /// Key management domain
  public static let keyManagement = "KeyManagement"
}

// MARK: - Base Error Context

/// Basic implementation of an error context with domain, code, and description
public struct BaseErrorContext: Equatable, Codable, Hashable, Sendable {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String
  /// Underlying error that caused this error
  public let underlyingError: Error?

  /// Creates a new BaseErrorContext
  /// - Parameters:
  ///   - domain: Error domain
  ///   - code: Error code
  ///   - description: Error description
  ///   - underlyingError: Optional underlying error
  public init(
    domain: String,
    code: Int,
    description: String,
    underlyingError: Error? = nil
  ) {
    self.domain = domain
    self.code = code
    self.description = description
    self.underlyingError = underlyingError
  }

  // Equatable can't be automatically synthesised due to Error not conforming to Equatable
  /// Checks if two BaseErrorContext instances are equal
  ///
  /// This method compares the values of two `BaseErrorContext` instances to determine
  /// if they are equal. It excludes the `underlyingError` from the comparison
  /// as it may contain non-equatable values.
  ///
  /// - Parameters:
  ///   - lhs: The first BaseErrorContext instance
  ///   - rhs: The second BaseErrorContext instance
  /// - Returns: True if the two instances are equal, false otherwise
  public static func == (lhs: BaseErrorContext, rhs: BaseErrorContext) -> Bool {
    lhs.domain == rhs.domain &&
      lhs.code == rhs.code &&
      lhs.description == rhs.description
    // Note: underlyingError is not compared
  }

  // Hashable can't be automatically synthesised due to Error not conforming to Hashable
  /// Combines the values of this base error context into the hasher
  ///
  /// This method enables `BaseErrorContext` to conform to `Hashable` despite
  /// containing an `Error` property that doesn't conform to `Hashable`.
  ///
  /// - Parameter hasher: The hasher to use when combining field values
  /// - Note: The `underlyingError` is intentionally excluded from hashing
  public func hash(into hasher: inout Hasher) {
    hasher.combine(domain)
    hasher.combine(code)
    hasher.combine(description)
    // Note: underlyingError is not hashed
  }

  /// Encodes this base error context for serialisation
  ///
  /// This method enables `BaseErrorContext` to conform to `Encodable` despite
  /// containing an `Error` property that doesn't conform to `Encodable`.
  ///
  /// - Parameter encoder: The encoder to write data to
  /// - Throws: Any encoding errors that occur during the encoding process
  /// - Note: The `underlyingError` is intentionally excluded from encoding
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(domain, forKey: .domain)
    try container.encode(code, forKey: .code)
    try container.encode(description, forKey: .description)
    // Note: underlyingError is not encoded
  }

  /// Creates a new BaseErrorContext instance from a decoder
  /// - Parameter decoder: The decoder to read data from
  /// - Throws: Any decoding errors that occur during the decoding process
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    domain = try container.decode(String.self, forKey: .domain)
    code = try container.decode(Int.self, forKey: .code)
    description = try container.decode(String.self, forKey: .description)
    underlyingError = nil // We can't decode Error
  }

  private enum CodingKeys: String, CodingKey {
    case domain
    case code
    case description
  }
}

// MARK: - Extensions for ErrorContext compatibility

/// Extension to convert BaseErrorContext to ErrorContext
extension BaseErrorContext {
  /// Convert to standard ErrorContext type
  public var asErrorContext: ErrorContext {
    ErrorContext(
      ["code": code],
      source: domain,
      details: description,
      underlyingError: underlyingError
    )
  }
}

/// Extension to add BaseErrorContext compatibility
extension ErrorContext {
  /// Create an ErrorContext from domain, code, and description
  public static func create(
    domain: String,
    code: Int,
    description: String,
    underlyingError: Error? = nil
  ) -> ErrorContext {
    ErrorContext(
      ["code": code],
      source: domain,
      details: description,
      underlyingError: underlyingError
    )
  }
}
