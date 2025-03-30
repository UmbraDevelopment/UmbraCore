import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Keychain Logger
 
 A domain-specific privacy-aware logger for keychain operations that follows
 the Alpha Dot Five architecture principles for structured logging.
 
 This logger ensures that sensitive information related to keychain operations
 is properly classified with appropriate privacy levels, with British spelling
 in documentation and comments.
 */
public struct KeychainLogger: Sendable {
    /// The underlying logger
    private let logger: any LoggingProtocol
    
    /**
     Initialises a new keychain logger.
     
     - Parameter logger: The core logger to wrap
     */
    public init(logger: LoggingProtocol) {
        self.logger = logger
    }
    
    /**
     Logs the start of a keychain operation.
     
     - Parameters:
        - operation: The operation being performed
        - account: Optional account identifier (private metadata)
        - additionalMetadata: Any additional metadata to include
     */
    public func logOperationStart(
        operation: String,
        account: String? = nil,
        additionalMetadata: [String: Any] = [:]
    ) async {
        var metadata = LogMetadataDTOCollection()
        
        metadata.addPublic(key: "operation", value: operation)
        
        if let account = account {
            metadata.addPrivate(key: "account", value: account)
        }
        
        // Add any additional metadata
        for (key, value) in additionalMetadata {
            metadata.add(LogMetadataDTO(key: key, value: String(describing: value), privacy: .auto))
        }
        
        await logger.info(
            "Starting keychain operation: \(operation)",
            metadata: metadata.toPrivacyMetadata(),
            source: "KeychainSecurity"
        )
    }
    
    /**
     Logs the start of a keychain operation with key identifier.
     
     - Parameters:
        - account: The account identifier (private metadata)
        - operation: The operation being performed
        - keyIdentifier: The key identifier (private metadata)
        - additionalContext: Optional additional structured context
     */
    public func logOperationStart(
        account: String? = nil,
        operation: String,
        keyIdentifier: String? = nil,
        additionalContext: LogMetadataDTOCollection? = nil
    ) async {
        var metadata = LogMetadataDTOCollection()
        
        metadata.addPublic(key: "operation", value: operation)
        
        if let account = account {
            metadata.addPrivate(key: "account", value: account)
        }
        
        if let keyIdentifier = keyIdentifier {
            metadata.addPrivate(key: "keyIdentifier", value: keyIdentifier)
        }
        
        // Add additional context if provided
        if let additionalContext = additionalContext {
            metadata.merge(with: additionalContext)
        }
        
        await logger.info(
            "Starting keychain operation: \(operation)",
            metadata: metadata.toPrivacyMetadata(),
            source: "KeychainSecurity"
        )
    }
    
    /**
     Logs the successful completion of a keychain operation.
     
     - Parameters:
        - operation: The operation that was performed
        - account: Optional account identifier (private metadata)
        - additionalMetadata: Any additional metadata to include
     */
    public func logOperationSuccess(
        operation: String,
        account: String? = nil,
        additionalMetadata: [String: Any] = [:]
    ) async {
        var metadata = LogMetadataDTOCollection()
        
        metadata.addPublic(key: "operation", value: operation)
        metadata.addPublic(key: "status", value: "success")
        
        if let account = account {
            metadata.addPrivate(key: "account", value: account)
        }
        
        // Add any additional metadata
        for (key, value) in additionalMetadata {
            metadata.add(LogMetadataDTO(key: key, value: String(describing: value), privacy: .auto))
        }
        
        await logger.info(
            "Completed keychain operation: \(operation)",
            metadata: metadata.toPrivacyMetadata(),
            source: "KeychainSecurity"
        )
    }
    
    /**
     Logs the successful completion of a keychain operation with key identifier.
     
     - Parameters:
        - account: The account identifier (private metadata)
        - operation: The operation that was performed
        - keyIdentifier: The key identifier (private metadata)
        - additionalContext: Optional additional structured context
     */
    public func logOperationSuccess(
        account: String? = nil,
        operation: String,
        keyIdentifier: String? = nil,
        additionalContext: LogMetadataDTOCollection? = nil
    ) async {
        var metadata = LogMetadataDTOCollection()
        
        metadata.addPublic(key: "operation", value: operation)
        metadata.addPublic(key: "status", value: "success")
        
        if let account = account {
            metadata.addPrivate(key: "account", value: account)
        }
        
        if let keyIdentifier = keyIdentifier {
            metadata.addPrivate(key: "keyIdentifier", value: keyIdentifier)
        }
        
        // Add additional context if provided
        if let additionalContext = additionalContext {
            metadata.merge(with: additionalContext)
        }
        
        await logger.info(
            "Completed keychain operation: \(operation)",
            metadata: metadata.toPrivacyMetadata(),
            source: "KeychainSecurity"
        )
    }
    
    /**
     Logs an error that occurred during a keychain operation.
     
     - Parameters:
        - operation: The operation where the error occurred
        - error: The error that occurred
        - account: Optional account identifier (private metadata)
        - additionalMetadata: Any additional metadata to include
     */
    public func logOperationError(
        operation: String,
        error: Error,
        account: String? = nil,
        additionalMetadata: [String: Any] = [:]
    ) async {
        var metadata = LogMetadataDTOCollection()
        
        metadata.addPublic(key: "operation", value: operation)
        metadata.addPublic(key: "status", value: "error")
        metadata.addPublic(key: "errorType", value: String(describing: type(of: error)))
        metadata.addPrivate(key: "errorMessage", value: error.localizedDescription)
        
        if let account = account {
            metadata.addPrivate(key: "account", value: account)
        }
        
        // Add any additional metadata
        for (key, value) in additionalMetadata {
            metadata.add(LogMetadataDTO(key: key, value: String(describing: value), privacy: .auto))
        }
        
        await logger.error(
            "Error during keychain operation: \(operation)",
            metadata: metadata.toPrivacyMetadata(),
            source: "KeychainSecurity"
        )
    }
    
    /**
     Logs an error that occurred during a keychain operation with key identifier.
     
     - Parameters:
        - account: The account identifier (private metadata)
        - operation: The operation where the error occurred
        - error: The error that occurred
        - keyIdentifier: The key identifier (private metadata)
        - additionalContext: Optional additional structured context
        - message: Optional custom message override
     */
    public func logOperationError(
        account: String? = nil,
        operation: String,
        error: Error,
        keyIdentifier: String? = nil,
        additionalContext: LogMetadataDTOCollection? = nil,
        message: String? = nil
    ) async {
        var metadata = LogMetadataDTOCollection()
        
        metadata.addPublic(key: "operation", value: operation)
        metadata.addPublic(key: "status", value: "error")
        metadata.addPublic(key: "errorType", value: String(describing: type(of: error)))
        metadata.addPrivate(key: "errorMessage", value: error.localizedDescription)
        
        if let account = account {
            metadata.addPrivate(key: "account", value: account)
        }
        
        if let keyIdentifier = keyIdentifier {
            metadata.addPrivate(key: "keyIdentifier", value: keyIdentifier)
        }
        
        // Add additional context if provided
        if let additionalContext = additionalContext {
            metadata.merge(with: additionalContext)
        }
        
        let defaultMessage = "Error during keychain operation: \(operation)"
        
        await logger.error(
            message ?? defaultMessage,
            metadata: metadata.toPrivacyMetadata(),
            source: "KeychainSecurity"
        )
    }
}
