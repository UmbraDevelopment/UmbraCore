import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 * A basic implementation of LogContextDTO for API Services
 * 
 * This provides a consistent way to create log contexts within the API Services module
 * and follows the privacy-by-design principles of the Alpha Dot Five architecture.
 */
public struct APILogContextDTO: LogContextDTO {
    /// The domain name for this context
    public let domainName: String
    
    /// Source information (class, file, etc.)
    public let source: String?
    
    /// Correlation ID for tracing related log events
    public let correlationID: String?
    
    /// The metadata collection for this context
    public let metadata: LogMetadataDTOCollection
    
    /**
     * Create a new API log context DTO
     * 
     * - Parameters:
     *   - domainName: The domain name (defaults to "APIServices")
     *   - source: Source information
     *   - metadata: The metadata collection
     *   - correlationID: Optional correlation ID
     */
    public init(
        domainName: String = "APIServices",
        source: String? = nil,
        metadata: LogMetadataDTOCollection = LogMetadataDTOCollection(),
        correlationID: String? = nil
    ) {
        self.domainName = domainName
        self.source = source
        self.correlationID = correlationID
        self.metadata = metadata
    }
}

// Extension to LogMetadataDTOCollection
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
        APILogContextDTO(
            domainName: domainName,
            source: source,
            metadata: self,
            correlationID: correlationID
        )
    }
}
