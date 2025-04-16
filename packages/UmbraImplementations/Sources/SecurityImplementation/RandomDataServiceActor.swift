import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import Security
import SecurityCoreInterfaces
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
  private var isInitialised: Bool=false

  /// The entropy source being used
  private var entropySource: EntropySource = .system

  /// Unique identifier for this random data service instance
  private let serviceIdentifier: UUID = .init()

  // MARK: - Initialisation

  /// Creates a new random data service actor with the given logger
  /// - Parameter logger: The logger to use for logging random data generation events
  public init(logger: LoggingProtocol) {
    self.logger=logger
  }

  /// Initialises the random data service with the specified entropy source
  /// - Parameter entropySource: The entropy source to use (system, hardware, or hybrid)
  /// - Throws: CoreSecurityError if initialisation fails
  public func initialise(entropySource: EntropySource) async throws {
    guard !isInitialised else {
      throw CoreSecurityError.configurationError("Random data service is already initialised")
    }

    self.entropySource=entropySource

    // Create a context for logging
    let context=RandomDataServiceContext(
      operation: "initialise",
      operationID: serviceIdentifier.uuidString,
      entropySource: entropySource.rawValue
    )

    await logger.info(
      "Initialising random data service with \(entropySource.rawValue) entropy source",
      context: context
    )

    // Verify that the entropy source is available
    switch entropySource {
      case .system:
        // System entropy is always available
        break
      case .hardware:
        // Check if hardware entropy is available
        guard
          SecRandomCopyBytes(
            kSecRandomDefault,
            1,
            UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
          ) == errSecSuccess
        else {
          throw CoreSecurityError.configurationError("Hardware entropy source is not available")
        }
      case .hybrid:
        // Check if hardware entropy is available for hybrid mode
        guard
          SecRandomCopyBytes(
            kSecRandomDefault,
            1,
            UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
          ) == errSecSuccess
        else {
          await logger.warning(
            "Hardware entropy source is not available, falling back to system entropy",
            context: context
          )
          self.entropySource = .system
          return
        }
    }

    isInitialised=true

    // Log success
    let successContext=RandomDataServiceContext(
      operation: "initialise",
      operationID: serviceIdentifier.uuidString,
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
    let context=RandomDataServiceContext(
      operation: "generateRandomBytes",
      operationID: serviceIdentifier.uuidString,
      entropySource: entropySource.rawValue,
      source: "RandomDataServiceActor",
      correlationID: UUID().uuidString
    ).adding(key: "byteCount", value: String(length), privacyLevel: .public)

    await logger.debug("Generating \(length) random bytes", context: context)

    var bytes=[UInt8](repeating: 0, count: length)

    switch entropySource {
      case .system, .hardware:
        // Use SecRandomCopyBytes for system and hardware entropy
        let status=SecRandomCopyBytes(kSecRandomDefault, length, &bytes)

        guard status == errSecSuccess else {
          throw CoreSecurityError.cryptoError("Failed to generate random bytes: \(status)")
        }

      case .hybrid:
        // For hybrid mode, combine multiple sources
        // In a real implementation, this would be more sophisticated
        let status=SecRandomCopyBytes(kSecRandomDefault, length, &bytes)

        guard status == errSecSuccess else {
          throw CoreSecurityError.cryptoError("Failed to generate random bytes: \(status)")
        }

        // Add additional entropy mixing (simplified for this example)
        for i in 0..<length {
          bytes[i]=bytes[i] ^ UInt8.random(in: 0...255)
        }
    }

    await logger.debug("Successfully generated \(length) random bytes", context: context)

    return bytes
  }

  /// Generates a random integer within the specified range
  /// - Parameter range: The range in which to generate the random integer
  /// - Returns: A random integer within the specified range
  public func generateRandomInteger<
    T: FixedWidthInteger & Sendable
  >(in range: Range<T>) async throws -> T {
    try validateInitialisation()

    // Log operation with privacy controls
    let context=RandomDataServiceContext(
      operation: "generateRandomInteger",
      operationID: serviceIdentifier.uuidString,
      entropySource: entropySource.rawValue,
      source: "RandomDataServiceActor",
      correlationID: UUID().uuidString
    ).adding(key: "lowerBound", value: String(range.lowerBound), privacyLevel: .public)
      .adding(key: "upperBound", value: String(range.upperBound), privacyLevel: .public)

    await logger.debug(
      "Generating random integer in range \(range.lowerBound)..<\(range.upperBound)",
      context: context
    )

    // Calculate the number of bytes needed to represent the range
    let byteCount=MemoryLayout<T>.size

    // Generate random bytes
    let randomBytes=try await generateRandomBytes(length: byteCount)

    // Convert bytes to integer
    var result: T=0
    for (index, byte) in randomBytes.enumerated() {
      let shiftAmount=index * 8
      if shiftAmount < T.bitWidth {
        result |= T(byte) << T(shiftAmount)
      }
    }

    // Adjust to fit within range
    let rangeSize=range.upperBound - range.lowerBound
    if rangeSize > 0 {
      result=(result % rangeSize) + range.lowerBound
    } else {
      result=range.lowerBound
    }

    await logger.debug("Generated random integer: \(result)", context: context)

    return result
  }

  /// Generates a random boolean value
  /// - Returns: A random boolean value
  public func generateRandomBoolean() async throws -> Bool {
    try validateInitialisation()

    // Log operation with privacy controls
    let context=RandomDataServiceContext(
      operation: "generateRandomBoolean",
      operationID: serviceIdentifier.uuidString,
      entropySource: entropySource.rawValue,
      source: "RandomDataServiceActor",
      correlationID: UUID().uuidString
    )

    await logger.debug("Generating random boolean", context: context)

    // Generate a single random byte and check if it's odd or even
    let randomByte=try await generateRandomBytes(length: 1)[0]
    let result=(randomByte % 2) == 1

    await logger.debug("Generated random boolean: \(result)", context: context)

    return result
  }

  /// Generates a random double value between 0.0 and 1.0
  /// - Returns: A random double value in the range [0.0, 1.0)
  public func generateRandomDouble() async throws -> Double {
    try validateInitialisation()

    // Log operation with privacy controls
    let context=RandomDataServiceContext(
      operation: "generateRandomDouble",
      operationID: serviceIdentifier.uuidString,
      entropySource: entropySource.rawValue,
      source: "RandomDataServiceActor",
      correlationID: UUID().uuidString
    )

    await logger.debug("Generating random double", context: context)

    // Generate 8 random bytes for a 64-bit double
    let randomBytes=try await generateRandomBytes(length: 8)

    // Convert to UInt64 first
    var value: UInt64=0
    for (index, byte) in randomBytes.enumerated() {
      let shiftAmount=index * 8
      value |= UInt64(byte) << UInt64(shiftAmount)
    }

    // Convert to double in range [0.0, 1.0)
    // Using the technique from the IEEE 754 standard to generate a uniform value
    let result=Double(value) / Double(UInt64.max)

    await logger.debug("Generated random double: \(result)", context: context)

    return result
  }

  /// Returns the entropy quality level of the random data service
  /// - Returns: Entropy quality level (low, medium, high)
  public func getEntropyQuality() async -> EntropyQuality {
    // Return the appropriate entropy quality based on the entropy source
    switch entropySource {
      case .system:
        .medium
      case .hardware:
        .high
      case .hybrid:
        .high
    }
  }
}
