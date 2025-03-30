import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # ErrorLogger
 
 A specialized logger for error handling that provides domain-specific
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
    ) {
        let metadata = createErrorMetadata(error, file: file, function: function, line: line)
        logger.error("Error encountered: \(String(describing: error), privacy: .private)", metadata: metadata)
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
    ) {
        let metadata = createErrorMetadata(error, file: file, function: function, line: line)
        logger.critical("Critical error: \(String(describing: error), privacy: .private)", metadata: metadata)
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
    ) {
        let metadata = createErrorMetadata(error, file: file, function: function, line: line)
        logger.error("\(message, privacy: .public) - \(String(describing: error), privacy: .private)", metadata: metadata)
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
    ) -> [String: LogMetadataValue] {
        var metadata: [String: LogMetadataValue] = [
            "subsystem": .string(subsystem),
            "errorType": .string(String(describing: type(of: error))),
            "file": .string(file),
            "function": .string(function),
            "line": .int(line)
        ]
        
        // Add error code if available
        if let nsError = error as NSError {
            metadata["errorCode"] = .int(nsError.code)
            metadata["errorDomain"] = .string(nsError.domain)
            
            if let userInfo = nsError.userInfo as? [String: Any], !userInfo.isEmpty {
                metadata["errorUserInfo"] = .string(String(describing: userInfo))
            }
        }
        
        return metadata
    }
}
