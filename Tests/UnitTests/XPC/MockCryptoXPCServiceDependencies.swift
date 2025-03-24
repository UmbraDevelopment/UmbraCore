import CommonCrypto
import Foundation
import Security
import SecurityInterfaces
import SecurityTypes
import SecurityUtils
import UmbraCryptoService
import UmbraKeychainService

/// Mock implementation of CryptoXPCServiceDependencies for testing
final class MockCryptoXPCServiceDependencies: CryptoXPCServiceDependencies {
  public let securityUtils: SecurityUtils
  public let keychain: UmbraKeychainService

  init() {
    securityUtils=SecurityUtils.shared
    keychain=UmbraKeychainService(identifier: "com.umbra.test.keychain")
  }
}
