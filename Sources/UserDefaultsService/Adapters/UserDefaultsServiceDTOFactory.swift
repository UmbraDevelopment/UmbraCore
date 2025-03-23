import CoreDTOs
import Foundation

/// Factory for creating UserDefaultsServiceDTOAdapter instances
public enum UserDefaultsServiceDTOFactory {
  /// Create a default UserDefaultsServiceDTOAdapter using standard UserDefaults
  /// - Returns: A configured UserDefaultsServiceDTOAdapter
  public static func createDefault() -> UserDefaultsServiceDTOAdapter {
    UserDefaultsServiceDTOAdapter()
  }

  /// Create a UserDefaultsServiceDTOAdapter with a specific UserDefaults
  /// - Parameter userDefaults: The UserDefaults to use
  /// - Returns: A configured UserDefaultsServiceDTOAdapter
  public static func create(with userDefaults: UserDefaults) -> UserDefaultsServiceDTOAdapter {
    UserDefaultsServiceDTOAdapter(userDefaults: userDefaults)
  }

  /// Create a UserDefaultsServiceDTOAdapter for testing with an isolated UserDefaults
  /// - Parameter suiteName: Suite name for the UserDefaults
  /// - Returns: A UserDefaultsServiceDTOAdapter with isolated UserDefaults
  public static func createForTesting(suiteName: String="com.umbra.testing")
  -> UserDefaultsServiceDTOAdapter? {
    guard let userDefaults=UserDefaults(suiteName: suiteName) else {
      return nil
    }

    return UserDefaultsServiceDTOAdapter(userDefaults: userDefaults)
  }
}
