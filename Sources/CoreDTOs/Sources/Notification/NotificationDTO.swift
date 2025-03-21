import Foundation

/// A Foundation-independent representation of a notification.
///
/// `NotificationDTO` provides a clean, Foundation-free way to work with notifications
/// across your application. It encapsulates the core components of a notification:
/// name, sender, user info dictionary, and timestamp.
///
/// ## Overview
/// This struct offers:
/// - A consistent interface for working with notifications
/// - Type-safe accessors for common user info value types
/// - Methods for creating modified notifications
/// - Foundation independence for improved portability
///
/// ## Example Usage
/// ```swift
/// // Create a notification
/// let notification = NotificationDTO(
///     name: "UserLoggedIn",
///     sender: "AuthenticationService",
///     userInfo: ["userId": "12345", "isNewUser": true]
/// )
///
/// // Access user info values
/// if let userId = notification.stringValue(for: "userId"),
///    let isNewUser = notification.boolValue(for: "isNewUser") {
///     // Use the extracted values
/// }
///
/// // Create a modified notification
/// let enrichedNotification = notification.withAdditionalUserInfo([
///     "loginTime": Date().timeIntervalSince1970
/// ])
/// ```
public struct NotificationDTO: Sendable, Equatable, Hashable {
    // MARK: - Properties
    
    /// Name of the notification.
    ///
    /// A string identifier that uniquely identifies the purpose or type of this notification.
    public let name: String
    
    /// Object that posted the notification.
    ///
    /// An optional reference to the sender of the notification, which can be used
    /// for filtering notifications by source.
    public let sender: AnyHashable?
    
    /// User info dictionary.
    ///
    /// A dictionary containing additional data associated with the notification.
    /// Keys are strings and values must conform to AnyHashable.
    public let userInfo: [String: AnyHashable]
    
    /// Timestamp when the notification was posted (seconds since 1970).
    ///
    /// Records when the notification was created, using the standard Unix timestamp format.
    public let timestamp: Double
    
    // MARK: - Initialization
    
    /// Initialize a notification with specified values.
    ///
    /// - Parameters:
    ///   - name: Name of the notification
    ///   - sender: Object that posted the notification, defaults to nil
    ///   - userInfo: User info dictionary, defaults to empty dictionary
    ///   - timestamp: Timestamp when the notification was posted, defaults to current time
    ///
    /// Creates a new notification with the given parameters. If no timestamp is provided,
    /// the current time is used automatically.
    public init(
        name: String,
        sender: AnyHashable? = nil,
        userInfo: [String: AnyHashable] = [:],
        timestamp: Double = Date().timeIntervalSince1970
    ) {
        self.name = name
        self.sender = sender
        self.userInfo = userInfo
        self.timestamp = timestamp
    }
    
    // MARK: - Accessing User Info
    
    /// Get a value from user info as a specific type.
    ///
    /// - Parameters:
    ///   - key: Key to look up
    ///   - type: Expected type
    /// - Returns: Value of the specified type or nil if not found or wrong type
    ///
    /// This is a generic method that allows you to extract values of any type from
    /// the user info dictionary, with automatic type casting.
    public func userInfoValue<T>(for key: String, as type: T.Type) -> T? {
        return userInfo[key] as? T
    }
    
    /// Get a string value from user info.
    ///
    /// - Parameter key: Key to look up
    /// - Returns: String value or nil if not found or wrong type
    public func stringValue(for key: String) -> String? {
        return userInfoValue(for: key, as: String.self)
    }
    
    /// Get an integer value from user info.
    ///
    /// - Parameter key: Key to look up
    /// - Returns: Integer value or nil if not found or wrong type
    public func intValue(for key: String) -> Int? {
        return userInfoValue(for: key, as: Int.self)
    }
    
    /// Get a double value from user info.
    ///
    /// - Parameter key: Key to look up
    /// - Returns: Double value or nil if not found or wrong type
    public func doubleValue(for key: String) -> Double? {
        return userInfoValue(for: key, as: Double.self)
    }
    
    /// Get a boolean value from user info.
    ///
    /// - Parameter key: Key to look up
    /// - Returns: Boolean value or nil if not found or wrong type
    public func boolValue(for key: String) -> Bool? {
        return userInfoValue(for: key, as: Bool.self)
    }
    
    /// Get a date value from user info.
    ///
    /// - Parameter key: Key to look up
    /// - Returns: Date value or nil if not found or wrong type
    public func dateValue(for key: String) -> Date? {
        return userInfoValue(for: key, as: Date.self)
    }
    
    /// Get a data value from user info.
    ///
    /// - Parameter key: Key to look up
    /// - Returns: Data value as byte array or nil if not found or wrong type
    ///
    /// This method can extract data either from a Foundation Data object or
    /// from a raw byte array.
    public func dataValue(for key: String) -> [UInt8]? {
        if let data = userInfoValue(for: key, as: Data.self) {
            return [UInt8](data)
        } else if let bytes = userInfoValue(for: key, as: [UInt8].self) {
            return bytes
        }
        return nil
    }
    
    // MARK: - Creating Modified Notifications
    
    /// Create a copy with additional user info.
    ///
    /// - Parameter additionalInfo: Additional user info to add
    /// - Returns: New notification with combined user info
    ///
    /// This method creates a new notification with the same properties as the original,
    /// but with additional key-value pairs in the user info dictionary. If there are
    /// duplicate keys, the values from `additionalInfo` will override the original values.
    public func withAdditionalUserInfo(_ additionalInfo: [String: AnyHashable]) -> NotificationDTO {
        var newUserInfo = userInfo
        for (key, value) in additionalInfo {
            newUserInfo[key] = value
        }
        
        return NotificationDTO(
            name: name,
            sender: sender,
            userInfo: newUserInfo,
            timestamp: timestamp
        )
    }
}
