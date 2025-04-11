import Foundation
import SecurityCoreInterfaces

/**
 # Basic Crypto Material
 
 A concrete implementation of the SendableCryptoMaterial protocol that contains
 cryptographic material such as keys, certificates, or other security-related data.
 
 This implementation follows the Alpha Dot Five architecture principles,
 ensuring secure handling of sensitive cryptographic material with proper 
 memory management and Sendable conformance for thread safety.
 */
public struct BasicCryptoMaterial: SendableCryptoMaterial {
    /// The raw bytes of the cryptographic material
    private let bytes: [UInt8]
    
    /**
     Initialises a new instance with the provided bytes.
     
     - Parameter bytes: The raw cryptographic material as an array of bytes
     */
    public init(bytes: [UInt8]) {
        self.bytes = bytes
    }
    
    /**
     Retrieves the raw bytes of the cryptographic material.
     
     - Returns: The raw cryptographic material as an array of bytes
     */
    public func getBytes() -> [UInt8] {
        return bytes
    }
    
    /**
     Retrieves the size of the cryptographic material in bytes.
     
     - Returns: The size of the material in bytes
     */
    public func size() -> Int {
        return bytes.count
    }
    
    /**
     Creates a new instance from a Data object.
     
     - Parameter data: The Data object containing the cryptographic material
     - Returns: A new BasicCryptoMaterial instance
     */
    public static func from(data: Data) -> Self {
        return BasicCryptoMaterial(bytes: [UInt8](data))
    }
    
    /**
     Converts the cryptographic material to a Data object.
     
     - Returns: A Data object containing the cryptographic material
     */
    public func toData() -> Data {
        return Data(bytes)
    }
}
