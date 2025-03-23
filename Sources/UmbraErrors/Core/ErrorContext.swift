import Foundation

/// A container for additional contextual information about an error
public struct ErrorContext: Sendable, Equatable {
  /// The dictionary of key-value pairs containing contextual information
  private var storage: [String: Any]

  /// Creates a new ErrorContext instance
  /// - Parameter context: Initial key-value pairs for the context
  public init(_ context: [String: Any] = [:]) {
    storage = context
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

  /// Creates a new context by merging with another context
  /// - Parameter other: Another ErrorContext to merge with
  /// - Returns: A new ErrorContext with values from both contexts (the other context takes
  /// precedence)
  public func merging(with other: ErrorContext) -> ErrorContext {
    adding(context: other.storage)
  }

  /// All keys in the context
  public var keys: [String] {
    Array(storage.keys)
  }

  /// Checks if two ErrorContext instances are equal by comparing their string representations
  /// - Parameter other: Another ErrorContext to compare with
  /// - Returns: True if the contexts are considered equal, false otherwise
  public static func == (lhs: ErrorContext, rhs: ErrorContext) -> Bool {
    // Since Any can't be directly compared, we'll consider contexts equal
    // if they have the same keys with the same string representations of values
    guard lhs.keys.sorted() == rhs.keys.sorted() else {
      return false
    }

    for key in lhs.keys {
      let lhsValue = lhs.storage[key]
      let rhsValue = rhs.storage[key]

      // Compare string representations as a best effort
      if String(describing: lhsValue) != String(describing: rhsValue) {
        return false
      }
    }

    return true
  }
}

/// Extension to add conveniences for common context values
extension ErrorContext {
  /// Creates a context with a message
  /// - Parameter message: The message to include
  /// - Returns: A new ErrorContext with the message
  public static func withMessage(_ message: String) -> ErrorContext {
    ErrorContext(["message": message])
  }

  /// Creates a context with detailed error information
  /// - Parameters:
  ///   - message: A descriptive message
  ///   - file: Source file
  ///   - line: Line number
  ///   - function: Function name
  /// - Returns: A new ErrorContext with error details
  public static func withDetails(
    message: String,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) -> ErrorContext {
    ErrorContext([
      "message": message,
      "file": file,
      "line": line,
      "function": function
    ])
  }

  /// The error message, if available
  public var message: String? {
    typedValue(for: "message")
  }
}
