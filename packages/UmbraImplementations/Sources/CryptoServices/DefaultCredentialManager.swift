import CryptoInterfaces
import CryptoTypes
import SecurityTypes
import UmbraErrors
import UmbraErrorsCore
import UmbraErrorsDTOs

/// Default implementation of CredentialManagerProtocol using a SecureStorageProvider
public actor DefaultCredentialManager: CredentialManagerProtocol {
    /// The secure storage provider used for storing credentials
    private let storageProvider: SecureStorageProvider
    
    /// The crypto service used for encryption/decryption
    private let cryptoService: CryptoServiceProtocol
    
    /// Initialise a new credential manager
    /// - Parameters:
    ///   - storageProvider: The storage provider to use
    ///   - cryptoService: The crypto service to use
    public init(storageProvider: SecureStorageProvider, cryptoService: CryptoServiceProtocol) {
        self.storageProvider = storageProvider
        self.cryptoService = cryptoService
    }
    
    /// Save a credential securely
    /// - Parameters:
    ///   - data: Data to store
    ///   - identifier: Identifier for the credential
    public func save(_ data: SecureBytes, forIdentifier identifier: String) async throws {
        // In a real implementation, we would encrypt the data before storing
        // This is a simplified implementation that delegates to the storage provider
        let result = await storageProvider.storeData(data.toData(), forKey: identifier)
        
        switch result {
        case .success:
            return
        case .failure(let error):
            let context = ErrorContext([
                "identifier": identifier,
                "error": error.localizedDescription
            ])
            throw CryptoErrorDTO(
                type: CryptoErrorDTO.CryptoErrorType.operationFailed,
                description: "Failed to store credential",
                context: context,
                underlyingError: error
            )
        }
    }
    
    /// Retrieve a credential
    /// - Parameter identifier: Identifier for the credential
    /// - Returns: Stored data
    public func retrieve(forIdentifier identifier: String) async throws -> SecureBytes {
        let result = await storageProvider.retrieveData(forKey: identifier)
        
        switch result {
        case .success(let data):
            // Convert Data to SecureBytes
            return SecureBytes(bytes: [UInt8](data))
        case .failure(let error):
            let context = ErrorContext([
                "identifier": identifier,
                "error": error.localizedDescription
            ])
            throw CryptoErrorDTO(
                type: CryptoErrorDTO.CryptoErrorType.operationFailed,
                description: "Failed to retrieve credential",
                context: context,
                underlyingError: error
            )
        }
    }
    
    /// Delete a credential
    /// - Parameter identifier: Identifier for the credential
    public func delete(forIdentifier identifier: String) async throws {
        let result = await storageProvider.deleteData(forKey: identifier)
        
        switch result {
        case .success:
            return
        case .failure(let error):
            let context = ErrorContext([
                "identifier": identifier,
                "error": error.localizedDescription
            ])
            throw CryptoErrorDTO(
                type: CryptoErrorDTO.CryptoErrorType.operationFailed,
                description: "Failed to delete credential",
                context: context,
                underlyingError: error
            )
        }
    }
}
