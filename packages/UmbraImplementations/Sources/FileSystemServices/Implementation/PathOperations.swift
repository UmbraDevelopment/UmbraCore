import Foundation
import FileSystemInterfaces
import FileSystemTypes
import LoggingTypes

/**
 # Path Operations Extension
 
 This extension provides path manipulation and normalisation operations for the
 FileSystemServiceImpl, enabling standardised handling of file paths.
 */
extension FileSystemServiceImpl {
    /**
     Normalises a file path, resolving any relative components and symlinks.
     
     - Parameter path: The path to normalise
     - Returns: The normalised path
     - Throws: `FileSystemError.invalidPath` if the path is invalid
               `FileSystemError.readError` if path resolution fails
     */
    public func normalisePath(_ path: FilePath) async throws -> FilePath {
        guard !path.path.isEmpty else {
            throw FileSystemInterfaces.FileSystemError.invalidPath(
                path: "",
                reason: "Empty path provided"
            )
        }
        
        // Convert to URL for standardisation
        let url = URL(fileURLWithPath: path.path)
        
        // Resolve any relative components (such as "../" or "./")
        let standardisedURL = url.standardized
        
        do {
            // This can fail if we don't have permission to access the file system
            // Force unwrapping this is safe as we've already checked path.path is not empty
            let resolvedURL = try FileManager.default.fileExists(atPath: standardisedURL.path) 
                ? URL(fileURLWithPath: FileManager.default.destinationOfSymbolicLink(atPath: standardisedURL.path), isDirectory: true) 
                : standardisedURL
            
            let normalisedPath = FilePath(path: resolvedURL.path)
            
            await logger.debug("Normalised path from \(path.path) to \(normalisedPath.path)", metadata: nil)
            
            return normalisedPath
        } catch {
            await logger.error("Failed to normalise path \(path.path): \(error.localizedDescription)", metadata: nil)
            throw FileSystemInterfaces.FileSystemError.readError(
                path: path.path,
                reason: "Failed to resolve path: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Joins two path components together.
     
     - Parameters:
        - base: The base path
        - component: The path component to append
     - Returns: The combined path
     - Throws: `FileSystemError.invalidPath` if either path is invalid
     */
    public func joinPath(_ base: FilePath, with component: String) async throws -> FilePath {
        guard !base.path.isEmpty else {
            throw FileSystemInterfaces.FileSystemError.invalidPath(
                path: "",
                reason: "Empty base path provided"
            )
        }
        
        guard !component.isEmpty else {
            throw FileSystemInterfaces.FileSystemError.invalidPath(
                path: component,
                reason: "Empty component provided"
            )
        }
        
        let baseURL = URL(fileURLWithPath: base.path)
        let joinedURL = baseURL.appendingPathComponent(component)
        let joinedPath = FilePath(path: joinedURL.path)
        
        await logger.debug("Joined path \(base.path) with \(component) to create \(joinedPath.path)", metadata: nil)
        
        return joinedPath
    }
    
    /**
     Gets the file name component of a path.
     
     - Parameter path: The path to extract the file name from
     - Returns: The file name component, or an empty string if the path ends with a directory separator
     */
    public func fileName(from path: FilePath) async -> String {
        guard !path.path.isEmpty else {
            return ""
        }
        
        let url = URL(fileURLWithPath: path.path)
        let fileName = url.lastPathComponent
        
        await logger.debug("Extracted file name \(fileName) from path \(path.path)", metadata: nil)
        
        return fileName
    }
    
    /**
     Gets the directory component of a path.
     
     - Parameter path: The path to extract the directory from
     - Returns: The directory component
     */
    public func directoryPath(from path: FilePath) async -> FilePath {
        guard !path.path.isEmpty else {
            return FilePath(path: "")
        }
        
        let url = URL(fileURLWithPath: path.path)
        let directoryURL = url.deletingLastPathComponent()
        let directoryPath = FilePath(path: directoryURL.path)
        
        await logger.debug("Extracted directory path \(directoryPath.path) from path \(path.path)", metadata: nil)
        
        return directoryPath
    }
    
    /**
     Gets the file extension component of a path.
     
     - Parameter path: The path to extract the extension from
     - Returns: The file extension (without the leading dot), or an empty string if there is no extension
     */
    public func fileExtension(from path: FilePath) async -> String {
        guard !path.path.isEmpty else {
            return ""
        }
        
        let url = URL(fileURLWithPath: path.path)
        let fileExtension = url.pathExtension
        
        await logger.debug("Extracted file extension \(fileExtension) from path \(path.path)", metadata: nil)
        
        return fileExtension
    }
    
    /**
     Creates a new path with a different extension.
     
     - Parameters:
        - path: The original path
        - extension: The new extension (without the leading dot)
     - Returns: A new path with the specified extension
     - Throws: `FileSystemError.invalidPath` if the path is invalid
     */
    public func changingFileExtension(
        of path: FilePath,
        to extension: String
    ) async throws -> FilePath {
        guard !path.path.isEmpty else {
            throw FileSystemInterfaces.FileSystemError.invalidPath(
                path: "",
                reason: "Empty path provided"
            )
        }
        
        let url = URL(fileURLWithPath: path.path)
        let fileName = url.deletingPathExtension().lastPathComponent
        let directory = url.deletingLastPathComponent()
        
        // Create the new file name with the specified extension
        let newFileName: String
        if `extension`.isEmpty {
            newFileName = fileName
        } else {
            newFileName = fileName + "." + `extension`
        }
        
        let newURL = directory.appendingPathComponent(newFileName)
        let newPath = FilePath(path: newURL.path)
        
        await logger.debug("Changed extension of \(path.path) to \(newPath.path)", metadata: nil)
        
        return newPath
    }
    
    // MARK: - Non-Isolated Path Methods (Protocol Conformance)
    
    /**
     Extracts the file name component from a path (non-isolated version).
     
     - Parameter path: The path to process
     - Returns: The file name component
     */
    public nonisolated func fileName(_ path: FilePath) -> String {
        guard !path.path.isEmpty else {
            return ""
        }
        
        let url = URL(fileURLWithPath: path.path)
        return url.lastPathComponent
    }
    
    /**
     Extracts the directory component from a path (non-isolated version).
     
     - Parameter path: The path to process
     - Returns: The directory component
     */
    public nonisolated func directoryPath(_ path: FilePath) -> FilePath {
        guard !path.path.isEmpty else {
            return FilePath(path: "")
        }
        
        let url = URL(fileURLWithPath: path.path)
        let directoryURL = url.deletingLastPathComponent()
        return FilePath(path: directoryURL.path)
    }
    
    /**
     Joins a base path with additional components (non-isolated version).
     
     - Parameters:
        - base: The base path
        - components: Additional path components to join
     - Returns: The combined path
     */
    public nonisolated func joinPath(_ base: FilePath, withComponents components: [String]) -> FilePath {
        guard !base.path.isEmpty else {
            return base
        }
        
        var url = URL(fileURLWithPath: base.path)
        
        for component in components {
            if !component.isEmpty {
                url = url.appendingPathComponent(component)
            }
        }
        
        return FilePath(path: url.path)
    }
    
    /**
     Checks if a path is within a specified directory (non-isolated version).
     
     - Parameters:
        - path: The path to check
        - directory: The directory to check against
     - Returns: True if path is a subpath of directory
     */
    public nonisolated func isSubpath(
        _ path: FilePath,
        of directory: FilePath
    ) -> Bool {
        guard !path.path.isEmpty && !directory.path.isEmpty else {
            return false
        }
        
        let pathComponents = URL(fileURLWithPath: path.path).standardized.pathComponents
        let dirComponents = URL(fileURLWithPath: directory.path).standardized.pathComponents
        
        // If directory has more components than path, path cannot be a subpath
        if dirComponents.count > pathComponents.count {
            return false
        }
        
        // Check that all directory components match the beginning of path components
        for i in 0..<dirComponents.count {
            if pathComponents[i] != dirComponents[i] {
                return false
            }
        }
        
        return true
    }
}
