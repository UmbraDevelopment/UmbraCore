import Foundation

/// Protocol for secure random data generation services.
///
/// This protocol defines the interface for services that provide secure random data
/// generation, conforming to the Alpha Dot Five architecture's privacy-by-design principles.
public protocol RandomDataServiceProtocol: Sendable {
    /// Generates cryptographically secure random bytes
    /// - Parameter length: The number of bytes to generate
    /// - Returns: The generated random bytes
    /// - Throws: SecurityError if random generation fails
    func generateRandomBytes(length: Int) async throws -> [UInt8]
    
    /// Generates a cryptographically secure random integer within the specified range
    /// - Parameter range: The range within which to generate the random integer
    /// - Returns: The generated random integer
    /// - Throws: SecurityError if random generation fails
    func generateRandomInteger<T: FixedWidthInteger>(in range: Range<T>) async throws -> T
    
    /// Generates a cryptographically secure random integer within the specified closed range
    /// - Parameter range: The closed range within which to generate the random integer
    /// - Returns: The generated random integer
    /// - Throws: SecurityError if random generation fails
    func generateRandomInteger<T: FixedWidthInteger>(in range: ClosedRange<T>) async throws -> T
    
    /// Generates a cryptographically secure random double between 0.0 and 1.0
    /// - Returns: The generated random double
    /// - Throws: SecurityError if random generation fails
    func generateRandomDouble() async throws -> Double
    
    /// Initialises the random data service with the specified entropy source
    /// - Parameter entropySource: The entropy source to use (system, hardware, or hybrid)
    /// - Throws: SecurityError if initialisation fails
    func initialise(entropySource: EntropySource) async throws
    
    /// Returns the entropy quality level of the random data service
    /// - Returns: Entropy quality level (low, medium, high)
    func getEntropyQuality() async -> EntropyQuality
}

/// Entropy source for random data generation
public enum EntropySource: String, Sendable, Equatable, CaseIterable {
    /// System entropy source
    case system
    
    /// Hardware entropy source if available
    case hardware
    
    /// Hybrid entropy source combining multiple sources
    case hybrid
}

/// Entropy quality level
public enum EntropyQuality: String, Sendable, Equatable, CaseIterable, Comparable {
    /// Low entropy quality
    case low
    
    /// Medium entropy quality
    case medium
    
    /// High entropy quality
    case high
    
    public static func < (lhs: EntropyQuality, rhs: EntropyQuality) -> Bool {
        let order: [EntropyQuality] = [.low, .medium, .high]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}
