/**
 # HashingService

 A comprehensive service implementation for cryptographic hashing operations,
 providing secure data integrity verification capabilities.

 ## Security Context

 Cryptographic hashing is a foundational security operation that serves several critical purposes:

 1. **Data Integrity**: Hashes verify that data has not been tampered with or corrupted
 2. **Authentication**: Password verification and challenge-response protocols
 3. **Digital Signatures**: Component of signature verification processes
 4. **Data Identification**: Creating unique identifiers for data without revealing contents

 ## Supported Algorithms

 This service provides implementation for industry-standard hashing algorithms:

 - **SHA-256**: Offers a good balance of security and performance (32-byte digest)
 - **SHA-512**: Provides enhanced security with longer digests (64-byte digest)

 ## Implementation Approach

 The service:
 - Wraps Apple's CryptoKit to provide standardised interfaces
 - Ensures proper memory management of sensitive data
 - Uses SecureBytes for handling hash values securely
 - Follows defensive programming practices for robust security

 ## Security Considerations

 - Hashing alone is **not encryption** - it is a one-way function that cannot be reversed
 - For password storage, use specialised password hashing functions with salting
 - Always verify hash algorithm security is appropriate for your use case
 - Consider using HMAC (Hash-based Message Authentication Code) when authentication is required

 ## Usage Guidelines

 - Use SHA-256 for general-purpose integrity verification
 - Consider SHA-512 for applications requiring higher security assurance
 - When comparing hashes, use constant-time comparison to prevent timing attacks
 - Avoid MD5 and SHA-1 as they are cryptographically broken for security applications
 */

import CryptoKit
import Foundation
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

/// Service implementation for cryptographic hashing operations
/// providing data integrity verification capabilities
public final class HashingService: Sendable {
  // MARK: - Initialisation

  /**
   Initialises a new hashing service instance.

   This service provides cryptographically secure hash functions
   that can be used to verify data integrity or create unique
   identifiers for data.
   */
  public init() {
    // No initialisation required - stateless service
  }

  // MARK: - Public Methods

  /**
   Computes a cryptographic hash of the input data using the specified algorithm.

   This method safely processes the input data and produces a fixed-length
   digest that uniquely represents the data. Any change to the input, no matter
   how small, will result in a completely different hash value.

   ## Example

   ```swift
   let dataToHash = SecureBytes(bytes: Array("Sensitive information".utf8))
   let hashingService = HashingService()

   let result = hashingService.hash(data: dataToHash, algorithm: .sha256)
   switch result {
   case .success(let hashedData):
       // Use the hash for verification or storage
       print("Hash generated successfully")
   case .failure(let error):
       print("Hashing failed: \(error)")
   }
   ```

   ## Security Considerations

   - Hash values should be protected if they contain information about sensitive data
   - Use constant-time comparison when verifying hashes to prevent timing attacks
   - Consider adding a salt for password hashing or other security-sensitive applications

   - Parameters:
     - data: Data to hash, contained in a SecureBytes instance for secure memory handling
     - algorithm: Hashing algorithm to use (e.g., SHA-256, SHA-512)
   - Returns: A Result containing either the hashed data in SecureBytes format or an error
   */
  public func hash(
    data: SecureBytes,
    algorithm: SecurityCoreTypes.HashAlgorithm
  ) -> Result<SecureBytes, SecurityProtocolError> {
    // Convert SecureBytes to array of bytes manually
    var bytes=[UInt8]()
    for i in 0..<data.count {
      bytes.append(data[i])
    }

    switch algorithm {
      case .sha256:
        let hash=SHA256.hash(data: Data(bytes))
        return .success(SecureBytes(bytes: [UInt8](hash)))
      case .sha512:
        let hash=SHA512.hash(data: Data(bytes))
        return .success(SecureBytes(bytes: [UInt8](hash)))
      default:
        return .failure(.unsupportedOperation(name: "Hash algorithm \(algorithm) not supported"))
    }
  }

  /**
   Computes a hash of the input data using a string-based algorithm identifier.

   This convenience method allows specifying the hash algorithm as a string,
   which is useful when the algorithm choice comes from configuration or user input.
   The method handles normalisation of algorithm names (e.g., "sha-256" and "sha256"
   are treated as equivalent).

   ## Example

   ```swift
   let data = SecureBytes(bytes: Array("Document contents".utf8))
   let hashingService = HashingService()

   // String-based algorithm specification
   let result = hashingService.hashWithAlgorithmName(data: data, algorithmName: "SHA-256")
   ```

   ## Algorithm Name Handling

   The following string formats are recognised:
   - SHA-256: "sha256", "sha-256" (case insensitive)
   - SHA-512: "sha512", "sha-512" (case insensitive)

   Unknown algorithm names default to SHA-256 for compatibility.

   - Parameters:
     - data: Data to hash, contained in a SecureBytes instance
     - algorithmName: String name of the hash algorithm (e.g., "SHA-256")
   - Returns: A Result containing either the hashed data in SecureBytes format or an error
   */
  public func hashWithAlgorithmName(
    data: SecureBytes,
    algorithmName: String
  ) -> Result<SecureBytes, SecurityProtocolError> {
    let algorithm=mapAlgorithmString(algorithmName)
    return hash(data: data, algorithm: algorithm)
  }

  /**
   Verifies that a hash value matches the expected hash of the input data.

   This method computes the hash of the provided data using the specified algorithm
   and compares it with the expected hash value. The comparison is performed in
   constant time to prevent timing attacks.

   ## Example

   ```swift
   let originalData = SecureBytes(bytes: Array("Important document".utf8))
   let expectedHash = retrievedHashFromStorage() // SecureBytes from storage

   let hashingService = HashingService()
   let isValid = hashingService.verifyHash(
       of: originalData,
       expectedHash: expectedHash,
       algorithm: .sha256
   )

   if isValid {
       print("Data integrity verified")
   } else {
       print("Data may have been tampered with")
   }
   ```

   - Parameters:
     - data: Original data to verify
     - expectedHash: The hash value that the data should match
     - algorithm: Hashing algorithm to use
   - Returns: True if the computed hash matches the expected hash, false otherwise
   */
  public func verifyHash(
    of data: SecureBytes,
    expectedHash: SecureBytes,
    algorithm: SecurityCoreTypes.HashAlgorithm
  ) -> Bool {
    let computedHashResult=hash(data: data, algorithm: algorithm)

    guard case let .success(computedHash)=computedHashResult else {
      return false
    }

    // Constant-time comparison to prevent timing attacks
    return constantTimeEqual(computedHash, expectedHash)
  }

  /**
   Converts a hash value to a hexadecimal string representation.

   This method safely converts a SecureBytes hash into a hexadecimal string,
   which is useful for displaying, logging, or storing hash values in a
   human-readable format.

   ## Example

   ```swift
   let data = SecureBytes(bytes: Array("Test data".utf8))
   let hashingService = HashingService()

   if case .success(let hashBytes) = hashingService.hash(data: data, algorithm: .sha256) {
       let hexString = hashingService.hashToHexString(hashBytes)
       print("SHA-256 hash: \(hexString)")
   }
   ```

   - Parameter hash: The hash value in SecureBytes format
   - Returns: Hexadecimal string representation of the hash
   */
  public func hashToHexString(_ hash: SecureBytes) -> String {
    let hexChars=Array("0123456789abcdef")
    var hexString=""

    // Access individual bytes by index since SecureBytes may not conform to Sequence
    for i in 0..<hash.count {
      let byte=hash[i]
      let value=Int(byte)
      hexString.append(hexChars[value >> 4])
      hexString.append(hexChars[value & 0xF])
    }

    return hexString
  }

  // MARK: - Private Methods

  /// Maps string algorithm names to HashAlgorithm enum values
  private func mapAlgorithmString(_ algorithm: String) -> SecurityCoreTypes.HashAlgorithm {
    switch algorithm.lowercased() {
      case "sha-256", "sha256":
        .sha256
      case "sha-512", "sha512":
        .sha512
      default:
        // Default to SHA-256 for unknown algorithms
        .sha256
    }
  }

  /// Performs a constant-time comparison of two SecureBytes instances
  /// This prevents timing attacks when comparing hashes
  private func constantTimeEqual(_ lhs: SecureBytes, _ rhs: SecureBytes) -> Bool {
    guard lhs.count == rhs.count else {
      return false
    }

    var result: UInt8=0

    for i in 0..<lhs.count {
      result |= lhs[i] ^ rhs[i]
    }

    return result == 0
  }
}
