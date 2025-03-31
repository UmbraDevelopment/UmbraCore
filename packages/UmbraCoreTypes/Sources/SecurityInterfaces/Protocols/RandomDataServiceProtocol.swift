import Foundation

/// Protocol defining the interface for secure random data generation services.
///
/// This protocol provides methods for generating cryptographically secure
/// random values for various security-sensitive applications.
public protocol RandomDataServiceProtocol: Sendable {
    /// Initialises the random data service with the specified configuration
    /// - Parameter configuration: Configuration options for random data generation
    /// - Throws: SecurityError if initialisation fails
    func initialise(configuration: RandomizationOptionsDTO) async throws
    
    /// Generates a random double value between 0.0 and 1.0
    /// - Returns: A random double value
    func generateRandomDouble() async -> Double
    
    /// Generates random bytes of the specified length
    /// - Parameter count: The number of random bytes to generate
    /// - Returns: An array of random bytes
    /// - Throws: SecurityError if random generation fails
    func generateRandomBytes(count: Int) async throws -> [UInt8]
    
    /// Generates a random integer within the specified range
    /// - Parameters:
    ///   - range: The range of values to generate from
    /// - Returns: A random integer
    func generateRandomInt(in range: ClosedRange<Int>) async -> Int
    
    /// Generates a random element from an array
    /// - Parameter array: The array to select from
    /// - Returns: A randomly selected element, or nil if the array is empty
    func generateRandomElement<T>(from array: [T]) async -> T?
    
    /// Shuffles an array randomly
    /// - Parameter array: The array to shuffle
    /// - Returns: A new array with the elements in random order
    func shuffle<T>(_ array: [T]) async -> [T]
    
    /// Generates a secure token as a string
    /// - Parameter byteCount: The number of bytes to use for the token
    /// - Returns: A secure token as a string
    /// - Throws: SecurityError if token generation fails
    func generateSecureToken(byteCount: Int) async throws -> String
    
    /// Generates a UUID
    /// - Returns: A new UUID
    func generateUUID() async -> UUID
}
