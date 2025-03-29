import Foundation
import LoggingInterfaces
import LoggingTypes

/// Protocol for file management operations needed by the file log destination
///
/// This protocol enables better testability by allowing mock implementations
/// for file operations in unit tests.
public protocol FileManagerProtocol: Sendable {
    /// Check if a file exists at the specified path
    /// - Parameter path: The file path to check
    /// - Returns: True if the file exists, false otherwise
    func fileExists(atPath path: String) -> Bool
    
    /// Create a directory at the specified path
    /// - Parameters:
    ///   - path: The directory path to create
    ///   - createIntermediates: Whether to create intermediate directories
    ///   - attributes: Optional file attributes
    /// - Throws: Error if directory creation fails
    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws
    
    /// Write data to file at the specified path
    /// - Parameters:
    ///   - data: The data to write
    ///   - path: The file path to write to
    /// - Throws: Error if write fails
    func writeData(_ data: Data, toFile path: String) throws
    
    /// Append data to file at the specified path
    /// - Parameters:
    ///   - data: The data to append
    ///   - path: The file path to append to
    /// - Throws: Error if append fails
    func appendData(_ data: Data, toFile path: String) throws
}

/// Extension to Foundation's FileManager to conform to FileManagerProtocol
extension FileManager: FileManagerProtocol {
    /// Write data to file at the specified path
    /// - Parameters:
    ///   - data: The data to write
    ///   - path: The file path to write to
    /// - Throws: Error if write fails
    public func writeData(_ data: Data, toFile path: String) throws {
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
    }
    
    /// Append data to file at the specified path
    /// - Parameters:
    ///   - data: The data to append
    ///   - path: The file path to append to
    /// - Throws: Error if append fails
    public func appendData(_ data: Data, toFile path: String) throws {
        if let fileHandle = FileHandle(forWritingAtPath: path) {
            defer {
                try? fileHandle.close()
            }
            
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: data)
        } else {
            // File doesn't exist, create it
            try writeData(data, toFile: path)
        }
    }
}

// Make FileManager Sendable-conforming to support actor isolation
// The @retroactive attribute silences warnings about extending an imported type
extension FileManager: @retroactive @unchecked Sendable {}

/// A log destination that writes to a file
///
/// This implementation provides file-based logging with rotation capabilities
/// and configurable formatting. It follows the Alpha Dot Five architecture
/// patterns with proper concurrency safety.
public actor FileLogDestination: LoggingTypes.LogDestination {
    /// Unique identifier for this destination
    public let identifier: String
    
    /// Minimum log level this destination will accept
    public nonisolated(unsafe) var minimumLevel: LoggingTypes.UmbraLogLevel
    
    /// Path to the log file
    public let filePath: String
    
    /// Path to the directory containing the log file
    private let directoryPath: String
    
    /// File manager for file operations
    private let fileManager: FileManagerProtocol
    
    /// Formatter for log entries
    private let formatter: LoggingInterfaces.LogFormatterProtocol
    
    /// Maximum file size in bytes before rotation
    private let maxFileSize: UInt64
    
    /// Number of backup log files to keep
    private let maxBackupCount: Int
    
    /// Logging queue for asynchronous file operations
    private var pendingWrites: [LoggingTypes.LogEntry] = []
    
    /// Initialise a file log destination with the given configuration
    /// - Parameters:
    ///   - identifier: Unique identifier for this destination
    ///   - filePath: Path where log file should be written
    ///   - minimumLevel: Minimum log level to record
    ///   - maxFileSize: Maximum file size in bytes before rotation
    ///   - maxBackupCount: Number of backup log files to keep
    ///   - formatter: Optional formatter to use
    ///   - fileManager: Optional file manager to use
    public init(
        identifier: String = "file",
        filePath: String,
        minimumLevel: LoggingTypes.UmbraLogLevel = .info,
        maxFileSize: UInt64 = 10 * 1024 * 1024, // 10MB default
        maxBackupCount: Int = 5,
        formatter: LoggingInterfaces.LogFormatterProtocol? = nil,
        fileManager: FileManagerProtocol? = nil
    ) {
        self.identifier = identifier
        self.filePath = filePath
        self.minimumLevel = minimumLevel
        self.maxFileSize = maxFileSize
        self.maxBackupCount = maxBackupCount
        self.formatter = formatter ?? DefaultLogFormatter()
        self.fileManager = fileManager ?? FileManager.default
        
        // Extract directory path from file path
        self.directoryPath = (filePath as NSString).deletingLastPathComponent
    }
    
    /// Ensure the log directory exists
    /// - Throws: LoggingError if directory creation fails
    private func ensureDirectoryExists() throws {
        if !fileManager.fileExists(atPath: directoryPath) {
            do {
                try fileManager.createDirectory(
                    atPath: directoryPath,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw LoggingTypes.LoggingError.destinationWriteFailed(
                    destination: identifier,
                    reason: "Failed to create log directory: \(error.localizedDescription)"
                )
            }
        }
    }
    
    /// Check if the log file needs rotation and rotate if necessary
    /// - Throws: LoggingError if rotation fails
    private func checkAndRotateLogFileIfNeeded() throws {
        // Check if the file exists and get its size
        if fileManager.fileExists(atPath: filePath) {
            let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
            if let fileSize = attributes[.size] as? UInt64, fileSize >= maxFileSize {
                try rotateLogFile()
            }
        }
    }
    
    /// Rotate log files
    /// - Throws: LoggingError if rotation fails
    private func rotateLogFile() throws {
        // Remove the oldest log file if we have reached max backup count
        let oldestBackupPath = "\(filePath).\(maxBackupCount)"
        if fileManager.fileExists(atPath: oldestBackupPath) {
            try FileManager.default.removeItem(atPath: oldestBackupPath)
        }
        
        // Shift backup log files
        for i in stride(from: maxBackupCount - 1, through: 1, by: -1) {
            let currentBackupPath = "\(filePath).\(i)"
            let newBackupPath = "\(filePath).\(i + 1)"
            
            if fileManager.fileExists(atPath: currentBackupPath) {
                try FileManager.default.moveItem(atPath: currentBackupPath, toPath: newBackupPath)
            }
        }
        
        // Move current log file to .1
        if fileManager.fileExists(atPath: filePath) {
            try FileManager.default.moveItem(atPath: filePath, toPath: "\(filePath).1")
        }
    }
    
    /// Write a log entry to the file
    /// - Parameter entry: The log entry to write
    /// - Throws: LoggingError if writing fails
    public func write(_ entry: LoggingTypes.LogEntry) async throws {
        // Check minimum level
        guard entry.level.rawValue >= minimumLevel.rawValue else {
            return
        }
        
        // Queue the entry for writing
        pendingWrites.append(entry)
    }
    
    /// Flush any pending log entries to the file
    /// - Throws: LoggingError if flushing fails
    public func flush() async throws {
        // Skip if no pending writes
        guard !pendingWrites.isEmpty else {
            return
        }
        
        // Format all pending entries
        let formattedEntries = pendingWrites.map { formatter.format($0) + "\n" }
        let dataToWrite = formattedEntries.joined().data(using: .utf8) ?? Data()
        
        // Clear pending writes
        pendingWrites.removeAll()
        
        do {
            // Ensure directory exists
            try ensureDirectoryExists()
            
            // Check and rotate log file if needed
            try checkAndRotateLogFileIfNeeded()
            
            // Write or append to file
            if fileManager.fileExists(atPath: filePath) {
                try fileManager.appendData(dataToWrite, toFile: filePath)
            } else {
                try fileManager.writeData(dataToWrite, toFile: filePath)
            }
        } catch {
            throw LoggingTypes.LoggingError.destinationWriteFailed(
                destination: identifier,
                reason: "Failed to write to log file: \(error.localizedDescription)"
            )
        }
    }
}
