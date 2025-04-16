import Foundation
import LoggingInterfaces
import LoggingTypes

/// Context for cryptographic operations, tracking metadata with privacy controls.
public struct CryptoLogContext {
    /// The operation being performed
    public let operation: String
    
    /// The cryptographic algorithm (if applicable)
    public let algorithm: String?
    
    /// Correlation ID for tracking related operations
    public let correlationID: String
    
    /// Metadata with privacy classification
    public let metadata: LogMetadataDTOCollection?
    
    /// Creates a new context for a cryptographic operation
    ///
    /// - Parameters:
    ///   - operation: The operation being performed
    ///   - algorithm: Optional algorithm name
    ///   - correlationID: Optional correlation ID, generated if not provided
    ///   - metadata: Optional metadata with privacy controls
    public init(
        operation: String,
        algorithm: String? = nil,
        correlationID: String = UUID().uuidString,
        metadata: LogMetadataDTOCollection? = nil
    ) {
        self.operation = operation
        self.algorithm = algorithm
        self.correlationID = correlationID
        self.metadata = metadata
    }
    
    /// Adds metadata to the context
    ///
    /// - Parameter metadata: The metadata to add
    /// - Returns: A new context with the combined metadata
    public func withMetadata(_ metadata: LogMetadataDTOCollection) -> CryptoLogContext {
        // If we have no existing metadata, just use the new metadata
        guard let existingMetadata = self.metadata else {
            return CryptoLogContext(
                operation: operation,
                algorithm: algorithm,
                correlationID: correlationID,
                metadata: metadata
            )
        }
        
        // Otherwise, combine the metadata
        var combinedMetadata = existingMetadata
        
        // Combine all entries
        for entry in metadata.entries {
            switch entry {
            case .publicEntry(let key, let value):
                combinedMetadata = combinedMetadata.withPublic(key: key, value: value)
            case .privateEntry(let key, let value):
                combinedMetadata = combinedMetadata.withPrivate(key: key, value: value)
            case .sensitiveEntry(let key, let value):
                combinedMetadata = combinedMetadata.withSensitive(key: key, value: value)
            }
        }
        
        return CryptoLogContext(
            operation: operation,
            algorithm: algorithm,
            correlationID: correlationID,
            metadata: combinedMetadata
        )
    }
    
    /// Creates a LogContextDTO from this context
    ///
    /// - Returns: A LogContextDTO representing this context
    public func toLogContextDTO() -> LogContextDTO {
        // Create an empty metadata collection if needed
        let metadataCollection = metadata ?? LogMetadataDTOCollection()
        
        var context = BaseLogContextDTO(
            domainName: "Cryptography",
            operation: operation,
            category: "Security",
            source: "CryptoServicesApple",
            metadata: metadataCollection,
            correlationID: correlationID
        )
        
        if let algorithm = algorithm {
            context = context.withContextualData(key: "algorithm", value: algorithm)
        }
        
        return context
    }
}

// Extension to add operational metadata
extension LogMetadataDTOCollection {
    /// Adds operational metadata with sensitive handling
    ///
    /// This method aliases to withSensitive for private operational data
    ///
    /// - Parameters:
    ///   - key: The metadata key
    ///   - value: The metadata value
    /// - Returns: The updated collection
    public func withOperational(key: String, value: String) -> LogMetadataDTOCollection {
        // Operational data is treated as sensitive data
        return self.withSensitive(key: key, value: value)
    }
}
