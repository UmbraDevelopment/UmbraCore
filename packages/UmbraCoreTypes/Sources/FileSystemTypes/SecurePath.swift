import Foundation

/**
 # SecurePath
 
 A secure, immutable representation of a file system path that abstracts away
 Foundation's URL type while providing enhanced security features.
 
 This type follows the Alpha Dot Five architecture principles by providing
 a Sendable, value-type representation of file paths that can be safely
 passed across actor boundaries.
 
 ## Security Features
 
 - Immutable by design to prevent path manipulation attacks
 - Validation of path components to prevent directory traversal
 - Sanitisation of inputs to prevent injection attacks
 - Support for security-scoped bookmarks
 
 ## Thread Safety
 
 This type is designed to be thread-safe and can be safely used across
 actor boundaries as it conforms to Sendable and uses only immutable properties.
 
 ## British Spelling
 
 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public struct SecurePath: Sendable, Equatable, Codable {
    /// The path string representation
    private let pathString: String
    
    /// Whether this path is absolute
    public let isAbsolute: Bool
    
    /// Whether this path is a directory (has a trailing slash)
    public let isDirectory: Bool
    
    /// Optional security bookmark data for security-scoped resources
    private let bookmarkData: Data?
    
    /// Optional security access level for this path
    public let securityLevel: PathSecurityLevel
    
    /**
     Initialises a new secure path with the provided path string.
     
     - Parameters:
        - path: The path string to secure
        - isDirectory: Whether this path represents a directory
        - bookmarkData: Optional security bookmark data
        - securityLevel: The security level for this path
     */
    public init?(
        path: String,
        isDirectory: Bool = false,
        bookmarkData: Data? = nil,
        securityLevel: PathSecurityLevel = .standard
    ) {
        // Validate and sanitise the path
        guard let sanitisedPath = Self.sanitisePath(path) else {
            return nil
        }
        
        self.pathString = sanitisedPath
        self.isAbsolute = sanitisedPath.starts(with: "/")
        self.isDirectory = isDirectory
        self.bookmarkData = bookmarkData
        self.securityLevel = securityLevel
    }
    
    /**
     Initialises a new secure path from a URL.
     
     This initialiser should only be used when receiving URLs from external
     APIs. For normal operations, create SecurePath instances directly.
     
     - Parameters:
        - url: The URL to convert
        - bookmarkData: Optional security bookmark data
        - securityLevel: The security level for this path
     */
    public init?(
        url: URL,
        bookmarkData: Data? = nil,
        securityLevel: PathSecurityLevel = .standard
    ) {
        guard url.isFileURL else {
            return nil
        }
        
        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        
        self.init(
            path: url.path,
            isDirectory: isDir,
            bookmarkData: bookmarkData,
            securityLevel: securityLevel
        )
    }
    
    /**
     Returns the string representation of this path.
     
     - Returns: The path as a string
     */
    public func toString() -> String {
        return pathString
    }
    
    /**
     Converts this secure path to a URL.
     
     This method should only be used when interacting with APIs that
     specifically require Foundation's URL type. For normal operations,
     use the SecurePath methods instead.
     
     - Returns: A URL representation of this secure path
     */
    public func toURL() -> URL {
        return URL(fileURLWithPath: pathString, isDirectory: isDirectory)
    }
    
    /**
     Appends a path component to this path.
     
     - Parameter component: The component to append
     - Returns: A new secure path with the component appended
     */
    public func appendingComponent(_ component: String) -> SecurePath? {
        guard let sanitisedComponent = Self.sanitiseComponent(component) else {
            return nil
        }
        
        var newPath = pathString
        
        // Add a separator if needed
        if !newPath.hasSuffix("/") && !sanitisedComponent.starts(with: "/") {
            newPath += "/"
        }
        
        // Remove duplicate separators
        if newPath.hasSuffix("/") && sanitisedComponent.starts(with: "/") {
            newPath += sanitisedComponent.dropFirst()
        } else {
            newPath += sanitisedComponent
        }
        
        return SecurePath(
            path: newPath,
            isDirectory: sanitisedComponent.hasSuffix("/") || isDirectory,
            bookmarkData: bookmarkData,
            securityLevel: securityLevel
        )
    }
    
    /**
     Appends multiple path components to this path.
     
     - Parameter components: The components to append
     - Returns: A new secure path with the components appended
     */
    public func appendingComponents(_ components: [String]) -> SecurePath? {
        var result = self
        
        for component in components {
            guard let newPath = result.appendingComponent(component) else {
                return nil
            }
            result = newPath
        }
        
        return result
    }
    
    /**
     Returns the parent directory of this path.
     
     - Returns: A new secure path representing the parent directory
     */
    public func deletingLastComponent() -> SecurePath? {
        let url = URL(fileURLWithPath: pathString)
        let parentPath = url.deletingLastPathComponent().path
        
        return SecurePath(
            path: parentPath,
            isDirectory: true,
            bookmarkData: bookmarkData,
            securityLevel: securityLevel
        )
    }
    
    /**
     Returns the last component of this path.
     
     - Returns: The last path component
     */
    public func lastComponent() -> String {
        let url = URL(fileURLWithPath: pathString)
        return url.lastPathComponent
    }
    
    /**
     Returns the file extension of this path.
     
     - Returns: The file extension, or nil if there is none
     */
    public func fileExtension() -> String? {
        let url = URL(fileURLWithPath: pathString)
        let ext = url.pathExtension
        return ext.isEmpty ? nil : ext
    }
    
    /**
     Returns a new path with the file extension changed.
     
     - Parameter extension: The new file extension
     - Returns: A new secure path with the extension changed
     */
    public func changingFileExtension(to extension: String) -> SecurePath? {
        let url = URL(fileURLWithPath: pathString)
        let newURL = url.deletingPathExtension().appendingPathExtension(`extension`)
        
        return SecurePath(
            path: newURL.path,
            isDirectory: isDirectory,
            bookmarkData: bookmarkData,
            securityLevel: securityLevel
        )
    }
    
    /**
     Starts accessing a security-scoped resource.
     
     This method should be called before accessing security-scoped resources,
     and must be balanced with a call to stopAccessingSecurityScopedResource().
     
     - Returns: true if access was granted, false otherwise
     */
    public func startAccessingSecurityScopedResource() -> Bool {
        guard let data = bookmarkData else {
            return false
        }
        
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
            return url.startAccessingSecurityScopedResource()
        } catch {
            return false
        }
    }
    
    /**
     Stops accessing a security-scoped resource.
     
     This method should be called after accessing security-scoped resources
     to release the security-scoped resource.
     */
    public func stopAccessingSecurityScopedResource() {
        guard let data = bookmarkData else {
            return
        }
        
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
            url.stopAccessingSecurityScopedResource()
        } catch {
            // Ignore errors when stopping access
        }
    }
    
    /**
     Creates a security bookmark for this path.
     
     - Returns: A new secure path with the bookmark data attached
     */
    public func creatingSecurityBookmark() -> SecurePath? {
        guard bookmarkData == nil else {
            return self
        }
        
        do {
            let url = URL(fileURLWithPath: pathString, isDirectory: isDirectory)
            let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            return SecurePath(
                path: pathString,
                isDirectory: isDirectory,
                bookmarkData: data,
                securityLevel: securityLevel
            )
        } catch {
            return nil
        }
    }
    
    // MARK: - Static Helper Methods
    
    /**
     Sanitises a path string to prevent path traversal attacks.
     
     - Parameter path: The path to sanitise
     - Returns: A sanitised path string, or nil if the path is invalid
     */
    private static func sanitisePath(_ path: String) -> String? {
        // Normalize the path to remove redundant separators and resolve . and ..
        let url = URL(fileURLWithPath: path)
        var standardisedPath = url.standardized.path
        
        // Ensure the path doesn't contain dangerous sequences
        if standardisedPath.contains("../") || standardisedPath.contains("/..") ||
           standardisedPath.contains("./") || standardisedPath.contains("/.") {
            return nil
        }
        
        return standardisedPath
    }
    
    /**
     Sanitises a path component to prevent path traversal attacks.
     
     - Parameter component: The component to sanitise
     - Returns: A sanitised component string, or nil if the component is invalid
     */
    private static func sanitiseComponent(_ component: String) -> String? {
        // Reject components that could be used for path traversal
        if component == ".." || component == "." ||
           component.contains("../") || component.contains("./") {
            return nil
        }
        
        return component
    }
    
    /**
     Creates a temporary directory path.
     
     - Returns: A secure path to a temporary directory
     */
    public static func temporaryDirectory() -> SecurePath {
        let tempDir = NSTemporaryDirectory()
        return SecurePath(path: tempDir, isDirectory: true)!
    }
    
    /**
     Creates a unique temporary file path.
     
     - Parameter extension: Optional file extension
     - Returns: A secure path to a unique temporary file
     */
    public static func uniqueTemporaryFile(extension: String? = nil) -> SecurePath {
        let tempDir = NSTemporaryDirectory()
        let uuid = UUID().uuidString
        
        var filename = uuid
        if let ext = `extension` {
            filename = "\(uuid).\(ext)"
        }
        
        let path = tempDir + "/" + filename
        return SecurePath(path: path)!
    }
}

/**
 Security level for a file path.
 */
public enum PathSecurityLevel: String, Sendable, Codable {
    /// Standard security level
    case standard
    
    /// Elevated security level for sensitive files
    case elevated
    
    /// High security level for critical files
    case high
    
    /// Restricted security level for confidential files
    case restricted
}
