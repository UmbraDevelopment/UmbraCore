import CoreErrors
import CryptoTypes
import Foundation
import SecurityUtils
import UmbraKeychainService

@preconcurrency
public protocol CryptoXPCServiceDependencies: Sendable {
  var securityUtils: SecurityUtils { get }
  var keychain: UmbraKeychainService { get }
}

@preconcurrency
public struct DefaultCryptoXPCServiceDependencies: CryptoXPCServiceDependencies {
  public let securityUtils: SecurityUtils
  public let keychain: UmbraKeychainService

  public init(securityUtils: SecurityUtils, keychain: UmbraKeychainService) {
    self.securityUtils=securityUtils
    self.keychain=keychain
  }
}
