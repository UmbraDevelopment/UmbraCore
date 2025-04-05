import CoreDTOs
import Foundation
import SecurityBridge
import SecurityInterfacesBase
import SecurityProtocolsCore
import UmbraCoreTypes
import XPCProtocolsCore

/// Example implementation of SecurityProvider
/// This demonstrates how to implement the SecurityProvider protocol with Foundation types
public final class ExampleSecurityProvider: @unchecked Sendable, SecurityProvider {
  // MARK: - Properties

  private var configuration: SecurityConfiguration
  private let hostIdentifier: String
  private let cryptocomponentsService: any SecurityProtocolsCore.CryptoServiceProtocol
  private let keyManagementService: any SecurityProtocolsCore.KeyManagementProtocol

  // MARK: - Initializer

  public init(
    configuration: SecurityConfiguration=SecurityConfiguration(
      securityLevel: .standard,
      encryptionAlgorithm: "AES-GCM",
      hashAlgorithm: "SHA-256",
      options: nil
    ),
    hostIdentifier: String="example-host-\(UUID().uuidString.prefix(8))",
    cryptocomponentsService: any SecurityProtocolsCore.CryptoServiceProtocol=MockCryptoService(),
    keyManagementService: (any SecurityProtocolsCore.KeyManagementProtocol)?=nil
  ) {
    self.configuration=configuration
    self.hostIdentifier=hostIdentifier
    self.cryptocomponentsService=cryptocomponentsService
    self.keyManagementService=keyManagementService ?? MockKeyManager()
  }

  // MARK: - SecurityProvider Protocol Conformance

  public var cryptoService: any SecurityProtocolsCore.CryptoServiceProtocol {
    cryptocomponentsService
  }

  public var keyManager: any SecurityProtocolsCore.KeyManagementProtocol {
    keyManagementService
  }

  // For backward compatibility
  public var keyService: any SecurityProtocolsCore.KeyManagementProtocol {
    keyManagementService
  }

  /// Perform a security operation with the specified configuration
  /// - Parameters:
  ///   - operation: The operation to perform
  ///   - config: The configuration for the operation
  /// - Returns: The result with data or error
  public func performSecureOperation(
    operation: SecurityProtocolsCore.SecurityOperation,
    config: SecurityProtocolsCore.SecurityConfigDTO
  ) async -> SecurityProtocolsCore.SecurityResultDTO {
    // Log the operation
    print("Performing operation: \(operation) with config: \(config)")

    // Handle different operations
    switch operation {
      case .randomGeneration:
        // Generate random data
        let length=config.keySizeInBits / 8 // Convert bits to bytes
        let result=await cryptocomponentsService.generateRandomData(length: length)

        switch result {
          case let .success(data):
            return SecurityResultDTO(data: data)
          case let .failure(error):
            return SecurityResultDTO(success: false, error: error, errorDetails: nil)
        }

      case .symmetricEncryption:
        // Attempt to extract the input data and key from config
        guard let inputData=config.inputData else {
          return SecurityResultDTO(
            success: false,
            error: .invalidInput("Missing input data for encryption"),
            errorDetails: nil
          )
        }

        guard let key=config.key else {
          return SecurityResultDTO(
            success: false,
            error: .invalidInput("Missing key for encryption"),
            errorDetails: nil
          )
        }

        // Perform encryption
        let result=await cryptocomponentsService.encrypt(data: inputData, using: key)

        switch result {
          case let .success(data):
            return SecurityResultDTO(data: data)
          case let .failure(error):
            return SecurityResultDTO(success: false, error: error, errorDetails: nil)
        }

      case .symmetricDecryption:
        // Attempt to extract the input data and key from config
        guard let inputData=config.inputData else {
          return SecurityResultDTO(
            success: false,
            error: .invalidInput("Missing input data for decryption"),
            errorDetails: nil
          )
        }

        guard let key=config.key else {
          return SecurityResultDTO(
            success: false,
            error: .invalidInput("Missing key for decryption"),
            errorDetails: nil
          )
        }

        // Perform decryption
        let result=await cryptocomponentsService.decrypt(data: inputData, using: key)

        switch result {
          case let .success(data):
            return SecurityResultDTO(data: data)
          case let .failure(error):
            return SecurityResultDTO(success: false, error: error, errorDetails: nil)
        }

      case .hashing:
        // Attempt to extract the input data from config
        guard let inputData=config.inputData else {
          return SecurityResultDTO(
            success: false,
            error: .invalidInput("Missing input data for hashing"),
            errorDetails: nil
          )
        }

        // Perform hashing
        let result=await cryptocomponentsService.hash(data: inputData, config: config)

        switch result {
          case let .success(data):
            return SecurityResultDTO(data: data)
          case let .failure(error):
            return SecurityResultDTO(success: false, error: error, errorDetails: nil)
        }

      case .keyGeneration, .keyStorage, .keyRetrieval:
        // Key management operations
        let result: Result<SecureBytes, UmbraErrors.Security.Protocols>

        switch operation {
          case .keyGeneration:
            // Simple random key generation
            let keySize=config.keySizeInBits / 8
            result=await cryptocomponentsService.generateRandomData(length: keySize)

          case .keyStorage:
            // Store a key
            guard let key=config.key, let keyIdentifier=config.keyIdentifier else {
              return SecurityResultDTO(
                success: false,
                error: .invalidInput("Missing key or key identifier"),
                errorDetails: nil
              )
            }

            let storeResult=await keyManagementService.storeKey(key, withIdentifier: keyIdentifier)

            switch storeResult {
              case .success:
                return SecurityResultDTO(success: true)
              case let .failure(error):
                return SecurityResultDTO(success: false, error: error, errorDetails: nil)
            }

          case .keyRetrieval:
            // Retrieve a key
            guard let keyIdentifier=config.keyIdentifier else {
              return SecurityResultDTO(
                success: false,
                error: .invalidInput("Missing key identifier"),
                errorDetails: nil
              )
            }

            result=await keyManagementService.retrieveKey(withIdentifier: keyIdentifier)

          default:
            return SecurityResultDTO(
              success: false,
              error: .unsupportedOperation("Operation \(operation) not implemented"),
              errorDetails: nil
            )
        }

        switch result {
          case let .success(data):
            return SecurityResultDTO(data: data)
          case let .failure(error):
            return SecurityResultDTO(success: false, error: error, errorDetails: nil)
        }

      default:
        return SecurityResultDTO(
          success: false,
          error: .unsupportedOperation("Operation \(operation) not implemented"),
          errorDetails: nil
        )
    }
  }

  /// Create a secure configuration with appropriate defaults
  /// - Parameter options: Optional dictionary of configuration options
  /// - Returns: A properly configured SecurityConfigDTO
  public func createSecureConfig(options: [String: Any]?) -> SecurityProtocolsCore
  .SecurityConfigDTO {
    // Convert the options dictionary to a SecurityConfig
    let stringOptions=options as? [String: String] ?? [:]

    // Get algorithm and key size from options or defaults
    let algorithm=stringOptions["algorithm"] ?? "AES-GCM"
    let keySizeInBits=Int(stringOptions["keySizeInBits"] ?? "256") ?? 256

    // Create a SecurityConfig with defaults for any missing options
    return SecurityProtocolsCore.SecurityConfigDTO(
      algorithm: algorithm,
      keySizeInBits: keySizeInBits,
      options: stringOptions
    )
  }

  // MARK: - SecurityProvider Protocol Conformance

  public func getSecurityConfiguration() async
  -> Result<SecurityConfiguration, SecurityInterfacesError> {
    .success(SecurityConfiguration(
      securityLevel: .standard,
      encryptionAlgorithm: "AES-256",
      hashAlgorithm: "SHA-256",
      options: [:]
    ))
  }

  public func updateSecurityConfiguration(_: SecurityConfiguration) async throws {
    // In a real implementation, this would update the configuration
  }

  public func getHostIdentifier() async -> Result<String, SecurityInterfacesError> {
    .success(hostIdentifier)
  }

  public func registerClient(bundleIdentifier _: String) async
  -> Result<Bool, SecurityInterfacesError> {
    .success(true)
  }

  public func requestKeyRotation(keyID _: String) async -> Result<Void, SecurityInterfacesError> {
    .success(())
  }

  public func notifyKeyCompromise(keyID _: String) async -> Result<Void, SecurityInterfacesError> {
    .success(())
  }

  public func generateRandomData(length: Int) async
  -> Result<SecureBytes, SecurityInterfacesError> {
    do {
      let randomBytes=await cryptocomponentsService.generateRandomData(length: length)
      switch randomBytes {
        case let .success(randomData):
          return .success(randomData)
        case let .failure(error):
          return .failure(.randomGenerationFailed)
      }
  }

  public func getKeyInfo(keyID: String) async
  -> Result<[String: AnyObject], SecurityInterfacesError> {
    // Mock implementation
    let info: [String: AnyObject]=[
      "keyId": keyID as NSString,
      "created": Date() as NSDate,
      "algorithm": "AES256" as NSString
    ]
    return .success(info)
  }

  public func registerNotifications() async -> Result<Void, SecurityInterfacesError> {
    .success(())
  }

  public func randomBytes(count: Int) async -> Result<SecureBytes, SecurityInterfacesError> {
    do {
      let randomBytes=await cryptocomponentsService.generateRandomData(length: count)
      switch randomBytes {
        case let .success(randomData):
          return .success(randomData)
        case let .failure(error):
          return .failure(.randomGenerationFailed)
      }
  }

  public func encryptData(_ data: SecureBytes, withKey key: SecureBytes) async
    -> Result<SecureBytes, SecurityInterfacesError>
  {
    do {
      let encryptedData=try await cryptocomponentsService.encrypt(data: data, using: key)
      switch encryptedData {
        case let .success(encrypted):
          return .success(encrypted)
        case let .failure(error):
          return .failure(.encryptionFailed(reason: error.localizedDescription))
      }
    } catch {
      return .failure(.encryptionFailed(reason: error.localizedDescription))
    }
  }

  // Helper method to create SecureBytes from Data
  private func secureBytes(from data: Data) -> SecureBytes {
    var bytes=[UInt8](repeating: 0, count: data.count)
    data.copyBytes(to: &bytes, count: data.count)
    return SecureBytes(bytes: bytes)
  }

  public func performSecurityOperation(
    operation: SecurityProtocolsCore.SecurityOperation,
    data: Data?,
    parameters: [String: String]
  ) async throws -> SecurityResult {
    // Convert Data to SecureBytes if needed
    let secureData=data.map { secureBytes(from: $0) }

    do {
      let result=try await performSecurityOperationWithLogging(
        operation: operation,
        data: secureData,
        parameters: parameters
      )

      // Convert result back to Data
      let resultData=dataFrom(secureBytes: result)
      return SecurityResult(success: true, data: resultData, metadata: parameters)
    } catch {
      return SecurityResult(
        success: false,
        metadata: ["error": error.localizedDescription]
      )
    }
  }

  public func performSecurityOperation(
    operationName: String,
    data: Data?,
    parameters: [String: String]
  ) async throws -> SecurityResult {
    // Convert the string operation name to SecurityOperation if possible
    if let operation=SecurityProtocolsCore.SecurityOperation(rawValue: operationName) {
      return try await performSecurityOperation(
        operation: operation,
        data: data,
        parameters: parameters
      )
    } else {
      // Handle custom operations
      let secureData=data.map { secureBytes(from: $0) }

      do {
        let result=try await performSecurityOperation(
          operationName: operationName,
          data: secureData,
          parameters: parameters
        )

        // Convert the result
        let resultData=result.data.map { dataFrom(secureBytes: $0) }
        return SecurityResult(
          success: result.success,
          data: resultData,
          metadata: parameters
        )
      } catch {
        return SecurityResult(
          success: false,
          metadata: ["error": error.localizedDescription]
        )
      }
    }
  }

  /// Perform a security operation with logging
  /// - Parameters:
  ///   - operation: The operation to perform
  ///   - data: The data to use in the operation
  ///   - parameters: Additional parameters for the operation
  /// - Returns: The operation result data
  /// - Throws: UmbraErrors.Security.Protocols if the operation fails
  func performSecurityOperationWithLogging(
    operation: SecurityProtocolsCore.SecurityOperation,
    data: SecureBytes?,
    parameters: [String: String]
  ) async throws -> SecureBytes {
    // Log the operation
    print("Performing operation: \(operation) with parameters: \(parameters)")

    // Generate some random data as a placeholder for the result
    switch operation {
      case .symmetricEncryption:
        guard let inputData=data else {
          throw UmbraErrors.Security.Protocols.invalidInput("Missing input data for encryption")
        }

        // In a real implementation, this would do actual encryption
        let result=await cryptoService.encrypt(data: inputData, using: SecureBytes(capacity: 32))
        switch result {
          case let .success(encryptedData):
            return encryptedData
          case let .failure(error):
            throw error
        }

      case .symmetricDecryption:
        guard let inputData=data else {
          throw UmbraErrors.Security.Protocols.invalidInput("Missing input data for decryption")
        }

        // In a real implementation, this would do actual decryption
        let result=await cryptoService.decrypt(data: inputData, using: SecureBytes(capacity: 32))
        switch result {
          case let .success(decrypted):
            return decrypted
          case let .failure(error):
            throw error
        }

      case .hashing:
        guard let inputData=data else {
          throw UmbraErrors.Security.Protocols.invalidInput("Missing input data for hashing")
        }

        // In a real implementation, this would do actual hashing
        let result=await cryptoService.hash(data: inputData)
        switch result {
          case let .success(hashedData):
            return hashedData
          case let .failure(error):
            throw error
        }

      case .signatureGeneration:
        guard let inputData=data else {
          throw UmbraErrors.Security.Protocols.invalidInput("Missing input data for signing")
        }

        // For signing, we would need a proper implementation
        throw UmbraErrors.Security.Protocols
          .notImplemented("Signing not implemented in example provider")

      case .signatureVerification:
        // In a real implementation, this would do actual verification
        return SecureBytes(capacity: 0) // Empty result indicates success

      case .keyGeneration:
        // Generate a random key
        let result=await cryptoService.generateKey()
        switch result {
          case let .success(key):
            return key
          case let .failure(error):
            throw error
        }

      case .randomGeneration:
        // In a real implementation, this would derive a key
        let result=await cryptoService.generateRandomData(length: 32)
        switch result {
          case let .success(key):
            return key
          case let .failure(error):
            throw error
        }

      default:
        throw UmbraErrors.Security.Protocols
          .unsupportedOperation("Operation not supported: \(operation)")
    }
  }

  /// Perform a security operation with a custom operation name
  /// - Parameters:
  ///   - operationName: The name of the operation
  ///   - data: The data to use
  ///   - parameters: Additional parameters
  /// - Returns: The operation result
  /// - Throws: Error if the operation fails
  func performSecurityOperation(
    operationName: String,
    data: SecureBytes?,
    parameters: [String: String]
  ) async throws -> SecurityOperationResult {
    // Handle custom operations
    switch operationName {
      case "custom.generateNonce":
        let length=Int(parameters["length"] ?? "16") ?? 16
        let result=await cryptoService.generateRandomData(length: length)
        switch result {
          case let .success(randomData):
            return SecurityOperationResult(data: randomData)
          case let .failure(error):
            throw error
        }

      case "custom.tokenize":
        guard let inputData=data else {
          throw UmbraErrors.Security.Protocols.invalidInput("Missing input data for tokenization")
        }

        // Mock tokenization by generating a token of the same length
        let result=await cryptoService.generateRandomData(length: inputData.count)
        switch result {
          case let .success(tokenData):
            return SecurityOperationResult(data: tokenData)
          case let .failure(error):
            throw error
        }

      default:
        throw UmbraErrors.Security.Protocols
          .unsupportedOperation("Unsupported custom operation: \(operationName)")
    }
  }

  /// Create a secure configuration from options
  /// - Parameter options: Configuration options
  /// - Returns: The security configuration DTO
  public func createSecureConfig(options: [String: Any]?) -> SecurityProtocolsCore
  .SecurityConfigDTO {
    // Convert the options dictionary to a SecurityConfig
    let stringOptions=options as? [String: String] ?? [:]

    // Get algorithm and key size from options or defaults
    let algorithm=stringOptions["algorithm"] ?? "AES-GCM"
    let keySizeInBits=Int(stringOptions["keySizeInBits"] ?? "256") ?? 256

    // Create a SecurityConfig with defaults for any missing options
    return SecurityProtocolsCore.SecurityConfigDTO(
      algorithm: algorithm,
      keySizeInBits: keySizeInBits,
      options: stringOptions
    )
  }

  // Legacy method with different signature
  private func createSecureConfig(options: [String: String]?) -> SecurityProtocolsCore
  .SecurityConfigDTO {
    createSecureConfig(options: options as [String: Any]?)
  }

  /// Convert secure data to result
  /// - Parameter result: The secure operation result
  /// - Returns: A DTO representation of the result
  private func secureResultToDTO(_ result: Result<SecureBytes, UmbraErrors.Security.Protocols>)
    -> SecurityResultDTO
  {
    switch result {
      case let .success(data):
        SecurityResultDTO(data: data)
      case let .failure(error):
        SecurityResultDTO(success: false, error: error, errorDetails: nil)
    }
  }

  /// Convert Data to SecureBytes
  /// - Parameter data: The Foundation Data to convert
  /// - Returns: The SecureBytes representation
  private func convertToSecureBytes(from data: Data) -> SecureBytes {
    var bytes=[UInt8](repeating: 0, count: data.count)
    data.copyBytes(to: &bytes, count: data.count)
    return SecureBytes(bytes: bytes)
  }

  /// Convert SecureBytes to Data
  /// - Parameter secureBytes: The SecureBytes to convert
  /// - Returns: Data representation
  func dataFrom(secureBytes: SecureBytes) -> Data {
    secureBytes.withUnsafeBytes { bufferPointer in
      Data(bufferPointer)
    }
  }

  /// Mapping from SecurityResult to SecurityOperationResult
  /// - Parameter securityResult: The security result
  /// - Returns: The security operation result
  private func mapToOperationResult(_ securityResult: SecurityResultDTO)
  -> SecurityOperationResult {
    if securityResult.success {
      SecurityOperationResult(data: securityResult.data ?? SecureBytes(capacity: 0))
    } else {
      SecurityOperationResult(
        errorCode: securityResult.errorCode ?? -1,
        errorMessage: securityResult.errorMessage ?? "Unknown error"
      )
    }
  }
}

/// Example implementation of SecurityProviderDTO
/// This demonstrates how to directly implement the DTO-based protocol
/// without using Foundation types
public final class ExampleSecurityProviderDTO: @unchecked Sendable,
SecurityProtocolsCore.SecurityProviderProtocol {
  // MARK: - Properties

  private var configuration: SecurityProtocolsCore.SecurityConfigDTO
  private let hostIdentifier: String

  // Required by SecurityProviderProtocol
  public let cryptoService: SecurityProtocolsCore.CryptoServiceProtocol
  public let keyManager: SecurityProtocolsCore.KeyManagementProtocol

  // MARK: - Initializer

  public init(
    configuration: SecurityProtocolsCore.SecurityConfigDTO,
    hostIdentifier: String=UUID().uuidString
  ) {
    self.configuration=configuration
    self.hostIdentifier=hostIdentifier
    cryptoService=MockCryptoService()
    keyManager=MockKeyManager()
  }

  // MARK: - SecurityProviderDTO Implementation

  public func getSecurityConfigDTO() async
  -> Result<SecurityProtocolsCore.SecurityConfigDTO, CoreDTOs.SecurityErrorDTO> {
    .success(configuration)
  }

  public func updateSecurityConfigDTO(
    _ configuration: SecurityProtocolsCore
      .SecurityConfigDTO
  ) async -> Result<Void, CoreDTOs.SecurityErrorDTO> {
    self.configuration=configuration
    return .success(())
  }

  public func getHostIdentifier() async -> Result<String, CoreDTOs.SecurityErrorDTO> {
    .success(hostIdentifier)
  }

  public func registerClient(bundleIdentifier _: String) async
  -> Result<Bool, CoreDTOs.SecurityErrorDTO> {
    .success(true)
  }

  public func requestKeyRotation(keyID _: String) async -> Result<Void, CoreDTOs.SecurityErrorDTO> {
    .success(())
  }

  public func notifyKeyCompromise(keyID _: String) async
  -> Result<Void, CoreDTOs.SecurityErrorDTO> {
    .success(())
  }

  public func generateRandomData(length: Int) async
  -> Result<SecureBytes, CoreDTOs.SecurityErrorDTO> {
    // For demo purposes; in a real implementation, would use a Foundation-independent
    // random number generator
    var randomBytes=[UInt8](repeating: 0, count: length)

    for i in 0..<length {
      randomBytes[i]=UInt8.random(in: 0...255)
    }

    return .success(SecureBytes(bytes: randomBytes))
  }

  public func randomBytes(count: Int) async -> Result<SecureBytes, CoreDTOs.SecurityErrorDTO> {
    await generateRandomData(length: count)
  }

  public func encryptData(
    _ data: SecureBytes,
    withKey key: SecureBytes
  ) async -> Result<SecureBytes, CoreDTOs.SecurityErrorDTO> {
    // Simple example implementation
    var bytesToEncrypt=[UInt8](repeating: 0, count: data.count)
    var keyBytes=[UInt8](repeating: 0, count: key.count)

    // Extract bytes from SecureBytes using byte(at:) method
    for i in 0..<data.count {
      do {
        bytesToEncrypt[i]=try data.byte(at: i)
      } catch {
        return .failure(CoreDTOs.SecurityErrorDTO(
          code: 1001,
          domain: "security.encryption",
          message: "Error accessing data bytes",
          details: [:]
        ))
      }
    }

    for i in 0..<key.count {
      do {
        keyBytes[i]=try key.byte(at: i)
      } catch {
        return .failure(CoreDTOs.SecurityErrorDTO(
          code: 1001,
          domain: "security.encryption",
          message: "Error accessing key bytes",
          details: [:]
        ))
      }
    }

    // XOR with key for demonstration purposes only
    var encrypted=[UInt8](repeating: 0, count: bytesToEncrypt.count)
    for i in 0..<bytesToEncrypt.count {
      encrypted[i]=bytesToEncrypt[i] ^ keyBytes[i % keyBytes.count]
    }

    return .success(SecureBytes(bytes: encrypted))
  }

  public func performSecurityOperationDTO(
    operation: SecurityProtocolsCore.SecurityOperation,
    data: SecureBytes?,
    parameters: [String: String]
  ) async -> Result<SecureBytes, CoreDTOs.SecurityErrorDTO> {
    // Implementation based on operation type
    switch operation {
      case .symmetricEncryption:
        guard let inputData=data else {
          return .failure(CoreDTOs.SecurityErrorDTO(
            code: 4001,
            domain: "security.operation",
            message: "Missing input data for encryption",
            details: ["operation": operation.rawValue]
          ))
        }

        guard let keyBytes=parameters["key"] else {
          return .failure(CoreDTOs.SecurityErrorDTO(
            code: 4002,
            domain: "security.operation",
            message: "Missing key for encryption",
            details: ["operation": operation.rawValue]
          ))
        }

        return await encryptData(inputData, withKey: SecureBytes(bytes: [UInt8](keyBytes.utf8)))

      case .symmetricDecryption:
        guard let inputData=data else {
          return .failure(CoreDTOs.SecurityErrorDTO(
            code: 4001,
            domain: "security.operation",
            message: "Missing input data for decryption",
            details: ["operation": operation.rawValue]
          ))
        }

        guard let keyBytes=parameters["key"] else {
          return .failure(CoreDTOs.SecurityErrorDTO(
            code: 4002,
            domain: "security.operation",
            message: "Missing key for decryption",
            details: ["operation": operation.rawValue]
          ))
        }

        return await encryptData(inputData, withKey: SecureBytes(bytes: [UInt8](keyBytes.utf8)))

      case .hashing:
        guard let inputData=data else {
          return .failure(CoreDTOs.SecurityErrorDTO(
            code: 4001,
            domain: "security.operation",
            message: "Missing input data for hashing",
            details: ["operation": operation.rawValue]
          ))
        }

        // Very simple "hash" for example purposes - NOT a real hash
        var hash=[UInt8](repeating: 0, count: 32)
        var bytes=[UInt8](repeating: 0, count: inputData.count)
        for i in 0..<inputData.count {
          do {
            bytes[i]=try inputData.byte(at: i)
          } catch {
            return .failure(CoreDTOs.SecurityErrorDTO(
              code: 4005,
              domain: "security.operation",
              message: "Error accessing input data bytes",
              details: ["operation": operation.rawValue]
            ))
          }
        }
        for i in 0..<bytes.count {
          hash[i % 32] ^= bytes[i]
        }

        return .success(SecureBytes(bytes: hash))

      case .keyGeneration:
        let keySize=Int(parameters["keySize"] ?? "32") ?? 32
        return await generateRandomData(length: keySize)

      case .asymmetricEncryption, .asymmetricDecryption:
        return .failure(CoreDTOs.SecurityErrorDTO(
          code: 4007,
          domain: "security.operation",
          message: "Operation not implemented in example provider",
          details: ["operation": operation.rawValue]
        ))

      default:
        // Handle any new operations added to enum in the future
        let keySize=Int(parameters["keySize"] ?? "32") ?? 32
        return await generateRandomData(length: keySize)
    }
  }

  public func performSecurityOperationDTO(
    operationName: String,
    data: SecureBytes?,
    parameters: [String: String]
  ) async -> Result<SecureBytes, CoreDTOs.SecurityErrorDTO> {
    // Convert operation name to enum if possible
    if let operation=SecurityProtocolsCore.SecurityOperation(rawValue: operationName) {
      await performSecurityOperationDTO(
        operation: operation,
        data: data,
        parameters: parameters
      )
    } else {
      .failure(CoreDTOs.SecurityErrorDTO(
        code: 4007,
        domain: "security.operation",
        message: "Unknown operation",
        details: ["operationName": operationName]
      ))
    }
  }

  public func createSecureConfig(options: [String: Any]?) -> SecurityProtocolsCore
  .SecurityConfigDTO {
    let stringOptions: [String: String]=options?.compactMapValues { value in
      if let stringValue=value as? String {
        return stringValue
      }
      return String(describing: value)
    } ?? [:]

    return SecurityProtocolsCore.SecurityConfigDTO(
      algorithm: configuration.algorithm,
      keySizeInBits: configuration.keySizeInBits,
      options: stringOptions
    )
  }

  public func performSecureOperation(
    operation: SecurityProtocolsCore.SecurityOperation,
    config: SecurityProtocolsCore.SecurityConfigDTO
  ) async -> SecurityProtocolsCore.SecurityResultDTO {
    // Create an async result
    do {
      let result=try await performSecurityOperationWithLogging(
        operation: operation,
        data: nil,
        parameters: config.options
      )

      return SecurityProtocolsCore.SecurityResultDTO(data: result)
    } catch let error as UmbraErrors.Security.Protocols {
      return SecurityProtocolsCore.SecurityResultDTO(
        success: false,
        error: error,
        errorDetails: "Operation failed: \(error)"
      )
    } catch {
      return SecurityProtocolsCore.SecurityResultDTO(
        errorCode: 1000,
        errorMessage: "Unknown error: \(error)"
      )
    }
  }
}
