import Foundation
import UmbraErrors
import UserDefaultsDTOs

/// Protocol defining the UserDefaults service adapter interface.
///
/// This adapter provides a platform-independent way to interact with user defaults
/// across different parts of the UmbraCore system.
public protocol UserDefaultsServiceAdapter {
  /// Retrieve a value from user defaults
  /// - Parameters:
  ///   - key: The key to retrieve
  ///   - namespace: Optional namespace for the key
  /// - Returns: The value as UserDefaultsValueDTO or null if not found
  func getValue(forKey key: String, namespace: String?) -> UserDefaultsValueDTO
  
  /// Set a value in user defaults
  /// - Parameters:
  ///   - value: The value to store
  ///   - key: The key to store under
  ///   - namespace: Optional namespace for the key
  /// - Throws: Error if the operation fails
  func setValue(_ value: UserDefaultsValueDTO, forKey key: String, namespace: String?) throws
  
  /// Remove a value from user defaults
  /// - Parameters:
  ///   - key: The key to remove
  ///   - namespace: Optional namespace for the key
  /// - Throws: Error if the operation fails
  func removeValue(forKey key: String, namespace: String?) throws
  
  /// Check if a value exists in user defaults
  /// - Parameters:
  ///   - key: The key to check
  ///   - namespace: Optional namespace for the key
  /// - Returns: Whether the key exists
  func hasValue(forKey key: String, namespace: String?) -> Bool
  
  /// Get all keys in a namespace
  /// - Parameter namespace: The namespace to check
  /// - Returns: Array of keys in the namespace
  func getKeys(inNamespace namespace: String?) -> [String]
  
  /// Clear all values in a namespace
  /// - Parameter namespace: The namespace to clear
  /// - Throws: Error if the operation fails
  func clearNamespace(_ namespace: String?) throws
  
  /// Synchronise any pending changes to persistent storage
  /// - Throws: Error if the operation fails
  func synchronise() throws
}

/// Factory for creating UserDefaultsServiceAdapter instances
public enum UserDefaultsServiceAdapterFactory {
  /// Create a default UserDefaultsServiceAdapter
  /// - Parameter suiteName: Optional suite name for the defaults database
  /// - Returns: A UserDefaultsServiceAdapter implementation
  public static func createAdapter(suiteName: String? = nil) -> UserDefaultsServiceAdapter {
    // In the migrated version, we return a placeholder implementation
    // that will be properly implemented in a separate module
    return PlaceholderUserDefaultsAdapter(suiteName: suiteName)
  }
}

/// Placeholder implementation of UserDefaultsServiceAdapter
/// This is used temporarily until the proper implementation is migrated
private class PlaceholderUserDefaultsAdapter: UserDefaultsServiceAdapter {
  private let suiteName: String?
  private var storage: [String: Any] = [:]
  
  init(suiteName: String?) {
    self.suiteName = suiteName
  }
  
  func getValue(forKey key: String, namespace: String?) -> UserDefaultsValueDTO {
    let fullKey = makeFullKey(key, namespace: namespace)
    guard let value = storage[fullKey] else {
      return .null
    }
    return UserDefaultsValueDTO.from(value)
  }
  
  func setValue(_ value: UserDefaultsValueDTO, forKey key: String, namespace: String?) throws {
    let fullKey = makeFullKey(key, namespace: namespace)
    
    switch value {
      case .null:
        storage.removeValue(forKey: fullKey)
      default:
        storage[fullKey] = value
    }
  }
  
  func removeValue(forKey key: String, namespace: String?) throws {
    let fullKey = makeFullKey(key, namespace: namespace)
    storage.removeValue(forKey: fullKey)
  }
  
  func hasValue(forKey key: String, namespace: String?) -> Bool {
    let fullKey = makeFullKey(key, namespace: namespace)
    return storage[fullKey] != nil
  }
  
  func getKeys(inNamespace namespace: String?) -> [String] {
    let prefix = namespace.map { "\($0)." } ?? ""
    return storage.keys.compactMap { key in
      guard key.hasPrefix(prefix) else { return nil }
      return String(key.dropFirst(prefix.count))
    }
  }
  
  func clearNamespace(_ namespace: String?) throws {
    let prefix = namespace.map { "\($0)." } ?? ""
    storage = storage.filter { key, _ in !key.hasPrefix(prefix) }
  }
  
  func synchronise() throws {
    // No-op in placeholder implementation
  }
  
  private func makeFullKey(_ key: String, namespace: String?) -> String {
    if let namespace = namespace, !namespace.isEmpty {
      return "\(namespace).\(key)"
    }
    return key
  }
}
