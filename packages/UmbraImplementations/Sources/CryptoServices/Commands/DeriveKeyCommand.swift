import CommonCrypto
import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 Command for deriving cryptographic keys from existing keys.

 This command implements high-security key derivation with multiple algorithms.
 It follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling.
 */
public class DeriveKeyCommand: BaseCryptoCommand, CryptoCommand {
  /// The type of result returned by this command
  public typealias ResultType=CryptoKey

  /// The identifier of the source key
  private let sourceKeyIdentifier: String

  /// Optional salt for key derivation
  private let salt: [UInt8]?

  /// Optional context information for key derivation
  private let info: [UInt8]?

  /// The type of key to derive
  private let keyType: KeyType

  /// Optional identifier for the derived key
  private let targetIdentifier: String?

  /**
   Create a new key derivation command.
   
   - Parameters:
     - sourceKeyIdentifier: Identifier of the source key to derive from
     - saltData: Optional salt data to use in the derivation
     - info: Optional info data to use in the derivation
     - iterationCount: Iteration count for PBKDF2 (ignored for HKDF)
     - keyType: The type of key to derive
     - targetIdentifier: Optional identifier for the derived key
     - secureStorage: Secure storage instance to use
     - logger: Logger to use
   */
  public init(
    sourceKeyIdentifier: String,
    saltData: [UInt8]?=nil,
    info: [UInt8]?=nil,
    iterationCount: Int=10000,
    keyType: KeyType,
    targetIdentifier: String?=nil,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.sourceKeyIdentifier=sourceKeyIdentifier
    self.salt=saltData
    self.info=info
    self.keyType=keyType
    self.targetIdentifier=targetIdentifier
    super.init(secureStorage: secureStorage, logger: logger)
  }

  /**
   Execute the key derivation command.
   
   - Parameters:
     - context: Logging context
     - operationID: Operation ID for tracking
   - Returns: The derived key or an error
   */
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<CryptoKey, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let logContext=createLogContext(
      operation: "deriveKey",
      correlationID: operationID,
      additionalMetadata: [
        ("sourceKeyIdentifier", (value: sourceKeyIdentifier, privacyLevel: .private)),
        ("keyType", (value: keyType.rawValue, privacyLevel: .public)),
        ("saltProvided", (value: salt != nil ? "true" : "false", privacyLevel: .public)),
        ("infoProvided", (value: info != nil ? "true" : "false", privacyLevel: .public))
      ]
    )

    await logDebug("Starting key derivation operation", context: logContext)

    // Retrieve the source key
    let keyResult=await secureStorage.retrieveData(withIdentifier: sourceKeyIdentifier)

    switch keyResult {
      case let .success(sourceKeyData):
        // Generate a unique identifier if not provided
        let keyIdentifier=targetIdentifier ?? UUID().uuidString
        
        // Default salt if not provided
        let saltData=salt ?? (try? generateRandomBytes(count: 16)) ?? Array(repeating: 0, count: 16)
        
        do {
          // Derive a new key based on the key type
          let derivedKeyData: [UInt8]
          
          switch keyType {
            case .aes:
              // Determine the key size based on key type
              let keySize: Int = 32 // Default to 256-bit (32 bytes)
              
              // Derive the key using PBKDF2 or HKDF
              derivedKeyData=try pbkdf2(
                password: sourceKeyData,
                salt: saltData,
                keySize: keySize,
                iterations: 10000
              )
              
            case .hmac:
              // Determine the key size based on key type
              let keySize: Int = 32 // Default to 256-bit (32 bytes)
              
              // Derive the key using HKDF
              derivedKeyData=try hkdf(
                secret: sourceKeyData,
                salt: saltData,
                info: info ?? [],
                keySize: keySize
              )
              
            case .ec, .rsa:
              // Asymmetric keys cannot be derived using simple KDFs
              throw SecurityStorageError.operationFailed(
                "Key derivation not supported for asymmetric key types"
              )
          }
          
          // Store the derived key in secure storage
          let storeResult=await secureStorage.storeData(
            derivedKeyData,
            withIdentifier: keyIdentifier
          )
          
          switch storeResult {
            case .success:
              // Create the key object
              let key=CryptoKey(
                id: keyIdentifier,
                keyData: Data(derivedKeyData),
                creationDate: Date(),
                expirationDate: nil,
                purpose: .encryption,
                algorithm: .aes256CBC,
                metadata: [
                  "type": keyType.rawValue,
                  "derived": "true",
                  "sourceKey": sourceKeyIdentifier
                ]
              )
              
              await logInfo(
                "Successfully derived \(keyType.rawValue) key",
                context: logContext.withMetadata(
                  LogMetadataDTOCollection().withPrivate(
                    key: "keyIdentifier",
                    value: keyIdentifier
                  )
                )
              )
              
              return .success(key)
              
            case let .failure(error):
              await logError(
                "Failed to store derived key: \(error.localizedDescription)",
                context: logContext
              )
              return .failure(error)
          }
        } catch {
          await logError(
            "Key derivation failed: \(error.localizedDescription)",
            context: logContext
          )
          if let securityError=error as? SecurityStorageError {
            return .failure(securityError)
          } else {
            return .failure(.operationFailed("Key derivation failed: \(error.localizedDescription)"))
          }
        }
        
      case let .failure(error):
        await logError(
          "Failed to retrieve source key: \(error.localizedDescription)",
          context: logContext
        )
        return .failure(error)
    }
  }

  /**
   Generate random bytes.
   
   - Parameter count: Number of bytes to generate
   - Returns: Random bytes
   - Throws: SecurityStorageError if the operation fails
   */
  private func generateRandomBytes(count: Int) throws -> [UInt8] {
    var randomBytes=[UInt8](repeating: 0, count: count)
    let result=SecRandomCopyBytes(kSecRandomDefault, count, &randomBytes)
    
    guard result == errSecSuccess else {
      throw SecurityStorageError.operationFailed("Failed to generate secure random bytes")
    }
    
    return randomBytes
  }

  /**
   Derive a key using PBKDF2.
   
   - Parameters:
     - password: The password or key to derive from
     - salt: Salt data
     - keySize: Size of the derived key in bytes
     - iterations: Number of iterations
   - Returns: Derived key
   - Throws: SecurityStorageError if the operation fails
   */
  private func pbkdf2(
    password: [UInt8],
    salt: [UInt8],
    keySize: Int,
    iterations: Int
  ) throws -> [UInt8] {
    var derivedKey=[UInt8](repeating: 0, count: keySize)
    
    let status=CCKeyDerivationPBKDF(
      CCPBKDFAlgorithm(kCCPBKDF2),
      password,
      password.count,
      salt,
      salt.count,
      CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
      UInt32(iterations),
      &derivedKey,
      keySize
    )
    
    guard status == kCCSuccess else {
      throw SecurityStorageError
        .operationFailed("PBKDF2 key derivation failed with status \(status)")
    }
    
    return derivedKey
  }

  /**
   Derive a key using HKDF.
   
   - Parameters:
     - secret: The secret key to derive from
     - salt: Salt data
     - info: Optional context and application specific information
     - keySize: Size of the derived key in bytes
   - Returns: Derived key
   - Throws: SecurityStorageError if the operation fails
   */
  private func hkdf(
    secret: [UInt8],
    salt: [UInt8],
    info: [UInt8],
    keySize: Int
  ) throws -> [UInt8] {
    // For now, we'll use a simple implementation of HKDF
    // Extract phase - create a pseudorandom key using HMAC-SHA256
    let prk=hmacSHA256(key: salt, data: secret)
    
    // Expand phase - expand the pseudorandom key to the desired length
    var derivedKey=[UInt8]()
    var lastBlock=[UInt8]()
    var counter: UInt8=1
    
    while derivedKey.count < keySize {
      var input=lastBlock
      input.append(contentsOf: info)
      input.append(counter)
      
      lastBlock=hmacSHA256(key: prk, data: input)
      derivedKey.append(contentsOf: lastBlock)
      
      counter+=1
    }
    
    // Truncate to the desired key size
    return Array(derivedKey.prefix(keySize))
  }

  /**
   Compute HMAC-SHA256.
   
   - Parameters:
     - key: The key for HMAC
     - data: The data to authenticate
   - Returns: HMAC result
   */
  private func hmacSHA256(key: [UInt8], data: [UInt8]) -> [UInt8] {
    var digest=[UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    
    CCHmac(
      CCHmacAlgorithm(kCCHmacAlgSHA256),
      key,
      key.count,
      data,
      data.count,
      &digest
    )
    
    return digest
  }
}
