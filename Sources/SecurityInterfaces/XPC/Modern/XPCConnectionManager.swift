import Foundation

@available(macOS 14.0, *)
public actor XPCConnectionManager {
  /// Dictionary of connections marked as unchecked Sendable because NSXPCConnection is thread-safe
  /// for invalidation operations but doesn't conform to Sendable protocol
  private var connections: [String: NSXPCConnection] = [:]

  /// Nonisolated collection of connections for use in deinit
  /// This is safe because:
  /// 1. NSXPCConnection is thread-safe for invalidation
  /// 2. We're only using this for thread-safe operations in deinit
  private nonisolated let deinitConnectionHandler = DeinitConnectionHandler()

  private let serviceName: String
  private let interfaceProtocol: Protocol

  public init(serviceName: String, interfaceProtocol: Protocol) {
    self.serviceName = serviceName
    self.interfaceProtocol = interfaceProtocol
  }

  public func connection() async throws -> NSXPCConnection {
    if let existingConnection = connections[serviceName] {
      return existingConnection
    }

    return try await createNewConnection()
  }

  private func createNewConnection() async throws -> NSXPCConnection {
    let connection = NSXPCConnection(serviceName: serviceName)

    // Configure the connection
    connection.remoteObjectInterface = NSXPCInterface(with: interfaceProtocol)

    // Set up error handling
    let serviceName = serviceName // Capture in local variable
    let weakSelf = self as XPCConnectionManager? // Capture as optional for weak reference
    connection.invalidationHandler = { [serviceName] in
      // Create a new detached task to avoid potential data races
      Task.detached {
        if let strongSelf = weakSelf {
          await strongSelf.handleInvalidation(for: serviceName)
        }
      }
    }

    connection.interruptionHandler = { [serviceName] in
      // Create a new detached task to avoid potential data races
      Task.detached {
        if let strongSelf = weakSelf {
          await strongSelf.handleInterruption(for: serviceName)
        }
      }
    }

    // Resume the connection
    connection.resume()

    // Store the connection
    connections[serviceName] = connection

    // Also store in our deinit handler
    deinitConnectionHandler.addConnection(connection)

    return connection
  }

  private func handleInvalidation(for serviceName: String) {
    if let connection = connections.removeValue(forKey: serviceName) {
      deinitConnectionHandler.removeConnection(connection)
    }
  }

  private func handleInterruption(for serviceName: String) {
    // Handle interruption - could implement retry logic here
    if let connection = connections.removeValue(forKey: serviceName) {
      deinitConnectionHandler.removeConnection(connection)
    }
  }

  public func invalidateConnection(for serviceName: String) {
    if let connection = connections.removeValue(forKey: serviceName) {
      deinitConnectionHandler.removeConnection(connection)
      connection.invalidate()
    }
  }

  public func invalidateAll() {
    // Take a snapshot of the connections to avoid mutation during iteration
    let connectionsToInvalidate = connections
    connections.removeAll()

    // Update deinit handler
    deinitConnectionHandler.removeAllConnections()

    for connection in connectionsToInvalidate.values {
      connection.invalidate()
    }
  }

  deinit {
    // Note: We can't use async/await in deinit, but NSXPCConnection is thread-safe for invalidation
    // We use the nonisolated DeinitConnectionHandler which is safe for the operations we're
    // performing
    deinitConnectionHandler.invalidateAllConnections()
  }
}

/// Helper class to manage connections for deinit
/// This class is nonisolated and can be safely used in deinit
@available(macOS 14.0, *)
private final class DeinitConnectionHandler: @unchecked Sendable {
  // Using NSMutableSet for thread-safe operations
  private let connections = NSMutableSet()
  private let lock = NSLock()

  func addConnection(_ connection: NSXPCConnection) {
    lock.lock()
    defer { lock.unlock() }
    connections.add(connection)
  }

  func removeConnection(_ connection: NSXPCConnection) {
    lock.lock()
    defer { lock.unlock() }
    connections.remove(connection)
  }

  func removeAllConnections() {
    lock.lock()
    defer { lock.unlock() }
    connections.removeAllObjects()
  }

  func invalidateAllConnections() {
    lock.lock()
    let connectionsCopy = connections.copy() as! NSSet
    connections.removeAllObjects()
    lock.unlock()

    for case let connection as NSXPCConnection in connectionsCopy {
      connection.invalidate()
    }
  }
}
