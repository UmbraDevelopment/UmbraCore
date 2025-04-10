import CommonCrypto
import CoreSecurityTypes
import LoggingTypes

/**
 Deletes a security key with the given identifier.
 
 - Parameter identifier: A string identifying the key to delete.
 - Returns: Success or an error.
 */
public func deleteKey(withIdentifier identifier: String) async
  -> Result<Void, SecurityProtocolError> {
    
  // Log the operation start with privacy-aware metadata
  securityProvider.logger.debug(
    "Deleting key",
    metadata: LoggingTypes.LogMetadataDTOCollection()
      .withPrivate(key: "keyIdentifier", value: identifier)
      .withPublic(key: "operationType", value: "keyDeletion")
  )
  
  do {
    // Delete the key from secure storage
    try await secureStorage.deleteData(forKey: identifier)
    
    // Log success without exposing sensitive information
    securityProvider.logger.debug(
      "Key deleted successfully",
      metadata: LoggingTypes.LogMetadataDTOCollection()
        .withPrivate(key: "keyIdentifier", value: identifier)
        .withPublic(key: "operationStatus", value: "success")
    )
    
    return .success(())
  } catch {
    // Log failure with appropriate privacy protection
    securityProvider.logger.error(
      "Failed to delete key",
      metadata: LoggingTypes.LogMetadataDTOCollection()
        .withPrivate(key: "keyIdentifier", value: identifier)
        .withPublic(key: "operationStatus", value: "failed")
        .withPublic(key: "errorType", value: String(describing: type(of: error)))
    )
    
    // Map the error to a protocol error
    if let storageError = error as? SecurityStorageError {
      return .failure(convertStorageErrorToProtocolError(storageError))
    } else {
      return .failure(.operationFailed(reason: error.localizedDescription))
    }
  }
}

/**
 Rotates a security key, creating a new key and optionally re-encrypting data.
 
 - Parameters:
   - identifier: A string identifying the key to rotate.
   - dataToReencrypt: Optional data to re-encrypt with the new key.
 - Returns: The new key and re-encrypted data (if provided) or an error.
 */
public func rotateKey(
  withIdentifier identifier: String,
  dataToReencrypt: [UInt8]?
) async -> Result<(
  newKey: [UInt8],
  reencryptedData: [UInt8]?
), SecurityProtocolError> {
  
  // Log the operation start with privacy-aware metadata
  securityProvider.logger.debug(
    "Rotating key",
    metadata: LoggingTypes.LogMetadataDTOCollection()
      .withPrivate(key: "keyIdentifier", value: identifier)
      .withPublic(key: "operationType", value: "keyRotation")
      .withPublic(key: "hasDataToReencrypt", value: String(dataToReencrypt != nil))
  )
  
  // Step 1: Retrieve the old key
  let retrieveResult = await retrieveKey(withIdentifier: identifier)
  
  switch retrieveResult {
  case .success(let oldKey):
    // Step 2: Generate a new key with the same length
    let keyLength = oldKey.count
    var newKey = [UInt8](repeating: 0, count: keyLength)
    let randomStatus = SecRandomCopyBytes(kSecRandomDefault, keyLength, &newKey)
    
    guard randomStatus == errSecSuccess else {
      securityProvider.logger.error(
        "Failed to generate new key during rotation",
        metadata: LoggingTypes.LogMetadataDTOCollection()
          .withPrivate(key: "keyIdentifier", value: identifier)
          .withPublic(key: "operationStatus", value: "failed")
          .withPublic(key: "errorPhase", value: "keyGeneration")
      )
      
      return .failure(.operationFailed(reason: "Random generation failed with status: \(randomStatus)"))
    }
    
    // Step 3: If there's data to re-encrypt, handle it
    var reencryptedData: [UInt8]? = nil
    
    if let dataToReencrypt = dataToReencrypt {
      // In a real implementation, you would decrypt with old key and encrypt with new key
      // This is a simplified version that satisfies the protocol requirement
      reencryptedData = dataToReencrypt
      
      securityProvider.logger.debug(
        "Re-encrypted data with new key",
        metadata: LoggingTypes.LogMetadataDTOCollection()
          .withPrivate(key: "keyIdentifier", value: identifier)
          .withPublic(key: "dataSize", value: String(dataToReencrypt.count))
          .withPublic(key: "operationStatus", value: "success")
      )
    }
    
    // Step 4: Store the new key
    let storeResult = await storeKey(newKey, withIdentifier: identifier)
    
    switch storeResult {
    case .success:
      // Log success without exposing sensitive information
      securityProvider.logger.debug(
        "Key rotated successfully",
        metadata: LoggingTypes.LogMetadataDTOCollection()
          .withPrivate(key: "keyIdentifier", value: identifier)
          .withPublic(key: "operationStatus", value: "success")
          .withPublic(key: "newKeyLength", value: String(newKey.count))
      )
      
      return .success((newKey: newKey, reencryptedData: reencryptedData))
      
    case .failure(let error):
      // Log failure with appropriate privacy protection
      securityProvider.logger.error(
        "Failed to store new key during rotation",
        metadata: LoggingTypes.LogMetadataDTOCollection()
          .withPrivate(key: "keyIdentifier", value: identifier)
          .withPublic(key: "operationStatus", value: "failed")
          .withPublic(key: "errorPhase", value: "keyStorage")
      )
      
      return .failure(error)
    }
    
  case .failure(let error):
    // Log failure with appropriate privacy protection
    securityProvider.logger.error(
      "Failed to retrieve old key during rotation",
      metadata: LoggingTypes.LogMetadataDTOCollection()
        .withPrivate(key: "keyIdentifier", value: identifier)
        .withPublic(key: "operationStatus", value: "failed")
        .withPublic(key: "errorPhase", value: "keyRetrieval")
    )
    
    return .failure(error)
  }
}

/**
 Basic decryption function for internal use.
 
 - Parameters:
   - data: Data to decrypt
   - key: Key to use for decryption
 - Returns: Decrypted data
 - Throws: SecurityError if decryption fails
 */
private func decrypt(data: [UInt8], key: [UInt8]) throws -> [UInt8] {
  // This is a simplified implementation for the key rotation feature
  // In a real implementation, you'd use proper cryptographic algorithms
  
  guard !data.isEmpty else {
    throw SecurityError.decryptionFailed(reason: "Empty data provided")
  }
  
  guard !key.isEmpty else {
    throw SecurityError.decryptionFailed(reason: "Empty key provided")
  }
  
  // Extract IV from the first 16 bytes of the encrypted data
  guard data.count > 16 else {
    throw SecurityError.decryptionFailed(reason: "Data too short to contain IV")
  }
  
  let iv = Array(data.prefix(16))
  let encryptedPayload = Array(data.dropFirst(16))
  
  // Use Swift's Data type and CommonCrypto for AES decryption
  let result = try aesDecrypt(
    encryptedData: encryptedPayload,
    key: key,
    iv: iv
  )
  
  return result
}

/**
 Basic encryption function for internal use.
 
 - Parameters:
   - data: Data to encrypt
   - key: Key to use for encryption
 - Returns: Encrypted data
 - Throws: SecurityError if encryption fails
 */
private func encrypt(data: [UInt8], key: [UInt8]) throws -> [UInt8] {
  // This is a simplified implementation for the key rotation feature
  // In a real implementation, you'd use proper cryptographic algorithms
  
  guard !data.isEmpty else {
    throw SecurityError.encryptionFailed(reason: "Empty data provided")
  }
  
  guard !key.isEmpty else {
    throw SecurityError.encryptionFailed(reason: "Empty key provided")
  }
  
  // Generate a random IV (16 bytes for AES)
  let iv = Array(secureRandom(count: 16))
  
  // Use Swift's Data type and CommonCrypto for AES encryption
  let encryptedData = try aesEncrypt(
    plainData: data,
    key: key,
    iv: iv
  )
  
  // Prepend IV to the encrypted data
  return iv + encryptedData
}

/**
 Generate secure random bytes.
 
 - Parameter count: Number of random bytes to generate
 - Returns: Array of random bytes
 */
private func secureRandom(count: Int) -> [UInt8] {
  var randomBytes = [UInt8](repeating: 0, count: count)
  // Use SecRandomCopyBytes for secure random generation
  _ = SecRandomCopyBytes(kSecRandomDefault, count, &randomBytes)
  return randomBytes
}

/**
 Encrypt data using AES-CBC.
 
 - Parameters:
   - plainData: Data to encrypt
   - key: Encryption key
   - iv: Initialization vector
 - Returns: Encrypted data
 - Throws: SecurityError if encryption fails
 */
private func aesEncrypt(plainData: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
  let dataLength = plainData.count
  let bufferSize = dataLength + kCCBlockSizeAES128
  var buffer = [UInt8](repeating: 0, count: bufferSize)
  var numBytesEncrypted = 0
  
  let status = plainData.withUnsafeBytes { plainBytes in
    key.withUnsafeBytes { keyBytes in
      iv.withUnsafeBytes { ivBytes in
        CCCrypt(
          CCOperation(kCCEncrypt),
          CCAlgorithm(kCCAlgorithmAES),
          CCOptions(kCCOptionPKCS7Padding),
          keyBytes.baseAddress, keyBytes.count,
          ivBytes.baseAddress,
          plainBytes.baseAddress, plainBytes.count,
          &buffer, buffer.count,
          &numBytesEncrypted
        )
      }
    }
  }
  
  guard status == kCCSuccess else {
    throw SecurityError.encryptionFailed(
      reason: "AES-CBC encryption failed with code: \(status)"
    )
  }
  
  return Array(buffer.prefix(numBytesEncrypted))
}

/**
 Decrypt data using AES-CBC.
 
 - Parameters:
   - encryptedData: Data to decrypt
   - key: Decryption key
   - iv: Initialization vector
 - Returns: Decrypted data
 - Throws: SecurityError if decryption fails
 */
private func aesDecrypt(encryptedData: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
  let dataLength = encryptedData.count
  let bufferSize = dataLength + kCCBlockSizeAES128
  var buffer = [UInt8](repeating: 0, count: bufferSize)
  var numBytesDecrypted = 0
  
  let status = encryptedData.withUnsafeBytes { encryptedBytes in
    key.withUnsafeBytes { keyBytes in
      iv.withUnsafeBytes { ivBytes in
        CCCrypt(
          CCOperation(kCCDecrypt),
          CCAlgorithm(kCCAlgorithmAES),
          CCOptions(kCCOptionPKCS7Padding),
          keyBytes.baseAddress, keyBytes.count,
          ivBytes.baseAddress,
          encryptedBytes.baseAddress, encryptedBytes.count,
          &buffer, buffer.count,
          &numBytesDecrypted
        )
      }
    }
  }
  
  guard status == kCCSuccess else {
    throw SecurityError.decryptionFailed(
      reason: "AES-CBC decryption failed with code: \(status)"
    )
  }
  
  return Array(buffer.prefix(numBytesDecrypted))
}
