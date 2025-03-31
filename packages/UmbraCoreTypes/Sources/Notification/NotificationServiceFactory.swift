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
  /// The observation actor used for thread-safe operations
  private let observationActor = ObservationActor()
  
  /// The notification center used for posting and observing notifications
  private let notificationCenter: NotificationCenter

  /// Initialise with the default notification center
  init() {
    notificationCenter = NotificationCenter.default
  }

  /// Initialise with a custom notification center
  /// - Parameter notificationCenter: The notification center to use
  init(notificationCenter: NotificationCenter) {
    self.notificationCenter = notificationCenter
  }

  /// Post a notification
  /// - Parameter notification: The notification to post
  public func post(notification: NotificationDTO) {
    let name = Notification.Name(notification.name)
    // Convert [String: String] to [AnyHashable: Any] for NotificationCenter
    let userInfo = notification.userInfo.reduce(into: [AnyHashable: Any]()) { result, pair in
      result[pair.key] = pair.value
    }
    notificationCenter.post(name: name, object: notification.sender, userInfo: userInfo)
  }

  /// Post a notification with a name
  /// - Parameters:
  ///   - name: The name of the notification
  ///   - sender: The sender of the notification (optional)
  ///   - userInfo: User info dictionary (optional)
  public func post(name: String, sender: AnyHashable?, userInfo: [String: AnyHashable]?) {
    let notificationName = Notification.Name(name)
    notificationCenter.post(name: notificationName, object: sender, userInfo: userInfo)
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
    handler: @escaping NotificationHandler
  ) -> NotificationObserverID {
    let notificationName = Notification.Name(name)
    let observerID = UUID().uuidString
    
    let observer = notificationCenter.addObserver(
      forName: notificationName,
      object: sender,
      queue: .main
    ) { [weak self] notification in
      guard let self else { return }
      let dto = createDTO(from: notification)
      handler(dto)
    }

    Task {
      await observationActor.addObserver(observer, forID: observerID)
    }

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
    handler: @escaping NotificationHandler
  ) -> NotificationObserverID {
    let observerID = UUID().uuidString

    Task {
      await observationActor.addMultipleObservers(for: names, baseID: observerID) { name in
        let notificationName = Notification.Name(name)
        let observer = notificationCenter.addObserver(
          forName: notificationName,
          object: sender,
          queue: .main
        ) { [weak self] notification in
          guard let self else { return }
          let dto = createDTO(from: notification)
          handler(dto)
        }
        return observer
      }
    }
    
    return observerID
  }

  /// Remove an observer
  /// - Parameter observerID: The ID of the observer to remove
  public func removeObserver(withID observerID: NotificationObserverID) {
    Task {
      await observationActor.removeObserver(withID: observerID) { observer in
        notificationCenter.removeObserver(observer)
      }
    }
  }

  /// Remove all observers
  public func removeAllObservers() {
    Task {
      await observationActor.removeAllObservers { observer in
        notificationCenter.removeObserver(observer)
      }
    }
  }

  /// Create a NotificationDTO from a Foundation Notification
  /// - Parameter notification: The notification to observe
  /// - Returns: A NotificationDTO representation
  private func createDTO(from notification: Notification) -> NotificationDTO {
    // Convert [AnyHashable: Any]? to [String: String]
    let userInfo = notification.userInfo?
      .reduce(into: [String: String]()) { result, pair in
        if let key = pair.key as? String {
          if let stringValue = pair.value as? String {
            result[key] = stringValue
          } else {
            result[key] = "\(pair.value)"
          }
        }
      } ?? [:]

    return NotificationDTO(
      name: notification.name.rawValue,
      sender: (notification.object as? String) ?? "unknown",
      userInfo: userInfo
    )
  }
}

/// Actor for managing notification observers in a thread-safe manner
private actor ObservationActor {
  /// Dictionary mapping observer IDs to observer objects
  private var observers: [NotificationObserverID: NSObjectProtocol] = [:]
  
  /// Add an observer with the given ID
  /// - Parameters:
  ///   - observer: The observer object
  ///   - id: The ID to associate with the observer
  func addObserver(_ observer: NSObjectProtocol, forID id: NotificationObserverID) {
    observers[id] = observer
  }
  
  /// Add multiple observers for different notification names but with a base ID
  /// - Parameters:
  ///   - names: Notification names to observe
  ///   - baseID: The base ID to use (will be combined with notification name)
  ///   - createObserver: A closure that creates an observer for a given name
  func addMultipleObservers(
    for names: [String], 
    baseID: String,
    createObserver: (String) -> NSObjectProtocol
  ) {
    for name in names {
      let observer = createObserver(name)
      // Store each individual observer with a compound ID
      let compoundID = "\(baseID):\(name)"
      observers[compoundID] = observer
    }
  }
  
  /// Remove an observer with the given ID
  /// - Parameters:
  ///   - id: The ID of the observer to remove
  ///   - cleanup: A closure that performs any cleanup needed for the observer
  func removeObserver(
    withID id: NotificationObserverID,
    cleanup: (NSObjectProtocol) -> Void
  ) {
    // Check for compound IDs (from multi-notification observers)
    let compoundPrefix = "\(id):"
    let keysToRemove = observers.keys.filter {
      $0 == id || $0.hasPrefix(compoundPrefix)
    }
    
    for key in keysToRemove {
      if let observer = observers[key] {
        cleanup(observer)
        observers.removeValue(forKey: key)
      }
    }
  }
  
  /// Remove all observers
  /// - Parameter cleanup: A closure that performs any cleanup needed for each observer
  func removeAllObservers(cleanup: (NSObjectProtocol) -> Void) {
    for (_, observer) in observers {
      cleanup(observer)
    }
    observers.removeAll()
  }
}
