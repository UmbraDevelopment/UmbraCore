import Foundation

/**
 # KeychainAccessOptions

 Defines access control options for keychain items, determining how and when
 stored items can be accessed.

 This type conforms to `Codable` to support XPC communication and `Sendable` for
 use with Swift concurrency.

 ## Usage

 These options are used when storing items in the keychain to control accessibility:

 ```swift
 // Store a password that's only accessible when the device is unlocked
 try await keychainService.storePassword(
     "securePassword",
     for: "userAccount",
     accessOptions: [.whenUnlocked]
 )

 // Store a password with multiple access restrictions
 try await keychainService.storePassword(
     "securePassword",
     for: "userAccount",
     accessOptions: [.whenUnlocked, .thisDeviceOnly]
 )
 ```
 */
public struct KeychainAccessOptions: OptionSet, Sendable, Codable {
  public let rawValue: UInt

  public init(rawValue: UInt) {
    self.rawValue=rawValue
  }

  /// Item data can only be accessed while the device is unlocked for the current user
  public static let whenUnlocked=KeychainAccessOptions(rawValue: 1 << 0)

  /// Item data can only be accessed once per unlock
  public static let whenPasscodeSetThisDeviceOnly=KeychainAccessOptions(rawValue: 1 << 1)

  /// Item data can only be accessed while the application is in the foreground
  public static let accessibleWhenUnlockedThisDeviceOnly=KeychainAccessOptions(rawValue: 1 << 2)

  /// Item data cannot be synchronised to other devices
  public static let thisDeviceOnly=KeychainAccessOptions(rawValue: 1 << 3)

  /// Default access options (when unlocked, this device only)
  public static let `default`: KeychainAccessOptions=[.whenUnlocked, .thisDeviceOnly]

  /**
   Converts KeychainAccessOptions to the corresponding CFString constant for Security framework

   - Returns: The CFString accessibility constant
   */
  public func toSecurityAccessibility() -> CFString {
    if contains(.whenPasscodeSetThisDeviceOnly) {
      kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
    } else if contains(.accessibleWhenUnlockedThisDeviceOnly) {
      kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    } else if contains([.whenUnlocked, .thisDeviceOnly]) {
      kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    } else if contains(.whenUnlocked) {
      kSecAttrAccessibleAfterFirstUnlock
    } else {
      // Default to most secure option if nothing specific is selected
      kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    }
  }
}
