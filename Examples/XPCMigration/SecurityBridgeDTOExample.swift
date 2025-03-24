import UmbraErrors
import UmbraErrorsCore
import CoreDTOs

import Foundation
import SecurityBridge
import SecurityInterfaces
import UmbraCoreTypes
import XPCProtocolsCore

/// This example demonstrates how to use the Foundation-independent DTOs with the SecurityBridge
/// module.
/// It shows how to create and use the XPCServiceDTOAdapter and perform cryptographic operations
/// without relying on Foundation types at the interface boundaries.
struct SecurityBridgeDTOExample {
  // MARK: - Properties

  /// The XPC service adapter that uses Foundation-independent DTOs
  private let serviceAdapter: XPCServiceProtocolStandardDTO

  // MARK: - Initialization

  /// Initialize with a service name
  /// - Parameter serviceName: The name of the XPC service
  init(serviceName: String) {
    // Use the factory to create an adapter for the specified service
    serviceAdapter=XPCServiceDTOFactory.createStandardAdapter(
      forService: serviceName
    )
  }

  // MARK: - Example Methods

  /// Check if the service is available
  /// - Returns: A Result indicating whether the service is available
  func checkServiceAvailability() async
  -> Result<Bool, UmbraErrors.Security.ProtocolsDTO> {
    await serviceAdapter.ping()
  }

  /// Get service status information
  /// - Returns: A Result containing the service status
  func getServiceStatus() async
    -> Result<
      XPCServiceDTO.ServiceStatusDTO,
      UmbraErrors.Security.ProtocolsDTO
    >
  {
    await serviceAdapter.getServiceStatus()
  }

  /// Encrypt data using the service
  /// - Parameters:
  ///   - data: The data to encrypt as a string
  ///   - keyIdentifier: Optional key identifier
  /// - Returns: A Result containing the encrypted data or an error
  func encryptString(
    _ data: String,
    keyIdentifier: String?=nil
  ) async
  -> Result<String, UmbraErrors.Security.ProtocolsDTO> {
    // Convert the string to bytes
    guard let dataBytes=data.data(using: .utf8) else {
      return .failure(
        UmbraErrors.Security.ProtocolsDTO
          .invalidInput(details: "Invalid UTF-8 string")
      )
    }

    // Create SecureBytes from the data
    let secureBytes=SecureBytes(bytes: [UInt8](dataBytes))

    // Encrypt the data
    let result=await serviceAdapter.encryptData(secureBytes, keyIdentifier: keyIdentifier)

    // Convert the result to a Base64 string
    return result.flatMap { encryptedBytes in
      // Convert SecureBytes to a Base64 string
      var bytesArray=[UInt8]()
      encryptedBytes.withUnsafeBytes { buffer in
        bytesArray=Array(buffer)
      }

      let base64String=Data(bytesArray).base64EncodedString()
      return .success(base64String)
    }
  }

  /// Decrypt data using the service
  /// - Parameters:
  ///   - base64Data: The Base64-encoded data to decrypt
  ///   - keyIdentifier: Optional key identifier
  /// - Returns: A Result containing the decrypted string or an error
  func decryptToString(
    _ base64Data: String,
    keyIdentifier: String?=nil
  ) async
  -> Result<String, UmbraErrors.Security.ProtocolsDTO> {
    // Convert the Base64 string to data
    guard let data=Data(base64Encoded: base64Data) else {
      return .failure(
        UmbraErrors.Security.ProtocolsDTO
          .invalidInput(details: "Invalid Base64 string")
      )
    }

    // Create SecureBytes from the data
    let secureBytes=SecureBytes(bytes: [UInt8](data))

    // Decrypt the data
    let result=await serviceAdapter.decryptData(secureBytes, keyIdentifier: keyIdentifier)

    // Convert the result to a string
    return result.flatMap { decryptedBytes in
      // Convert SecureBytes to a String
      var bytesArray=[UInt8]()
      decryptedBytes.withUnsafeBytes { buffer in
        bytesArray=Array(buffer)
      }

      guard let resultString=String(data: Data(bytesArray), encoding: .utf8) else {
        return .failure(
          UmbraErrors.Security.ProtocolsDTO
            .invalidInput(details: "Invalid UTF-8 data in decryption result")
        )
      }

      return .success(resultString)
    }
  }

  /// Generate random data
  /// - Parameter length: The length of the random data to generate (in bytes)
  /// - Returns: A Result containing the random data as a Base64 string or an error
  func generateRandomData(length: Int) async
  -> Result<String, UmbraErrors.Security.ProtocolsDTO> {
    let result=await serviceAdapter.generateRandomData(length: length)

    return result.flatMap { randomBytes in
      // Convert SecureBytes to a Base64 string
      var bytesArray=[UInt8]()
      randomBytes.withUnsafeBytes { buffer in
        bytesArray=Array(buffer)
      }

      let base64String=Data(bytesArray).base64EncodedString()
      return .success(base64String)
    }
  }

  /// Sign data using the service
  /// - Parameters:
  ///   - data: The data to sign as a string
  ///   - keyIdentifier: Key identifier
  /// - Returns: A Result containing the signature as a Base64 string or an error
  func signString(
    _ data: String,
    keyIdentifier: String
  ) async
  -> Result<String, UmbraErrors.Security.ProtocolsDTO> {
    // Convert the string to bytes
    guard let dataBytes=data.data(using: .utf8) else {
      return .failure(
        UmbraErrors.Security.ProtocolsDTO
          .invalidInput(details: "Invalid UTF-8 string")
      )
    }

    // Create SecureBytes from the data
    let secureBytes=SecureBytes(bytes: [UInt8](dataBytes))

    // Sign the data
    let result=await serviceAdapter.sign(secureBytes, keyIdentifier: keyIdentifier)

    // Convert the result to a Base64 string
    return result.flatMap { signatureBytes in
      // Convert SecureBytes to a Base64 string
      var bytesArray=[UInt8]()
      signatureBytes.withUnsafeBytes { buffer in
        bytesArray=Array(buffer)
      }

      let base64String=Data(bytesArray).base64EncodedString()
      return .success(base64String)
    }
  }

  /// Verify a signature
  /// - Parameters:
  ///   - signature: The Base64-encoded signature to verify
  ///   - data: The original data as a string
  ///   - keyIdentifier: Key identifier
  /// - Returns: A Result containing a boolean indicating validity or an error
  func verifySignature(
    _ signature: String,
    for data: String,
    keyIdentifier: String
  ) async -> Result<Bool, UmbraErrors.Security.ProtocolsDTO> {
    // Convert the signature from Base64
    guard let signatureData=Data(base64Encoded: signature) else {
      return .failure(
        UmbraErrors.Security.ProtocolsDTO
          .invalidInput(details: "Invalid Base64 signature")
      )
    }

    // Convert the data string to bytes
    guard let dataBytes=data.data(using: .utf8) else {
      return .failure(
        UmbraErrors.Security.ProtocolsDTO
          .invalidInput(details: "Invalid UTF-8 string")
      )
    }

    // Create SecureBytes from the data
    let signatureBytes=SecureBytes(bytes: [UInt8](signatureData))
    let dataSecureBytes=SecureBytes(bytes: [UInt8](dataBytes))

    // Verify the signature
    return await serviceAdapter.verify(
      signature: signatureBytes,
      for: dataSecureBytes,
      keyIdentifier: keyIdentifier
    )
  }
}

// MARK: - Usage Example

/// Example usage of the SecurityBridgeDTOExample
enum SecurityBridgeDTOUsageExample {
  static func runExample() async {
    // Create an instance of the example with the XPC service name
    let example=SecurityBridgeDTOExample(serviceName: "com.umbra.xpc.security")

    // Check if the service is available
    let availabilityResult=await example.checkServiceAvailability()
    switch availabilityResult {
      case let .success(isAvailable):
        print("Service is available: \(isAvailable)")
      case let .failure(error):
        print("Error checking service availability: \(error)")
        return
    }

    // Get service status
    let statusResult=await example.getServiceStatus()
    switch statusResult {
      case let .success(status):
        print("Service status: \(status.status)")
        print("Service version: \(status.version)")
      case let .failure(error):
        print("Error getting service status: \(error)")
    }

    // Generate random data
    let randomDataResult=await example.generateRandomData(length: 32)
    switch randomDataResult {
      case let .success(randomData):
        print("Generated random data: \(randomData)")
      case let .failure(error):
        print("Error generating random data: \(error)")
    }

    // Encrypt and decrypt a string
    let originalString="Hello, secure world!"
    print("Original string: \(originalString)")

    // Encrypt the string
    let encryptResult=await example.encryptString(originalString)
    switch encryptResult {
      case let .success(encryptedString):
        print("Encrypted string: \(encryptedString)")

        // Decrypt the string
        let decryptResult=await example.decryptToString(encryptedString)
        switch decryptResult {
          case let .success(decryptedString):
            print("Decrypted string: \(decryptedString)")
            assert(decryptedString == originalString, "Decryption did not match original string")
          case let .failure(error):
            print("Error decrypting string: \(error)")
        }

      case let .failure(error):
        print("Error encrypting string: \(error)")
    }
  }
}
