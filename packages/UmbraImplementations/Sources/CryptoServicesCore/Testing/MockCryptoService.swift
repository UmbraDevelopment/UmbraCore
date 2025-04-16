import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

/**
 # MockCryptoService

 A standardised mock implementation of the CryptoServiceProtocol for testing purposes.

 This mock provides deterministic responses for all cryptographic operations, making
 it suitable for unit testing and integration testing without requiring actual
 cryptographic operations to be performed.
 */
@available(*, deprecated, message: "Use only for testing")
public final class MockCryptoService: CryptoServiceProtocol {
  // MARK: - Configuration

  /// Configuration options for the mock crypto service behaviour
  public struct MockBehaviour: Sendable {
    /// Whether operations should succeed or fail
    public var shouldSucceed: Bool

    /// Optional delay in seconds to simulate operation time
    public var delay: TimeInterval?

    /// Custom error to return when operations fail
    public var mockError: SecurityStorageError

    /// Default mock data to return for retrieveData operations
    public var mockData: Data

    /// Whether to log operations
    public var logOperations: Bool

    /// Create a new mock behaviour configuration
    public init(
      shouldSucceed: Bool=true,
      delay: TimeInterval?=nil,
      mockError: SecurityStorageError = .operationFailed("Mock operation failed"),
      mockData: Data=Data([0, 1, 2, 3, 4, 5]),
      logOperations: Bool=false
    ) {
      self.shouldSucceed=shouldSucceed
      self.delay=delay
      self.mockError=mockError
      self.mockData=mockData
      self.logOperations=logOperations
    }
  }

  // MARK: - Properties

  /// The secure storage implementation to use
  public let secureStorage: SecureStorageProtocol

  /// The behaviour configuration for this mock
  private let behaviour: MockBehaviour

  /// Actor for maintaining mutable state in a thread-safe way
  private actor StateActor {
    var behaviour: MockBehaviour

    init(behaviour: MockBehaviour) {
      self.behaviour=behaviour
    }

    func updateBehaviour(_ newBehaviour: MockBehaviour) {
      behaviour=newBehaviour
    }

    func getBehaviour() -> MockBehaviour {
      behaviour
    }
  }

  /// Thread-safe state container
  private let stateActor: StateActor

  /// Optional call handler for monitoring and customising mock responses
  @MainActor
  public var callHandler: ((String, [String: Any]) -> Void)?

  // MARK: - Initialisation

  /**
   Initialises a new mock crypto service with the specified configuration.

   - Parameters:
      - secureStorage: Secure storage implementation to use
      - mockBehaviour: Configuration for the mock behaviour
   */
  public init(
    secureStorage: SecureStorageProtocol=MockSecureStorage(),
    mockBehaviour: MockBehaviour=MockBehaviour()
  ) {
    self.secureStorage=secureStorage
    behaviour=mockBehaviour
    stateActor=StateActor(behaviour: mockBehaviour)
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
    params: [String: Any]=[:],
    successResult: T
  ) async -> Result<T, SecurityStorageError> {
    // Get current behaviour
    let currentBehaviour=await stateActor.getBehaviour()

    // Log the operation if configured
    if currentBehaviour.logOperations {
      print("MockCryptoService: \(operation) called with \(params)")
    }

    // Call the handler if set
    let safeParams=params as NSDictionary as? [String: String] ?? [:]
    await MainActor.run {
      callHandler?(operation, safeParams)
    }

    // Simulate delay if configured
    if let delay=currentBehaviour.delay {
      try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    // Return result based on configuration
    if currentBehaviour.shouldSucceed {
      return .success(successResult)
    } else {
      return .failure(currentBehaviour.mockError)
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
        "hasOptions": options != nil
      ],
      successResult: "mock-encrypted-\(UUID().uuidString)"
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
        "hasOptions": options != nil
      ],
      successResult: "mock-decrypted-\(UUID().uuidString)"
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
        "hasOptions": options != nil
      ],
      successResult: "mock-hash-\(UUID().uuidString)"
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
        "hasOptions": options != nil
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
        "hasOptions": options != nil
      ],
      successResult: "mock-key-\(UUID().uuidString)"
    )
  }

  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    let identifier=customIdentifier ?? "mock-data-\(UUID().uuidString)"
    return await mockOperation(
      operation: "importData",
      params: [
        "dataSize": data.count,
        "customIdentifier": customIdentifier ?? "nil"
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
        "hasOptions": options != nil
      ],
      successResult: "mock-hash-\(UUID().uuidString)"
    )
  }

  // MARK: - Storage Operations

  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await mockOperation(
      operation: "storeData",
      params: [
        "dataSize": data.count,
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
        "dataSize": data.count,
        "customIdentifier": customIdentifier
      ],
      successResult: customIdentifier
    )
  }

  // MARK: - Additional Methods for Testing

  /**
   Configures the mock to always succeed for future operations.
   */
  public func configureToSucceed() async {
    var currentBehaviour=await stateActor.getBehaviour()
    currentBehaviour.shouldSucceed=true
    await stateActor.updateBehaviour(currentBehaviour)
  }

  /**
   Configures the mock to always fail for future operations.

   - Parameter error: The error to return for failed operations
   */
  public func configureToFail(with error: SecurityStorageError) async {
    var currentBehaviour=await stateActor.getBehaviour()
    currentBehaviour.shouldSucceed=false
    currentBehaviour.mockError=error
    await stateActor.updateBehaviour(currentBehaviour)
  }

  /**
   Sets the call handler for monitoring operations.

   - Parameter handler: The handler function
   */
  @MainActor
  public func setCallHandler(_ handler: @escaping (String, [String: Any]) -> Void) {
    callHandler=handler
  }
}
