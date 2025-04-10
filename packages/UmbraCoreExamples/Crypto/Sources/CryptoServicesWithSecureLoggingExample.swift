import CryptoInterfaces
import CryptoTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces

/**
 # CryptoServicesWithSecureLoggingExample

 This example demonstrates how to properly integrate the UmbraCore's
 privacy-aware logging capabilities with cryptographic services following
 the Alpha Dot Five architecture principles.

 The example shows:
 1. Setting up appropriate secure loggers
 2. Integrating with CryptoServices
 3. Proper privacy tagging for sensitive operations
 4. Best practices for error handling with secure logging
 */
public enum CryptoServicesWithSecureLoggingExample {

  /**
   Demonstrates the end-to-end flow of encrypting data with proper privacy-aware logging.
   This example showcases best practices for handling sensitive operations.

   - Parameters:
     - data: The data to encrypt
     - key: The encryption key
     - subsystem: The logging subsystem identifier
   - Returns: The encrypted data or throws an error
   */
  public static func encryptWithSecureLogging(
    data: Data,
    key: Data,
    subsystem: String="com.umbra.example"
  ) async throws -> Data {
    // Step 1: Set up secure logging
    let secureLogger=await LoggingServices.createSecureLogger(
      subsystem: subsystem,
      category: "CryptoExample"
    )

    // Step 2: Log the start of the operation with appropriate privacy controls
    await secureLogger.securityEvent(
      action: "DataEncryption",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public),
        "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
        "keySize": PrivacyTaggedValue(value: key.count, privacyLevel: .public)
      ]
    )

    do {
      // Step 3: Create the crypto service using the factory with secure logging
      let cryptoService=await CryptoServiceFactory.shared.createDefault(
        logger: secureLogger
      )

      // Step 4: Convert Data to [UInt8] for CryptoService API
      let dataBytes=[UInt8](data)
      let keyBytes=[UInt8](key)

      // Step 5: Perform the encryption operation
      let encryptionResult=await cryptoService.encrypt(
        data: dataBytes,
        using: keyBytes
      )

      // Step 6: Handle the result with proper logging
      switch encryptionResult {
        case let .success(encryptedBytes):
          // Step 7: Log successful completion with privacy controls
          await secureLogger.securityEvent(
            action: "DataEncryption",
            status: .success,
            subject: nil,
            resource: nil,
            additionalMetadata: [
              "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public),
              "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
              "resultSize": PrivacyTaggedValue(value: encryptedBytes.count, privacyLevel: .public)
            ]
          )

          // Step 8: Convert back to Data
          return Data(encryptedBytes)

        case let .failure(error):
          // Step 9: Log failure with privacy controls
          await secureLogger.securityEvent(
            action: "DataEncryption",
            status: .failed,
            subject: nil,
            resource: nil,
            additionalMetadata: [
              "operation": PrivacyTaggedValue(value: "error", privacyLevel: .public),
              "errorType": PrivacyTaggedValue(value: String(describing: type(of: error)),
                                              privacyLevel: .public),
              "errorDescription": PrivacyTaggedValue(value: error.localizedDescription,
                                                     privacyLevel: .public)
            ]
          )

          // Step 10: Throw the error for the caller to handle
          throw error
      }
    } catch {
      // Step 11: Log any unexpected errors
      await secureLogger.securityEvent(
        action: "DataEncryption",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "operation": PrivacyTaggedValue(value: "unexpectedError", privacyLevel: .public),
          "errorType": PrivacyTaggedValue(value: String(describing: type(of: error)),
                                          privacyLevel: .public),
          "errorDescription": PrivacyTaggedValue(value: error.localizedDescription,
                                                 privacyLevel: .public)
        ]
      )

      throw error
    }
  }

  /**
   Demonstrates a complete workflow using cryptographic services with secure logging.
   This shows how to properly handle secrets and sensitive data throughout the lifecycle.

   - Parameter sampleData: The sample data to process
   - Returns: The processed data result
   */
  public static func secureDataWorkflow(sampleData: Data) async throws -> Data {
    // Step 1: Set up secure logging
    let secureLogger=await LoggingServices.createSecureLogger(
      category: "SecureWorkflow"
    )

    // Step 2: Log workflow start
    await secureLogger.info(
      "Starting secure data workflow",
      metadata: [
        "dataSize": PrivacyTaggedValue(value: sampleData.count, privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "workflow", privacyLevel: .public)
      ]
    )

    do {
      // Step 3: Generate a secure random key (simulated)
      let keyData=generateSecureRandomKey(length: 32)

      // Step 4: Encrypt the data
      let encryptedData=try await encryptWithSecureLogging(
        data: sampleData,
        key: keyData
      )

      // Step 5: Calculate a hash of the encrypted data
      let hashResult=try await calculateSecureHash(
        data: encryptedData,
        secureLogger: secureLogger
      )

      // Step 6: Log workflow completion
      await secureLogger.securityEvent(
        action: "SecureWorkflow",
        status: .success,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public),
          "encryptedSize": PrivacyTaggedValue(value: encryptedData.count, privacyLevel: .public),
          "hashSize": PrivacyTaggedValue(value: hashResult.count, privacyLevel: .public)
        ]
      )

      // Step 7: Return the processed data
      return encryptedData

    } catch {
      // Step 8: Log workflow failure
      await secureLogger.securityEvent(
        action: "SecureWorkflow",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "operation": PrivacyTaggedValue(value: "error", privacyLevel: .public),
          "errorType": PrivacyTaggedValue(value: String(describing: type(of: error)),
                                          privacyLevel: .public),
          "errorDescription": PrivacyTaggedValue(value: error.localizedDescription,
                                                 privacyLevel: .public)
        ]
      )

      throw error
    }
  }

  // MARK: - Helper Methods

  /**
   Calculates a secure hash of the provided data with privacy-aware logging.

   - Parameters:
     - data: The data to hash
     - secureLogger: The secure logger to use
   - Returns: The hash as Data
   */
  private static func calculateSecureHash(
    data: Data,
    secureLogger: SecureLoggerActor
  ) async throws -> Data {
    // Step 1: Log hash operation start
    await secureLogger.securityEvent(
      action: "HashCalculation",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public),
        "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public)
      ]
    )

    // Step 2: Create crypto service
    let cryptoService=await CryptoServiceFactory.shared.createDefault(
      logger: secureLogger
    )

    // Step 3: Perform hashing
    let hashResult=await cryptoService.hash(data: [UInt8](data))

    // Step 4: Handle the result
    switch hashResult {
      case let .success(hash):
        // Step 5: Log success
        await secureLogger.securityEvent(
          action: "HashCalculation",
          status: .success,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public),
            "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
            "hashSize": PrivacyTaggedValue(value: hash.count, privacyLevel: .public)
          ]
        )

        return Data(hash)

      case let .failure(error):
        // Step 6: Log failure
        await secureLogger.securityEvent(
          action: "HashCalculation",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "operation": PrivacyTaggedValue(value: "error", privacyLevel: .public),
            "errorType": PrivacyTaggedValue(value: String(describing: type(of: error)),
                                            privacyLevel: .public),
            "errorDescription": PrivacyTaggedValue(value: error.localizedDescription,
                                                   privacyLevel: .public)
          ]
        )

        throw error
    }
  }

  /**
   Generates a secure random key for cryptographic operations.

   - Parameter length: The desired key length in bytes
   - Returns: The generated key as Data
   */
  private static func generateSecureRandomKey(length: Int) -> Data {
    // In a real implementation, this would use a proper secure random generator
    // For this example, we're creating a simple simulated key
    var keyData=Data(count: length)
    for i in 0..<length {
      keyData[i]=UInt8.random(in: 0...255)
    }
    return keyData
  }
}
