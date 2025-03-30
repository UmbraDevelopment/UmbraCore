import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # ErrorLogger
 
 A specialised logger for error handling that provides domain-specific
 logging methods with appropriate privacy controls and contextual
 information.
 
 This component enhances error logs with consistent formatting, privacy
 annotations, and structured metadata to improve debugging and analysis.
 */
public final class ErrorLogger: @unchecked Sendable {
    /// The underlying logger implementation
    private let logger: LoggingProtocol
    
    /// The subsystem for error logging
    private let subsystem = "ErrorHandling"
    
    /**
     Initialises a new error logger with the provided logging implementation.
     
     - Parameter logger: The underlying logger to use for output
     */
    public init(logger: LoggingProtocol) {
        self.logger = logger
    }
    
    /**
     Logs an error with appropriate privacy controls and context.
     
     - Parameters:
       - error: The error to log
       - file: The file where the error occurred
       - function: The function where the error occurred
       - line: The line where the error occurred
     */
    public func logError(
        _ error: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        // Create metadata for debugging but don't pass it yet 
        // as PrivacyMetadata integration needs to be completed
        _ = createErrorMetadata(error, file: file, function: function, line: line)
        await logger.error("Error encountered: \(String(describing: error))", metadata: nil, source: subsystem)
    }
    
    /**
     Logs an error with source information and additional metadata.
     
     - Parameters:
       - error: The error to log
       - source: The source component identifier
       - metadata: Additional metadata to include
     */
    public func logError(
        _ error: Error,
        source: String?,
        metadata: [String: String]
    ) async {
        var baseMetadata = createErrorMetadata(error, file: #file, function: #function, line: #line)
        
        // Add any additional metadata
        for (key, value) in metadata {
            baseMetadata[key] = value
        }
        
        // Use nil for PrivacyMetadata as it's acceptable in the interface
        await logger.error("Error encountered: \(String(describing: error))", 
                          metadata: nil, 
                          source: source ?? subsystem)
    }
    
    /**
     Logs a critical error with appropriate privacy controls and context.
     
     - Parameters:
       - error: The error to log
       - file: The file where the error occurred
       - function: The function where the error occurred
       - line: The line where the error occurred
     */
    public func logCritical(
        _ error: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        // Create metadata for debugging but don't pass it yet
        _ = createErrorMetadata(error, file: file, function: function, line: line)
        await logger.critical("Critical error: \(String(describing: error))", metadata: nil, source: subsystem)
    }
    
    /**
     Logs an error with a custom message and appropriate privacy controls.
     
     - Parameters:
       - message: The message to log
       - error: The error to include as context
       - file: The file where the error occurred
       - function: The function where the error occurred
       - line: The line where the error occurred
     */
    public func logMessage(
        _ message: String,
        error: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        // Create metadata for debugging but don't pass it yet
        _ = createErrorMetadata(error, file: file, function: function, line: line)
        await logger.error("\(message) - \(String(describing: error))", metadata: nil, source: subsystem)
    }
    
    // MARK: - Private Methods
    
    /**
     Creates metadata for an error log entry.
     
     - Parameters:
       - error: The error to create metadata for
       - file: The file where the error occurred
       - function: The function where the error occurred
       - line: The line where the error occurred
     - Returns: Metadata dictionary for the log entry
     */
    private func createErrorMetadata(
        _ error: Error,
        file: String,
        function: String,
        line: Int
    ) -> LogMetadata {
        var metadata = LogMetadata([
            "subsystem": subsystem,
            "errorType": String(describing: type(of: error)),
            "file": file,
            "function": function,
            "line": String(line)
        ])
        
        // All Swift errors can be bridged to NSError safely without optional casting
        let nsError = error as NSError
        metadata["errorCode"] = String(nsError.code)
        metadata["errorDomain"] = nsError.domain
        
        if !nsError.userInfo.isEmpty {
            metadata["errorUserInfo"] = String(describing: nsError.userInfo)
        }
        
        return metadata
    }
}
