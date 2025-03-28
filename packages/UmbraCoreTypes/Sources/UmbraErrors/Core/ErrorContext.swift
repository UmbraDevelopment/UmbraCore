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
    _ context: [String: Any]=[:],
    source: String?=nil,
    operation: String?=nil,
    details: String?=nil,
    underlyingError: Error?=nil,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) {
    var initialStorage=context
    if let underlyingError {
      initialStorage["underlyingError"]=underlyingError
    }

    storage=initialStorage
    self.source=source
    self.operation=operation
    self.details=details
    self.file=file
    self.line=line
    self.function=function
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
  public func typedValue<T>(for key: String, as _: T.Type=T.self) -> T? {
    storage[key] as? T
  }

  /// Creates a new context with the specified key-value pair added
  /// - Parameters:
  ///   - key: The key to add
  ///   - value: The value to associate with the key
  /// - Returns: A new ErrorContext instance with the added key-value pair
  public func adding(key: String, value: Any) -> ErrorContext {
    var newContext=self
    newContext.storage[key]=value
    return newContext
  }

  /// Creates a new context with multiple key-value pairs added
  /// - Parameter context: Dictionary of key-value pairs to add
  /// - Returns: A new ErrorContext instance with the added key-value pairs
  public func adding(context: [String: Any]) -> ErrorContext {
    var newContext=self
    for (key, value) in context {
      newContext.storage[key]=value
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
    var newStorage=storage
    newStorage["underlyingError"]=error

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
    var combinedStorage=storage

    // Merge storage values, with other taking precedence
    for (key, value) in other.storage {
      combinedStorage[key]=value
    }

    // For a merged context, we keep our source/operation/details unless the other one has non-nil
    // values
    let mergedSource=other.source ?? source
    let mergedOperation=other.operation ?? operation
    let mergedDetails=other.details ?? details

    return ErrorContext(
      combinedStorage,
      source: mergedSource,
      operation: mergedOperation,
      details: mergedDetails,
      file: file,
      line: line,
      function: function
    )
  }

  // MARK: - Codable Implementation

  public init(from decoder: Decoder) throws {
    let container=try decoder.container(keyedBy: CodingKeys.self)
    source=try container.decodeIfPresent(String.self, forKey: .source)
    operation=try container.decodeIfPresent(String.self, forKey: .operation)
    details=try container.decodeIfPresent(String.self, forKey: .details)
    file=try container.decode(String.self, forKey: .file)
    line=try container.decode(Int.self, forKey: .line)
    function=try container.decode(String.self, forKey: .function)

    // Storage can't be directly encoded/decoded due to Any values
    // We initialize with an empty dictionary, as Codable errors can't store Any values
    storage=[:]
  }

  public func encode(to encoder: Encoder) throws {
    var container=encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(source, forKey: .source)
    try container.encodeIfPresent(operation, forKey: .operation)
    try container.encodeIfPresent(details, forKey: .details)
    try container.encode(file, forKey: .file)
    try container.encode(line, forKey: .line)
    try container.encode(function, forKey: .function)
    // storage is not encoded
  }

  // MARK: - Equatable Implementation

  public static func == (lhs: ErrorContext, rhs: ErrorContext) -> Bool {
    // We only compare the public properties, not the storage dictionary
    // since the storage dictionary contains Any values that can't reliably be compared
    lhs.source == rhs.source &&
      lhs.operation == rhs.operation &&
      lhs.details == rhs.details &&
      lhs.file == rhs.file &&
      lhs.line == rhs.line &&
      lhs.function == rhs.function
  }

  // MARK: - Hashable Implementation

  public func hash(into hasher: inout Hasher) {
    // Only hash the public properties
    hasher.combine(source)
    hasher.combine(operation)
    hasher.combine(details)
    hasher.combine(file)
    hasher.combine(line)
    hasher.combine(function)
  }
}

// MARK: - Convenience Extensions

extension ErrorContext {
  /// Creates a context that includes basic information about a file operation
  /// - Parameters:
  ///   - path: The file path related to the operation
  ///   - operation: The operation being performed
  ///   - details: Additional details about the operation
  /// - Returns: An ErrorContext with file operation information
  public static func fileOperation(
    path: String,
    operation: String,
    details: String?=nil
  ) -> ErrorContext {
    ErrorContext(
      ["path": path],
      source: "FileSystem",
      operation: operation,
      details: details
    )
  }

  /// Creates a context for network-related errors
  /// - Parameters:
  ///   - url: The URL related to the operation
  ///   - statusCode: HTTP status code if applicable
  ///   - operation: The network operation being performed
  /// - Returns: An ErrorContext with network operation information
  public static func network(
    url: URL,
    statusCode: Int?=nil,
    operation: String
  ) -> ErrorContext {
    var context: [String: Any]=["url": url.absoluteString]
    if let statusCode {
      context["statusCode"]=statusCode
    }

    return ErrorContext(
      context,
      source: "Network",
      operation: operation
    )
  }
}

/// An error context specific to CoreData operations
public struct BaseErrorContext: Equatable, Codable, Hashable, Sendable {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String
  /// Optional URL context
  public let url: URL?

  /// Create a new CoreDataErrorContext
  /// - Parameters:
  ///   - domain: Domain of the error
  ///   - code: Code of the error
  ///   - description: Description of the error
  ///   - url: Optional URL context
  public init(
    domain: String,
    code: Int,
    description: String,
    url: URL?=nil
  ) {
    self.domain=domain
    self.code=code
    self.description=description
    self.url=url
  }
}
