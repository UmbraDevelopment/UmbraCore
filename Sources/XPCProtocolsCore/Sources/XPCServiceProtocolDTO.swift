import CoreDTOs
@_exported import struct CoreDTOs.OperationResultDTO
@_exported import struct CoreDTOs.SecurityConfigDTO
@_exported import struct CoreDTOs.SecurityErrorDTO
import UmbraCoreTypes

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Application domain
  public static let application = "Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain = domain
    self.code = code
    self.description = description
  }
}

/**
 # XPC Service Protocol with DTOs

 This file defines foundation-independent protocols for XPC services using DTOs.
 These protocols enable consistent data exchange between XPC clients and services
 without relying on Foundation types.
 */

/// Basic XPC service protocol with DTO support
public protocol XPCServiceProtocolDTO {
  /// Protocol identifier
  static var protocolIdentifier: String { get }

  /// Ping the service to check availability
  /// - Returns: Boolean indicating if service is available
  func pingWithDTO() async -> Bool

  /// Get random bytes from the service
  /// - Parameter length: Number of random bytes to generate
  /// - Returns: Operation result with secure random bytes or error
  func getRandomBytesWithDTO(
    length: Int
  ) async -> OperationResultDTO<SecureBytes>

  /// Perform a secure operation with DTOs
  /// - Parameters:
  ///   - operation: Operation name
  ///   - inputs: Input parameters
  ///   - config: Security configuration
  /// - Returns: Operation result with output data or error
  func performSecureOperationWithDTO(
    operation: String,
    inputs: [String: SecureBytes],
    config: SecurityConfigDTO
  ) async -> OperationResultDTO<[String: SecureBytes]>

  /// Generate a cryptographic signature with DTOs
  /// - Parameters:
  ///   - data: Data to sign
  ///   - keyIdentifier: Key to use for signing
  ///   - config: Security configuration
  /// - Returns: Operation result with signature or error
  func generateSignatureWithDTO(
    data: SecureBytes,
    keyIdentifier: String,
    config: SecurityConfigDTO
  ) async -> OperationResultDTO<SecureBytes>

  /// Verify a cryptographic signature with DTOs
  /// - Parameters:
  ///   - signature: Signature to verify
  ///   - data: Data that was signed
  ///   - keyIdentifier: Key to use for verification
  ///   - config: Security configuration
  /// - Returns: Operation result with verification result or error
  func verifySignatureWithDTO(
    signature: SecureBytes,
    data: SecureBytes,
    keyIdentifier: String,
    config: SecurityConfigDTO
  ) async -> OperationResultDTO<Bool>

  /// Get current service status
  /// - Returns: Operation result with service status DTO or error
  func getStatusWithDTO() async -> OperationResultDTO<XPCProtocolDTOs.ServiceStatusDTO>
}

/// Default implementations for the basic service protocol
extension XPCServiceProtocolDTO {
  /// Default protocol identifier
  public static var protocolIdentifier: String {
    "com.umbra.xpc.service.protocol.dto"
  }

  /// Default ping implementation
  public func pingWithDTO() async -> Bool {
    true
  }

  /// Default implementation for random bytes
  public func getRandomBytesWithDTO(length: Int) async -> OperationResultDTO<SecureBytes> {
    // Default implementation just returns a failure
    OperationResultDTO(
      status: .failure,
      errorCode: 1_000,
      errorMessage: "Random bytes generation not implemented",
      details: ["requestedLength": "\(length)"]
    )
  }

  /// Get status with current timestamp and protocol version
  public func getStatusWithDTO() async -> OperationResultDTO<XPCProtocolDTOs.ServiceStatusDTO> {
    let status = XPCProtocolDTOs.ServiceStatusDTO.current(
      protocolVersion: Self.protocolIdentifier,
      serviceVersion: "1.0.0",
      details: ["serviceType": "XPC"]
    )

    return OperationResultDTO(value: status)
  }
}
