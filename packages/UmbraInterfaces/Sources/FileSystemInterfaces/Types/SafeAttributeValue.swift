import Foundation

/**
 A type-safe representation of attribute values for file system metadata.

 This enum provides a type-safe alternative to using `Any` for attribute values,
 ensuring that all values are Sendable and can be safely used across concurrency
 domains. It supports a variety of common attribute value types encountered
 in file system operations.
 */
public enum SafeAttributeValue: Sendable, Equatable {
  /// String value
  case string(String)

  /// Integer value
  case int(Int)

  /// Unsigned integer value
  case uint(UInt)

  /// Int64 value
  case int64(Int64)

  /// UInt64 value
  case uint64(UInt64)

  /// Boolean value
  case bool(Bool)

  /// Date value
  case date(Date)

  /// Double value
  case double(Double)

  /// URL value
  case url(URL)

  /// Data value
  case data(Data)

  /// Array of SafeAttributeValue
  case array([SafeAttributeValue])

  /// Dictionary of String to SafeAttributeValue
  case dictionary([String: SafeAttributeValue])

  /**
   Creates a SafeAttributeValue from an Any value if possible.

   This initializer attempts to convert various types to their corresponding
   SafeAttributeValue cases. Returns nil if the value cannot be safely converted.

   - Parameter value: The value to convert
   - Returns: A SafeAttributeValue if conversion is possible, nil otherwise
   */
  public init?(from value: Any) {
    switch value {
      case let stringValue as String:
        self = .string(stringValue)
      case let intValue as Int:
        self = .int(intValue)
      case let uintValue as UInt:
        self = .uint(uintValue)
      case let int64Value as Int64:
        self = .int64(int64Value)
      case let uint64Value as UInt64:
        self = .uint64(uint64Value)
      case let boolValue as Bool:
        self = .bool(boolValue)
      case let dateValue as Date:
        self = .date(dateValue)
      case let doubleValue as Double:
        self = .double(doubleValue)
      case let urlValue as URL:
        self = .url(urlValue)
      case let dataValue as Data:
        self = .data(dataValue)
      case let arrayValue as [Any]:
        // Try to convert each element in the array
        let safeValues=arrayValue.compactMap { SafeAttributeValue(from: $0) }
        // Only create the array if all elements could be converted
        if safeValues.count == arrayValue.count {
          self = .array(safeValues)
        } else {
          return nil
        }
      case let dictionaryValue as [String: Any]:
        // Try to convert each value in the dictionary
        var safeDictionary=[String: SafeAttributeValue]()
        for (key, value) in dictionaryValue {
          if let safeValue=SafeAttributeValue(from: value) {
            safeDictionary[key]=safeValue
          } else {
            // If any value can't be converted, return nil
            return nil
          }
        }
        self = .dictionary(safeDictionary)
      default:
        // Type not supported
        return nil
    }
  }

  /**
   Gets the underlying value as a specific type.

   - Returns: The value as the requested type, or nil if type conversion isn't possible
   */
  public func asString() -> String? {
    if case let .string(value)=self { return value }
    return nil
  }

  public func asInt() -> Int? {
    switch self {
      case let .int(value): value
      case let .uint(value): Int(exactly: value)
      case let .int64(value): Int(exactly: value)
      case let .uint64(value): Int(exactly: value)
      default: nil
    }
  }

  public func asUInt() -> UInt? {
    switch self {
      case let .int(value): UInt(exactly: value)
      case let .uint(value): value
      case let .int64(value): UInt(exactly: value)
      case let .uint64(value): UInt(exactly: value)
      default: nil
    }
  }

  public func asInt64() -> Int64? {
    switch self {
      case let .int(value): Int64(value)
      case let .uint(value): Int64(exactly: value)
      case let .int64(value): value
      case let .uint64(value): Int64(exactly: value)
      default: nil
    }
  }

  public func asUInt64() -> UInt64? {
    switch self {
      case let .int(value): UInt64(exactly: value)
      case let .uint(value): UInt64(value)
      case let .int64(value): UInt64(exactly: value)
      case let .uint64(value): value
      default: nil
    }
  }

  public func asBool() -> Bool? {
    if case let .bool(value)=self { return value }
    return nil
  }

  public func asDate() -> Date? {
    if case let .date(value)=self { return value }
    return nil
  }

  public func asDouble() -> Double? {
    switch self {
      case let .double(value): value
      case let .int(value): Double(value)
      case let .uint(value): Double(value)
      case let .int64(value): Double(value)
      case let .uint64(value): Double(value)
      default: nil
    }
  }

  public func asURL() -> URL? {
    if case let .url(value)=self { return value }
    return nil
  }

  public func asData() -> Data? {
    if case let .data(value)=self { return value }
    return nil
  }

  public func asArray() -> [SafeAttributeValue]? {
    if case let .array(value)=self { return value }
    return nil
  }

  public func asDictionary() -> [String: SafeAttributeValue]? {
    if case let .dictionary(value)=self { return value }
    return nil
  }
}
