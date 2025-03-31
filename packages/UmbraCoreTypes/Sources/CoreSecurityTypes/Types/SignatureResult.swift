import Foundation

/**
 # SignatureResult
 
 Represents the result of a digital signature operation in the Alpha Dot Five architecture.
 Provides strong typing for signature outputs with additional metadata.
 
 ## Usage
 ```swift
 let result = SignatureResult(
     signature: signatureData,
     algorithm: .ed25519
 )
 ```
 */
public struct SignatureResult: Sendable, Equatable {
    /// The digital signature data
    public let signature: Data
    
    /// The algorithm used for signing
    public let algorithm: SigningAlgorithm
    
    /// Additional metadata for verification
    public let metadata: [String: Data]
    
    /// Creates a new signature result
    public init(signature: Data, algorithm: SigningAlgorithm, metadata: [String: Data] = [:]) {
        self.signature = signature
        self.algorithm = algorithm
        self.metadata = metadata
    }
}
