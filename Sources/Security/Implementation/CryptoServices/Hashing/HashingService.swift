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
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes
import Errors // Import Errors module which contains the SecurityProtocolError type
import Types // Import Types module to get access to SecurityResultDTO

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
        status: .failure,
        error: SecurityProtocolError.invalidInput("Cannot hash empty data"),
        metadata: ["details": "Empty data provided for hashing"]
      )
    }

    // Validate algorithm
    guard !algorithm.isEmpty else {
      return SecurityResultDTO(
        status: .failure,
        error: SecurityProtocolError.invalidInput("Algorithm cannot be empty"),
        metadata: ["details": "No hashing algorithm specified"]
      )
    }

    do {
      // Implement SHA-256 hashing using CommonCrypto
      if algorithm.lowercased() == "sha-256" || algorithm.lowercased() == "sha256" {
        // Allocate buffer for SHA-256 result (32 bytes)
        var hashBytes=[UInt8](repeating: 0, count: 32)

        // Extract bytes from SecureBytes for hashing
        // SecureBytes doesn't have withUnsafeBytes, so we need to access its bytes directly
        let dataBytes = data.toArray()
        let dataCount = CC_LONG(dataBytes.count)
        
        // Use CC_SHA256 from CommonCrypto
        _ = CC_SHA256(dataBytes, dataCount, &hashBytes)

        let hashedData=SecureBytes(bytes: hashBytes)
        return SecurityResultDTO(
          status: .success,
          data: hashedData
        )
      } else {
        // For now, return an unsupported operation error for other algorithms
        return SecurityResultDTO(
          status: .failure,
          error: SecurityProtocolError.operationFailed("Hash algorithm not supported: \(algorithm)"),
          metadata: ["details": "The specified hash algorithm is not currently implemented"]
        )
      }
    } catch {
      return SecurityResultDTO(
        status: .failure,
        error: SecurityProtocolError.operationFailed("Hashing operation failed: \(error.localizedDescription)"),
        metadata: ["details": "Error during cryptographic hashing: \(error)"]
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
