import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

/**
 # MockSecureStorage
 
 A mock implementation of the SecureStorageProtocol for testing.
 
 This mock implementation allows testing of components that depend on secure storage
 without requiring access to actual secure storage mechanisms. It provides:
 - In-memory storage of data
 - Configurable success/failure responses
 - Optional simulated delays
 - Operation logging
 
 Because this is a mock implementation, it does not provide any actual security
 guarantees and should only be used for testing.
 */
@available(*, deprecated, message: "Use only for testing")
public actor MockSecureStorage: SecureStorageProtocol {
    // MARK: - Types
    
    /// Configuration options for the mock storage behaviour
    public struct MockBehaviour: Sendable {
        /// Whether operations should succeed or fail
        public var shouldSucceed: Bool
        
        /// Optional delay to simulate asynchronous operations (in seconds)
        public var delay: TimeInterval?
        
        /// Whether to log operations
        public var logOperations: Bool
        
        /// Error to return when operations fail
        public var failureError: SecurityStorageError
        
        /// Creates a new behaviour configuration
        public init(
            shouldSucceed: Bool = true,
            delay: TimeInterval? = nil,
            logOperations: Bool = false,
            failureError: SecurityStorageError = .operationFailed("Mock operation failed")
        ) {
            self.shouldSucceed = shouldSucceed
            self.delay = delay
            self.logOperations = logOperations
            self.failureError = failureError
        }
    }
    
    /**
     A thread-safe dictionary implementation for use in the mock storage.
     */
    private final class AtomicDictionary<Key: Hashable, Value>: @unchecked Sendable {
        private var dictionary: [Key: Value]
        private let lock = NSLock()
        
        init(dictionary: [Key: Value] = [:]) {
            self.dictionary = dictionary
        }
        
        /// Get a value for a key in a thread-safe manner
        func value(for key: Key) -> Value? {
            lock.lock()
            defer { lock.unlock() }
            return dictionary[key]
        }
        
        /// Set a value for a key in a thread-safe manner
        func setValue(_ value: Value, for key: Key) {
            lock.lock()
            defer { lock.unlock() }
            dictionary[key] = value
        }
        
        /// Remove a value for a key in a thread-safe manner
        func removeValue(for key: Key) {
            lock.lock()
            defer { lock.unlock() }
            dictionary.removeValue(forKey: key)
        }
        
        /// Get all keys in a thread-safe manner
        var keys: [Key] {
            lock.lock()
            defer { lock.unlock() }
            return Array(dictionary.keys)
        }
        
        /// Get all values in a thread-safe manner
        var values: [Value] {
            lock.lock()
            defer { lock.unlock() }
            return Array(dictionary.values)
        }
        
        /// Check if the dictionary contains a key in a thread-safe manner
        func containsKey(_ key: Key) -> Bool {
            lock.lock()
            defer { lock.unlock() }
            return dictionary.keys.contains(key)
        }
        
        /// Return a thread-safe copy of the dictionary
        var dictionaryCopy: [Key: Value] {
            lock.lock()
            defer { lock.unlock() }
            return dictionary
        }
    }
    
    // MARK: - Properties
    
    /// In-memory storage for data
    private let storage: AtomicDictionary<String, [UInt8]>
    
    /// Behaviour configuration
    private let behaviour: MockBehaviour
    
    /// Optional call handler for monitoring and customising mock responses
    private var callHandler: ((String, [String: Any]) -> Void)?
    
    // MARK: - Initialisation
    
    /**
     Create a new mock secure storage instance.
     
     - Parameters:
       - behaviour: Configuration for the mock behaviour
       - callHandler: Optional handler to receive notifications of method calls
     */
    public init(
        behaviour: MockBehaviour = MockBehaviour(),
        callHandler: ((String, [String: Any]) -> Void)? = nil
    ) {
        self.storage = AtomicDictionary<String, [UInt8]>()
        self.behaviour = behaviour
        self.callHandler = callHandler
    }
    
    // MARK: - Helper Methods
    
    /**
     Simulates a mock operation with configurable outcomes.
     
     - Parameters:
        - operation: The name of the operation being performed
        - parameters: Operation parameters for logging
        - body: The operation implementation to run on success
     - Returns: A Result with the operation outcome or configured error
     */
    private func mockOperation<T>(
        operation: String,
        parameters: [String: Any] = [:],
        body: () throws -> T
    ) async -> Result<T, SecurityStorageError> {
        // Log the operation if enabled
        if behaviour.logOperations {
            print("[MockSecureStorage] \(operation) - Parameters: \(parameters)")
        }
        
        // Call the handler if available
        callHandler?(operation, parameters)
        
        // Apply configured delay if needed
        if let delay = behaviour.delay {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Return success or failure based on configuration
        if behaviour.shouldSucceed {
            do {
                let result = try body()
                return .success(result)
            } catch {
                return .failure(.operationFailed("Internal error: \(error.localizedDescription)"))
            }
        } else {
            return .failure(behaviour.failureError)
        }
    }
    
    // MARK: - SecureStorageProtocol Methods
    
    public func storeData(
        _ data: [UInt8],
        withIdentifier identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        await mockOperation(
            operation: "storeData",
            parameters: ["identifier": identifier, "dataSize": data.count]
        ) {
            storage.setValue(data, for: identifier)
            return ()
        }
    }
    
    public func retrieveData(
        withIdentifier identifier: String
    ) async -> Result<[UInt8], SecurityStorageError> {
        await mockOperation(
            operation: "retrieveData",
            parameters: ["identifier": identifier]
        ) {
            if let data = storage.value(for: identifier) {
                return data
            } else {
                throw SecurityStorageError.dataNotFound
            }
        }
    }
    
    public func deleteData(
        withIdentifier identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        await mockOperation(
            operation: "deleteData",
            parameters: ["identifier": identifier]
        ) {
            storage.removeValue(for: identifier)
            return ()
        }
    }
    
    /**
     Lists all available data identifiers in the storage.
     
     - Returns: Array of identifiers or error
     */
    public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
        await mockOperation(
            operation: "listDataIdentifiers",
            parameters: [:]
        ) {
            return storage.keys
        }
    }
    
    // MARK: - Additional Methods for Testing
    
    /**
     Get a list of all identifiers currently in the storage.
     
     - Returns: Array of identifiers
     */
    public func allIdentifiers() -> [String] {
        return storage.keys
    }
    
    /**
     Check if the storage contains data for an identifier.
     
     - Parameter identifier: The identifier to check
     - Returns: True if data exists, false otherwise
     */
    public func containsIdentifier(_ identifier: String) -> Bool {
        return storage.containsKey(identifier)
    }
    
    /**
     Clear all data from the storage.
     */
    public func clearAllData() {
        for key in storage.keys {
            storage.removeValue(for: key)
        }
    }
    
    /**
     Set the call handler for monitoring operations.
     
     - Parameter handler: The handler function
     */
    public func setCallHandler(_ handler: @escaping (String, [String: Any]) -> Void) {
        callHandler = handler
    }
}
