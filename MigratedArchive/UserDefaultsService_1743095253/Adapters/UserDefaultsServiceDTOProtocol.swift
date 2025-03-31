import CoreDTOs
import Foundation

/// Protocol defining a Foundation-independent interface for user defaults operations
public protocol UserDefaultsServiceDTOProtocol: Sendable {
  /// Set a value for a key
  /// - Parameters:
  ///   - value: The value to set
  ///   - key: The key to set the value for
  /// - Returns: Success or failure
  func set(value: UserDefaultsValueDTO, forKey key: String) -> Bool

  /// Get a value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: The value or null if not found
  func value(forKey key: String) -> UserDefaultsValueDTO

  /// Remove a value for a key
  /// - Parameter key: The key to remove the value for
  func removeValue(forKey key: String)

  /// Check if a value exists for a key
  /// - Parameter key: The key to check
  /// - Returns: True if a value exists
  func hasValue(forKey key: String) -> Bool

  /// Get all keys
  /// - Returns: Array of all keys
  func allKeys() -> [String]

  /// Remove all values
  func removeAll()

  /// Get a string value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: String value or nil
  func string(forKey key: String) -> String?

  /// Get an integer value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Integer value or nil
  func integer(forKey key: String) -> Int?

  /// Get a double value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Double value or nil
  func double(forKey key: String) -> Double?

  /// Get a boolean value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Boolean value or nil
  func boolean(forKey key: String) -> Bool?

  /// Get a data value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Data value or nil
  func data(forKey key: String) -> [UInt8]?

  /// Get a URL value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: URL value or nil
  func url(forKey key: String) -> URL?

  /// Get a date value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Date value or nil
  func date(forKey key: String) -> Date?

  /// Get a string array value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: String array value or nil
  func stringArray(forKey key: String) -> [String]?

  /// Get a dictionary value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Dictionary value or nil
  func dictionary(forKey key: String) -> [String: UserDefaultsValueDTO]?

  /// Get an array value for a key
  /// - Parameter key: The key to get the value for
  /// - Returns: Array value or nil
  func array(forKey key: String) -> [UserDefaultsValueDTO]?

  /// Synchronize changes to persistent storage
  /// - Returns: Success or failure
  func synchronize() -> Bool
}
