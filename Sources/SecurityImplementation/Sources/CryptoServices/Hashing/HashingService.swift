/**
 # UmbraCore Hashing Service

 This file provides implementation of cryptographic hashing operations
 for the UmbraCore security framework, including SHA-2 family hash functions.

 ## Responsibilities

 * Cryptographic hash generation
 * Support for multiple hash algorithms (SHA-256, SHA-512, etc.)
 * Data integrity verification
 */

import CommonCrypto
import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// Service for cryptographic hashing operations
final class HashingService: Sendable {
  // MARK: - Initialisation

  /// Creates a new hashing service
  init() {
    // Initialise any resources needed
  }

  // MARK: - Public Methods

  /// Hash data using the specified algorithm
  /// - Parameters:
  ///   - data: Data to hash
  ///   - algorithm: Hashing algorithm to use (e.g., "SHA-256")
  /// - Returns: Result of the hashing operation
  func hashData(
    data: SecureBytes,
    algorithm: String
  ) async -> SecurityResultDTO {
    // Validate inputs
    guard !data.isEmpty else {
      return SecurityResultDTO(
        success: false,
        error: UmbraErrors.Security.Protocols.invalidInput("Cannot hash empty data"),
        errorDetails: "Empty data provided for hashing"
      )
    }

    // Validate algorithm
    guard isSupportedHashAlgorithm(algorithm) else {
      return SecurityResultDTO(
        success: false,
        error: UmbraErrors.Security.Protocols
          .unsupportedOperation(name: "Hash algorithm: \(algorithm)"),
        errorDetails: "The specified hash algorithm is not supported"
      )
    }

    do {
      // Implement SHA-256 hashing using CommonCrypto
      if algorithm == "SHA-256" {
        // Allocate buffer for SHA-256 result (32 bytes)
        var hashBytes=[UInt8](repeating: 0, count: 32)

        // Use CC_SHA256 from CommonCrypto
        data.withUnsafeBytes { dataPtr in
          let dataCount=CC_LONG(data.count)
          _=CC_SHA256(dataPtr.baseAddress, dataCount, &hashBytes)
        }

        let hashedData=SecureBytes(bytes: hashBytes)
        return SecurityResultDTO(data: hashedData)
      } else {
        // For now, return an unsupported operation error for other algorithms
        return SecurityResultDTO(
          success: false,
          error: UmbraErrors.Security.Protocols
            .unsupportedOperation(name: "Hash algorithm: \(algorithm)"),
          errorDetails: "The specified hash algorithm is not currently implemented"
        )
      }
    } catch {
      return SecurityResultDTO(
        success: false,
        error: UmbraErrors.Security.Protocols
          .internalError("Hashing operation failed: \(error.localizedDescription)"),
        errorDetails: "Error during cryptographic hashing: \(error)"
      )
    }
  }

  // MARK: - Private Methods

  /// Check if the specified hash algorithm is supported
  /// - Parameter algorithm: The algorithm name to check
  /// - Returns: True if supported, false otherwise
  private func isSupportedHashAlgorithm(_ algorithm: String) -> Bool {
    // For now, only SHA-256 is fully implemented
    let supportedAlgorithms=[
      "SHA-256"
    ]

    return supportedAlgorithms.contains(algorithm)
  }
}
