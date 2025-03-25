import CoreDTOs
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore

/**
 # XPC Service Protocol with DTOs

 This file defines foundation-independent protocols for XPC services using DTOs.
 These protocols enable consistent data exchange between XPC clients and services
 without relying on Foundation types.
 */

/// Basic XPC service protocol with DTO support
public protocol XPCServiceProtocolDTO: XPCServiceProtocolBase {
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
    .failure(
      UmbraErrors.SecurityError(
        domain: "XPC",
        code: "NOT_IMPLEMENTED",
        errorDescription: "Random bytes generation not implemented in this service",
        source: nil,
        underlyingError: nil,
        context: ErrorContext()
      )
    )
  }

  /// Get status with current timestamp and protocol version
  public func getStatusWithDTO() async -> OperationResultDTO<XPCProtocolDTOs.ServiceStatusDTO> {
    let status = XPCProtocolDTOs.ServiceStatusDTO(
      code: 200,
      message: "Service is running",
      isRunning: true,
      version: Self.protocolIdentifier + " v1.0.0",
      properties: ["timestamp": "\(Date())", "serviceType": "XPC"]
    )

    return .success(status)
  }
}
