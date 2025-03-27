import CoreDTOs
import Foundation
import os.log

/// Foundation-independent adapter for user defaults operations
public class UserDefaultsServiceDTOAdapter: UserDefaultsServiceDTOProtocol {
  // MARK: - Private Properties

  private let userDefaults: UserDefaults
  private let logger=Logger(
    subsystem: "com.umbra.userDefaultsService",
    category: "UserDefaultsServiceDTOAdapter"
  )

  // MARK: - Initialization

  /// Initialize with specific UserDefaults
  /// - Parameter userDefaults: The UserDefaults to use
  public init(userDefaults: UserDefaults = .standard) {
    self.userDefaults=userDefaults
  }

  // MARK: - UserDefaultsServiceDTOProtocol Implementation

  /// Set a value for a key
  /// - Parameters:
  ///   - value: The value to set
  ///   - key: The key to set the value for
  /// - Returns: Success or failure
  public func set(value: UserDefaultsValueDTO, forKey key: String) -> Bool {
    guard !key.isEmpty else {
      logger.error("Cannot set value for empty key")
      return false
    }

    if value.isNull {
      // For null values, remove the key entirely
      userDefaults.removeObject(forKey: key)
      return true
    }

    // Convert to Foundation object
    if let object=value.toFoundationObject() {
      userDefaults.set(object, forKey: key)
      return true
    } else {
      logger.error("Failed to convert value for key '\(key)' to a Foundation object")
      return false
    }
  }

  /// Get a value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: The value or null if not found
  public func value(forKey key: String) -> UserDefaultsValueDTO {
    guard !key.isEmpty else {
      logger.error("Cannot get value for empty key")
      return .null
    }

    let object=userDefaults.object(forKey: key)
    return UserDefaultsValueDTO.from(object: object) ?? .null
  }

  /// Remove a value for a key
  /// - Parameter key: The key to remove the value for
  public func removeValue(forKey key: String) {
    guard !key.isEmpty else {
      logger.error("Cannot remove value for empty key")
      return
    }

    userDefaults.removeObject(forKey: key)
  }

  /// Check if a value exists for a key
  /// - Parameter key: The key to check
  /// - Returns: True if a value exists
  public func hasValue(forKey key: String) -> Bool {
    guard !key.isEmpty else {
      logger.error("Cannot check value for empty key")
      return false
    }

    return userDefaults.object(forKey: key) != nil
  }

  /// Get all keys
  /// - Returns: Array of all keys
  public func allKeys() -> [String] {
    guard let dictionary=userDefaults.dictionaryRepresentation() as? [String: Any] else {
      return []
    }

    return Array(dictionary.keys)
  }

  /// Remove all values
  public func removeAll() {
    for key in allKeys() {
      userDefaults.removeObject(forKey: key)
    }
  }

  /// Get a string value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: String value or nil
  public func string(forKey key: String) -> String? {
    value(forKey: key).stringValue
  }

  /// Get an integer value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Integer value or nil
  public func integer(forKey key: String) -> Int? {
    value(forKey: key).integerValue
  }

  /// Get a double value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Double value or nil
  public func double(forKey key: String) -> Double? {
    value(forKey: key).doubleValue
  }

  /// Get a boolean value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Boolean value or nil
  public func boolean(forKey key: String) -> Bool? {
    value(forKey: key).booleanValue
  }

  /// Get a data value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Data value or nil
  public func data(forKey key: String) -> [UInt8]? {
    value(forKey: key).dataValue
  }

  /// Get a URL value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: URL value or nil
  public func url(forKey key: String) -> URL? {
    value(forKey: key).urlValue
  }

  /// Get a date value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Date value or nil
  public func date(forKey key: String) -> Date? {
    value(forKey: key).dateValue
  }

  /// Get a string array value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: String array value or nil
  public func stringArray(forKey key: String) -> [String]? {
    value(forKey: key).stringArrayValue
  }

  /// Get a dictionary value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Dictionary value or nil
  public func dictionary(forKey key: String) -> [String: UserDefaultsValueDTO]? {
    value(forKey: key).dictionaryValue
  }

  /// Get an array value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Array value or nil
  public func array(forKey key: String) -> [UserDefaultsValueDTO]? {
    value(forKey: key).arrayValue
  }

  /// Synchronize changes to persistent storage
  /// - Returns: Success or failure
  public func synchronize() -> Bool {
    userDefaults.synchronize()
  }
}
