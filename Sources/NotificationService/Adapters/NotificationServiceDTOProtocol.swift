import CoreDTOs
import Foundation

/// Observer ID type for notification observers
public typealias NotificationObserverID=String

/// Notification handler type
public typealias NotificationHandler=(NotificationDTO) -> Void

/// Protocol defining a Foundation-independent interface for notification operations
public protocol NotificationServiceDTOProtocol: Sendable {
  /// Post a notification
  /// - Parameter notification: The notification to post
  func post(notification: NotificationDTO)

  /// Post a notification with a name
  /// - Parameters:
  ///   - name: The name of the notification
  ///   - sender: The sender of the notification (optional)
  ///   - userInfo: User info dictionary (optional)
  func post(name: String, sender: AnyHashable?, userInfo: [String: AnyHashable]?)

  /// Add an observer for a specific notification
  /// - Parameters:
  ///   - name: The name of the notification to observe
  ///   - sender: The sender to filter by (optional)
  ///   - handler: The handler to call when the notification is received
  /// - Returns: An observer ID that can be used to remove the observer
  func addObserver(
    for name: String,
    sender: AnyHashable?,
    handler: @escaping NotificationHandler
  ) -> NotificationObserverID

  /// Add an observer for multiple notifications
  /// - Parameters:
  ///   - names: Array of notification names to observe
  ///   - sender: The sender to filter by (optional)
  ///   - handler: The handler to call when any of the notifications is received
  /// - Returns: An observer ID that can be used to remove the observer
  func addObserver(
    for names: [String],
    sender: AnyHashable?,
    handler: @escaping NotificationHandler
  ) -> NotificationObserverID

  /// Remove an observer
  /// - Parameter observerID: The ID of the observer to remove
  func removeObserver(withID observerID: NotificationObserverID)

  /// Remove all observers
  func removeAllObservers()
}
