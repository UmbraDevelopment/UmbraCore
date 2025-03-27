import Foundation
import UmbraErrors

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
///   "name": .string("John"),
///   "age": .number(30),
///   "isPremium": .boolean(true)
/// ])
///
/// // Convert between compatible types
/// let numAsString = UserDefaultsValueDTO.number(42).stringValue // "42"
/// let boolAsString = UserDefaultsValueDTO.boolean(true).stringValue // "true"
/// ```
public enum UserDefaultsValueDTO: Sendable, Equatable, Hashable {
  /// String value.
  ///
  /// Represents a textual value stored in user defaults.
  case string(String)
  
  /// Number value.
  ///
  /// Represents a numeric value stored in user defaults.
  case number(Double)
  
  /// Boolean value.
  ///
  /// Represents a true/false value stored in user defaults.
  case boolean(Bool)
  
  /// Date value stored as ISO8601 string.
  ///
  /// Represents a date and time value stored in user defaults.
  case date(String)
  
  /// Data value stored as base64 encoded string.
  ///
  /// Represents binary data stored in user defaults.
  case data(String)
  
  /// URL value stored as string.
  ///
  /// Represents a URL stored in user defaults.
  case url(String)
  
  /// Array of UserDefaultsValueDTO values.
  ///
  /// Represents an ordered collection of values stored in user defaults.
  case array([UserDefaultsValueDTO])
  
  /// Dictionary of string keys to UserDefaultsValueDTO values.
  ///
  /// Represents a key-value collection of values stored in user defaults.
  case dictionary([String: UserDefaultsValueDTO])
  
  /// Null value.
  ///
  /// Represents a nil or null value in user defaults.
  case null
  
  // MARK: - Convenient type accessors
  
  /// Gets the value as a string if possible.
  public var stringValue: String? {
    switch self {
      case let .string(value):
        value
      case let .number(value):
        String(value)
      case let .boolean(value):
        String(value)
      case let .date(value):
        value
      case let .data(value):
        value
      case let .url(value):
        value
      default:
        nil
    }
  }
  
  /// Gets the value as a double if possible.
  public var numberValue: Double? {
    switch self {
      case let .number(value):
        value
      case let .string(value):
        Double(value)
      case let .boolean(value):
        value ? 1.0 : 0.0
      default:
        nil
    }
  }
  
  /// Gets the value as a boolean if possible.
  public var booleanValue: Bool? {
    switch self {
      case let .boolean(value):
        value
      case let .number(value):
        value != 0
      case let .string(value):
        value.lowercased() == "true" || value == "1"
      default:
        nil
    }
  }
  
  /// Gets the value as a Date if possible.
  public var dateValue: Date? {
    switch self {
      case let .date(value):
        ISO8601DateFormatter().date(from: value)
      case let .string(value):
        ISO8601DateFormatter().date(from: value)
      default:
        nil
    }
  }
  
  /// Gets the value as Data if possible.
  public var dataValue: Data? {
    switch self {
      case let .data(value):
        Data(base64Encoded: value)
      case let .string(value):
        Data(base64Encoded: value)
      default:
        nil
    }
  }
  
  /// Gets the value as a URL if possible.
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
  
  /// Gets the value as an array if possible.
  public var arrayValue: [UserDefaultsValueDTO]? {
    switch self {
      case let .array(value):
        value
      default:
        nil
    }
  }
  
  /// Gets the value as a dictionary if possible.
  public var dictionaryValue: [String: UserDefaultsValueDTO]? {
    switch self {
      case let .dictionary(value):
        value
      default:
        nil
    }
  }
  
  /// Whether the value is null.
  public var isNull: Bool {
    switch self {
      case .null:
        true
      default:
        false
    }
  }
  
  // MARK: - Conversion helpers
  
  /// Create a UserDefaultsValueDTO from any supported type.
  public static func from(_ value: Any?) -> UserDefaultsValueDTO {
    guard let value = value else {
      return .null
    }
    
    switch value {
      case let string as String:
        return .string(string)
      case let number as NSNumber:
        return .number(number.doubleValue)
      case let bool as Bool:
        return .boolean(bool)
      case let date as Date:
        return .date(ISO8601DateFormatter().string(from: date))
      case let data as Data:
        return .data(data.base64EncodedString())
      case let url as URL:
        return .url(url.absoluteString)
      case let array as [Any]:
        return .array(array.map { from($0) })
      case let dict as [String: Any]:
        var result: [String: UserDefaultsValueDTO] = [:]
        for (key, value) in dict {
          result[key] = from(value)
        }
        return .dictionary(result)
      default:
        // For unsupported types, convert to string description as fallback
        return .string(String(describing: value))
    }
  }
}
