import Foundation

/// A strongly-typed, Sendable-compliant representation of JSON-like values
/// used in Restic command results.
public enum ResticDataValue: Sendable, Equatable {
  /// String value
  case string(String)
  /// Numeric value
  case number(Double)
  /// Boolean value
  case boolean(Bool)
  /// Array of ResticDataValues
  case array([ResticDataValue])
  /// Dictionary of string keys to ResticDataValues
  case dictionary([String: ResticDataValue])
  /// Null value
  case null
  
  /// Creates a ResticDataValue from a JSON-compatible value
  /// - Parameter value: Value to convert
  /// - Returns: Corresponding ResticDataValue or nil if not convertible
  public static func from(_ value: Any) -> ResticDataValue? {
    switch value {
    case let string as String:
      return .string(string)
    case let number as NSNumber:
      // Handle boolean special case
      if CFGetTypeID(number) == CFBooleanGetTypeID() {
        return .boolean(number.boolValue)
      }
      return .number(number.doubleValue)
    case let bool as Bool:
      return .boolean(bool)
    case let array as [Any]:
      let converted = array.compactMap { from($0) }
      // Only return if all elements were convertible
      guard converted.count == array.count else { return nil }
      return .array(converted)
    case let dict as [String: Any]:
      var result = [String: ResticDataValue]()
      for (key, value) in dict {
        guard let converted = from(value) else { return nil }
        result[key] = converted
      }
      return .dictionary(result)
    case is NSNull:
      return .null
    default:
      return nil
    }
  }
  
  /// Accessor for string values
  public var stringValue: String? {
    guard case let .string(value) = self else { return nil }
    return value
  }
  
  /// Accessor for number values
  public var numberValue: Double? {
    guard case let .number(value) = self else { return nil }
    return value
  }
  
  /// Accessor for boolean values
  public var boolValue: Bool? {
    guard case let .boolean(value) = self else { return nil }
    return value
  }
  
  /// Accessor for array values
  public var arrayValue: [ResticDataValue]? {
    guard case let .array(value) = self else { return nil }
    return value
  }
  
  /// Accessor for dictionary values
  public var dictionaryValue: [String: ResticDataValue]? {
    guard case let .dictionary(value) = self else { return nil }
    return value
  }
  
  /// Determines if this value represents null
  public var isNull: Bool {
    guard case .null = self else { return false }
    return true
  }
}

/// Represents the result of a Restic command execution.
///
/// This type encapsulates both the raw output and structured data resulting from
/// a Restic command execution, providing a consistent interface for handling command results.
public struct ResticCommandResult: Sendable {
  /// The raw output string from the command
  public let output: String

  /// The exit code of the command (0 for success)
  public let exitCode: Int

  /// Whether the command was successful
  public let isSuccess: Bool

  /// Duration of the command execution in seconds
  public let duration: TimeInterval

  /// Any structured data parsed from the command output
  public let data: [String: ResticDataValue]

  /// Creates a new command result.
  ///
  /// - Parameters:
  ///   - output: The raw output string from the command
  ///   - exitCode: The exit code of the command (0 for success)
  ///   - duration: Duration of the command execution in seconds
  ///   - data: Any structured data parsed from the command output
  public init(
    output: String,
    exitCode: Int=0,
    duration: TimeInterval=0,
    data: [String: ResticDataValue]=[:]
  ) {
    self.output=output
    self.exitCode=exitCode
    isSuccess=exitCode == 0
    self.duration=duration
    self.data=data
  }

  /// Creates a new command result from legacy untyped data.
  ///
  /// - Parameters:
  ///   - output: The raw output string from the command
  ///   - exitCode: The exit code of the command (0 for success)
  ///   - duration: Duration of the command execution in seconds
  ///   - untypedData: Any structured data parsed from the command output
  public init(
    output: String,
    exitCode: Int=0,
    duration: TimeInterval=0,
    untypedData: [String: Any]=[:]
  ) {
    self.output=output
    self.exitCode=exitCode
    isSuccess=exitCode == 0
    self.duration=duration
    
    // Convert untyped data to typed format
    var typedData = [String: ResticDataValue]()
    for (key, value) in untypedData {
      if let converted = ResticDataValue.from(value) {
        typedData[key] = converted
      }
    }
    self.data=typedData
  }

  /// Creates a successful result.
  ///
  /// - Parameters:
  ///   - output: The raw output string from the command
  ///   - duration: Duration of the command execution in seconds
  ///   - data: Any structured data parsed from the command output
  /// - Returns: A successful command result
  public static func success(
    output: String,
    duration: TimeInterval=0,
    data: [String: ResticDataValue]=[:] 
  ) -> ResticCommandResult {
    ResticCommandResult(
      output: output,
      exitCode: 0,
      duration: duration,
      data: data
    )
  }

  /// Creates a failure result.
  ///
  /// - Parameters:
  ///   - output: The raw output string from the command
  ///   - exitCode: The exit code of the command
  ///   - duration: Duration of the command execution in seconds
  ///   - data: Any structured data parsed from the command output
  /// - Returns: A failure command result
  public static func failure(
    output: String,
    exitCode: Int=1,
    duration: TimeInterval=0,
    data: [String: ResticDataValue]=[:] 
  ) -> ResticCommandResult {
    ResticCommandResult(
      output: output,
      exitCode: exitCode,
      duration: duration,
      data: data
    )
  }
}
