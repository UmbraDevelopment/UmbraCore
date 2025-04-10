import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 SecureStorageService handles secure data storage operations.
 
 This implementation follows the Alpha Dot Five architecture principles:
 - Privacy-aware logging using SecurityLogContext
 - Consistent error handling with typed exceptions
 - Thread safety through actor-based concurrency
 - Type-safe interfaces with proper parameter validation
 */
actor SecureStorageService: SecureStorageProtocol {
  // MARK: - Properties
  
  /// The logger instance for recording operation details
  private let logger: LoggingProtocol
  
  /// Storage location for secure data (simulated in this implementation)
  private var secureStorage: [String: [UInt8]] = [:]
  
  /**
   Initialises the service with required dependencies
   
   - Parameters:
       - logger: The logging service to use for operation logging
   */
  init(logger: LoggingProtocol) {
    self.logger = logger
  }
  
  // MARK: - SecureStorageProtocol Implementation
  
  /**
   Stores data securely with the given identifier.
   
   - Parameters:
     - data: The data to store as a byte array
     - identifier: A string identifier for the stored data
   - Returns: Success or an error
   */
  public func storeData(_ data: [UInt8], withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
    let operationID = UUID().uuidString
    let startTime = Date()
    
    // Create logging context for the operation
    let logContext = SecurityLogContext(
      operation: "secureStore",
      component: "SecureStorageService",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )
    
    await logger.info("Starting secure storage operation", context: logContext)
    
    do {
      // Check if identifier is valid
      guard !identifier.isEmpty else {
        let error = SecurityStorageError.invalidIdentifier(reason: "Identifier cannot be empty")
        throw error
      }
      
      // Store data in secure storage (simulated)
      secureStorage[identifier] = data
      
      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log success with privacy-aware metadata
      await logger.info(
        "Secure storage operation completed successfully",
        context: logContext.adding(
          key: "identifier",
          value: identifier,
          privacy: .private
        ).adding(
          key: "dataSize",
          value: "\(data.count)",
          privacy: .public
        ).adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacy: .public
        )
      )
      
      return .success(())
    } catch {
      // Calculate duration before failure
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log failure with privacy-aware metadata
      let errorContext = logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      ).adding(
        key: "durationMs",
        value: String(format: "%.2f", duration),
        privacy: .public
      )
      
      await logger.error(
        "Secure storage operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      // Map to appropriate error type
      if let storageError = error as? SecurityStorageError {
        return .failure(storageError)
      } else {
        return .failure(.generalError(reason: error.localizedDescription))
      }
    }
  }
  
  /**
   Retrieves data securely by its identifier.
   
   - Parameter identifier: A string identifying the data to retrieve
   - Returns: The retrieved data as a byte array or an error
   */
  public func retrieveData(withIdentifier identifier: String) async -> Result<[UInt8], SecurityStorageError> {
    let operationID = UUID().uuidString
    let startTime = Date()
    
    // Create logging context for the operation
    let logContext = SecurityLogContext(
      operation: "secureRetrieve",
      component: "SecureStorageService",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )
    
    await logger.info("Starting secure retrieval operation", context: logContext)
    
    do {
      // Check if identifier is valid
      guard !identifier.isEmpty else {
        let error = SecurityStorageError.invalidIdentifier(reason: "Identifier cannot be empty")
        throw error
      }
      
      // Retrieve data from secure storage (simulated)
      guard let data = secureStorage[identifier] else {
        let error = SecurityStorageError.identifierNotFound(identifier: identifier)
        throw error
      }
      
      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log success with privacy-aware metadata
      await logger.info(
        "Secure retrieval operation completed successfully",
        context: logContext.adding(
          key: "identifier",
          value: identifier,
          privacy: .private
        ).adding(
          key: "dataSize",
          value: "\(data.count)",
          privacy: .public
        ).adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacy: .public
        )
      )
      
      return .success(data)
    } catch {
      // Calculate duration before failure
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log failure with privacy-aware metadata
      let errorContext = logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      ).adding(
        key: "durationMs",
        value: String(format: "%.2f", duration),
        privacy: .public
      )
      
      await logger.error(
        "Secure retrieval operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      // Map to appropriate error type
      if let storageError = error as? SecurityStorageError {
        return .failure(storageError)
      } else {
        return .failure(.generalError(reason: error.localizedDescription))
      }
    }
  }
  
  /**
   Deletes data securely by its identifier.
   
   - Parameter identifier: A string identifying the data to delete
   - Returns: Success or an error
   */
  public func deleteData(withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
    let operationID = UUID().uuidString
    let startTime = Date()
    
    // Create logging context for the operation
    let logContext = SecurityLogContext(
      operation: "secureDelete",
      component: "SecureStorageService",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )
    
    await logger.info("Starting secure deletion operation", context: logContext)
    
    do {
      // Check if identifier is valid
      guard !identifier.isEmpty else {
        let error = SecurityStorageError.invalidIdentifier(reason: "Identifier cannot be empty")
        throw error
      }
      
      // Check if data exists
      guard secureStorage[identifier] != nil else {
        let error = SecurityStorageError.identifierNotFound(identifier: identifier)
        throw error
      }
      
      // Delete data from secure storage (simulated)
      secureStorage.removeValue(forKey: identifier)
      
      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log success with privacy-aware metadata
      await logger.info(
        "Secure deletion operation completed successfully",
        context: logContext.adding(
          key: "identifier",
          value: identifier,
          privacy: .private
        ).adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacy: .public
        )
      )
      
      return .success(())
    } catch {
      // Calculate duration before failure
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log failure with privacy-aware metadata
      let errorContext = logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      ).adding(
        key: "durationMs",
        value: String(format: "%.2f", duration),
        privacy: .public
      )
      
      await logger.error(
        "Secure deletion operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      // Map to appropriate error type
      if let storageError = error as? SecurityStorageError {
        return .failure(storageError)
      } else {
        return .failure(.generalError(reason: error.localizedDescription))
      }
    }
  }
  
  /**
   Lists all available data identifiers.
   
   - Returns: An array of data identifiers or an error
   */
  public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
    let operationID = UUID().uuidString
    let startTime = Date()
    
    // Create logging context for the operation
    let logContext = SecurityLogContext(
      operation: "listIdentifiers",
      component: "SecureStorageService",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )
    
    await logger.info("Starting list identifiers operation", context: logContext)
    
    do {
      // Get all identifiers from secure storage (simulated)
      let identifiers = Array(secureStorage.keys)
      
      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log success with privacy-aware metadata
      await logger.info(
        "List identifiers operation completed successfully",
        context: logContext.adding(
          key: "identifierCount",
          value: "\(identifiers.count)",
          privacy: .public
        ).adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacy: .public
        )
      )
      
      return .success(identifiers)
    } catch {
      // Calculate duration before failure
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log failure with privacy-aware metadata
      let errorContext = logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      ).adding(
        key: "durationMs",
        value: String(format: "%.2f", duration),
        privacy: .public
      )
      
      await logger.error(
        "List identifiers operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      return .failure(.generalError(reason: error.localizedDescription))
    }
  }
  
  // MARK: - Bridge Methods for SecurityProviderImpl
  
  /**
   Bridge method to work with Data type and ConfigDTO
   
   - Parameters:
     - data: The data to store
     - identifier: A string identifier for the stored data
   - Throws: SecurityError if the operation fails
   */
  func secureStore(data: Data, identifier: String) async throws {
    // Convert Data to [UInt8]
    let bytes = [UInt8](data)
    
    // Use the protocol implementation
    let result = await storeData(bytes, withIdentifier: identifier)
    
    // Convert Result to throw
    switch result {
    case .success:
      return
    case .failure(let error):
      throw mapToSecurityError(error)
    }
  }
  
  /**
   Bridge method to work with Data type and ConfigDTO
   
   - Parameter identifier: A string identifying the data to retrieve
   - Returns: The retrieved data
   - Throws: SecurityError if the operation fails
   */
  func secureRetrieve(identifier: String) async throws -> Data {
    // Use the protocol implementation
    let result = await retrieveData(withIdentifier: identifier)
    
    // Convert Result to throw
    switch result {
    case .success(let bytes):
      return Data(bytes)
    case .failure(let error):
      throw mapToSecurityError(error)
    }
  }
  
  /**
   Bridge method to work with ConfigDTO
   
   - Parameter identifier: A string identifying the data to delete
   - Throws: SecurityError if the operation fails
   */
  func secureDelete(identifier: String) async throws {
    // Use the protocol implementation
    let result = await deleteData(withIdentifier: identifier)
    
    // Convert Result to throw
    switch result {
    case .success:
      return
    case .failure(let error):
      throw mapToSecurityError(error)
    }
  }
  
  // MARK: - Helper Methods
  
  /**
   Maps StorageError to SecurityError for compatibility
   
   - Parameter error: The storage error to map
   - Returns: A corresponding SecurityError
   */
  private func mapToSecurityError(_ error: SecurityStorageError) -> CoreSecurityTypes.SecurityError {
    switch error {
    case .invalidIdentifier(let reason):
      return .invalidInputData(reason: reason)
    case .identifierNotFound(let identifier):
      return .dataNotFound(reason: "Data with identifier '\(identifier)' not found")
    case .storageFailure(let reason):
      return .storageOperationFailed(reason: reason)
    case .generalError(let reason):
      return .generalError(reason: reason)
    @unknown default:
      return .generalError(reason: "Unknown storage error: \(error.localizedDescription)")
    }
  }
}
