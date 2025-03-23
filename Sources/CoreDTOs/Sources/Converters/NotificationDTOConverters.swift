import Foundation

/// Extension for converting between Foundation types and NotificationDTO
extension NotificationDTO {
  /// Create a NotificationDTO from a Foundation Notification
  /// - Parameter notification: The Foundation Notification to convert
  /// - Returns: A NotificationDTO representation
  public static func from(notification: Notification) -> NotificationDTO {
    // Convert user info dictionary
    var userInfoDict=[String: String]()
    if let userInfo=notification.userInfo {
      for (key, value) in userInfo {
        if let keyString=key as? String {
          // Convert all values to string representation for Sendable compliance
          userInfoDict[keyString]=String(describing: value)
        }
      }
    }

    // Convert sender to string representation
    let senderString: String?=notification
      .object != nil ? String(describing: notification.object!) : nil

    return NotificationDTO(
      name: notification.name.rawValue,
      sender: senderString,
      userInfo: userInfoDict,
      timestamp: Date().timeIntervalSince1970
    )
  }

  /// Convert to a Foundation Notification
  /// - Returns: A Foundation Notification
  public func toNotification() -> Notification {
    let notificationName=Notification.Name(name)
    // Convert string-based userInfo to proper types if needed
    return Notification(
      name: notificationName,
      object: sender,
      userInfo: userInfo
    )
  }

  /// Create an error notification
  /// - Parameters:
  ///   - title: Error title
  ///   - message: Error message
  ///   - source: Source of the error
  ///   - timestamp: Time when the error occurred
  /// - Returns: Notification with error information
  public static func error(
    title: String,
    message: String,
    source: String,
    timestamp: UInt64
  ) -> NotificationDTO {
    NotificationDTO(
      name: "error_notification",
      sender: source,
      userInfo: [
        "title": title,
        "message": message,
        "type": "error",
        "timestamp": String(timestamp)
      ]
    )
  }

  /// Create an info notification
  /// - Parameters:
  ///   - title: Information title
  ///   - message: Information message
  ///   - source: Source of the information
  ///   - timestamp: Time when the info was generated
  /// - Returns: Notification with information
  public static func info(
    title: String,
    message: String,
    source: String,
    timestamp: UInt64
  ) -> NotificationDTO {
    NotificationDTO(
      name: "info_notification",
      sender: source,
      userInfo: [
        "title": title,
        "message": message,
        "type": "info",
        "timestamp": String(timestamp)
      ]
    )
  }
}
