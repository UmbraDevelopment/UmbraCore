import CryptoTypes
import Foundation
import LoggingWrapper
import SecurityUtils
import UmbraKeychainService
import UmbraLogging
import UmbraXPC
import XPC
import XPCProtocolsCore

/// XPC listener for the crypto service
///
/// This listener is responsible for accepting XPC connections from clients
/// and creating instances of the CryptoXPCService to handle requests.
@available(macOS 14.0, *)
@objc
public final class CryptoServiceListener: NSObject, NSXPCListenerDelegate {
  /// The XPC listener
  private let listener: NSXPCListener

  /// Dependencies required by the cryptographic service
  private let dependencies: CryptoXPCServiceDependencies

  /// Shared instance
  public static let shared=CryptoServiceListener()

  /// Machservice name for the XPC service
  @objc
  public static var serviceType: NSObjectProtocol.Type? {
    // Use NSProtocolFromString to get the protocol at runtime
    if NSProtocolFromString("ModernCryptoXPCServiceProtocol") == nil {
      return nil
    }
    // This is just to satisfy the API requirement, actual protocol is used differently
    return CryptoXPCService.self as NSObjectProtocol.Type
  }

  /// Initialize a new crypto service listener
  /// - Parameter dependencies: Dependencies required by the service
  private override init() {
    // Initialize dependencies for the XPC service

    // Create keychain service with default logger
    let keychain=UmbraKeychainService(
      identifier: "com.umbracore.xpc.crypto"
    )

    dependencies=DefaultCryptoXPCServiceDependencies(
      securityUtils: SecurityUtils.shared,
      keychain: keychain
    )

    // Use string literal instead of accessing MainActor isolated property
    listener=NSXPCListener(machServiceName: "com.umbracore.xpc.crypto")
    super.init()
    listener.delegate=self
  }

  /// Start the XPC listener
  public func start() {
    Logger.info("Starting CryptoServiceListener")
    listener.resume()
  }

  /// Decide whether to accept a new connection
  /// - Parameter listener: The XPC listener
  /// - Returns: Whether the connection was accepted
  public func listener(
    _: NSXPCListener,
    shouldAcceptNewConnection newConnection: NSXPCConnection
  ) -> Bool {
    Logger.info("Received connection request")

    // Configure the connection
    let interfaceName="ModernCryptoXPCServiceProtocol"
    guard let proto=NSProtocolFromString(interfaceName) else {
      Logger.error("Failed to find protocol: \(interfaceName)")
      return false
    }

    // Create the interface with the protocol
    newConnection.exportedInterface=NSXPCInterface(with: proto)

    // Set the exported object
    let service=CryptoXPCService(dependencies: dependencies)
    newConnection.exportedObject=service

    // Save the connection reference in the service
    service.connection=newConnection

    // Handle invalidation
    newConnection.invalidationHandler={ [weak service] in
      service?.connection=nil
      Logger.info("Connection invalidated")
    }

    // Resume the connection
    newConnection.resume()

    Logger.info("Connection accepted")
    return true
  }
}

/// Simple implementation of LoggingProtocol that forwards to LoggingWrapper.Logger
private final class SimpleLogger: LoggingProtocol, Sendable {
  func debug(_ message: String, metadata _: LogMetadata?) async {
    Logger.debug(message)
  }

  func info(_ message: String, metadata _: LogMetadata?) async {
    Logger.info(message)
  }

  func warning(_ message: String, metadata _: LogMetadata?) async {
    Logger.warning(message)
  }

  func error(_ message: String, metadata _: LogMetadata?) async {
    Logger.error(message)
  }
}

/// Start the XPC service listener
@available(macOS 14.0, *)
public func startService() {
  // Configure the logger
  Logger.configure()

  // Create and start the listener
  let listener=CryptoServiceListener.shared
  listener.start()

  Logger.info("Crypto XPC Service started")

  // Keep the service running
  RunLoop.current.run()
}
