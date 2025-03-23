import Foundation
import FoundationBridgeTypes
import SecurityBridge

import SecurityProtocolsCore

/// Factory class for creating security providers
@MainActor
public final class SecurityProviderFactory {
  /// Create a default security provider
  /// - Returns: A fully configured SecurityProvider instance
  public static func createDefaultProvider() -> SecurityProtocolsCore.SecurityProvider {
    // Create the Foundation implementation
    let foundationImpl=DefaultSecurityProviderFoundationImpl()

    // Create the adapter to convert between Foundation and bridge types
    let foundationAdapter=SecurityBridge.SecurityProviderFoundationAdapter(impl: foundationImpl)

    // Create the bridge that implements SecurityProviderBridge
    let bridge=DefaultSecurityProviderBridge(adapter: foundationAdapter)

    // Create the final adapter that implements SecurityProvider
    return SecurityProtocolsCore.SecurityProviderAdapter(bridge: bridge)
  }

  /// Creates a simple security provider using the built-in implementation
  /// - Returns: A security provider bridged through our internal implementation
  public static func createSimpleProvider() -> SecurityProtocolsCore.SecurityProvider {
    // Use our internal implementation directly
    let securityService=SecurityService.shared
    let bridge=DefaultSecurityProviderBridge(adapter: securityService.securityProviderAdapter)

    // Create the final adapter that implements SecurityProvider
    return SecurityProtocolsCore.SecurityProviderAdapter(bridge: bridge)
  }
}

/// Default implementation of SecurityProviderBridge
@MainActor
final class DefaultSecurityProviderBridge: SecurityProviderBridge.SecurityProviderBridge {
  private let adapter: SecurityBridge.SecurityProviderFoundationAdapter

  init(adapter: SecurityBridge.SecurityProviderFoundationAdapter) {
    self.adapter=adapter
  }

  static var protocolIdentifier: String {
    "com.umbra.security.provider.bridge.default"
  }

  func encrypt(
    _ data: FoundationBridgeTypes.DataBridge,
    key: FoundationBridgeTypes.DataBridge
  ) async throws -> FoundationBridgeTypes.DataBridge {
    try await adapter.encrypt(data, key: key)
  }

  func decrypt(
    _ data: FoundationBridgeTypes.DataBridge,
    key: FoundationBridgeTypes.DataBridge
  ) async throws -> FoundationBridgeTypes.DataBridge {
    try await adapter.decrypt(data, key: key)
  }

  func generateKey(length: Int) async throws -> FoundationBridgeTypes.DataBridge {
    try await adapter.generateKey(length: length)
  }

  func generateRandomData(length: Int) async throws -> FoundationBridgeTypes.DataBridge {
    try await adapter.generateRandomData(length: length)
  }

  func hash(_ data: FoundationBridgeTypes.DataBridge) async throws -> FoundationBridgeTypes
  .DataBridge {
    try await adapter.hash(data)
  }

  func createBookmark(for urlString: String) async throws -> FoundationBridgeTypes.DataBridge {
    try await adapter.createBookmark(for: urlString)
  }

  func resolveBookmark(_ data: FoundationBridgeTypes.DataBridge) async throws -> String {
    try await adapter.resolveBookmark(data)
  }

  func validateBookmark(_ bookmarkData: FoundationBridgeTypes.DataBridge) async throws -> Bool {
    try await adapter.validateBookmark(bookmarkData)
  }
}
