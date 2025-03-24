import Foundation
@testable import UmbraKeychainService
import XCTest

enum XPCError: Error {
  case serviceNotResponsive
  case serviceNotAvailable
  case connectionFailed
  case invalidServiceType
}

/// Helper class for managing XPC service lifecycle in tests
@available(macOS 10.15, *)
final class XPCServiceHelper {
  private let stateQueue=DispatchQueue(label: "com.umbracore.test.state")
  private static var sharedService: KeychainXPCService?
  private var _connection: NSXPCConnection?

  private var service: KeychainXPCService? {
    get { stateQueue.sync { Self.sharedService } }
    set { stateQueue.sync { Self.sharedService=newValue } }
  }

  private init() {}

  func stop() async {
    _connection?.invalidate()
    _connection=nil
    await service?.stop()
    service=nil
  }

  static func startService() async throws {
    // Clean up any existing service
    let helper=XPCServiceHelper()
    if helper.service != nil {
      await helper.stop()
    }

    // Start new service
    let service=KeychainXPCService()
    helper.service=service
    await service.start()

    // Wait for startup with timeout
    guard service.waitForStartup(timeout: 5.0) else {
      throw XPCError.serviceNotResponsive
    }

    // Verify connection
    _=try await getServiceProxy()
  }

  static func stopService() async {
    let helper=XPCServiceHelper()
    await helper.stop()
  }

  static func getServiceProxy() async throws -> any KeychainXPCProtocol {
    let helper=XPCServiceHelper()
    guard let service=helper.service else {
      throw XPCError.serviceNotAvailable
    }

    // Get the endpoint from the service
    guard let endpoint=await service.getListenerEndpoint() else {
      throw XPCError.serviceNotAvailable
    }

    // Create connection
    let connection=NSXPCConnection(listenerEndpoint: endpoint)
    connection.remoteObjectInterface=NSXPCInterface(with: KeychainXPCProtocol.self)

    // Set up error handler
    return try await withCheckedThrowingContinuation { continuation in
      connection.invalidationHandler={
        continuation.resume(throwing: XPCError.connectionFailed)
      }

      connection.resume()
      helper._connection=connection

      let proxy=connection.remoteObjectProxyWithErrorHandler { error in
        continuation.resume(throwing: error)
      }

      guard let keychainProxy=proxy as? any KeychainXPCProtocol else {
        continuation.resume(throwing: XPCError.invalidServiceType)
        return
      }

      continuation.resume(returning: keychainProxy)
    }
  }

  static func cleanupTestItems() async throws {
    let proxy=try await getServiceProxy()

    // Clean up test accounts
    for index in 0..<10 {
      let account="testAccount_\(index)"
      do {
        try await proxy.removeItem(
          account: account,
          service: "com.umbracore.tests",
          accessGroup: nil as String?
        )
      } catch let error as KeychainError {
        if case .itemNotFound=error {
          // Ignore not found errors during cleanup
          continue
        }
        throw error
      }
    }

    // Clean up main test account
    do {
      try await proxy.removeItem(
        account: "testAccount",
        service: "com.umbracore.tests",
        accessGroup: nil as String?
      )
    } catch let error as KeychainError {
      if case .itemNotFound=error {
        // Ignore not found errors during cleanup
        return
      }
      throw error
    }
  }

  /// Helper function for timeout
  private static func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @escaping () async throws -> T
  ) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
      // Start the operation
      group.addTask {
        try await operation()
      }

      // Start the timeout task
      group.addTask {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        throw TimeoutError(seconds: seconds)
      }

      // Wait for first completion and cancel the other task
      defer { group.cancelAll() }
      let result=try await group.next()
      return try result ?? { throw TimeoutError(seconds: seconds) }()
    }
  }

  // Custom error for timeout
  private struct TimeoutError: LocalizedError {
    let seconds: TimeInterval
    var errorDescription: String? {
      "Operation timed out after \(seconds) seconds"
    }
  }
}
