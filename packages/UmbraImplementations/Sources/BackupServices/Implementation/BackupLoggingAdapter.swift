import Foundation
import BackupInterfaces
import LoggingTypes
import LoggingInterfaces

/**
 # Modern Backup Logging Adapter
 
 A privacy-aware logging adapter for backup operations that integrates with
 the modern progress reporting system using AsyncStream.
 
 This adapter implements the Alpha Dot Five architecture principles with
 proper British spelling in documentation and follows the privacy-enhanced
 logging system design.
 */
public struct BackupLoggingAdapter {
    /// The underlying logger
    private let logger: LoggingProtocol
    
    /**
     Creates a new backup logging adapter.
     
     - Parameter logger: The core logger to wrap
     */
    public init(logger: LoggingProtocol) {
        self.logger = logger
    }
    
    /**
     Logs the start of a backup operation using a structured log context.
     
     - Parameters:
        - logContext: The structured log context with privacy metadata
        - message: Optional custom message override
     */
    public func logOperationStart(
        logContext: BackupLogContext,
        message: String? = nil
    ) async {
        let operation = logContext.operation ?? "unknown"
        let defaultMessage = "Starting backup operation: \(operation)"
        
        await logger.info(
            message ?? defaultMessage,
            metadata: logContext.toPrivacyMetadata(),
            source: "BackupService"
        )
    }
    
    /**
     Logs the successful completion of a backup operation using a structured log context.
     
     - Parameters:
        - logContext: The structured log context with privacy metadata
        - message: Optional custom message override
     */
    public func logOperationSuccess(
        logContext: BackupLogContext,
        message: String? = nil
    ) async {
        let operation = logContext.operation ?? "unknown"
        let defaultMessage = "Completed backup operation: \(operation)"
        
        var metadata = logContext.toPrivacyMetadata()
        metadata["status"] = PrivacyMetadataValue(value: "success", privacy: .public)
        
        await logger.info(
            message ?? defaultMessage,
            metadata: metadata,
            source: "BackupService"
        )
    }
    
    /**
     Logs the cancellation of a backup operation.
     
     - Parameters:
        - logContext: The structured log context with privacy metadata
        - message: Optional custom message override
     */
    public func logOperationCancelled(
        logContext: BackupLogContext,
        message: String? = nil
    ) async {
        let operation = logContext.operation ?? "unknown"
        let defaultMessage = "Cancelled backup operation: \(operation)"
        
        var metadata = logContext.toPrivacyMetadata()
        metadata["status"] = PrivacyMetadataValue(value: "cancelled", privacy: .public)
        
        await logger.info(
            message ?? defaultMessage,
            metadata: metadata,
            source: "BackupService"
        )
    }
    
    /**
     Logs a specific backup error with structured context.
     
     - Parameters:
        - error: The error that occurred
        - logContext: Structured context with privacy metadata
        - message: Optional custom message override
     */
    public func logOperationFailure(
        error: Error,
        logContext: BackupLogContext,
        message: String? = nil
    ) async {
        let operation = logContext.operation ?? "unknown"
        let defaultMessage = "Error during backup operation: \(operation)"
        
        var metadata = logContext.toPrivacyMetadata()
        metadata["status"] = PrivacyMetadataValue(value: "error", privacy: .public)
        
        // Add error details with appropriate privacy levels
        if let backupError = error as? BackupError {
            metadata["errorCode"] = PrivacyMetadataValue(value: String(describing: backupError.code), privacy: .public)
            metadata["errorMessage"] = PrivacyMetadataValue(value: backupError.localizedDescription, privacy: .private)
            
            // Add structured error context if available
            if let errorContext = backupError.context {
                for (key, value) in errorContext {
                    metadata["error_\(key)"] = PrivacyMetadataValue(value: value, privacy: .private)
                }
            }
        } else {
            metadata["errorType"] = PrivacyMetadataValue(value: String(describing: type(of: error)), privacy: .public)
            metadata["errorMessage"] = PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)
        }
        
        await logger.error(
            message ?? defaultMessage,
            metadata: metadata,
            source: "BackupService"
        )
    }
    
    /**
     Logs a progress update for a backup operation.
     
     - Parameters:
        - progress: The progress update
        - operation: The backup operation
        - logContext: Optional additional context to include
     */
    public func logProgressUpdate(
        _ progress: BackupProgress,
        for operation: BackupOperation,
        logContext: BackupLogContext? = nil
    ) async {
        var metadata = logContext?.toPrivacyMetadata() ?? PrivacyMetadata()
        metadata["operation"] = PrivacyMetadataValue(value: String(describing: operation), privacy: .public)
        
        switch progress {
        case .initialising(let description):
            metadata["progressPhase"] = PrivacyMetadataValue(value: "initialising", privacy: .public)
            metadata["description"] = PrivacyMetadataValue(value: description, privacy: .public)
            
            await logger.info(
                "Initialising backup operation: \(operation)",
                metadata: metadata,
                source: "BackupService"
            )
            
        case .processing(let phase, let percentComplete):
            metadata["progressPhase"] = PrivacyMetadataValue(value: "processing", privacy: .public)
            metadata["description"] = PrivacyMetadataValue(value: phase, privacy: .public)
            metadata["percentComplete"] = PrivacyMetadataValue(value: String(format: "%.1f%%", percentComplete * 100), privacy: .public)
            
            await logger.info(
                "Processing backup operation: \(operation) - \(phase) (\(String(format: "%.1f%%", percentComplete * 100)))",
                metadata: metadata,
                source: "BackupService"
            )
            
        case .completed:
            metadata["progressPhase"] = PrivacyMetadataValue(value: "completed", privacy: .public)
            
            await logger.info(
                "Completed backup operation: \(operation)",
                metadata: metadata,
                source: "BackupService"
            )
            
        case .cancelled:
            metadata["progressPhase"] = PrivacyMetadataValue(value: "cancelled", privacy: .public)
            
            await logger.info(
                "Cancelled backup operation: \(operation)",
                metadata: metadata,
                source: "BackupService"
            )
            
        case .failed(let error):
            metadata["progressPhase"] = PrivacyMetadataValue(value: "failed", privacy: .public)
            
            if let backupError = error as? BackupError {
                metadata["errorCode"] = PrivacyMetadataValue(value: String(describing: backupError.code), privacy: .public)
                metadata["errorMessage"] = PrivacyMetadataValue(value: backupError.localizedDescription, privacy: .private)
            } else {
                metadata["errorType"] = PrivacyMetadataValue(value: String(describing: type(of: error)), privacy: .public)
                metadata["errorMessage"] = PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)
            }
            
            await logger.error(
                "Failed backup operation: \(operation)",
                metadata: metadata,
                source: "BackupService"
            )
        }
    }
}
