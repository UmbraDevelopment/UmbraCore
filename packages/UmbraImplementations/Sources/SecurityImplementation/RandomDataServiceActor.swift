import Foundation
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
    private let serviceIdentifier: UUID = UUID()
    
    // MARK: - Initialisation
    
    /// Creates a new random data service actor with the given logger
    /// - Parameter logger: The logger to use for logging random data generation events
    public init(logger: LoggingProtocol) {
        self.logger = logger
    }
    
    /// Initialises the random data service with the specified entropy source
    /// - Parameter entropySource: The entropy source to use (system, hardware, or hybrid)
    /// - Throws: SecurityError if initialisation fails
    public func initialise(entropySource: EntropySource) async throws {
        guard !isInitialised else {
            throw SecurityError.alreadyInitialized("Random data service is already initialised")
        }
        
        // Log initialisation
        await logger.debug(
            "Initialising random data service with \(entropySource.rawValue) entropy source",
            metadata: PrivacyMetadata([
                "entropy_source": (value: entropySource.rawValue, privacy: .public),
                "service_id": (value: serviceIdentifier.uuidString, privacy: .public)
            ]),
            source: "RandomDataServiceActor.initialise"
        )
        
        // Store the entropy source
        self.entropySource = entropySource
        
        // Perform any entropy source-specific initialisation
        switch entropySource {
        case .hardware:
            // Validate hardware entropy is available
            let testBytes = [UInt8](repeating: 0, count: 16)
            var bytes = testBytes
            let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            
            guard result == errSecSuccess else {
                throw SecurityError.initialisationFailed(
                    reason: "Hardware entropy source is not available"
                )
            }
            
            // Ensure the bytes are actually random
            guard bytes != testBytes else {
                throw SecurityError.initialisationFailed(
                    reason: "Entropy source did not produce random data"
                )
            }
            
        case .system, .hybrid:
            // System and hybrid entropy sources are always available
            break
        }
        
        isInitialised = true
        
        // Log success
        await logger.debug(
            "Random data service initialised successfully",
            metadata: PrivacyMetadata([
                "entropy_source": (value: entropySource.rawValue, privacy: .public)
            ]),
            source: "RandomDataServiceActor.initialise"
        )
    }
    
    /// Returns the entropy quality level of the random data service
    /// - Returns: Entropy quality level (low, medium, high)
    public func getEntropyQuality() async -> EntropyQuality {
        switch entropySource {
        case .hardware:
            return .high
        case .hybrid:
            return .medium
        case .system:
            return .low
        }
    }
    
    // MARK: - RandomDataServiceProtocol Implementation
    
    /// Generates cryptographically secure random bytes
    /// - Parameter length: The number of bytes to generate
    /// - Returns: The generated random bytes
    /// - Throws: SecurityError if random generation fails
    public func generateRandomBytes(length: Int) async throws -> [UInt8] {
        try validateInitialisation()
        
        // Log operation with privacy controls
        await logger.debug(
            "Generating \(length) random bytes",
            metadata: PrivacyMetadata([
                "length": (value: String(length), privacy: .public)
            ]),
            source: "RandomDataServiceActor.generateRandomBytes"
        )
        
        // Generate the random bytes using Apple's SecRandom API
        var bytes = [UInt8](repeating: 0, count: length)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        guard result == errSecSuccess else {
            throw SecurityError.operationFailed("SecRandomCopyBytes failed with error \(result)")
        }
        
        // Log success
        await logger.debug(
            "Successfully generated random bytes",
            metadata: PrivacyMetadata([
                "length": (value: String(bytes.count), privacy: .public)
            ]),
            source: "RandomDataServiceActor.generateRandomBytes"
        )
        
        return bytes
    }
    
    /// Generates a cryptographically secure random integer within the specified range
    /// - Parameter range: The range within which to generate the random integer
    /// - Returns: The generated random integer
    /// - Throws: SecurityError if random generation fails
    public func generateRandomInteger<T: FixedWidthInteger>(in range: Range<T>) async throws -> T {
        try validateInitialisation()
        
        // Log operation with privacy controls
        await logger.debug(
            "Generating random integer in range \(range.lowerBound)..<\(range.upperBound)",
            metadata: PrivacyMetadata([
                "lower_bound": (value: String(range.lowerBound), privacy: .public),
                "upper_bound": (value: String(range.upperBound), privacy: .public),
                "type": (value: String(describing: T.self), privacy: .public)
            ]),
            source: "RandomDataServiceActor.generateRandomInteger"
        )
        
        // Calculate range width and validate
        let width = range.upperBound - range.lowerBound
        guard width > 0 else {
            throw SecurityError.invalidInput("Range width must be greater than zero")
        }
        
        // Determine how many bytes we need
        let bytesNeeded = (T.bitWidth + 7) / 8
        
        // Generate random bytes
        let randomBytes = try await generateRandomBytes(length: bytesNeeded)
        
        // Convert bytes to integer
        var randomValue: T = 0
        for byte in randomBytes {
            randomValue = (randomValue << 8) | T(byte)
        }
        
        // Map to range
        let scaled = range.lowerBound + T(UInt64(randomValue) % UInt64(width))
        
        // Log success
        await logger.debug(
            "Successfully generated random integer",
            metadata: PrivacyMetadata([
                "value": (value: String(scaled), privacy: .public)
            ]),
            source: "RandomDataServiceActor.generateRandomInteger"
        )
        
        return scaled
    }
    
    /// Generates a cryptographically secure random integer within the specified closed range
    /// - Parameter range: The closed range within which to generate the random integer
    /// - Returns: The generated random integer
    /// - Throws: SecurityError if random generation fails
    public func generateRandomInteger<T: FixedWidthInteger>(in range: ClosedRange<T>) async throws -> T {
        // Convert closed range to half-open range and use existing implementation
        return try await generateRandomInteger(in: range.lowerBound..<(range.upperBound + 1))
    }
    
    /// Generates a cryptographically secure random double between 0.0 and 1.0
    /// - Returns: The generated random double
    /// - Throws: SecurityError if random generation fails
    public func generateRandomDouble() async throws -> Double {
        try validateInitialisation()
        
        // Log operation with privacy controls
        await logger.debug(
            "Generating random double between 0.0 and 1.0",
            metadata: PrivacyMetadata([:]),
            source: "RandomDataServiceActor.generateRandomDouble"
        )
        
        // Generate 8 random bytes
        let randomBytes = try await generateRandomBytes(length: 8)
        
        // Convert to UInt64
        var value: UInt64 = 0
        for byte in randomBytes {
            value = (value << 8) | UInt64(byte)
        }
        
        // Convert to Double in range [0, 1)
        let scaled = Double(value) / Double(UInt64.max)
        
        // Log success
        await logger.debug(
            "Successfully generated random double",
            metadata: PrivacyMetadata([
                "value": (value: String(format: "%.6f", scaled), privacy: .public)
            ]),
            source: "RandomDataServiceActor.generateRandomDouble"
        )
        
        return scaled
    }
    
    // MARK: - Helper Methods
    
    /// Validates that the service has been initialised
    /// - Throws: SecurityError if not initialised
    private func validateInitialisation() throws {
        guard isInitialised else {
            throw SecurityError.notInitialized("Random data service is not initialised")
        }
    }
}
