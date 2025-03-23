import CommonCrypto
import Foundation
import Security
import SecurityBridge

// Import specific modules instead of SecurityInterfaces
import SecurityInterfacesBase
import SecurityInterfacesProtocols

// import SecurityInterfaces
import ErrorHandlingDomains
import SecurityProtocolsCore
import SecurityTypesTypes
import UmbraCoreTypes
import XPCProtocolsCore

/// SecurityUtils Module
///
/// This module provides utility functions for security-related operations
/// such as generating secure random data and hashing.
public final class SecurityUtils: @unchecked Sendable {
  /// Shared instance of SecurityUtils
  public static let shared=SecurityUtils()

  /// Private initializer to enforce singleton pattern
  private init() {}

  /// Generate cryptographically secure random data
  /// - Parameter length: Length of random data to generate
  /// - Returns: Random data of specified length
  /// - Throws: UmbraErrors.Security.Protocols if random generation fails
  public func generateRandomData(_ length: Int) throws -> Data {
    var data=Data(count: length)
    let result=data.withUnsafeMutableBytes { bytes in
      SecRandomCopyBytes(kSecRandomDefault, length, bytes.baseAddress!)
    }

    guard result == errSecSuccess else {
      throw UmbraErrors.Security.Protocols
        .randomGenerationFailed("SecRandomCopyBytes failed with status: \(result)")
    }

    return data
  }

  /// Hash data using the specified algorithm
  /// - Parameters:
  ///   - data: Data to hash
  ///   - algorithm: Hash algorithm to use
  /// - Returns: Hashed data
  /// - Throws: UmbraErrors.Security.Protocols if hashing fails
  public func hash(_ data: Data, using algorithm: SecurityTypesTypes.HashAlgorithm) throws -> Data {
    switch algorithm {
      case .sha256:
        var hashData=Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        _=hashData.withUnsafeMutableBytes { hashBytes in
          data.withUnsafeBytes { dataBytes in
            CC_SHA256(
              dataBytes.baseAddress,
              CC_LONG(data.count),
              hashBytes.baseAddress?.assumingMemoryBound(to: UInt8.self)
            )
          }
        }
        return hashData

      case .sha512:
        var hashData=Data(count: Int(CC_SHA512_DIGEST_LENGTH))
        _=hashData.withUnsafeMutableBytes { hashBytes in
          data.withUnsafeBytes { dataBytes in
            CC_SHA512(
              dataBytes.baseAddress,
              CC_LONG(data.count),
              hashBytes.baseAddress?.assumingMemoryBound(to: UInt8.self)
            )
          }
        }
        return hashData

      @unknown default:
        throw UmbraErrors.Security.Protocols
          .unsupportedOperation(name: "Hash algorithm not supported: \(algorithm)")
    }
  }
}
