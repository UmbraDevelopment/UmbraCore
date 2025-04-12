import CoreSecurityTypes
import CryptoInterfaces
import Foundation

/**
 # MockCryptoService
 
 A standardised mock implementation of the CryptoServiceProtocol for testing purposes.
 
 This mock provides deterministic responses for all cryptographic operations, making
 it suitable for unit testing and integration testing without requiring actual
 cryptographic operations to be performed.
 
 ## Usage
 
 ```swift
 // Create a mock with default configuration
 let mockCryptoService = MockCryptoService()
 
 // Create a mock with custom secure storage
 let mockCryptoService = MockCryptoService(secureStorage: customSecureStorage)
 
 // Configure the mock to return specific results
 let mockCryptoService = MockCryptoService(
     mockBehaviour: MockCryptoServiceBehaviour(
         shouldSucceed: true,
         mockResponseDelay: 0.1
     )
 )
 ```
 
 ## Features
 
 - Configurable success/failure responses
 - Optional simulated delays to mimic asynchronous operations
 - Custom secure storage support
 - Controllable error conditions
 */
public final class MockCryptoService: CryptoServiceProtocol {
    // MARK: - Configuration
    
    /// Configuration options for the mock crypto service behaviour
    public struct MockBehaviour {
        /// Whether operations should succeed or fail
        public var shouldSucceed: Bool
        
        /// Optional delay in seconds to simulate operation time
        public var mockResponseDelay: TimeInterval?
        
        /// Custom error to return when operations fail
        public var mockError: SecurityStorageError
        
        /// Default mock data to return for retrieveData operations
        public var mockData: Data
        
        /// Whether to log mock operations
        public var logOperations: Bool
        
        public init(
            shouldSucceed: Bool = true,
            mockResponseDelay: TimeInterval? = nil,
            mockError: SecurityStorageError = .storageError("Mock operation failed"),
            mockData: Data = Data([0, 1, 2, 3, 4, 5]),
            logOperations: Bool = false
        ) {
            self.shouldSucceed = shouldSucceed
            self.mockResponseDelay = mockResponseDelay
            self.mockError = mockError
            self.mockData = mockData
            self.logOperations = logOperations
        }
    }
    
    // MARK: - Properties
    
    /// The secure storage implementation to use
    public let secureStorage: SecureStorageProtocol
    
    /// The behaviour configuration for this mock
    private let behaviour: MockBehaviour
    
    /// Optional call handler for monitoring and customising mock responses
    public var callHandler: ((String, [String: Any]) -> Void)?
    
    // MARK: - Initialisation
    
    /**
     Initialises a new mock crypto service with the specified configuration.
     
     - Parameters:
        - secureStorage: The secure storage to use (defaults to MockSecureStorage)
        - behaviour: Configuration for the mock behaviour
     */
    public init(
        secureStorage: SecureStorageProtocol = MockSecureStorage(),
        mockBehaviour: MockBehaviour = MockBehaviour()
    ) {
        self.secureStorage = secureStorage
        self.behaviour = mockBehaviour
    }
    
    // MARK: - Helper Methods
    
    /**
     Simulates an asynchronous operation with configurable delay and success.
     
     - Parameters:
        - operation: The name of the operation for logging
        - params: Parameters associated with the operation
        - successResult: The result to return on success
     - Returns: A result with either the success value or the configured error
     */
    private func mockOperation<T>(
        operation: String,
        params: [String: Any] = [:],
        successResult: T
    ) async -> Result<T, SecurityStorageError> {
        // Log the operation if configured
        if behaviour.logOperations {
            print("MockCryptoService: \(operation) called with \(params)")
        }
        
        // Call the handler if set
        callHandler?(operation, params)
        
        // Simulate delay if configured
        if let delay = behaviour.mockResponseDelay {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Return result based on configuration
        if behaviour.shouldSucceed {
            return .success(successResult)
        } else {
            return .failure(behaviour.mockError)
        }
    }
    
    // MARK: - CryptoServiceProtocol Implementation
    
    public func encrypt(
        dataIdentifier: String,
        keyIdentifier: String,
        options: CoreSecurityTypes.EncryptionOptions?
    ) async -> Result<String, SecurityStorageError> {
        await mockOperation(
            operation: "encrypt",
            params: [
                "dataIdentifier": dataIdentifier,
                "keyIdentifier": keyIdentifier,
                "options": options as Any
            ],
            successResult: "mock-encrypted-\(dataIdentifier)"
        )
    }
    
    public func decrypt(
        encryptedDataIdentifier: String,
        keyIdentifier: String,
        options: CoreSecurityTypes.DecryptionOptions?
    ) async -> Result<String, SecurityStorageError> {
        await mockOperation(
            operation: "decrypt",
            params: [
                "encryptedDataIdentifier": encryptedDataIdentifier,
                "keyIdentifier": keyIdentifier,
                "options": options as Any
            ],
            successResult: "mock-decrypted-\(encryptedDataIdentifier)"
        )
    }
    
    public func hash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<String, SecurityStorageError> {
        await mockOperation(
            operation: "hash",
            params: [
                "dataIdentifier": dataIdentifier,
                "options": options as Any
            ],
            successResult: "mock-hash-\(dataIdentifier)"
        )
    }
    
    public func verifyHash(
        dataIdentifier: String,
        hashIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<Bool, SecurityStorageError> {
        await mockOperation(
            operation: "verifyHash",
            params: [
                "dataIdentifier": dataIdentifier,
                "hashIdentifier": hashIdentifier,
                "options": options as Any
            ],
            successResult: true
        )
    }
    
    public func generateKey(
        length: Int,
        options: CoreSecurityTypes.KeyGenerationOptions?
    ) async -> Result<String, SecurityStorageError> {
        await mockOperation(
            operation: "generateKey",
            params: [
                "length": length,
                "options": options as Any
            ],
            successResult: "mock-key-\(UUID().uuidString)"
        )
    }
    
    public func importData(
        _ data: [UInt8],
        customIdentifier: String?
    ) async -> Result<String, SecurityStorageError> {
        let identifier = customIdentifier ?? "mock-data-\(UUID().uuidString)"
        return await mockOperation(
            operation: "importData",
            params: [
                "data": data,
                "customIdentifier": customIdentifier as Any
            ],
            successResult: identifier
        )
    }
    
    public func exportData(
        identifier: String
    ) async -> Result<[UInt8], SecurityStorageError> {
        await mockOperation(
            operation: "exportData",
            params: ["identifier": identifier],
            successResult: Array(behaviour.mockData)
        )
    }
    
    public func generateHash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<String, SecurityStorageError> {
        await mockOperation(
            operation: "generateHash",
            params: [
                "dataIdentifier": dataIdentifier,
                "options": options as Any
            ],
            successResult: "mock-hash-\(dataIdentifier)"
        )
    }
    
    public func storeData(
        data: Data,
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        await mockOperation(
            operation: "storeData",
            params: [
                "data": data,
                "identifier": identifier
            ],
            successResult: ()
        )
    }
    
    public func retrieveData(
        identifier: String
    ) async -> Result<Data, SecurityStorageError> {
        await mockOperation(
            operation: "retrieveData",
            params: ["identifier": identifier],
            successResult: behaviour.mockData
        )
    }
    
    public func deleteData(
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        await mockOperation(
            operation: "deleteData",
            params: ["identifier": identifier],
            successResult: ()
        )
    }
    
    public func importData(
        _ data: Data,
        customIdentifier: String
    ) async -> Result<String, SecurityStorageError> {
        await mockOperation(
            operation: "importData",
            params: [
                "data": data,
                "customIdentifier": customIdentifier
            ],
            successResult: customIdentifier
        )
    }
}
