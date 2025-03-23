import CoreErrors
import ErrorHandlingDomains
import Foundation
import XPCProtocolsCore

/// Custom error for Foundation bridging that doesn't require direct NSError use
public enum FoundationBridgingError: Error, Sendable {
  /// Invalid data format
  case invalidDataFormat(details: String)

  /// Failed to convert data
  case conversionFailed(details: String)

  /// Service connection error
  case serviceConnectionFailed(details: String)

  /// Implementation missing
  case implementationMissing(String)
}

/// Protocol for XPC services in ObjCBridgingTypesFoundation that depends on Foundation
/// This is a standalone protocol that doesn't try to bridge to CoreTypes directly
///
/// **Migration Notice:**
/// This protocol is deprecated and will be removed in a future release.
/// Please use `XPCServiceProtocolBasic` from the XPCProtocolsCore module instead.
///
/// Migration steps:
/// 1. Replace implementations of XPCServiceProtocolBaseFoundation with XPCServiceProtocolBasic
/// 2. Use XPCProtocolMigrationFactory.createBasicAdapter() to create a service instance
/// 3. Update client code to use async/await patterns with proper error handling
///
/// See `XPCProtocolMigrationGuide` in XPCProtocolsCore for comprehensive migration guidance.
@available(*, deprecated, message: "Use XPCServiceProtocolBasic from XPCProtocolsCore instead")
@objc
public protocol XPCServiceProtocolBaseFoundation: NSObjectProtocol {
  /// Protocol identifier - used for protocol negotiation
  @objc
  static var protocolIdentifier: String { get }

  /// Base method to test connectivity
  @objc
  func ping(withReply reply: @escaping (Bool, Error?) -> Void)

  /// Raw method for synchronising keys with Foundation.Data
  @objc
  optional func synchroniseKeys(_ data: Any, withReply reply: @escaping (Error?) -> Void)
}

/// Default implementation for XPCServiceProtocolBaseFoundation
@available(*, deprecated, message: "Use XPCServiceProtocolBasic from XPCProtocolsCore instead")
extension XPCServiceProtocolBaseFoundation {
  /// Default protocol identifier - must be implemented by concrete types
  public static var protocolIdentifierDefault: String {
    "com.umbra.xpc.service.protocol.base.foundation"
  }

  /// Raw implementation for synchronising keys
  public var synchroniseKeysRaw: ((Any, @escaping (Error?) -> Void) -> Void)? {
    self.synchroniseKeys(_:withReply:)
  }

  /// Async ping implementation
  public func ping() async -> Result<Bool, CoreErrors.XPCErrors.SecurityError> {
    await withCheckedContinuation { continuation in
      ping { success, error in
        if let error=error as? CoreErrors.XPCErrors.SecurityError {
          continuation.resume(returning: .failure(error))
        } else if let error {
          continuation
            .resume(returning: .failure(.internalError(description: error.localizedDescription)))
        } else {
          continuation.resume(returning: .success(success))
        }
      }
    }
  }

  /// Async implementation for synchronising keys with byte array
  public func synchroniseKeys(_ bytes: [UInt8]) async throws {
    let data=Data(bytes) as NSData

    return try await withCheckedThrowingContinuation { continuation in
      guard let synchroniseKeysRaw=self.synchroniseKeysRaw else {
        continuation
          .resume(
            throwing: FoundationBridgingError
              .implementationMissing("synchroniseKeys not implemented")
          )
        return
      }

      synchroniseKeysRaw(data) { error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: ())
        }
      }
    }
  }

  /// Convert this legacy service to a modern XPCServiceProtocolBasic
  ///
  /// This helper method simplifies the migration from legacy to modern protocols
  ///
  /// Example:
  /// ```swift
  /// // Legacy code:
  /// let legacyService: XPCServiceProtocolBaseFoundation = getLegacyService()
  ///
  /// // Migration:
  /// let modernService = legacyService.asModernXPCService()
  /// ```
  public func asModernXPCService() -> any XPCServiceProtocolBasic {
    // Use the migration factory to create a properly wrapped service
    XPCProtocolMigrationFactory.createBasicAdapter()
  }
}

// MARK: - Migration Guide

/// Provides information about migrating from Foundation bridging types to XPCProtocolsCore
public enum XPCServiceFoundationMigrationGuide {
  /// Returns a comprehensive guide to migrating from Foundation-based protocols to XPCProtocolsCore
  public static var migrationSteps: String {
    """
    # ObjC Bridging Types Foundation Migration Guide

    ## Overview

    This guide provides steps to migrate from Foundation-based ObjC bridging protocols to the modern
    XPCProtocolsCore protocol hierarchy.

    ## Migration Steps

    1. Replace implementations of `XPCServiceProtocolBaseFoundation` with
       `XPCServiceProtocolBasic` from XPCProtocolsCore.

    2. For existing services:
       ```swift
       // Instead of:
       let service = myLegacyService

       // Use:
       let modernService = service.asModernXPCService()
       ```

    3. For creating new services:
       ```swift
       // Instead of creating Foundation-based services:
       // let service = FoundationBasedXPCService()

       // Use ModernXPCService:
       let service = ModernXPCService()
       ```

    4. Update all method calls to use async/await syntax and Result types:
       ```swift
       // Instead of:
       service.ping { success, error in
           // Handle callback
       }

       // Use:
       let result = await service.ping()
       switch result {
       case .success(let value):
           // Handle success
       case .failure(let error):
           // Handle error
       }
       ```

    ## Complete Documentation

    For more detailed guidance, please refer to the `XPCProtocolMigrationGuide` in the
    XPCProtocolsCore module.
    """
  }
}
