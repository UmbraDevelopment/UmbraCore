import Foundation

/**
 # FileManager Isolation Wrapper
 
 A concurrency-safe wrapper around FileManager that isolates operations 
 to ensure thread safety and avoid Swift 6 data race warnings.
 
 This wrapper helps guarantee proper isolation of FileManager instances
 when used across different isolation domains, particularly when passed
 between task-isolated and actor-isolated contexts.
 */
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor FileManagerWrapper: @unchecked Sendable {
    /// The wrapped FileManager instance, isolated within this actor
    private let fileManager: FileManager
    
    /**
     Initialises a new FileManagerWrapper with the specified FileManager.
     
     - Parameter fileManager: The FileManager to wrap and isolate
     */
    public init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
    }
    
    // MARK: - FileManager Property Forwarding
    
    /// The current directory path of the file manager
    public var currentDirectoryPath: String {
        return fileManager.currentDirectoryPath
    }
    
    /// The temporary directory path for the file manager
    public var temporaryDirectory: URL {
        return fileManager.temporaryDirectory
    }
    
    // MARK: - FileManager Method Forwarding
    
    /// Forwards file existence checking to the isolated FileManager
    public func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>? = nil) -> Bool {
        return fileManager.fileExists(atPath: path, isDirectory: isDirectory)
    }
    
    /// Forwards directory creation to the isolated FileManager
    public func createDirectory(at url: URL, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]? = nil) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories, attributes: attributes)
    }
    
    /// Forwards file copying to the isolated FileManager
    public func copyItem(at srcURL: URL, to dstURL: URL) throws {
        try fileManager.copyItem(at: srcURL, to: dstURL)
    }
    
    /// Forwards file moving to the isolated FileManager
    public func moveItem(at srcURL: URL, to dstURL: URL) throws {
        try fileManager.moveItem(at: srcURL, to: dstURL)
    }
    
    /// Forwards file removal to the isolated FileManager
    public func removeItem(at URL: URL) throws {
        try fileManager.removeItem(at: URL)
    }
    
    /// Forwards directory content listing to the isolated FileManager
    public func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions = []) throws -> [URL] {
        return try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: mask)
    }
    
    /// Forwards attribute retrieval to the isolated FileManager
    public func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        return try fileManager.attributesOfItem(atPath: path)
    }
    
    /// Forwards URL resource values retrieval to the isolated FileManager
    public func resourceValues(at url: URL, keys: Set<URLResourceKey>) throws -> URLResourceValues {
        var urlCopy = url
        return try urlCopy.resourceValues(forKeys: keys)
    }
    
    /// Creates a unique temporary directory and returns its URL
    public func createTemporaryDirectory(withNamePrefix prefix: String = "") throws -> URL {
        let tempDir = fileManager.temporaryDirectory
        let uuid = UUID().uuidString
        let dirName = prefix.isEmpty ? uuid : "\(prefix)-\(uuid)"
        let tempDirURL = tempDir.appendingPathComponent(dirName, isDirectory: true)
        
        try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
        
        return tempDirURL
    }
}
