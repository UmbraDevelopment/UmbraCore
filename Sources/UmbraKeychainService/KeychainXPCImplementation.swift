import Foundation
import UmbraLogging

@objc(KeychainXPCImplementation)
@available(macOS 14.0, *)
final class KeychainXPCImplementation: NSObject, KeychainXPCProtocol {
  /// Simple logger implementation for XPC service
  private final class XPCLogger: LoggingProtocol {
    func debug(_ message: String, metadata: LogMetadata?) async {
      NSLog("DEBUG: \(message) \(metadata?.asDictionary ?? [:])")
    }

    func info(_ message: String, metadata: LogMetadata?) async {
      NSLog("INFO: \(message) \(metadata?.asDictionary ?? [:])")
    }

    func warning(_ message: String, metadata: LogMetadata?) async {
      NSLog("WARNING: \(message) \(metadata?.asDictionary ?? [:])")
    }

    func error(_ message: String, metadata: LogMetadata?) async {
      NSLog("ERROR: \(message) \(metadata?.asDictionary ?? [:])")
    }
  }

  private let keychain: KeychainService
  private let queue=DispatchQueue(label: "com.umbracore.keychain.xpc", qos: .userInitiated)

  override init() {
    // Create keychain service with XPC logger
    keychain=KeychainService(logger: XPCLogger())
    super.init()
  }

  func addItem(
    account: String,
    service: String,
    accessGroup: String?,
    data: Data,
    reply: @escaping @Sendable (Error?) -> Void
  ) {
    // Capture values in local variables to avoid capturing self
    let keychain=keychain
    let queue=queue

    Task { @Sendable in
      do {
        try await keychain.addItem(
          data,
          account: account,
          service: service,
          accessGroup: accessGroup,
          accessibility: kSecAttrAccessibleAfterFirstUnlock,
          flags: []
        )
        queue.async { reply(nil) }
      } catch {
        queue.async { reply(error as? KeychainError ?? KeychainError.unhandledError(status: 0)) }
      }
    }
  }

  func updateItem(
    account: String,
    service: String,
    accessGroup: String?,
    data: Data,
    reply: @escaping @Sendable (Error?) -> Void
  ) {
    let keychain=keychain
    let queue=queue

    Task { @Sendable in
      do {
        try await keychain.updateItem(
          data,
          account: account,
          service: service,
          accessGroup: accessGroup
        )
        queue.async { reply(nil) }
      } catch {
        queue.async { reply(error as? KeychainError ?? KeychainError.unhandledError(status: 0)) }
      }
    }
  }

  func removeItem(
    account: String,
    service: String,
    accessGroup: String?,
    reply: @escaping @Sendable (Error?) -> Void
  ) {
    let keychain=keychain
    let queue=queue

    Task { @Sendable in
      do {
        try await keychain.deleteItem(
          account: account,
          service: service,
          accessGroup: accessGroup
        )
        queue.async { reply(nil) }
      } catch {
        queue.async { reply(error as? KeychainError ?? KeychainError.unhandledError(status: 0)) }
      }
    }
  }

  func containsItem(
    account: String,
    service: String,
    accessGroup: String?,
    reply: @escaping @Sendable (Bool, Error?) -> Void
  ) {
    let keychain=keychain
    let queue=queue

    Task { @Sendable in
      do {
        let exists=await keychain.containsItem(
          account: account,
          service: service,
          accessGroup: accessGroup
        )
        queue.async { reply(exists, nil) }
      } catch {
        queue.async { reply(
          false,
          error as? KeychainError ?? KeychainError.unhandledError(status: 0)
        )
        }
      }
    }
  }

  func retrieveItem(
    account: String,
    service: String,
    accessGroup: String?,
    reply: @escaping @Sendable (Data?, Error?) -> Void
  ) {
    let keychain=keychain
    let queue=queue

    Task { @Sendable in
      do {
        let data=try await keychain.readItem(
          account: account,
          service: service,
          accessGroup: accessGroup
        )
        queue.async { reply(data, nil) }
      } catch {
        queue
          .async { reply(nil, error as? KeychainError ?? KeychainError.unhandledError(status: 0)) }
      }
    }
  }

  func deleteItem(
    account: String,
    service: String,
    accessGroup: String?,
    reply: @escaping @Sendable (Error?) -> Void
  ) {
    let keychain=keychain
    let queue=queue

    Task { @Sendable in
      do {
        try await keychain.deleteItem(
          account: account,
          service: service,
          accessGroup: accessGroup
        )
        queue.async { reply(nil) }
      } catch {
        queue.async { reply(error as? KeychainError ?? KeychainError.unhandledError(status: 0)) }
      }
    }
  }

  func getItem(
    account: String,
    service: String,
    accessGroup: String?,
    reply: @escaping @Sendable (Data?, Error?) -> Void
  ) {
    let keychain=keychain
    let queue=queue

    Task { @Sendable in
      do {
        let data=try await keychain.readItem(
          account: account,
          service: service,
          accessGroup: accessGroup
        )
        queue.async { reply(data, nil) }
      } catch {
        queue
          .async { reply(nil, error as? KeychainError ?? KeychainError.unhandledError(status: 0)) }
      }
    }
  }
}
