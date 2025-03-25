import CoreServicesTypes
import SecurityInterfaces
import SecurityUtils
import SecurityInterfacesProtocols
import SecurityTypes
import UmbraCoreTypes
import UmbraLogging
import XPCProtocolsCore
import SecurityInterfacesBase

/// Minimal factory for creating security services with no Foundation dependencies
/// This demonstrates how to use the components we've created to break circular dependencies
public enum SecurityServiceFactoryMinimal {
  /// Create a minimal security service with no crypto dependencies
  /// This is useful when you need basic security functionality but want to avoid circular
  /// dependencies
  public static func createMinimalService() -> SecurityServiceNoCrypto {
    SecurityServiceNoCrypto()
  }
}
