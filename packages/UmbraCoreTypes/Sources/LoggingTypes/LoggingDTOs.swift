import Foundation

/// Data Transfer Object for log metadata that includes privacy information
public struct LogMetadataDTO: Sendable, Hashable, Equatable {
    /// The key for the metadata entry
    public let key: String
    
    /// The value for the metadata entry
    public let value: String
    
    /// The privacy level for the metadata entry
    public let privacy: LogPrivacyLevel
    
    /// Create a new metadata entry
    /// - Parameters:
    ///   - key: The key for the entry
    ///   - value: The value for the entry
    ///   - privacy: The privacy level for the entry
    public init(key: String, value: String, privacy: LogPrivacyLevel) {
        self.key = key
        self.value = value
        self.privacy = privacy
    }
    
    /// Convert the DTO to a PrivacyMetadataValue
    /// - Returns: A value that can be used with PrivacyMetadata
    public func toPrivacyMetadataValue() -> PrivacyMetadataValue {
        return PrivacyMetadataValue(value: value, privacy: privacy)
    }
}

/// A collection of LogMetadataDTO values that can be converted to PrivacyMetadata
public struct LogMetadataDTOCollection: Sendable, Equatable {
    /// The metadata entries
    private var entries: [LogMetadataDTO]
    
    /// Create an empty collection
    public init() {
        self.entries = []
    }
    
    /// Create a collection with initial entries
    /// - Parameter entries: The initial entries for the collection
    public init(entries: [LogMetadataDTO]) {
        self.entries = entries
    }
    
    /// Add a new entry to the collection
    /// - Parameter entry: The entry to add
    public mutating func add(_ entry: LogMetadataDTO) {
        entries.append(entry)
    }
    
    /// Add a new public entry to the collection
    /// - Parameters:
    ///   - key: The key for the entry
    ///   - value: The value for the entry
    public mutating func addPublic(key: String, value: String) {
        add(LogMetadataDTO(key: key, value: value, privacy: .public))
    }
    
    /// Add a new private entry to the collection
    /// - Parameters:
    ///   - key: The key for the entry
    ///   - value: The value for the entry
    public mutating func addPrivate(key: String, value: String) {
        add(LogMetadataDTO(key: key, value: value, privacy: .private))
    }
    
    /// Add a new sensitive entry to the collection
    /// - Parameters:
    ///   - key: The key for the entry
    ///   - value: The value for the entry
    public mutating func addSensitive(key: String, value: String) {
        add(LogMetadataDTO(key: key, value: value, privacy: .sensitive))
    }
    
    /// Add error information to the collection
    /// - Parameter error: The error to add
    public mutating func addError(_ error: Error) {
        addPrivate(key: "error", value: error.localizedDescription)
        addPublic(key: "errorType", value: String(describing: type(of: error)))
    }
    
    /// Merge this collection with another collection
    /// - Parameter other: The collection to merge with
    /// - Returns: A new collection with the merged entries
    public mutating func merge(with other: LogMetadataDTOCollection) {
        for entry in other.entries {
            add(entry)
        }
    }
    
    /// Convert the collection to PrivacyMetadata
    /// - Returns: A PrivacyMetadata instance containing all entries
    public func toPrivacyMetadata() -> PrivacyMetadata {
        var metadata = PrivacyMetadata()
        for entry in entries {
            metadata[entry.key] = entry.toPrivacyMetadataValue()
        }
        return metadata
    }
    
    /// Check if the collection contains a specific key
    /// - Parameter key: The key to check
    /// - Returns: True if the key is present
    public func contains(key: String) -> Bool {
        return entries.contains { $0.key == key }
    }
}

/// A base context for domain-specific log contexts
public protocol LogContextDTO: Sendable {
    /// Convert the context to PrivacyMetadata
    /// - Returns: A PrivacyMetadata instance
    func toPrivacyMetadata() -> PrivacyMetadata
    
    /// Get the source for this log context
    /// - Returns: The source identifier
    func getSource() -> String
}

/// Domain-specific context for snapshot-related logs
public struct SnapshotLogContext: LogContextDTO, Sendable, Equatable {
    /// The snapshot ID
    public let snapshotID: String
    
    /// The operation being performed
    public let operation: String
    
    /// Additional context information
    public let additionalContext: LogMetadataDTOCollection
    
    /// Create a new snapshot log context
    /// - Parameters:
    ///   - snapshotID: The snapshot ID
    ///   - operation: The operation being performed
    ///   - additionalContext: Additional context information
    public init(
        snapshotID: String,
        operation: String,
        additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection()
    ) {
        self.snapshotID = snapshotID
        self.operation = operation
        self.additionalContext = additionalContext
    }
    
    /// Convert the context to PrivacyMetadata
    /// - Returns: A PrivacyMetadata instance
    public func toPrivacyMetadata() -> PrivacyMetadata {
        var metadata = additionalContext.toPrivacyMetadata()
        metadata["snapshotID"] = PrivacyMetadataValue(value: snapshotID, privacy: .public)
        metadata["operation"] = PrivacyMetadataValue(value: operation, privacy: .public)
        return metadata
    }
    
    /// Get the source for this log context
    /// - Returns: The source identifier
    public func getSource() -> String {
        return "SnapshotService"
    }
}

/// Domain-specific context for key management logs
public struct KeyManagementLogContext: LogContextDTO, Sendable, Equatable {
    /// The key identifier
    public let keyIdentifier: String
    
    /// The operation being performed
    public let operation: String
    
    /// Additional context information
    public let additionalContext: LogMetadataDTOCollection
    
    /// Create a new key management log context
    /// - Parameters:
    ///   - keyIdentifier: The key identifier
    ///   - operation: The operation being performed
    ///   - additionalContext: Additional context information
    public init(
        keyIdentifier: String,
        operation: String,
        additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection()
    ) {
        self.keyIdentifier = keyIdentifier
        self.operation = operation
        self.additionalContext = additionalContext
    }
    
    /// Convert the context to PrivacyMetadata
    /// - Returns: A PrivacyMetadata instance
    public func toPrivacyMetadata() -> PrivacyMetadata {
        var metadata = additionalContext.toPrivacyMetadata()
        metadata["keyIdentifier"] = PrivacyMetadataValue(value: keyIdentifier, privacy: .private)
        metadata["operation"] = PrivacyMetadataValue(value: operation, privacy: .public)
        return metadata
    }
    
    /// Get the source for this log context
    /// - Returns: The source identifier
    public func getSource() -> String {
        return "KeyManagementActor"
    }
}

/// A log context for keychain-related operations.
/// 
/// This context provides structured information about keychain operations,
/// including the account identifier, operation type, and additional metadata
/// while respecting privacy requirements.
public struct KeychainLogContext: LogContextDTO {
    /// The account identifier, typically treated as private
    public let account: String
    
    /// The operation being performed (e.g., store, retrieve, delete)
    public let operation: String
    
    /// Additional context specific to the operation
    public let additionalContext: LogMetadataDTOCollection
    
    /// Domain name for logging categorization
    public let domain = "Keychain"
    
    /**
     Initializes a new KeychainLogContext.
     
     - Parameters:
        - account: The account identifier associated with the operation.
        - operation: The type of operation being performed.
        - additionalContext: Optional additional context with privacy annotations.
     */
    public init(
        account: String,
        operation: String,
        additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection()
    ) {
        self.account = account
        self.operation = operation
        self.additionalContext = additionalContext
    }
    
    /**
     Converts this context to a privacy-annotated metadata collection.
     
     - Returns: A PrivacyMetadata instance with appropriate privacy controls.
     */
    public func toPrivacyMetadata() -> PrivacyMetadata {
        var metadata = additionalContext.toPrivacyMetadata()
        
        // Ensure core fields are present with proper privacy
        if !additionalContext.contains(key: "account") {
            metadata["account"] = PrivacyMetadataValue(value: account, privacy: .private)
        }
        
        if !additionalContext.contains(key: "operation") {
            metadata["operation"] = PrivacyMetadataValue(value: operation, privacy: .public)
        }
        
        metadata["domain"] = PrivacyMetadataValue(value: domain, privacy: .public)
        
        return metadata
    }
    
    /// Get the source for this log context
    /// - Returns: The source identifier
    public func getSource() -> String {
        return "Keychain"
    }
}

/// A log context for cryptographic operations.
/// 
/// This context provides structured information about crypto operations,
/// including the operation type, algorithm, and additional metadata
/// while respecting privacy requirements.
public struct CryptoLogContext: LogContextDTO {
    /// The cryptographic operation being performed (e.g., encrypt, decrypt, sign)
    public let operation: String
    
    /// The cryptographic algorithm being used, if applicable
    public let algorithm: String?
    
    /// Additional context specific to the operation
    public let additionalContext: LogMetadataDTOCollection
    
    /// Domain name for logging categorization
    public let domain = "Crypto"
    
    /**
     Initializes a new CryptoLogContext.
     
     - Parameters:
        - operation: The type of cryptographic operation being performed.
        - algorithm: Optional cryptographic algorithm being used.
        - additionalContext: Optional additional context with privacy annotations.
     */
    public init(
        operation: String,
        algorithm: String? = nil,
        additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection()
    ) {
        self.operation = operation
        self.algorithm = algorithm
        self.additionalContext = additionalContext
    }
    
    /**
     Converts this context to a privacy-annotated metadata collection.
     
     - Returns: A PrivacyMetadata instance with appropriate privacy controls.
     */
    public func toPrivacyMetadata() -> PrivacyMetadata {
        var metadata = additionalContext.toPrivacyMetadata()
        
        // Ensure core fields are present with proper privacy
        if !additionalContext.contains(key: "operation") {
            metadata["operation"] = PrivacyMetadataValue(value: operation, privacy: .public)
        }
        
        if let algorithm = algorithm, !additionalContext.contains(key: "algorithm") {
            metadata["algorithm"] = PrivacyMetadataValue(value: algorithm, privacy: .public)
        }
        
        metadata["domain"] = PrivacyMetadataValue(value: domain, privacy: .public)
        
        return metadata
    }
    
    /// Get the source for this log context
    /// - Returns: The source identifier
    public func getSource() -> String {
        return "CryptoService"
    }
}

/// Protocol for structured error logging with privacy classifications
public protocol LoggableErrorProtocol: Error {
    /// Convert the error to a privacy metadata collection
    /// - Returns: A PrivacyMetadata instance with properly classified error details
    func toPrivacyMetadata() -> PrivacyMetadata
}

/// DTO for error information with privacy classification
public struct LoggableError: LoggableErrorProtocol, Sendable, Equatable {
    /// The error that was encountered
    public let error: Error
    
    /// Fields that should be treated as public
    public let publicFields: [String]
    
    /// Fields that should be treated as private
    public let privateFields: [String]
    
    /// Fields that should be treated as sensitive
    public let sensitiveFields: [String]
    
    /// Create a new loggable error
    /// - Parameters:
    ///   - error: The error that was encountered
    ///   - publicFields: Fields that should be treated as public
    ///   - privateFields: Fields that should be treated as private
    ///   - sensitiveFields: Fields that should be treated as sensitive
    public init(
        error: Error,
        publicFields: [String] = [],
        privateFields: [String] = [],
        sensitiveFields: [String] = []
    ) {
        self.error = error
        self.publicFields = publicFields
        self.privateFields = privateFields
        self.sensitiveFields = sensitiveFields
    }
    
    /// Convert the error to PrivacyMetadata
    /// - Returns: A PrivacyMetadata instance
    public func toPrivacyMetadata() -> PrivacyMetadata {
        var metadata = PrivacyMetadata()
        let errorMirror = Mirror(reflecting: error)
        
        // Add base error information
        metadata["errorType"] = PrivacyMetadataValue(value: String(describing: type(of: error)), privacy: .public)
        metadata["localizedDescription"] = PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)
        
        // Process the error properties based on privacy classification
        for child in errorMirror.children {
            guard let label = child.label else { continue }
            
            // Remove any underscore prefix from property names
            let cleanLabel = label.hasPrefix("_") ? String(label.dropFirst()) : label
            let value = String(describing: child.value)
            
            if publicFields.contains(label) {
                metadata[cleanLabel] = PrivacyMetadataValue(value: value, privacy: .public)
            } else if privateFields.contains(label) {
                metadata[cleanLabel] = PrivacyMetadataValue(value: value, privacy: .private)
            } else if sensitiveFields.contains(label) {
                metadata[cleanLabel] = PrivacyMetadataValue(value: value, privacy: .sensitive)
            } else {
                // Default to private for unknown fields
                metadata[cleanLabel] = PrivacyMetadataValue(value: value, privacy: .private)
            }
        }
        
        // Add domain information if available
        if let domainError = error as? CustomNSError {
            metadata["errorDomain"] = PrivacyMetadataValue(
                value: String(describing: type(of: domainError).errorDomain), 
                privacy: .public
            )
            metadata["errorCode"] = PrivacyMetadataValue(
                value: String(domainError.errorCode),
                privacy: .public
            )
        }
        
        return metadata
    }
    
    /// Check if two LoggableError instances are equal
    /// - Parameters:
    ///   - lhs: Left-hand side instance
    ///   - rhs: Right-hand side instance
    /// - Returns: True if the instances are equal
    public static func == (lhs: LoggableError, rhs: LoggableError) -> Bool {
        // Compare the error types and descriptions
        let lhsErrorType = String(describing: type(of: lhs.error))
        let rhsErrorType = String(describing: type(of: rhs.error))
        let lhsDescription = lhs.error.localizedDescription
        let rhsDescription = rhs.error.localizedDescription
        
        return lhsErrorType == rhsErrorType && 
               lhsDescription == rhsDescription &&
               lhs.publicFields == rhs.publicFields &&
               lhs.privateFields == rhs.privateFields &&
               lhs.sensitiveFields == rhs.sensitiveFields
    }
}

/**
 A log context for error handling operations.
 
 This context provides structured information about errors, including
 error type, message, domain information, and additional contextual
 metadata while respecting privacy requirements.
 */
public struct ErrorLogContext: LogContextDTO {
    /// The error that occurred
    public let error: Error
    
    /// Optional source of the error
    public let source: String?
    
    /// Additional context specific to the error
    public let additionalContext: LogMetadataDTOCollection
    
    /// Domain name for logging categorisation
    public let domain = "Error"
    
    /**
     Initialises a new ErrorLogContext.
     
     - Parameters:
        - error: The error that occurred.
        - source: Optional source of the error.
        - additionalContext: Optional additional context with privacy annotations.
     */
    public init(
        error: Error,
        source: String? = nil,
        additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection()
    ) {
        self.error = error
        self.source = source
        self.additionalContext = additionalContext
    }
    
    /**
     Converts this context to a privacy-annotated metadata collection.
     
     - Returns: A PrivacyMetadata instance with appropriate privacy controls.
     */
    public func toPrivacyMetadata() -> PrivacyMetadata {
        var metadata = additionalContext.toPrivacyMetadata()
        
        // Add error information with appropriate privacy level
        metadata["errorType"] = PrivacyMetadataValue(
            value: String(describing: type(of: error)), 
            privacy: .public
        )
        metadata["errorMessage"] = PrivacyMetadataValue(
            value: error.localizedDescription, 
            privacy: .private
        )
        
        // Add domain information if available
        if let domainError = error as? CustomNSError {
            metadata["errorDomain"] = PrivacyMetadataValue(
                value: String(describing: type(of: domainError).errorDomain), 
                privacy: .public
            )
            metadata["errorCode"] = PrivacyMetadataValue(
                value: String(domainError.errorCode),
                privacy: .public
            )
        }
        
        // Add source information if available
        if let source = source {
            metadata["source"] = PrivacyMetadataValue(value: source, privacy: .public)
        }
        
        metadata["domain"] = PrivacyMetadataValue(value: domain, privacy: .public)
        
        return metadata
    }
    
    /// Get the source for this log context
    /// - Returns: The source identifier
    public func getSource() -> String {
        return source ?? "ErrorHandler"
    }
}

/**
 A log context for file system operations.
 
 This context provides structured information about file operations,
 including paths, operation types, and additional metadata
 while respecting privacy requirements for file paths.
 */
public struct FileSystemLogContext: LogContextDTO {
    /// The file system operation being performed (e.g., read, write, delete)
    public let operation: String
    
    /// The file path involved in the operation, treated as private by default
    public let path: String?
    
    /// Additional context specific to the operation
    public let additionalContext: LogMetadataDTOCollection
    
    /// Domain name for logging categorisation
    public let domain = "FileSystem"
    
    /**
     Initialises a new FileSystemLogContext.
     
     - Parameters:
        - operation: The type of file operation being performed.
        - path: Optional path to the file or directory involved.
        - additionalContext: Optional additional context with privacy annotations.
     */
    public init(
        operation: String,
        path: String? = nil,
        additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection()
    ) {
        self.operation = operation
        self.path = path
        self.additionalContext = additionalContext
    }
    
    /**
     Converts this context to a privacy-annotated metadata collection.
     
     - Returns: A PrivacyMetadata instance with appropriate privacy controls.
     */
    public func toPrivacyMetadata() -> PrivacyMetadata {
        var metadata = additionalContext.toPrivacyMetadata()
        
        // Ensure core fields are present with proper privacy
        if !additionalContext.contains(key: "operation") {
            metadata["operation"] = PrivacyMetadataValue(value: operation, privacy: .public)
        }
        
        if let path = path, !additionalContext.contains(key: "path") {
            // Paths are private by default as they may contain sensitive information
            metadata["path"] = PrivacyMetadataValue(value: path, privacy: .private)
        }
        
        metadata["domain"] = PrivacyMetadataValue(value: domain, privacy: .public)
        
        return metadata
    }
    
    /// Get the source for this log context
    /// - Returns: The source identifier
    public func getSource() -> String {
        return "FileSystem"
    }
}
