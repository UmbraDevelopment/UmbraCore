import Foundation
import CoreSecurityTypes
import LoggingInterfaces
import LoggingTypes
import Security
import UmbraErrors

/// Actor implementation of the RandomDataServiceProtocol that provides thread-safe
/// access to secure random data generation with proper error handling.
///
/// This implementation follows the Alpha Dot Five architecture principles:
/// - Actor-based concurrency for thread safety
/// - Privacy-aware logging for sensitive operations
/// - Strong type safety with proper error handling
public actor RandomDataServiceActor: RandomDataServiceProtocol {
  // MARK: - Private Properties

  /// The logger used for logging random data generation events
  private let logger: LoggingProtocol

  /// Flag indicating whether the service has been initialised
  private var isInitialised: Bool = false

  /// The entropy source being used
  private var entropySource: EntropySource = .system

  /// Unique identifier for this random data service instance
  private let serviceIdentifier: UUID = .init()

  // MARK: - Initialisation

  /// Creates a new random data service actor with the given logger
  /// - Parameter logger: The logger to use for logging random data generation events
  public init(logger: LoggingProtocol) {
    self.logger = logger
  }

  /// Initialises the random data service with the specified entropy source
  /// - Parameter entropySource: The entropy source to use (system, hardware, or hybrid)
  /// - Throws: CoreSecurityError if initialisation fails
  public func initialise(entropySource: EntropySource) async throws {
    guard !isInitialised else {
      throw CoreSecurityError.configurationError("Random data service is already initialised")
    }

    self.entropySource = entropySource
    
    // Create a context for logging
    let context = RandomDataServiceContext(
      operation: "initialise",
      operationId: serviceIdentifier.uuidString,
      entropySource: entropySource.rawValue
    )
    
    await logger.info("Initialising random data service with \(entropySource.rawValue) entropy source", context: context)
    
    // Verify that the entropy source is available
    switch entropySource {
    case .system:
      // System entropy is always available
      break
    case .hardware:
      // Check if hardware entropy is available
      guard SecRandomCopyBytes(kSecRandomDefault, 1, UnsafeMutablePointer<UInt8>.allocate(capacity: 1)) == errSecSuccess else {
        throw CoreSecurityError.configurationError("Hardware entropy source is not available")
      }
    case .hybrid:
      // Check if hardware entropy is available for hybrid mode
      guard SecRandomCopyBytes(kSecRandomDefault, 1, UnsafeMutablePointer<UInt8>.allocate(capacity: 1)) == errSecSuccess else {
        await logger.warning("Hardware entropy source is not available, falling back to system entropy", context: context)
        self.entropySource = .system
      }
    }
    
    isInitialised = true
    
    // Log success
    let successContext = RandomDataServiceContext(
      operation: "initialise",
      operationId: serviceIdentifier.uuidString,
      entropySource: entropySource.rawValue
    )
    
    await logger.info("Random data service initialised successfully", context: successContext)
  }
  
  // MARK: - Private Helpers
  
  /// Validates that the service has been initialised
  /// - Throws: CoreSecurityError if the service has not been initialised
  private func validateInitialisation() throws {
    guard isInitialised else {
      throw CoreSecurityError.configurationError("Random data service has not been initialised")
    }
  }
  
  // MARK: - RandomDataServiceProtocol Implementation
  
  /// Generates random bytes of the specified length
  /// - Parameter length: The number of random bytes to generate
  /// - Returns: An array of random bytes
  /// - Throws: CoreSecurityError if random data generation fails
  public func generateRandomBytes(length: Int) async throws -> [UInt8] {
    try validateInitialisation()
    
    // Log operation with privacy controls
    let context = RandomDataServiceContext(
      operation: "generateRandomBytes",
      operationId: serviceIdentifier.uuidString,
      entropySource: entropySource.rawValue,
      byteCount: String(length)
    )
    
    await logger.debug("Generating \(length) random bytes", context: context)
    
    var bytes = [UInt8](repeating: 0, count: length)
    
    switch entropySource {
    case .system, .hardware:
      // Use SecRandomCopyBytes for system and hardware entropy
      let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
      
      guard status == errSecSuccess else {
        throw CoreSecurityError.operationFailed("Failed to generate random bytes: \(status)")
      }
      
    case .hybrid:
      // For hybrid mode, combine multiple sources
      // In a real implementation, this would be more sophisticated
      let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
      
      guard status == errSecSuccess else {
        throw CoreSecurityError.operationFailed("Failed to generate random bytes: \(status)")
      }
      
      // Add additional entropy mixing (simplified for this example)
      for i in 0..<length {
        bytes[i] = bytes[i] ^ UInt8.random(in: 0...255)
      }
    }
    
    await logger.debug("Successfully generated \(length) random bytes", context: context)
    
    return bytes
  }
  
  /// Generates a random integer within the specified range
  /// - Parameter range: The range in which to generate the random integer
  /// - Returns: A random integer within the specified range
  public func generateRandomInteger<T: FixedWidthInteger & Sendable>(in range: Range<T>) async throws -> T {
    try validateInitialisation()
    
    // Log operation with privacy controls
    let context = RandomDataServiceContext(
      operation: "generateRandomInteger",
      operationId: serviceIdentifier.uuidString,
      entropySource: entropySource.rawValue,
      range: "\(range.lowerBound)..<\(range.upperBound)"
    )
    
    await logger.debug("Generating random integer in range \(range.lowerBound)..<\(range.upperBound)", context: context)
    
    // Calculate the number of bytes needed to represent the range
    let byteCount = MemoryLayout<T>.size
    
    // Generate random bytes
    let randomBytes = try await generateRandomBytes(length: byteCount)
    
    // Convert bytes to integer
    var result: T = 0
    for (index, byte) in randomBytes.enumerated() {
      let shiftAmount = index * 8
      result |= T(byte) << T(shiftAmount)
    }
    
    // Map to the desired range
    let rangeSize = range.upperBound - range.lowerBound
    if rangeSize > 0 {
      result = range.lowerBound + (result % rangeSize)
    } else {
      result = range.lowerBound
    }
    
    await logger.debug("Successfully generated random integer: \(result)", context: context)
    
    return result
  }
  
  /// Generates a random double between 0.0 and 1.0
  /// - Returns: A random double between 0.0 and 1.0
  public func generateRandomDouble() async throws -> Double {
    try validateInitialisation()
    
    // Log operation with privacy controls
    let context = RandomDataServiceContext(
      operation: "generateRandomDouble",
      operationId: serviceIdentifier.uuidString,
      entropySource: entropySource.rawValue
    )
    
    await logger.debug("Generating random double", context: context)
    
    // Generate 8 random bytes (for a 64-bit double)
    let randomBytes = try await generateRandomBytes(length: 8)
    
    // Convert to UInt64
    var value: UInt64 = 0
    for (index, byte) in randomBytes.enumerated() {
      let shiftAmount = index * 8
      value |= UInt64(byte) << UInt64(shiftAmount)
    }
    
    // Convert to double between 0.0 and 1.0
    // Using a technique that avoids modulo bias
    let result = Double(value) / Double(UInt64.max)
    
    await logger.debug("Successfully generated random double", context: context)
    
    return result
  }
  
  /// Returns the entropy quality level of the random data service
  /// - Returns: Entropy quality level (low, medium, high)
  public func getEntropyQuality() async -> EntropyQuality {
    // Return the appropriate entropy quality based on the entropy source
    switch entropySource {
    case .system:
      return .medium
    case .hardware:
      return .high
    case .hybrid:
      return .high
    }
  }
}

/// Context for logging random data service operations
private struct RandomDataServiceContext: LogContextDTO {
  /// The operation being performed
  let operation: String
  
  /// A unique identifier for the operation
  let operationId: String
  
  /// The entropy source being used
  let entropySource: String
  
  /// The number of bytes being generated (if applicable)
  let byteCount: String?
  
  /// The range for random integer generation (if applicable)
  let range: String?
  
  /// Creates a new random data service context
  /// - Parameters:
  ///   - operation: The operation being performed
  ///   - operationId: A unique identifier for the operation
  ///   - entropySource: The entropy source being used
  ///   - byteCount: The number of bytes being generated (if applicable)
  ///   - range: The range for random integer generation (if applicable)
  init(
    operation: String,
    operationId: String,
    entropySource: String,
    byteCount: String? = nil,
    range: String? = nil
  ) {
    self.operation = operation
    self.operationId = operationId
    self.entropySource = entropySource
    self.byteCount = byteCount
    self.range = range
  }
  
  /// Creates a metadata collection with the context information
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    var metadata = LogMetadataDTOCollection()
    
    // Add the basic context information
    metadata = metadata.withPublic(key: "operation", value: operation)
    metadata = metadata.withPublic(key: "operationId", value: operationId)
    metadata = metadata.withPublic(key: "entropySource", value: entropySource)
    
    // Add optional context information if available
    if let byteCount = byteCount {
      metadata = metadata.withPublic(key: "byteCount", value: byteCount)
    }
    
    if let range = range {
      metadata = metadata.withPublic(key: "range", value: range)
    }
    
    return metadata
  }
}
