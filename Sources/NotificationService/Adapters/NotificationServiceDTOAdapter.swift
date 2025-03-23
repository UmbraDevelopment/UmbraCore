import CoreDTOs
import Foundation
import os.log

/// Foundation-independent adapter for notification operations
public class NotificationServiceDTOAdapter: NotificationServiceDTOProtocol {
  // MARK: - Private Properties

  private let notificationCenter: NotificationCenter
  private var observers: [NotificationObserverID: NSObjectProtocol]=[:]
  private let observerQueue=DispatchQueue(
    label: "com.umbra.notificationAdapter.observerQueue",
    attributes: .concurrent
  )
  private let logger=Logger(
    subsystem: "com.umbra.notificationService",
    category: "NotificationServiceDTOAdapter"
  )

  // MARK: - Initialization

  /// Initialize with a specific NotificationCenter
  /// - Parameter notificationCenter: The NotificationCenter to use
  public init(notificationCenter: NotificationCenter = .default) {
    self.notificationCenter=notificationCenter
  }

  // MARK: - NotificationServiceDTOProtocol Implementation

  /// Post a notification
  /// - Parameter notification: The notification to post
  public func post(notification: NotificationDTO) {
    // Convert to Foundation notification
    let foundationNotification=notification.toNotification()

    // Post to notification center
    notificationCenter.post(foundationNotification)
  }

  /// Post a notification with a name
  /// - Parameters:
  ///   - name: The name of the notification
  ///   - sender: The sender of the notification (optional)
  ///   - userInfo: User info dictionary (optional)
  public func post(name: String, sender: AnyHashable?=nil, userInfo: [String: AnyHashable]?=nil) {
    // Create DTO
    let notification=NotificationDTO(
      name: name,
      sender: sender,
      userInfo: userInfo ?? [:]
    )

    // Post notification
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
    sender: AnyHashable?=nil,
    handler: @escaping NotificationHandler
  ) -> NotificationObserverID {
    // Create notification name
    let notificationName=Notification.Name(name)

    // Add observer
    let observer=notificationCenter.addObserver(
      forName: notificationName,
      object: sender,
      queue: .main
    ) { [weak self] notification in
      guard let self else { return }

      // Convert to DTO
      let notificationDTO=NotificationDTO.from(notification: notification)

      // Call handler
      handler(notificationDTO)
    }

    // Generate unique ID
    let observerID=UUID().uuidString

    // Store observer
    observerQueue.async(flags: .barrier) { [weak self] in
      guard let self else { return }
      observers[observerID]=observer
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
    sender: AnyHashable?=nil,
    handler: @escaping NotificationHandler
  ) -> NotificationObserverID {
    // Generate a group ID
    let groupObserverID="group_\(UUID().uuidString)"
    var individualObserverIDs: [NotificationObserverID]=[]

    // Add observer for each name
    for name in names {
      let observer=notificationCenter.addObserver(
        forName: Notification.Name(name),
        object: sender,
        queue: .main
      ) { [weak self] notification in
        guard let self else { return }

        // Convert to DTO
        let notificationDTO=NotificationDTO.from(notification: notification)

        // Call handler
        handler(notificationDTO)
      }

      // Generate unique ID for this individual observer
      let observerID="\(groupObserverID)_\(name)_\(UUID().uuidString)"
      individualObserverIDs.append(observerID)

      // Store observer
      observerQueue.async(flags: .barrier) { [weak self] in
        guard let self else { return }
        observers[observerID]=observer
      }
    }

    // Store the mapping from group ID to individual IDs
    observerQueue.async(flags: .barrier) { [weak self] in
      guard let self else { return }
      let groupInfo=GroupObserverInfo(individualObserverIDs: individualObserverIDs)
      observers[groupObserverID]=groupInfo
    }

    return groupObserverID
  }

  /// Remove an observer
  /// - Parameter observerID: The ID of the observer to remove
  public func removeObserver(withID observerID: NotificationObserverID) {
    observerQueue.async(flags: .barrier) { [weak self] in
      guard let self else { return }

      if let observer=observers[observerID] {
        // Handle different types of observers
        if let notificationObserver=observer as? NSObjectProtocol {
          // Individual observer
          notificationCenter.removeObserver(notificationObserver)
          observers.removeValue(forKey: observerID)
        } else if let groupInfo=observer as? GroupObserverInfo {
          // Group observer - remove all individual observers
          for individualID in groupInfo.individualObserverIDs {
            if let individualObserver=observers[individualID] as? NSObjectProtocol {
              notificationCenter.removeObserver(individualObserver)
              observers.removeValue(forKey: individualID)
            }
          }
          observers.removeValue(forKey: observerID)
        }
      }
    }
  }

  /// Remove all observers
  public func removeAllObservers() {
    observerQueue.async(flags: .barrier) { [weak self] in
      guard let self else { return }

      // Remove all individual observers
      for (_, observer) in observers {
        if let notificationObserver=observer as? NSObjectProtocol {
          notificationCenter.removeObserver(notificationObserver)
        }
      }

      // Clear the dictionary
      observers.removeAll()
    }
  }

  // MARK: - Deinitializer

  deinit {
    removeAllObservers()
  }
}

/// Helper class to store information about a group of observers
private class GroupObserverInfo: NSObject {
  let individualObserverIDs: [NotificationObserverID]

  init(individualObserverIDs: [NotificationObserverID]) {
    self.individualObserverIDs=individualObserverIDs
    super.init()
  }
}
