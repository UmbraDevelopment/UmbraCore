import Foundation

/// Public interface for the UmbraSecurityServices module
/// This file serves as a facade to prevent circular dependencies by breaking
/// the dependency chain between Foundation and CryptoSwift
public enum UmbraSecurityServicesModule {
  /// Version of the UmbraSecurityServices module
  public static let version = "1.0.0"

  /// Module identifier for registration and discovery
  public static let moduleIdentifier = "com.umbracore.security.services"

  /// Get the shared security service instance
  @MainActor
  public static var securityService: SecurityService {
    SecurityService.shared
  }
}
