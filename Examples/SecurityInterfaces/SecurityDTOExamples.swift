import CoreDTOs
import UmbraErrors
import UmbraErrorsCore

import SecurityBridge
import SecurityInterfacesBase
import SecurityProtocolsCore
import UmbraCoreTypes
import XPCProtocolsCore

/// Examples of using the Foundation-independent Security DTOs
/// These examples demonstrate how to use the various DTO-based interfaces for security operations
public enum SecurityDTOExamples {
  /// Example of using SecurityProviderDTO directly
  public static func useDirectDTOProvider() async {
    // Create a provider that implements SecurityProviderDTO directly
    let defaultConfig=SecurityProtocolsCore.SecurityConfigDTO(
      algorithm: "AES-GCM",
      keySizeInBits: 256
    )
    let provider=ExampleSecurityProviderDTO(configuration: defaultConfig)

    // Get the current configuration
    let configResult=await provider.getSecurityConfigDTO()
    switch configResult {
      case let .success(config):
        print("Current configuration:")
        print("  Algorithm: \(config.algorithm)")
        print("  Key size: \(config.keySizeInBits) bits")
        print("  Options: \(config.options)")

        // Generate random data
        if let randomResult=await provider.generateRandomData(length: 32).success {
          print("Generated \(randomResult.bytes.count) random bytes")

          // Encrypt data
          let dataToEncrypt="Hello, secure world!".data(using: .utf8)!
          let secureData=SecureBytes(bytes: [UInt8](dataToEncrypt))

          if
            let encryptionResult=await provider.encryptData(secureData, withKey: randomResult)
              .success
          {
            print("Successfully encrypted data (\(encryptionResult.bytes.count) bytes)")

            // Decrypt data (using the same operation with XOR)
            if
              let decryptionResult=await provider.encryptData(
                encryptionResult,
                withKey: randomResult
              ).success
            {
              let decryptedString=String(bytes: decryptionResult.bytes, encoding: .utf8)
              print("Decrypted: \(decryptedString ?? "unable to decode")")
            }
          }
        }

      case let .failure(error):
        print("Error getting configuration: \(error.message)")
    }
  }

  /// Example of adapting an existing SecurityProvider to use DTOs
  public static func useAdaptedDTOProvider() async {
    // Create a traditional SecurityProvider
    let legacyProvider=ExampleSecurityProvider()

    // Adapt it to use DTOs
    let dtoProvider=SecurityProviderDTOAdapter(provider: legacyProvider)

    // Use the DTO interface
    let configResult=await dtoProvider.getSecurityConfigDTO()
    switch configResult {
      case let .success(config):
        print("Adapted provider configuration:")
        print("  Algorithm: \(config.algorithm)")
        print("  Key size: \(config.keySizeInBits) bits")

        // Perform a security operation
        let operationParams=["keySize": "16"]
        let keyGenResult=await dtoProvider.performSecurityOperationDTO(
          operation: .keyGeneration,
          data: nil,
          parameters: operationParams
        )

        if keyGenResult.status == .success, let key=keyGenResult.value {
          print("Generated key with \(key.bytes.count) bytes")
        } else if keyGenResult.status == .failure, let errorMessage=keyGenResult.errorMessage {
          print("Error generating key: \(errorMessage)")
        }

      case let .failure(error):
        print("Error getting configuration: \(error.message)")
    }
  }

  /// Example of using XPC with DTOs
  public static func useXPCWithDTOs() async {
    // In a real application, you would connect to an XPC service
    // For this example, we'll simulate one using our adapter

    // Create a traditional XPC service
    let legacyService=ExampleMockXPCService()

    // Adapt it to use DTOs
    let dtoService=XPCServiceDTOAdapter(legacyService)

    // Use DTO-based methods
    let configResult=await dtoService.getSecurityConfigDTO()
    switch configResult {
      case let .success(config):
        print("XPC service configuration:")
        print("  Algorithm: \(config.algorithm)")
        print("  Key size: \(config.keySizeInBits) bits")

        // Generate a key using the DTO interface
        let keyGenResult=await dtoService.generateKeyDTO(config: config)

        if let key=keyGenResult.success {
          print("XPC service generated key with \(key.bytes.count) bytes")

          // Check the status via the legacy interface
          let statusResult=await dtoService.status()
          if let status=statusResult.success {
            print("Service status: \(status)")
          }
        }

      case let .failure(error):
        print("Error getting XPC configuration: \(error.message)")
    }
  }
}

// Simple mock XPC service for the example
private final class ExampleMockXPCService: XPCServiceProtocolComplete {
  static var protocolIdentifier: String="com.example.security.mock"

  // Helper function to convert SecureBytes to [UInt8]
  static func bytesFrom(secureBytes: SecureBytes) -> [UInt8] {
    var bytes=[UInt8](repeating: 0, count: secureBytes.count)
    for i in 0..<secureBytes.count {
      do {
        bytes[i]=try secureBytes.byte(at: i)
      } catch {
        // In case of error, return empty array
        return []
      }
    }
    return bytes
  }

  // MARK: - XPCServiceProtocolBasic

  func ping() async -> Bool {
    true
  }

  func synchroniseKeys(_: SecureBytes) async throws {
    // Mock implementation
  }

  // MARK: - XPCServiceProtocolStandard

  func generateRandomData(length: Int) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    var bytes=[UInt8](repeating: 0, count: length)
    for i in 0..<length {
      bytes[i]=UInt8.random(in: 0...255)
    }
    return .success(SecureBytes(bytes: bytes))
  }

  func encryptSecureData(
    _ data: SecureBytes,
    keyIdentifier _: String?
  ) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Simple mock implementation - just return data unchanged for this example
    .success(data)
  }

  func decryptSecureData(
    _ data: SecureBytes,
    keyIdentifier _: String?
  ) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Simple mock implementation - just return data unchanged for this example
    .success(data)
  }

  func sign(
    _: SecureBytes,
    keyIdentifier _: String
  ) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Mock signature - just use random bytes
    await generateRandomData(length: 32)
  }

  func verify(
    signature _: SecureBytes,
    for _: SecureBytes,
    keyIdentifier _: String
  ) async
  -> Result<Bool, UmbraErrors.Security.Protocols> {
    // Mock verification - always return success for example purposes
    .success(true)
  }

  func pingStandard() async -> Result<Bool, UmbraErrors.Security.Protocols> {
    .success(true)
  }

  func resetSecurity() async -> Result<Void, UmbraErrors.Security.Protocols> {
    .success(())
  }

  func getServiceVersion() async
  -> Result<String, UmbraErrors.Security.Protocols> {
    .success("1.0.0-mock")
  }

  func getHardwareIdentifier() async
  -> Result<String, UmbraErrors.Security.Protocols> {
    .success("MOCK-HARDWARE-ID")
  }

  func status() async
  -> Result<[String: Any], UmbraErrors.Security.Protocols> {
    let status: [String: Any]=[
      "status": "active",
      "version": "1.0.0",
      "uptime": 3600,
      "operations": 42,
      "errors": 0
    ]
    return .success(status)
  }

  // MARK: - XPCServiceProtocolComplete

  func pingAsync() async -> Result<Bool, UmbraErrors.Security.Protocols> {
    .success(true)
  }

  func getDiagnosticInfo() async
  -> Result<String, UmbraErrors.Security.Protocols> {
    .success("Mock XPC Service - All systems operational")
  }

  func getVersion() async -> Result<String, UmbraErrors.Security.Protocols> {
    .success("1.0.0-mock")
  }

  func getMetrics() async
  -> Result<[String: String], UmbraErrors.Security.Protocols> {
    .success([
      "operations": "42",
      "errors": "0",
      "uptime": "3600",
      "memory": "64MB"
    ])
  }

  func getSecurityConfigDTO() async
    -> Result<
      SecurityProtocolsCore.SecurityConfigDTO,
      UmbraErrors.Security.Protocols
    >
  {
    // Return a mock configuration
    .success(SecurityProtocolsCore.SecurityConfigDTO(
      algorithm: "AES-GCM",
      keySizeInBits: 256
    ))
  }

  func generateKeyDTO(
    config: SecurityProtocolsCore
      .SecurityConfigDTO
  ) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Generate a random key of the specified size
    let keyLength=config.keySizeInBits / 8
    return await generateRandomData(length: keyLength)
  }
}
