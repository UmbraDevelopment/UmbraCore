@preconcurrency import Foundation

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
  private let observationActor=ObservationActor()

  /// The notification center used for posting and observing notifications
  private let notificationCenter: NotificationCenter

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
    let notificationName=Notification.Name(name)
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
    let notificationName=Notification.Name(name)
    let observerID=UUID().uuidString

    // Convert to immutable copies for thread safety
    let senderCopy=sender

    // Create observer in a thread-safe manner
    let observer=notificationCenter.addObserver(
      forName: notificationName,
      object: senderCopy,
      queue: .main
    ) { [weak self] notification in
      guard let self else { return }
      // Use nonisolated helper to prevent actor isolation warnings
      let dto=createDTO(from: notification)
      handler(dto)
    }

    // Safely send observer to actor using a detached task to avoid data races
    // with the non-Sendable NSObjectProtocol observer
    let observerCopy=observer // Make a local copy of the observer
    Task.detached { [observationActor, observerID] in
      await observationActor.storeObserver(observerCopy, forID: observerID)
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
    let observerID=UUID().uuidString
    let names=names // Create immutable copy
    let senderCopy=sender // Create immutable copy

    // Create and store observers in a thread-safe manner
    for name in names {
      // Create a unique ID for each observer to ensure proper cleanup
      let uniqueID="\(observerID):\(name)"

      let notificationName=Notification.Name(name)
      let observer=notificationCenter.addObserver(
        forName: notificationName,
        object: senderCopy,
        queue: .main
      ) { [weak self] notification in
        guard let self else { return }
        // Use nonisolated helper to prevent actor isolation warnings
        let dto=createDTO(from: notification)
        handler(dto)
      }

      // Safely store each observer with its unique ID
      Task { [observationActor] in
        await observationActor.storeObserver(observer, forID: uniqueID)
      }
    }

    return observerID
  }

  /// Remove an observer
  /// - Parameter observerID: The ID of the observer to remove
  public func removeObserver(withID observerID: NotificationObserverID) {
    // Use a detached task to avoid data races with the non-Sendable NSObjectProtocol
    Task.detached { [weak self, observationActor, notificationCenter, observerID] in
      guard let _=self else { return }
      // Use structured concurrency to properly isolate the non-Sendable observers
      let observers=await observationActor.removeObservers(withIDPrefix: observerID)
      // Process observers within the isolated task
      for observer in observers {
        notificationCenter.removeObserver(observer)
      }
    }
  }

  /// Remove all observers
  public func removeAllObservers() {
    // Use a detached task to avoid data races with the non-Sendable NSObjectProtocol
    Task.detached { [weak self, observationActor, notificationCenter] in
      guard let _=self else { return }
      // Use structured concurrency to properly isolate the non-Sendable observers
      let observers=await observationActor.removeAllObservers()
      // Process observers within the isolated task
      for observer in observers {
        notificationCenter.removeObserver(observer)
      }
    }
  }

  /// Create a NotificationDTO from a Foundation Notification
  /// - Parameter notification: The notification to observe
  /// - Returns: A NotificationDTO representation
  private nonisolated func createDTO(from notification: Notification) -> NotificationDTO {
    // Convert [AnyHashable: Any]? to [String: String]
    let userInfo=notification.userInfo?
      .reduce(into: [String: String]()) { result, pair in
        if let key=pair.key as? String {
          if let stringValue=pair.value as? String {
            result[key]=stringValue
          } else {
            result[key]="\(pair.value)"
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
  private var observers: [NotificationObserverID: NSObjectProtocol]=[:]

  /// Store an observer with the given ID
  /// - Parameters:
  ///   - observer: The observer object
  ///   - id: The ID to associate with the observer
  func storeObserver(_ observer: NSObjectProtocol, forID id: NotificationObserverID) {
    observers[id]=observer
  }

  /// Remove observers with the given ID prefix
  /// - Parameter idPrefix: The ID prefix to match
  /// - Returns: Array of removed observers
  func removeObservers(withIDPrefix idPrefix: String) -> [NSObjectProtocol] {
    var removedObservers: [NSObjectProtocol]=[]

    // Find all keys that match the ID exactly or have it as a prefix
    let keysToRemove=observers.keys.filter {
      $0 == idPrefix || $0.hasPrefix("\(idPrefix):")
    }

    // Remove each matching observer and collect them
    for key in keysToRemove {
      if let observer=observers[key] {
        removedObservers.append(observer)
        observers.removeValue(forKey: key)
      }
    }

    return removedObservers
  }

  /// Remove all observers
  /// - Returns: Array of all removed observers
  func removeAllObservers() -> [NSObjectProtocol] {
    let allObservers=observers.values.map { $0 }
    observers.removeAll()
    return allObservers
  }
}
