import Foundation

/**
 * Represents the content of a file retrieved from a snapshot.
 * 
 * This type encapsulates both the file's binary content and
 * its associated metadata, facilitating efficient file retrieval
 * from backup snapshots.
 */
public struct FileContent: Sendable, Equatable {
    /// Raw content of the file
    public let data: Data
    
    /// Information about the file
    public let fileInfo: FileInfo
    
    /// Mime type of the file, when it can be determined
    public let mimeType: String?
    
    /**
     * Initialises new file content.
     * 
     * - Parameters:
     *   - data: Raw content of the file
     *   - fileInfo: Information about the file
     *   - mimeType: Mime type of the file, if known
     */
    public init(
        data: Data,
        fileInfo: FileInfo,
        mimeType: String? = nil
    ) {
        self.data = data
        self.fileInfo = fileInfo
        self.mimeType = mimeType
    }
    
    /**
     * Attempts to convert the file content to a string.
     * 
     * - Parameter encoding: The encoding to use, defaults to UTF-8
     * - Returns: String representation if conversion is successful, nil otherwise
     */
    public func asString(encoding: String.Encoding = .utf8) -> String? {
        return String(data: data, encoding: encoding)
    }
    
    /**
     * Returns the size of the file content in bytes.
     */
    public var size: Int {
        return data.count
    }
    
    /**
     * Returns whether the file appears to be a text file.
     * 
     * This is determined either by the mime type or by attempting
     * to convert the content to a string.
     */
    public var isTextFile: Bool {
        // Check mime type first if available
        if let mime = mimeType {
            if mime.starts(with: "text/") {
                return true
            }
            
            // Common text-based mime types
            let textBasedMimeTypes = [
                "application/json",
                "application/xml",
                "application/javascript",
                "application/x-sh"
            ]
            
            if textBasedMimeTypes.contains(where: { mime.starts(with: $0) }) {
                return true
            }
        }
        
        // Otherwise, try to convert to string
        if data.count > 0 {
            // Sample just the first part of the file to avoid large memory usage
            let sampleSize = min(8192, data.count)
            let sample = data.prefix(sampleSize)
            
            // If we can convert to a string and it doesn't contain too many null bytes
            // or other binary-looking data, it's probably text
            if let _ = String(data: sample, encoding: .utf8) {
                // Count null and control characters
                let nullAndControlCount = sample.filter { $0 < 32 && $0 != 9 && $0 != 10 && $0 != 13 }.count
                return Double(nullAndControlCount) / Double(sample.count) < 0.05
            }
        }
        
        return false
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: FileContent, rhs: FileContent) -> Bool {
        return lhs.data == rhs.data &&
               lhs.fileInfo == rhs.fileInfo &&
               lhs.mimeType == rhs.mimeType
    }
}
