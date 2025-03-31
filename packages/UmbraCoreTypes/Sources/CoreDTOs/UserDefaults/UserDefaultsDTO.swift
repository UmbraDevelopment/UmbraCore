import Foundation

/// A Foundation-independent representation of a user defaults value.
///
/// `UserDefaultsValueDTO` encapsulates the various types of values that can be stored
/// in user defaults without relying on Foundation-specific types. This enum supports
/// all common data types used in preference storage with type-safe access methods.
///
/// ## Overview
/// This enum offers:
/// - Support for common value types (strings, numbers, booleans, dates, etc.)
/// - Type-safe accessors for converting between compatible types
/// - Foundation independence for improved portability
/// - Support for nested collections (arrays and dictionaries)
///
/// ## Example Usage
/// ```swift
/// // Create values
/// let stringValue = UserDefaultsValueDTO.string("Hello World")
/// let boolValue = UserDefaultsValueDTO.boolean(true)
/// let complexValue = UserDefaultsValueDTO.dictionary([
///     "name": .string("John"),
///     "age": .integer(30),
///     "isPremium": .boolean(true),
///     "settings": .dictionary([
///         "darkMode": .boolean(true),
///         "notifications": .boolean(false)
///     ])
/// ])
///
/// // Access values with type conversion
/// if let name = complexValue.dictionaryValue?["name"]?.stringValue,
///    let age = complexValue.dictionaryValue?["age"]?.integerValue {
///     // Use the extracted values
/// }
/// ```
public enum UserDefaultsValueDTO: Sendable, Equatable, Hashable {
  /// String value.
  ///
  /// Represents a textual value stored in user defaults.
  case string(String)

  /// Integer value.
  ///
  /// Represents a whole number value stored in user defaults.
  case integer(Int)

  /// Double value.
  ///
  /// Represents a floating-point number stored in user defaults.
  case double(Double)

  /// Boolean value.
  ///
  /// Represents a true/false value stored in user defaults.
  case boolean(Bool)

  /// Data value as bytes.
  ///
  /// Represents binary data stored in user defaults as an array of bytes.
  case data([UInt8])

  /// URL value as string.
  ///
  /// Represents a URL stored in user defaults as its string representation.
  case url(String)

  /// Date value as timestamp.
  ///
  /// Represents a date stored in user defaults as a time interval since 1970.
  case date(TimeInterval)

  /// String array.
  ///
  /// Represents an array of strings stored in user defaults.
  case stringArray([String])

  /// Dictionary with string keys and supported values.
  ///
  /// Represents a dictionary stored in user defaults with string keys
  /// and values that are themselves `UserDefaultsValueDTO` instances.
  case dictionary([String: UserDefaultsValueDTO])

  /// Array of supported values.
  ///
  /// Represents an array of mixed value types, where each element
  /// is a `UserDefaultsValueDTO` instance.
  case array([UserDefaultsValueDTO])

  /// Null value.
  ///
  /// Represents the absence of a value or a null value in user defaults.
  case null

  // MARK: - Conversion Methods

  /// Get as string if possible.
  ///
  /// Attempts to convert the value to a string. This succeeds for string,
  /// integer, double, boolean, and URL values. For other types, returns nil.
  ///
  /// - Returns: The string representation of the value, or nil if conversion isn't possible
  public var stringValue: String? {
    switch self {
      case let .string(value):
        value
      case let .integer(value):
        String(value)
      case let .double(value):
        String(value)
      case let .boolean(value):
        String(value)
      case let .url(value):
        value
      default:
        nil
    }
  }

  /// Get as integer if possible.
  ///
  /// Attempts to convert the value to an integer. This succeeds for integer,
  /// string (if it represents a valid integer), double (truncated), and boolean
  /// (1 for true, 0 for false) values. For other types, returns nil.
  ///
  /// - Returns: The integer representation of the value, or nil if conversion isn't possible
  public var integerValue: Int? {
    switch self {
      case let .integer(value):
        value
      case let .string(value):
        Int(value)
      case let .double(value):
        Int(value)
      case let .boolean(value):
        value ? 1 : 0
      default:
        nil
    }
  }

  /// Get as double if possible.
  ///
  /// Attempts to convert the value to a double. This succeeds for double,
  /// integer, string (if it represents a valid number), and boolean
  /// (1.0 for true, 0.0 for false) values. For other types, returns nil.
  ///
  /// - Returns: The double representation of the value, or nil if conversion isn't possible
  public var doubleValue: Double? {
    switch self {
      case let .double(value):
        value
      case let .integer(value):
        Double(value)
      case let .string(value):
        Double(value)
      case let .boolean(value):
        value ? 1.0 : 0.0
      default:
        nil
    }
  }

  /// Get as boolean if possible.
  ///
  /// Attempts to convert the value to a boolean. This succeeds for boolean,
  /// integer (non-zero is true), string ("true" or "1" is true), and double
  /// (non-zero is true) values. For other types, returns nil.
  ///
  /// - Returns: The boolean representation of the value, or nil if conversion isn't possible
  public var booleanValue: Bool? {
    switch self {
      case let .boolean(value):
        value
      case let .integer(value):
        value != 0
      case let .string(value):
        value.lowercased() == "true" || value == "1"
      case let .double(value):
        value != 0
      default:
        nil
    }
  }

  /// Get as data if possible.
  ///
  /// Retrieves the raw byte data from a data value.
  ///
  /// - Returns: The byte array, or nil if the value isn't a data type
  public var dataValue: [UInt8]? {
    if case let .data(value)=self {
      return value
    }
    return nil
  }

  /// Get as URL if possible.
  ///
  /// Attempts to convert the value to a URL. This succeeds for URL and
  /// string values that represent valid URLs. For other types, returns nil.
  ///
  /// - Returns: The URL representation of the value, or nil if conversion isn't possible
  public var urlValue: URL? {
    switch self {
      case let .url(value):
        URL(string: value)
      case let .string(value):
        URL(string: value)
      default:
        nil
    }
  }

  /// Get as date if possible.
  ///
  /// Retrieves the date from a date value.
  ///
  /// - Returns: The date representation, or nil if the value isn't a date type
  public var dateValue: Date? {
    if case let .date(value)=self {
      return Date(timeIntervalSince1970: value)
    }
    return nil
  }

  /// Get as string array if possible.
  ///
  /// Attempts to retrieve an array of strings. This succeeds for stringArray values
  /// and array values if all elements can be converted to strings.
  ///
  /// - Returns: The string array, or nil if conversion isn't possible
  public var stringArrayValue: [String]? {
    switch self {
      case let .stringArray(value):
        return value
      case let .array(array):
        // Attempt to convert each element to string
        var strings: [String]=[]
        for item in array {
          if let string=item.stringValue {
            strings.append(string)
          } else {
            return nil // Return nil if any element isn't convertible to string
          }
        }
        return strings
      default:
        return nil
    }
  }

  /// Get as dictionary if possible.
  ///
  /// Retrieves the dictionary from a dictionary value.
  ///
  /// - Returns: The dictionary representation, or nil if the value isn't a dictionary type
  public var dictionaryValue: [String: UserDefaultsValueDTO]? {
    if case let .dictionary(value)=self {
      return value
    }
    return nil
  }

  /// Get as array if possible.
  ///
  /// Attempts to retrieve an array of values. This succeeds for array values
  /// and stringArray values (converted to an array of string values).
  ///
  /// - Returns: The array representation, or nil if conversion isn't possible
  public var arrayValue: [UserDefaultsValueDTO]? {
    switch self {
      case let .array(value):
        value
      case let .stringArray(strings):
        strings.map { .string($0) }
      default:
        nil
    }
  }

  /// Check if the value is null.
  ///
  /// Determines whether this value represents null/nil.
  ///
  /// - Returns: True if the value is null, false otherwise
  public var isNull: Bool {
    if case .null=self {
      return true
    }
    return false
  }
}
