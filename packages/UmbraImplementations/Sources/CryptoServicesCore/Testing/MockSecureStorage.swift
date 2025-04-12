import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

/**
 # MockSecureStorage
 
 A standardised mock implementation of the SecureStorageProtocol for testing.
 
 This mock provides an in-memory implementation of secure storage with configurable
 behaviour for success and failure cases. It's suitable for unit testing and
 integration testing of components that rely on secure storage.
 
 ## Usage
 
 ```swift
 // Create a mock with default configuration
 let mockStorage = MockSecureStorage()
 
 // Create a mock that simulates failures
 let mockStorage = MockSecureStorage(shouldSucceed: false)
 
 // Configure behaviour with more options
 let mockStorage = MockSecureStorage(
     shouldSucceed: true,
     mockResponseDelay: 0.1,
     preloadedData: ["existing-id": Data([1, 2, 3])]
 )
 ```
 
 ## Features
 
 - In-memory storage that persists during the lifetime of the object
 - Configurable success/failure responses
 - Optional simulated delays to mimic asynchronous operations
 - Preloaded data option for testing retrieval scenarios
 - Operation logging for debugging and verification
 */
public final class MockSecureStorage: SecureStorageProtocol {
    // MARK: - Types
    
    /// Configuration options for the mock storage behaviour
    public struct MockBehaviour {
        /// Whether operations should succeed or fail
        public var shouldSucceed: Bool
        
        /// Optional delay in seconds to simulate operation time
        public var mockResponseDelay: TimeInterval?
        
        /// Custom error to return when operations fail
        public var mockError: SecurityStorageError
        
        /// Whether to log operations
        public var logOperations: Bool
        
        public init(
            shouldSucceed: Bool = true,
            mockResponseDelay: TimeInterval? = nil,
            mockError: SecurityStorageError = .storageError("Mock operation failed"),
            logOperations: Bool = false
        ) {
            self.shouldSucceed = shouldSucceed
            self.mockResponseDelay = mockResponseDelay
            self.mockError = mockError
            self.logOperations = logOperations
        }
    }
    
    // MARK: - Properties
    
    /// In-memory storage for data
    private var storage: [String: Data]
    
    /// Behaviour configuration
    private let behaviour: MockBehaviour
    
    /// Optional call handler for monitoring and customising mock responses
    public var callHandler: ((String, [String: Any]) -> Void)?
    
    // MARK: - Initialisation
    
    /**
     Initialises a new mock secure storage with the specified configuration.
     
     - Parameters:
        - shouldSucceed: Whether operations should succeed or fail
        - mockResponseDelay: Optional delay to simulate operation time
        - preloadedData: Initial data to populate the storage with
        - mockError: Error to return when operations fail
        - logOperations: Whether to log operations
     */
    public init(
        shouldSucceed: Bool = true,
        mockResponseDelay: TimeInterval? = nil,
        preloadedData: [String: Data] = [:],
        mockError: SecurityStorageError = .storageError("Mock operation failed"),
        logOperations: Bool = false
    ) {
        self.storage = preloadedData
        self.behaviour = MockBehaviour(
            shouldSucceed: shouldSucceed,
            mockResponseDelay: mockResponseDelay,
            mockError: mockError,
            logOperations: logOperations
        )
    }
    
    /**
     Initialises with a specific behaviour configuration.
     
     - Parameters:
        - behaviour: The behaviour configuration to use
        - preloadedData: Initial data to populate the storage with
     */
    public init(
        behaviour: MockBehaviour,
        preloadedData: [String: Data] = [:]
    ) {
        self.storage = preloadedData
        self.behaviour = behaviour
    }
    
    // MARK: - Helper Methods
    
    /**
     Simulates an asynchronous operation with configurable delay and success.
     
     - Parameters:
        - operation: The name of the operation for logging
        - params: Parameters associated with the operation
        - action: The storage action to perform if succeeding
        - successResult: The result to return on success
     - Returns: A result with either the success value or the configured error
     */
    private func mockOperation<T>(
        operation: String,
        params: [String: Any] = [:],
        action: () -> Void = {},
        successResult: T
    ) async -> Result<T, SecurityStorageError> {
        // Log the operation if configured
        if behaviour.logOperations {
            print("MockSecureStorage: \(operation) called with \(params)")
        }
        
        // Call the handler if set
        callHandler?(operation, params)
        
        // Simulate delay if configured
        if let delay = behaviour.mockResponseDelay {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Return result based on configuration
        if behaviour.shouldSucceed {
            action()
            return .success(successResult)
        } else {
            return .failure(behaviour.mockError)
        }
    }
    
    // MARK: - SecureStorageProtocol Implementation
    
    public func store(
        _ data: Data,
        withIdentifier identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        await mockOperation(
            operation: "store",
            params: [
                "identifier": identifier,
                "dataSize": data.count
            ],
            action: { self.storage[identifier] = data },
            successResult: ()
        )
    }
    
    public func retrieve(
        identifier: String
    ) async -> Result<Data, SecurityStorageError> {
        // Special case: If the identifier doesn't exist, return itemNotFound error
        // regardless of the shouldSucceed setting
        if !storage.keys.contains(identifier) {
            return .failure(.itemNotFound("Item with identifier \(identifier) not found"))
        }
        
        return await mockOperation(
            operation: "retrieve",
            params: ["identifier": identifier],
            successResult: storage[identifier] ?? Data()
        )
    }
    
    public func delete(
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        await mockOperation(
            operation: "delete",
            params: ["identifier": identifier],
            action: { self.storage.removeValue(forKey: identifier) },
            successResult: ()
        )
    }
    
    public func clear() async -> Result<Void, SecurityStorageError> {
        await mockOperation(
            operation: "clear",
            action: { self.storage.removeAll() },
            successResult: ()
        )
    }
}
