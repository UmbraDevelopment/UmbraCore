import CoreServices
import CoreServicesTypes
import UmbraErrors
import UmbraErrorsCore

import Foundation
import FoundationBridgeTypes
import SecurityInterfaces
import SecurityInterfacesBase
import SecurityInterfacesProtocols
import SecurityUtils
import UmbraCoreTypes
import UmbraLogging
import XPCProtocolsCore

/// A minimal implementation of the security service that doesn't depend on CryptoSwift
/// This helps break circular dependencies between Foundation and CryptoSwift
public actor SecurityServiceNoCrypto {
  // MARK: - Properties

  /// Current state of the service
  private var _state: CoreServicesTypes.ServiceState = .uninitialized

  /// Static property to store state for non-isolated access
  private static var _nonIsolatedStateStorage: [
    ObjectIdentifier: CoreServicesTypes
      .ServiceState
  ]=[:]
  private static let _stateAccessQueue=DispatchQueue(label: "com.umbra.security.service.state")

  /// Unique identifier for this instance
  private let instanceID=ObjectIdentifier(UUID() as NSObject)

  /// Public accessor for the state
  public nonisolated var state: CoreServicesTypes.ServiceState {
    SecurityServiceNoCrypto._stateAccessQueue.sync {
      SecurityServiceNoCrypto._nonIsolatedStateStorage[instanceID] ?? .uninitialized
    }
  }

  /// Update the non-isolated state - static method to avoid actor isolation issues
  private static func updateNonIsolatedState(
    for id: ObjectIdentifier,
    newState: CoreServicesTypes.ServiceState
  ) {
    _stateAccessQueue.sync {
      _nonIsolatedStateStorage[id]=newState
    }
  }

  /// Remove state for an instance
  private static func removeNonIsolatedState(for id: ObjectIdentifier) {
    _=_stateAccessQueue.sync {
      _nonIsolatedStateStorage.removeValue(forKey: id)
    }
  }

  // MARK: - Lifecycle

  /// Initialise the service with default parameters
  public init() {}

  deinit {
    Self.removeNonIsolatedState(for: instanceID)
  }

  /// Reset the service state
  public func reset() async {
    _state = .uninitialized
    Self.updateNonIsolatedState(for: instanceID, newState: _state)
  }

  // MARK: - Service State Management

  /// Initialise the security service
  /// - Parameter usesPrivilegedHelper: Whether to use the privileged helper for crypto
  /// - Returns: True if initialised successfully
  /// - Throws: SecurityError if initialisation fails
  public func initialize(usesPrivilegedHelper _: Bool=false) async
  -> Result<Bool, UmbraErrors.Security.Core> {
    // Minimal implementation - just update state
    _state = .initialized
    Self.updateNonIsolatedState(for: instanceID, newState: _state)
    return .success(true)
  }

  /// Start the security service
  /// - Returns: True if started successfully
  /// - Throws: SecurityError if startup fails
  public func start() async -> Result<Bool, UmbraErrors.Security.Core> {
    guard _state == .initialized else {
      return .failure(.operationFailed(reason: "Cannot start: service not initialised"))
    }

    _state = .running
    Self.updateNonIsolatedState(for: instanceID, newState: _state)
    return .success(true)
  }

  /// Stop the security service
  /// - Returns: True if stopped successfully
  /// - Throws: SecurityError if stopping fails
  public func stop() async -> Result<Bool, UmbraErrors.Security.Core> {
    guard _state == .running else {
      return .failure(.operationFailed(reason: "Cannot stop: service not running"))
    }

    _state = .stopped
    Self.updateNonIsolatedState(for: instanceID, newState: _state)
    return .success(true)
  }
}
