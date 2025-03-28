import Foundation

/// Factory for creating notification service implementations
public enum NotificationServiceFactory {
  /// Create the default notification service implementation
  /// - Returns: An object conforming to the NotificationServiceProtocol
  public static func createDefaultService() -> NotificationServiceProtocol {
    DefaultNotificationService()
  }

  /// Create a notification service with a custom notification center
  /// - Parameter notificationCenter: The notification center to use
  /// - Returns: An object conforming to the NotificationServiceProtocol
  public static func createService(with notificationCenter: NotificationCenter)
  -> NotificationServiceProtocol {
    DefaultNotificationService(notificationCenter: notificationCenter)
  }
}

/// Default implementation of the NotificationServiceProtocol using Foundation's NotificationCenter
private final class DefaultNotificationService: NotificationServiceProtocol {
  /// The notification center used for posting and observing notifications
  private let notificationCenter: NotificationCenter
  /// Lock for thread-safe operations on observers
  private let lock=NSLock()
  /// Dictionary of observer IDs to observer objects
  private var observers: [NotificationObserverID: NSObjectProtocol]=[:]

  /// Initialise with the default notification center
  init() {
    notificationCenter=NotificationCenter.default
  }

  /// Initialise with a custom notification center
  /// - Parameter notificationCenter: The notification center to use
  init(notificationCenter: NotificationCenter) {
    self.notificationCenter=notificationCenter
  }

  /// Post a notification
  /// - Parameter notification: The notification to post
  public func post(notification: NotificationDTO) {
    let name=Notification.Name(notification.name)
    // Convert [String: String] to [AnyHashable: Any] for NotificationCenter
    let userInfo=notification.userInfo.reduce(into: [AnyHashable: Any]()) { result, pair in
      result[pair.key]=pair.value
    }
    notificationCenter.post(name: name, object: notification.sender, userInfo: userInfo)
  }

  /// Post a notification with a name
  /// - Parameters:
  ///   - name: The name of the notification
  ///   - sender: The sender of the notification (optional)
  ///   - userInfo: User info dictionary (optional)
  public func post(name: String, sender: AnyHashable?, userInfo: [String: AnyHashable]?) {
    // Convert [String: AnyHashable] to [String: String] for NotificationDTO
    let stringUserInfo=userInfo?.reduce(into: [String: String]()) { result, pair in
      result[pair.key]=String(describing: pair.value)
    } ?? [:]

    let notification=NotificationDTO(
      name: name,
      sender: sender as? String,
      userInfo: stringUserInfo,
      timestamp: Date().timeIntervalSince1970
    )
    post(notification: notification)
  }

  /// Add an observer for a specific notification
  /// - Parameters:
  ///   - name: The name of the notification to observe
  ///   - sender: The sender to filter by (optional)
  ///   - handler: The handler to call when the notification is received
  /// - Returns: An observer ID that can be used to remove the observer
  public func addObserver(
    for name: String,
    sender: AnyHashable?,
    handler: @escaping @Sendable NotificationHandler
  ) -> NotificationObserverID {
    let observerID=UUID().uuidString
    let name=Notification.Name(name)
    let observer=notificationCenter.addObserver(
      forName: name,
      object: sender,
      queue: .main
    ) { [weak self] notification in
      guard let self else { return }
      let dto=createDTO(from: notification)
      handler(dto)
    }

    lock.lock()
    observers[observerID]=observer
    lock.unlock()

    return observerID
  }

  /// Add an observer for multiple notifications
  /// - Parameters:
  ///   - names: Array of notification names to observe
  ///   - sender: The sender to filter by (optional)
  ///   - handler: The handler to call when any of the notifications is received
  /// - Returns: An observer ID that can be used to remove the observer
  public func addObserver(
    for names: [String],
    sender: AnyHashable?,
    handler: @escaping @Sendable NotificationHandler
  ) -> NotificationObserverID {
    let observerID=UUID().uuidString

    lock.lock()
    for name in names {
      let notificationName=Notification.Name(name)
      let observer=notificationCenter.addObserver(
        forName: notificationName,
        object: sender,
        queue: .main
      ) { [weak self] notification in
        guard let self else { return }
        let dto=createDTO(from: notification)
        handler(dto)
      }

      // Store each individual observer with a compound ID
      let compoundID="\(observerID):\(name)"
      observers[compoundID]=observer
    }
    lock.unlock()

    return observerID
  }

  /// Remove an observer
  /// - Parameter observerID: The ID of the observer to remove
  public func removeObserver(withID observerID: NotificationObserverID) {
    lock.lock()
    defer { lock.unlock() }

    // Check for compound IDs (from multi-notification observers)
    let compoundPrefix="\(observerID):"
    let keysToRemove=observers.keys.filter {
      $0 == observerID || $0.hasPrefix(compoundPrefix)
    }

    for key in keysToRemove {
      if let observer=observers[key] {
        notificationCenter.removeObserver(observer)
        observers.removeValue(forKey: key)
      }
    }
  }

  /// Remove all observers
  public func removeAllObservers() {
    lock.lock()
    defer { lock.unlock() }

    for (_, observer) in observers {
      notificationCenter.removeObserver(observer)
    }
    observers.removeAll()
  }

  /// Create a NotificationDTO from a Foundation Notification
  /// - Parameter notification: The Foundation Notification
  /// - Returns: A NotificationDTO representation
  private func createDTO(from notification: Notification) -> NotificationDTO {
    // Convert [AnyHashable: Any]? to [String: String]
    let userInfo=(notification.userInfo as? [AnyHashable: Any])?
      .reduce(into: [String: String]()) { result, pair in
        if let key=pair.key as? String {
          result[key]=String(describing: pair.value)
        }
      } ?? [:]

    return NotificationDTO(
      name: notification.name.rawValue,
      sender: notification.object as? String,
      userInfo: userInfo,
      timestamp: Date().timeIntervalSince1970
    )
  }
}
