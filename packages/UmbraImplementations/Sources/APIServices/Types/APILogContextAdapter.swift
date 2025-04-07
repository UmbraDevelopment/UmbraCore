import Foundation
import LoggingTypes

/**
 * Adapter that converts LogMetadataDTOCollection to LogContextDTO.
 * 
 * This adapter is used to bridge between code that uses the older logging interface
 * (with metadata parameter) and the newer interface (with context parameter).
 */
public struct APILogContextAdapter: LogContextDTO {
    /// The domain name for this context
    public let domainName: String
    
    /// Optional source information (class, file, etc.)
    public let source: String?
    
    /// Optional correlation ID for tracing related log events
    public let correlationID: String?
    
    /// The metadata collection for this context
    public let metadata: LogMetadataDTOCollection
    
    /**
     * Create a new API log context adapter
     * 
     * - Parameters:
     *   - domainName: The domain name (defaults to "APIServices")
     *   - source: Optional source information
     *   - metadata: The metadata collection
     *   - correlationID: Optional correlation ID
     */
    public init(
        domainName: String = "APIServices",
        source: String? = nil,
        metadata: LogMetadataDTOCollection,
        correlationID: String? = nil
    ) {
        self.domainName = domainName
        self.source = source
        self.correlationID = correlationID
        self.metadata = metadata
    }
}

// MARK: - Extension for LogMetadataDTOCollection

public extension LogMetadataDTOCollection {
    /**
     * Convert this metadata collection to a LogContextDTO
     * 
     * - Parameters:
     *   - domainName: The domain name (defaults to "APIServices")
     *   - source: Optional source information
     *   - correlationID: Optional correlation ID
     * - Returns: A LogContextDTO with the metadata from this collection
     */
    func toLogContext(
        domainName: String = "APIServices",
        source: String? = nil,
        correlationID: String? = nil
    ) -> LogContextDTO {
        APILogContextAdapter(
            domainName: domainName,
            source: source,
            metadata: self,
            correlationID: correlationID
        )
    }
}
