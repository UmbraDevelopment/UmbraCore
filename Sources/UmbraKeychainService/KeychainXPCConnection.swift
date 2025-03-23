import Foundation

@available(macOS 14.0, *)
final class KeychainXPCConnection: @unchecked Sendable {
  // Using actor to make this thread-safe
  private actor ConnectionState {
    var connection: NSXPCConnection?
    var isInvalidated=false

    func setConnection(_ newConnection: NSXPCConnection?) {
      connection=newConnection
    }

    func getConnection() -> NSXPCConnection? {
      connection
    }

    func invalidate() {
      isInvalidated=true
      connection?.invalidate()
      connection=nil
    }

    func isInvalidatedState() -> Bool {
      isInvalidated
    }

    // Add a synchronized proxy retrieval method to isolate non-Sendable types
    func getProxyFromConnection() -> (any KeychainXPCProtocol)? {
      guard let connection else { return nil }

      return connection.remoteObjectProxyWithErrorHandler { error in
        print("XPC connection error: \(error)")
        // Invalidate directly from within the actor
        self.invalidate()
      } as? any KeychainXPCProtocol
    }
  }

  private let state=ConnectionState()
  private let queue=DispatchQueue(
    label: "com.umbracore.keychain.connection",
    qos: .userInitiated
  )
  private let listener: NSXPCListener?

  init(listener: NSXPCListener?=nil) {
    self.listener=listener
  }

  func connect() async throws -> any KeychainXPCProtocol {
    // Replace semaphore with Task-based synchronization
    try await Task { () -> any KeychainXPCProtocol in
      // Check if connection was invalidated
      if await state.isInvalidatedState() {
        throw NSError(domain: "com.umbracore.keychain", code: -1, userInfo: [
          NSLocalizedDescriptionKey: "Connection was invalidated"
        ])
      }

      // Try to get proxy from existing connection
      if let proxy=await state.getProxyFromConnection() {
        return proxy
      }

      // Create new connection
      let newConnection: NSXPCConnection
      if listener != nil {
        // No connection for listener mode
        throw NSError(domain: "com.umbracore.keychain", code: -1, userInfo: [
          NSLocalizedDescriptionKey: "Cannot connect in listener mode"
        ])
      } else {
        // Create connection to service
        newConnection=NSXPCConnection(serviceName: "com.umbracore.keychain")
      }

      newConnection.remoteObjectInterface=NSXPCInterface(with: KeychainXPCProtocol.self)
      newConnection.invalidationHandler={ [weak self] in
        Task { [weak self] in
          if let self {
            await state.invalidate()
          }
        }
      }
      newConnection.resume()

      // Store connection
      await state.setConnection(newConnection)

      // Get proxy using the actor-isolated method
      guard let proxy=await state.getProxyFromConnection() else {
        throw NSError(domain: "com.umbracore.keychain", code: -1, userInfo: [
          NSLocalizedDescriptionKey: "Failed to get remote proxy"
        ])
      }

      return proxy
    }.value
  }

  func invalidate() {
    Task {
      await state.invalidate()
    }
  }
}

// MARK: - KeychainXPCProtocol Implementation

extension KeychainXPCConnection: KeychainXPCProtocol {
  func addItem(
    account _: String,
    service _: String,
    accessGroup _: String?,
    data _: Data,
    reply: @escaping @Sendable (Error?) -> Void
  ) {
    // Implementation
    reply(NSError(domain: "com.umbracore.keychain", code: -1, userInfo: [
      NSLocalizedDescriptionKey: "Not implemented"
    ]))
  }

  func updateItem(
    account _: String,
    service _: String,
    accessGroup _: String?,
    data _: Data,
    reply: @escaping @Sendable (Error?) -> Void
  ) {
    // Implementation
    reply(NSError(domain: "com.umbracore.keychain", code: -1, userInfo: [
      NSLocalizedDescriptionKey: "Not implemented"
    ]))
  }

  func getItem(
    account _: String,
    service _: String,
    accessGroup _: String?,
    reply: @escaping @Sendable (Data?, Error?) -> Void
  ) {
    // Implementation
    reply(nil, NSError(domain: "com.umbracore.keychain", code: -1, userInfo: [
      NSLocalizedDescriptionKey: "Not implemented"
    ]))
  }

  func deleteItem(
    account _: String,
    service _: String,
    accessGroup _: String?,
    reply: @escaping @Sendable (Error?) -> Void
  ) {
    // Implementation
    reply(NSError(domain: "com.umbracore.keychain", code: -1, userInfo: [
      NSLocalizedDescriptionKey: "Not implemented"
    ]))
  }
}
