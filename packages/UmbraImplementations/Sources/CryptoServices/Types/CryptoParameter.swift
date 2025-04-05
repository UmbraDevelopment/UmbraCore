import Foundation

/**
 # CryptoParameter

 A strongly-typed, Sendable-compliant replacement for dictionary-based parameters
 in cryptographic operations.

 This type allows for safe transfer of parameters across actor boundaries while
 maintaining type safety.
 */
public enum CryptoParameter: Sendable, Equatable {
  /// String parameter value
  case string(String)
  /// Integer parameter value
  case integer(Int)
  /// Boolean parameter value
  case boolean(Bool)
  /// Float parameter value
  case float(Double)
  /// Data parameter value
  case data(Data)
  /// Array of parameters
  case array([CryptoParameter])
  /// Dictionary of parameters
  case dictionary([String: CryptoParameter])

  /// Get string value if this parameter holds a string
  public var stringValue: String? {
    if case let .string(value)=self {
      return value
    }
    return nil
  }

  /// Get integer value if this parameter holds an integer
  public var intValue: Int? {
    if case let .integer(value)=self {
      return value
    }
    return nil
  }

  /// Get boolean value if this parameter holds a boolean
  public var boolValue: Bool? {
    if case let .boolean(value)=self {
      return value
    }
    return nil
  }

  /// Get float value if this parameter holds a float
  public var floatValue: Double? {
    if case let .float(value)=self {
      return value
    }
    return nil
  }

  /// Get data value if this parameter holds data
  public var dataValue: Data? {
    if case let .data(value)=self {
      return value
    }
    return nil
  }

  /// Get array value if this parameter holds an array
  public var arrayValue: [CryptoParameter]? {
    if case let .array(value)=self {
      return value
    }
    return nil
  }

  /// Get dictionary value if this parameter holds a dictionary
  public var dictionaryValue: [String: CryptoParameter]? {
    if case let .dictionary(value)=self {
      return value
    }
    return nil
  }
}
