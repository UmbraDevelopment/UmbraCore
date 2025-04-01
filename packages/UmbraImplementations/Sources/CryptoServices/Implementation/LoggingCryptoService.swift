import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 # Logging Crypto Service
 
 Provides logging capabilities for cryptographic operations by wrapping
 any CryptoServiceProtocol implementation and adding comprehensive logging.
 
 This implementation follows the Alpha Dot Five architecture principles:
 - Full actor isolation
 - Privacy-aware logging
 - Proper error handling
 */
public actor LoggingCryptoService: CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol
  
  /// The logger to use for recording operations
  private let logger: LoggingProtocol
  
  /**
   Initializes a new logging crypto service.
   
   This decorator logs all cryptographic operations before and after
   delegating to the wrapped implementation.
   
   - Parameters:
   ///   - wrapping: The service to wrap with logging
   ///   - logger: The logger to use
   */
  public init(wrapping: CryptoServiceProtocol, logger: LoggingProtocol) {
    wrapped = wrapping
    self.logger = logger
  }
  
  // MARK: - CryptoServiceProtocol Implementation
  
  public func encrypt(data: [UInt8], using key: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    let startTime = DispatchTime.now()
    
    // Create metadata for logging
    var metadata = LoggingTypes.PrivacyMetadata()
    metadata["operation"] = .init(value: "encrypt", privacy: .public)
    metadata["dataSize"] = .init(value: "\(data.count)", privacy: .public)
    
    await logger.debug("Starting encryption operation", metadata: metadata, source: "CryptoService")
    
    // Perform the operation
    let result = await wrapped.encrypt(data: data, using: key)
    
    // Log result
    let endTime = DispatchTime.now()
    let elapsed = Float(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000.0
    
    switch result {
    case .success(let encrypted):
      metadata["resultSize"] = .init(value: "\(encrypted.count)", privacy: .public)
      metadata["elapsedMs"] = .init(value: String(format: "%.2f", elapsed), privacy: .public)
      await logger.debug("Encryption completed successfully", metadata: metadata, source: "CryptoService")
    case .failure(let error):
      metadata["error"] = .init(value: "\(error)", privacy: .private)
      metadata["elapsedMs"] = .init(value: String(format: "%.2f", elapsed), privacy: .public)
      await logger.error("Encryption failed: \(error)", metadata: metadata, source: "CryptoService")
    }
    
    return result
  }
  
  public func decrypt(data: [UInt8], using key: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    let startTime = DispatchTime.now()
    
    // Create metadata for logging
    var metadata = LoggingTypes.PrivacyMetadata()
    metadata["operation"] = .init(value: "decrypt", privacy: .public)
    metadata["dataSize"] = .init(value: "\(data.count)", privacy: .public)
    
    await logger.debug("Starting decryption operation", metadata: metadata, source: "CryptoService")
    
    // Perform the operation
    let result = await wrapped.decrypt(data: data, using: key)
    
    // Log result
    let endTime = DispatchTime.now()
    let elapsed = Float(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000.0
    
    switch result {
    case .success(let decrypted):
      metadata["resultSize"] = .init(value: "\(decrypted.count)", privacy: .public)
      metadata["elapsedMs"] = .init(value: String(format: "%.2f", elapsed), privacy: .public)
      await logger.debug("Decryption completed successfully", metadata: metadata, source: "CryptoService")
    case .failure(let error):
      metadata["error"] = .init(value: "\(error)", privacy: .private)
      metadata["elapsedMs"] = .init(value: String(format: "%.2f", elapsed), privacy: .public)
      await logger.error("Decryption failed: \(error)", metadata: metadata, source: "CryptoService")
    }
    
    return result
  }
  
  public func hash(data: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    let startTime = DispatchTime.now()
    
    // Create metadata for logging
    var metadata = LoggingTypes.PrivacyMetadata()
    metadata["operation"] = .init(value: "hash", privacy: .public)
    metadata["dataSize"] = .init(value: "\(data.count)", privacy: .public)
    
    await logger.debug("Starting hash operation", metadata: metadata, source: "CryptoService")
    
    // Perform the operation
    let result = await wrapped.hash(data: data)
    
    // Log result
    let endTime = DispatchTime.now()
    let elapsed = Float(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000.0
    
    switch result {
    case .success(let hash):
      metadata["resultSize"] = .init(value: "\(hash.count)", privacy: .public)
      metadata["elapsedMs"] = .init(value: String(format: "%.2f", elapsed), privacy: .public)
      await logger.debug("Hash operation completed successfully", metadata: metadata, source: "CryptoService")
    case .failure(let error):
      metadata["error"] = .init(value: "\(error)", privacy: .private)
      metadata["elapsedMs"] = .init(value: String(format: "%.2f", elapsed), privacy: .public)
      await logger.error("Hash operation failed: \(error)", metadata: metadata, source: "CryptoService")
    }
    
    return result
  }
  
  public func verifyHash(data: [UInt8], expectedHash: [UInt8]) async -> Result<Bool, SecurityProtocolError> {
    let startTime = DispatchTime.now()
    
    // Create metadata for logging
    var metadata = LoggingTypes.PrivacyMetadata()
    metadata["operation"] = .init(value: "verifyHash", privacy: .public)
    metadata["dataSize"] = .init(value: "\(data.count)", privacy: .public)
    metadata["hashSize"] = .init(value: "\(expectedHash.count)", privacy: .public)
    
    await logger.debug("Starting hash verification", metadata: metadata, source: "CryptoService")
    
    // Perform the operation
    let result = await wrapped.verifyHash(data: data, expectedHash: expectedHash)
    
    // Log result
    let endTime = DispatchTime.now()
    let elapsed = Float(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000.0
    
    switch result {
    case .success(let matches):
      metadata["matches"] = .init(value: "\(matches)", privacy: .public)
      metadata["elapsedMs"] = .init(value: String(format: "%.2f", elapsed), privacy: .public)
      await logger.debug("Hash verification completed", metadata: metadata, source: "CryptoService")
    case .failure(let error):
      metadata["error"] = .init(value: "\(error)", privacy: .private)
      metadata["elapsedMs"] = .init(value: String(format: "%.2f", elapsed), privacy: .public)
      await logger.error("Hash verification failed: \(error)", metadata: metadata, source: "CryptoService")
    }
    
    return result
  }
}
