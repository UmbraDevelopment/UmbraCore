import Foundation

/**
 # Sendable File Attributes

 A Swift 6-compatible wrapper for file attributes that
 preserves type information while conforming to Sendable.

 This replaces the non-Sendable [FileAttributeKey: Any] dictionary
 with a type-safe wrapper that conforms to the Sendable protocol.

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable struct for thread safety
 - Explicitly implements Sendable for concurrency safety
 - Provides type-safe access to file attributes
 - Uses British spelling in documentation
 */
public struct SendableFileAttributes: Sendable, Equatable {
  /// The underlying storage for the file attributes
  private let storage: [FileAttributeKey: SendableValue]

  /// Creates a new instance with the specified file attributes
  /// - Parameter attributes: The file attributes to store
  public init(attributes: [FileAttributeKey: Any]?=nil) {
    var storage: [FileAttributeKey: SendableValue]=[:]

    if let attributes {
      for (key, value) in attributes {
        if let stringValue=value as? String {
          storage[key] = .string(stringValue)
        } else if let boolValue=value as? Bool {
          storage[key] = .bool(boolValue)
        } else if let intValue=value as? Int {
          storage[key] = .int(intValue)
        } else if let uint64Value=value as? UInt64 {
          storage[key] = .uint64(uint64Value)
        } else if let int16Value=value as? Int16 {
          storage[key] = .int16(int16Value)
        } else if let doubleValue=value as? Double {
          storage[key] = .double(doubleValue)
        } else if let dateValue=value as? Date {
          storage[key] = .date(dateValue)
        } else if let dataValue=value as? Data {
          storage[key] = .data(dataValue)
        } else if let numberValue=value as? NSNumber {
          storage[key] = .number(numberValue)
        } else {
          // For any other type, we'll use its string description
          storage[key] = .string(String(describing: value))
        }
      }
    }

    self.storage=storage
  }

  /// Get a value for a specific attribute key
  /// - Parameter key: The attribute key
  /// - Returns: The value, if it exists
  public func value(for key: FileAttributeKey) -> Any? {
    guard let wrappedValue=storage[key] else {
      return nil
    }

    switch wrappedValue {
      case let .string(value): return value
      case let .bool(value): return value
      case let .int(value): return value
      case let .uint64(value): return value
      case let .int16(value): return value
      case let .double(value): return value
      case let .date(value): return value
      case let .data(value): return value
      case let .number(value): return value
    }
  }

  /// Get a strongly typed value for a specific attribute key
  /// - Parameter key: The attribute key
  /// - Returns: The value if it exists and matches the expected type
  public func value<T>(for key: FileAttributeKey, as _: T.Type=T.self) -> T? {
    value(for: key) as? T
  }

  /// Get all the keys in the file attributes
  public var keys: [FileAttributeKey] {
    Array(storage.keys)
  }

  /// Check if the file attributes contain a specific key
  public func contains(key: FileAttributeKey) -> Bool {
    storage[key] != nil
  }

  /// Count of file attributes
  public var count: Int {
    storage.count
  }

  /// Whether there are no file attributes
  public var isEmpty: Bool {
    storage.isEmpty
  }

  /// Convert to a dictionary with Any values
  /// - Returns: A dictionary with the same keys and values
  public func toDictionary() -> [FileAttributeKey: Any] {
    var result: [FileAttributeKey: Any]=[:]

    for (key, wrappedValue) in storage {
      switch wrappedValue {
        case let .string(value): result[key]=value
        case let .bool(value): result[key]=value
        case let .int(value): result[key]=value
        case let .uint64(value): result[key]=value
        case let .int16(value): result[key]=value
        case let .double(value): result[key]=value
        case let .date(value): result[key]=value
        case let .data(value): result[key]=value
        case let .number(value): result[key]=value
      }
    }

    return result
  }

  /// A type-safe wrapper for values that can be stored in file attributes
  private enum SendableValue: Sendable, Equatable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case uint64(UInt64)
    case int16(Int16)
    case double(Double)
    case date(Date)
    case data(Data)
    case number(NSNumber)
  }
}
