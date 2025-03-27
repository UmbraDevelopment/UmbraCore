import CoreDTOs
import Foundation

/// Factory for creating NotificationServiceDTOAdapter instances
public enum NotificationServiceDTOFactory {
  /// Create a default NotificationServiceDTOAdapter using the default notification center
  /// - Returns: A configured NotificationServiceDTOAdapter
  public static func createDefault() -> NotificationServiceDTOAdapter {
    NotificationServiceDTOAdapter()
  }

  /// Create a NotificationServiceDTOAdapter with a specific notification center
  /// - Parameter notificationCenter: The notification center to use
  /// - Returns: A configured NotificationServiceDTOAdapter
  public static func create(with notificationCenter: NotificationCenter)
  -> NotificationServiceDTOAdapter {
    NotificationServiceDTOAdapter(notificationCenter: notificationCenter)
  }

  /// Create a NotificationServiceDTOAdapter for testing with an isolated notification center
  /// - Returns: A NotificationServiceDTOAdapter with its own notification center
  public static func createForTesting() -> NotificationServiceDTOAdapter {
    NotificationServiceDTOAdapter(notificationCenter: NotificationCenter())
  }
}
