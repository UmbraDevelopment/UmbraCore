import Foundation

/// A container for additional contextual information about an error
public struct ErrorContext: Sendable, Equatable, Codable, Hashable {
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
    self.value(for: "underlyingError") as? Error
  }

  // Required for Codable conformance
  private enum CodingKeys: String, CodingKey {
    case source, operation, details, file, line, function
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
    if let underlyingError = underlyingError {
      initialStorage["underlyingError"] = underlyingError
    }
    
    self.storage = initialStorage
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
      self.storage,
      source: source,
      operation: self.operation,
      details: self.details,
      file: self.file,
      line: self.line,
      function: self.function
    )
  }
  
  /// Creates a new context with the specified operation
  /// - Parameter operation: The operation to set
  /// - Returns: A new ErrorContext with the updated operation
  public func with(operation: String) -> ErrorContext {
    ErrorContext(
      self.storage,
      source: self.source,
      operation: operation,
      details: self.details,
      file: self.file,
      line: self.line,
      function: self.function
    )
  }
  
  /// Creates a new context with the specified details
  /// - Parameter details: The details to set
  /// - Returns: A new ErrorContext with the updated details
  public func with(details: String) -> ErrorContext {
    ErrorContext(
      self.storage,
      source: self.source,
      operation: self.operation,
      details: details,
      file: self.file,
      line: self.line,
      function: self.function
    )
  }
  
  /// Creates a new context with the specified underlying error
  /// - Parameter error: The underlying error to set
  /// - Returns: A new ErrorContext with the updated underlying error
  public func with(underlyingError error: Error) -> ErrorContext {
    var newStorage = self.storage
    newStorage["underlyingError"] = error
    
    return ErrorContext(
      newStorage,
      source: self.source,
      operation: self.operation,
      details: self.details,
      file: self.file,
      line: self.line,
      function: self.function
    )
  }
  
  // MARK: - Codable Implementation
  
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
  
  // MARK: - Hashable Implementation
  
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
  public static func withMessage(_ message: String, file: String = #file, line: Int = #line, function: String = #function) -> ErrorContext {
    ErrorContext(details: message, file: file, line: line, function: function)
  }
  
  /// Creates a new ErrorContext that captures the current call site
  /// - Returns: A new ErrorContext with the current call site information
  public static func currentCallSite(file: String = #file, line: Int = #line, function: String = #function) -> ErrorContext {
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
