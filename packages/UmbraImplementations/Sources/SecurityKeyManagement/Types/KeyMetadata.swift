import CoreSecurityTypes
import DomainSecurityTypes
import Foundation

/**
 # KeyMetadata
 
 Represents metadata for a cryptographic key stored in the security system.
 This structure allows for tracking additional information about stored keys
 without exposing the actual key material.
 
 Key metadata includes:
 - Unique identifier for the key
 - Creation timestamp
 - Key algorithm and strength
 - Usage constraints and permissions
 - Additional application-specific attributes
 
 This metadata is stored separately from the key material for better
 security compartmentalisation and to support efficient querying and listing.
 */
public struct KeyMetadata: Sendable, Codable, Equatable, Identifiable {
    /// Unique identifier for the key
    public let id: String
    
    /// Creation date timestamp (seconds since reference date)
    public let createdAt: TimeInterval
    
    /// Algorithm used for this key
    public let algorithm: CryptoAlgorithm
    
    /// Key strength/size in bits
    public let keySize: Int
    
    /// Purpose for which this key is intended
    public let purpose: String
    
    /// Application-defined key attributes
    public let attributes: [String: String]
    
    /// The identifier used for retrieving the actual key
    public var identifier: String { id }
    
    /**
     Creates a new KeyMetadata instance.
     
     - Parameters:
       - id: Unique identifier for the key
       - createdAt: Creation timestamp (defaults to current time)
       - algorithm: Algorithm used for this key
       - keySize: Key strength/size in bits
       - purpose: Purpose for which this key is intended
       - attributes: Application-defined key attributes
     */
    public init(
        id: String,
        createdAt: TimeInterval = Date().timeIntervalSinceReferenceDate,
        algorithm: CryptoAlgorithm,
        keySize: Int,
        purpose: String,
        attributes: [String: String] = [:]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.algorithm = algorithm
        self.keySize = keySize
        self.purpose = purpose
        self.attributes = attributes
    }
    
    /**
     Serialises this metadata to a byte array.
     
     - Returns: Serialised metadata as [UInt8]
     - Throws: KeyMetadataError if serialisation fails
     */
    public func serialise() throws -> [UInt8] {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        return [UInt8](data)
    }
    
    /**
     Deserialises metadata from a byte array.
     
     - Parameter bytes: Serialised metadata
     - Returns: Deserialised KeyMetadata instance
     - Throws: KeyMetadataError if deserialisation fails
     */
    public static func deserialise(from bytes: [UInt8]) throws -> KeyMetadata {
        let decoder = JSONDecoder()
        let data = Data(bytes)
        return try decoder.decode(KeyMetadata.self, from: data)
    }
}
