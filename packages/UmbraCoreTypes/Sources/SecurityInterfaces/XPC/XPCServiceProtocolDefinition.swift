import Foundation
import UmbraErrors
import SecurityTypes

// MARK: - Migration Note for XPC Protocol Consolidation

/**
 This file defines the protocol for the legacy XPC service implementation.
 
 As part of the Alpha Dot Five architecture migration, XPC protocol definitions
 are being consolidated into the XPCProtocolsCore module. This file provides
 compatibility shims to allow existing code to continue working during the migration.
 
 - Note: New code should use the ModernXPCService protocol defined in XPCProtocolsCore instead.
 */

/// Protocol definition for the legacy XPC service
@objc public protocol XPCServiceProtocolDefinition {
  
  /// Synchronise keys between devices
  /// - Parameters:
  ///   - data: Key data to synchronise
  ///   - reply: Completion handler with optional error
  @objc func synchroniseKeys(_ data: NSData, withReply reply: @escaping (Error?) -> Void)
  
  /// Get the current version of the XPC service
  /// - Parameter reply: Completion handler with version string and optional error
  @objc func getVersion(withReply reply: @escaping (NSString?, Error?) -> Void)
  
  /// Get the host device identifier
  /// - Parameter reply: Completion handler with identifier string and optional error
  @objc func getHostIdentifier(withReply reply: @escaping (NSString?, Error?) -> Void)
  
  /// Register a client with the XPC service
  /// - Parameters:
  ///   - clientID: Client identifier
  ///   - reply: Completion handler with success flag and optional error
  @objc func registerClient(clientID: NSString, withReply reply: @escaping (Bool, Error?) -> Void)
  
  /// Deregister a client from the XPC service
  /// - Parameters:
  ///   - clientID: Client identifier
  ///   - reply: Completion handler with success flag and optional error
  @objc func deregisterClient(clientID: NSString, withReply reply: @escaping (Bool, Error?) -> Void)
}

/// Factory for creating XPC service protocol definition implementations
public enum XPCServiceProtocolDefinitionFactory {
  /// Create the default implementation of the XPC service protocol definition
  /// - Returns: An object conforming to XPCServiceProtocolDefinition
  public static func createDefaultImplementation() -> XPCServiceProtocolDefinition {
    return XPCServiceProtocolDefinitionImpl.shared
  }
}

/// Default implementation of the XPC service protocol definition
public class XPCServiceProtocolDefinitionImpl: NSObject, XPCServiceProtocolDefinition {

  /// Protocol identifier for XPC service registration
  public static var protocolIdentifier: String {
    "com.umbra.xpc.service.protocol"
  }
  
  /// Shared singleton instance
  public static let shared = XPCServiceProtocolDefinitionImpl()
  
  private override init() {
    super.init()
  }

  // MARK: - XPCServiceProtocolDefinition Implementation
  
  public func synchroniseKeys(_ data: NSData, withReply reply: @escaping (Error?) -> Void) {
    // For the migrated version, we'll simply return a not implemented error
    // as clients should be using the new XPCProtocolsCore module
    let error = NSError(domain: "com.umbra.security", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Method deprecated, use ModernXPCService instead"])
    reply(error)
  }
  
  public func getVersion(withReply reply: @escaping (NSString?, Error?) -> Void) {
    reply("Legacy.1.0.0" as NSString, nil)
  }
  
  public func getHostIdentifier(withReply reply: @escaping (NSString?, Error?) -> Void) {
    let error = NSError(domain: "com.umbra.security", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Method deprecated, use ModernXPCService instead"])
    reply(nil, error)
  }
  
  public func registerClient(clientID: NSString, withReply reply: @escaping (Bool, Error?) -> Void) {
    let error = NSError(domain: "com.umbra.security", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Method deprecated, use ModernXPCService instead"])
    reply(false, error)
  }
  
  public func deregisterClient(clientID: NSString, withReply reply: @escaping (Bool, Error?) -> Void) {
    let error = NSError(domain: "com.umbra.security", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Method deprecated, use ModernXPCService instead"])
    reply(false, error)
  }
}
