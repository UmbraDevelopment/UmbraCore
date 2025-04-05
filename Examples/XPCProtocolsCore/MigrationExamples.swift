import Foundation
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore
import XPCProtocolsCore

/**
 # XPC Protocol Migration Examples

 This file contains examples of how to migrate from legacy XPC protocols to the new DTO-based protocols.
 It provides comparison of the old way and the new way of using XPC services with practical examples.
 */

/// Example code showcasing how to use the modern XPC protocol implementations
final class XPCMigrationExamples {
  // MARK: - Modern Implementation Examples

  /// Example showing the usage of a modern service with async/await and Result types
  func modernServiceUsageExample() async {
    // Using the factory method to get a modern service
    let service=XPCProtocolMigrationFactory.createCompleteAdapter()

    // Create secure data using Swift types
    let testData=SecureBytes(bytes: [1, 2, 3, 4, 5])

    // Use async/await pattern with Result type
    let encryptResult=await service.encryptSecureData(testData, keyIdentifier: nil)

    // Pattern matching on results
    switch encryptResult {
      case let .success(encryptedData):
        print("Encryption successful with \(encryptedData.count) bytes")

        // Continue with decryption
        let decryptResult=await service.decryptSecureData(encryptedData, keyIdentifier: nil)

        switch decryptResult {
          case let .success(decryptedData):
            print(
              "Decryption successful, recovered the original data: \(decryptedData == testData)"
            )
          case let .failure(error):
            print("Decryption failed with error: \(error)")
        }

      case let .failure(error):
        print("Encryption failed with error: \(error)")
    }
  }

  /// Example showing key management operations with modern protocols
  func keyManagementModernExample() async {
    // Get a modern service implementation
    let service=XPCProtocolMigrationFactory.createCompleteAdapter()

    // Generate a key with Swift enums
    let generateResult=await service.generateKey(
      algorithm: "AES-256",
      keySize: 256,
      purpose: "test"
    )

    switch generateResult {
      case let .success(keyIdentifier):
        print("Generated key with identifier: \(keyIdentifier)")

        // Delete the key
        let deleteResult=await service.deleteKey(keyIdentifier: keyIdentifier)

        switch deleteResult {
          case .success:
            print("Key deletion successful")
          case let .failure(error):
            print("Key deletion failed with error: \(error)")
        }

      case let .failure(error):
        print("Key generation failed with error: \(error)")
    }
  }

  // MARK: - Legacy Service Migration Example

  /**
   This demonstrates how to wrap legacy code during migration.

   Example: You have existing code that uses the legacy APIs and need to
   gradually migrate to the new APIs.
   */
  func legacyToModernMigrationExample() async {
    // Legacy approach (simulated) - NOT RECOMMENDED FOR NEW CODE
    // This would have used the legacy adapter in the past
    func legacyOperation(_: Data) -> Data? {
      // Create dummy encrypted data for testing
      Data([20, 40, 60, 80, 100])
    }

    // Modern approach using factory and protocols
    func modernOperation(_ data: Data) async -> Result<Data, Error> {
      let service=XPCProtocolMigrationFactory.createCompleteAdapter()
      let secureData=SecureBytes(bytes: [UInt8](data))

      let result=await service.encryptSecureData(secureData, keyIdentifier: nil)
      // Convert UmbraErrors.Security.Protocols to Error to match the function
      // return type
      return result.mapError { error in
        error as Error
      }.map { _ in
        Data(secureData.bytes) // Simplified for example
      }
    }

    // Example usage in a client that's being migrated
    let testData=Data([1, 2, 3, 4, 5])

    // Legacy usage (should be migrated)
    if let legacyResult=legacyOperation(testData) {
      print("Legacy operation successful with \(legacyResult.count) bytes")
    } else {
      print("Legacy operation failed")
    }

    // Modern usage (target pattern)
    let modernResult=await modernOperation(testData)
    switch modernResult {
      case let .success(data):
        print("Modern operation successful with \(data.count) bytes")
      case let .failure(error):
        print("Modern operation failed with error: \(error)")
    }
  }
}
