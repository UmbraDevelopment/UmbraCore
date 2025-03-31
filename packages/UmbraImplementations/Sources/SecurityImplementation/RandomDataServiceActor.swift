import Foundation
import LoggingInterfaces
import SecurityInterfaces
import UmbraErrors

/// Actor implementation of the RandomDataServiceProtocol that provides thread-safe
/// access to secure random data generation.
///
/// This implementation follows the Alpha Dot Five architecture principles:
/// - Actor-based concurrency for thread safety
/// - Provider-based abstraction for multiple implementation strategies
/// - Privacy-aware logging for sensitive operations
/// - Strong type safety with proper error handling
public actor RandomDataServiceActor: RandomDataServiceProtocol {
    // MARK: - Private Properties
    
    /// The logger used for logging security events
    private let logger: LoggingProtocol
    
    /// The configuration for this random data service
    private var configuration: RandomizationOptionsDTO
    
    /// Flag indicating whether the service has been initialised
    private var isInitialised: Bool = false
    
    /// Secure random number generator
    private var secureRandomGenerator: SecureRandomGenerator
    
    // MARK: - Initialisation
    
    /// Creates a new random data service actor with the given logger
    /// - Parameter logger: The logger to use for logging security events
    public init(logger: LoggingProtocol) {
        self.logger = logger
        self.configuration = .default
        self.secureRandomGenerator = SecureRandomGenerator()
    }
    
    // MARK: - RandomDataServiceProtocol Implementation
    
    /// Initialises the random data service with the specified configuration
    /// - Parameter configuration: Configuration options for random data generation
    /// - Throws: SecurityError if initialisation fails
    public func initialise(configuration: RandomizationOptionsDTO) async throws {
        guard !isInitialised else {
            throw UmbraErrors.SecurityError.alreadyInitialised
        }
        
        self.configuration = configuration
        
        // Configure the random generator based on security level
        switch configuration.securityLevel {
        case .high:
            secureRandomGenerator.setHighSecurityMode(true)
        case .basic:
            secureRandomGenerator.setHighSecurityMode(false)
        case .standard:
            secureRandomGenerator.setHighSecurityMode(false)
        }
        
        // Log initialisation with privacy controls
        logger.log(
            level: .information,
            message: "Random data service initialised with \(configuration.securityLevel.rawValue) security level",
            metadata: [
                "security_level": .string(configuration.securityLevel.rawValue),
                "entropy_source": .string(configuration.entropySource.rawValue)
            ],
            privacy: .public
        )
        
        isInitialised = true
    }
    
    /// Generates a random double value between 0.0 and 1.0
    /// - Returns: A random double value
    public func generateRandomDouble() async -> Double {
        // Generate a secure random value even if not initialised
        let value = secureRandomGenerator.generateSecureDouble()
        
        // Log with privacy controls if initialised
        if isInitialised {
            logger.log(
                level: .debug,
                message: "Generated random double value",
                privacy: .private
            )
        }
        
        return value
    }
    
    /// Generates random bytes of the specified length
    /// - Parameter count: The number of random bytes to generate
    /// - Returns: An array of random bytes
    /// - Throws: SecurityError if random generation fails
    public func generateRandomBytes(count: Int) async throws -> [UInt8] {
        try validateInitialisation()
        
        // Log with privacy controls
        logger.log(
            level: .debug,
            message: "Generating \(count) random bytes",
            metadata: [
                "byte_count": .int(count)
            ],
            privacy: .public
        )
        
        // Generate random bytes
        do {
            let bytes = try secureRandomGenerator.generateSecureBytes(count: count)
            
            // Log success
            logger.log(
                level: .debug,
                message: "Random bytes generated successfully",
                metadata: [
                    "byte_count": .int(count)
                ],
                privacy: .public
            )
            
            return bytes
        } catch {
            // Log failure
            logger.log(
                level: .error,
                message: "Random byte generation failed: \(error.localizedDescription)",
                metadata: [
                    "byte_count": .int(count),
                    "error": .string(error.localizedDescription)
                ],
                privacy: .public
            )
            
            throw UmbraErrors.SecurityError.randomGenerationFailed(
                reason: "Random byte generation failed: \(error.localizedDescription)"
            )
        }
    }
    
    /// Generates a random integer within the specified range
    /// - Parameter range: The range of values to generate from
    /// - Returns: A random integer
    public func generateRandomInt(in range: ClosedRange<Int>) async -> Int {
        let value = secureRandomGenerator.generateSecureInt(in: range)
        
        // Log with privacy controls if initialised
        if isInitialised {
            logger.log(
                level: .debug,
                message: "Generated random integer in range \(range.lowerBound)...\(range.upperBound)",
                privacy: .private
            )
        }
        
        return value
    }
    
    /// Generates a random element from an array
    /// - Parameter array: The array to select from
    /// - Returns: A randomly selected element, or nil if the array is empty
    public func generateRandomElement<T>(from array: [T]) async -> T? {
        guard !array.isEmpty else {
            return nil
        }
        
        let index = await generateRandomInt(in: 0...(array.count - 1))
        
        // Log with privacy controls if initialised
        if isInitialised {
            logger.log(
                level: .debug,
                message: "Generated random element from array of \(array.count) items",
                privacy: .private
            )
        }
        
        return array[index]
    }
    
    /// Shuffles an array randomly
    /// - Parameter array: The array to shuffle
    /// - Returns: A new array with the elements in random order
    public func shuffle<T>(_ array: [T]) async -> [T] {
        var result = array
        
        // Early return for empty or single-element arrays
        guard result.count > 1 else {
            return result
        }
        
        // Fisher-Yates shuffle using secure random integers
        for i in 0..<(result.count - 1) {
            let remainingCount = result.count - i
            let j = await generateRandomInt(in: i...(i + remainingCount - 1))
            if i != j {
                result.swapAt(i, j)
            }
        }
        
        // Log with privacy controls if initialised
        if isInitialised {
            logger.log(
                level: .debug,
                message: "Shuffled array of \(array.count) items",
                privacy: .private
            )
        }
        
        return result
    }
    
    /// Generates a secure token as a string
    /// - Parameter byteCount: The number of bytes to use for the token
    /// - Returns: A secure token as a string
    /// - Throws: SecurityError if token generation fails
    public func generateSecureToken(byteCount: Int) async throws -> String {
        try validateInitialisation()
        
        // Log with privacy controls
        logger.log(
            level: .debug,
            message: "Generating secure token with \(byteCount) bytes of entropy",
            metadata: [
                "byte_count": .int(byteCount)
            ],
            privacy: .public
        )
        
        // Generate random bytes
        let randomBytes = try await generateRandomBytes(count: byteCount)
        
        // Convert to base64 string
        let base64String = Data(randomBytes).base64EncodedString()
        
        // Log success
        logger.log(
            level: .debug,
            message: "Secure token generated successfully",
            metadata: [
                "byte_count": .int(byteCount),
                "token_length": .int(base64String.count)
            ],
            privacy: .public
        )
        
        return base64String
    }
    
    /// Generates a UUID
    /// - Returns: A new UUID
    public func generateUUID() async -> UUID {
        // Generate a UUID
        let uuid = secureRandomGenerator.generateSecureUUID()
        
        // Log with privacy controls if initialised
        if isInitialised {
            logger.log(
                level: .debug,
                message: "Generated secure UUID",
                privacy: .private
            )
        }
        
        return uuid
    }
    
    // MARK: - Helper Methods
    
    /// Validates that the service has been initialised
    /// - Throws: SecurityError if not initialised
    private func validateInitialisation() throws {
        guard isInitialised else {
            throw UmbraErrors.SecurityError.notInitialised
        }
    }
}

/// Secure random number generator for cryptographic operations
private class SecureRandomGenerator {
    /// Flag indicating whether high security mode is enabled
    private var highSecurityMode: Bool = false
    
    /// Sets the security mode for the generator
    /// - Parameter enabled: Whether high security mode is enabled
    func setHighSecurityMode(_ enabled: Bool) {
        highSecurityMode = enabled
    }
    
    /// Generates a secure random double between 0.0 and 1.0
    /// - Returns: A secure random double
    func generateSecureDouble() -> Double {
        // In high security mode, use secure random bytes for better entropy
        if highSecurityMode {
            var randomBytes = [UInt8](repeating: 0, count: 8)
            let result = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
            
            if result == errSecSuccess {
                // Convert 8 random bytes to a UInt64
                let randomValue = randomBytes.withUnsafeBytes { bytes in
                    bytes.load(as: UInt64.self)
                }
                
                // Convert to Double between 0.0 and 1.0
                return Double(randomValue) / Double(UInt64.max)
            }
        }
        
        // Fall back to standard Swift random if high security isn't required or fails
        return Double.random(in: 0.0..<1.0)
    }
    
    /// Generates secure random bytes
    /// - Parameter count: The number of bytes to generate
    /// - Returns: An array of random bytes
    /// - Throws: Error if generation fails
    func generateSecureBytes(count: Int) throws -> [UInt8] {
        var randomBytes = [UInt8](repeating: 0, count: count)
        let result = SecRandomCopyBytes(kSecRandomDefault, count, &randomBytes)
        
        guard result == errSecSuccess else {
            throw UmbraErrors.SecurityError.randomGenerationFailed(
                reason: "SecRandomCopyBytes failed with error \(result)"
            )
        }
        
        return randomBytes
    }
    
    /// Generates a secure random integer in the specified range
    /// - Parameter range: The range to generate a random integer within
    /// - Returns: A secure random integer
    func generateSecureInt(in range: ClosedRange<Int>) -> Int {
        // In high security mode, use secure random bytes
        if highSecurityMode {
            // Calculate how many bits we need
            let rangeSize = UInt64(range.upperBound - range.lowerBound + 1)
            let bitsNeeded = UInt64.bitWidth - rangeSize.leadingZeroBitCount
            let bytesNeeded = (bitsNeeded + 7) / 8
            
            var randomValue: UInt64 = 0
            var randomBytes = [UInt8](repeating: 0, count: Int(bytesNeeded))
            
            // Keep trying until we get a value in range
            repeat {
                let result = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
                guard result == errSecSuccess else {
                    // Fall back to standard Swift random if secure generation fails
                    return Int.random(in: range)
                }
                
                // Convert bytes to UInt64
                randomValue = 0
                for i in 0..<min(8, randomBytes.count) {
                    randomValue = (randomValue << 8) | UInt64(randomBytes[i])
                }
                
                // Mask off unused bits to avoid bias
                let mask = (1 << bitsNeeded) - 1
                randomValue &= UInt64(mask)
                
            } while randomValue >= rangeSize
            
            return Int(randomValue) + range.lowerBound
        }
        
        // Fall back to standard Swift random if high security isn't required
        return Int.random(in: range)
    }
    
    /// Generates a secure UUID
    /// - Returns: A secure UUID
    func generateSecureUUID() -> UUID {
        // In high security mode, generate a UUID from secure random bytes
        if highSecurityMode {
            do {
                var uuidBytes = try generateSecureBytes(count: 16)
                
                // Set version to 4 (random)
                uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x40
                // Set variant to RFC 4122
                uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80
                
                return UUID(uuid: (
                    uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
                    uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
                    uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
                    uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
                ))
            } catch {
                // Fall back to standard UUID if secure generation fails
                return UUID()
            }
        }
        
        // Fall back to standard UUID generation if high security isn't required
        return UUID()
    }
}
