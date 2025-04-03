import Foundation
import LoggingInterfaces
import SecurityInterfaces
import SecurityCoreInterfaces
import SecurityUtils
import SecurityInterfacesProtocols
import ResticInterfaces

/**
 # Restic Repository Manager
 
 Manages Restic repositories with proper sandbox compliance, handling
 security-scoped bookmarks and access permissions.
 
 This class ensures that repositories are accessible within the macOS
 sandbox constraints and provides secure access to repository files.
 */
public actor ResticRepositoryManager {
    /// Security bookmark manager for handling file access
    private let bookmarkManager: SecurityBookmarkProtocol
    
    /// Secure storage for handling sensitive data
    private let secureStorage: SecureStorageProtocol
    
    /// Logger for recording operations and errors
    private let logger: LoggingProtocol?
    
    /// Cache of currently available repositories (without sensitive data)
    private var availableRepositories: [URL: RepositoryAccessInfo] = [:]
    
    /// Key prefix for repository passwords in secure storage
    private let passwordKeyPrefix = "restic.repository.password."
    
    /**
     Initialises a new repository manager.
     
     - Parameters:
        - bookmarkManager: The bookmark manager for handling file access
        - secureStorage: Secure storage for sensitive data
        - logger: Optional logger for recording operations and errors
     */
    public init(
        bookmarkManager: SecurityBookmarkProtocol,
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol? = nil
    ) {
        self.bookmarkManager = bookmarkManager
        self.secureStorage = secureStorage
        self.logger = logger
    }
    
    /**
     Gets a repository URL, ensuring it is accessible with proper permissions.
     
     - Parameter path: The repository path or URL string
     
     - Returns: A URL with sandbox access enabled
     - Throws: RepositoryError if access cannot be granted
     */
    public func getRepositoryURL(_ path: String) async throws -> URL {
        await log(.debug, "Getting repository URL for: \(path)")
        
        // Handle empty or nil paths
        guard !path.isEmpty else {
            throw RepositoryError.invalidRepositoryPath("Repository path is empty")
        }
        
        // Convert the path to a URL
        let url = URL(string: path) ?? URL(fileURLWithPath: path)
        
        // Check the scheme to determine how to handle the URL
        switch url.scheme {
        case "file":
            // Local file URL - requires security-scoped bookmarks
            return try await getLocalRepositoryURL(url)
        case "sftp", "rest", "s3", "swift", "b2", "azure":
            // Remote URL - no sandbox access needed
            return url
        default:
            // Assume local file path if no scheme is provided
            let fileURL = url.scheme == nil ? URL(fileURLWithPath: path) : url
            return try await getLocalRepositoryURL(fileURL)
        }
    }
    
    /**
     Registers a repository for future access.
     
     - Parameters:
        - url: The repository URL
        - password: Optional repository password
        - bookmark: Optional security bookmark data
     
     - Throws: RepositoryError if registration fails
     */
    public func registerRepository(
        url: URL,
        password: String? = nil,
        bookmark: Data? = nil
    ) async throws {
        await log(.info, "Registering repository: \(url)")
        
        // Store the password securely if provided
        if let repoPassword = password {
            let passwordKey = passwordKeyPrefix + url.absoluteString
            let passwordData = Array(repoPassword.utf8)
            
            let storeResult = await secureStorage.storeData(
                passwordData,
                withIdentifier: passwordKey
            )
            
            switch storeResult {
            case .success:
                await log(.debug, "Successfully stored repository password")
            case .failure(let error):
                await log(.error, "Failed to store repository password: \(error)")
                throw RepositoryError.passwordStorageFailed(
                    "Failed to securely store password: \(error.localizedDescription)"
                )
            }
        }
        
        // For local repositories, ensure we have a security bookmark
        if url.isFileURL {
            let bookmarkData: Data
            
            if let existingBookmark = bookmark {
                bookmarkData = existingBookmark
            } else {
                // Request a new bookmark through the security manager
                do {
                    // Generate a unique identifier for the bookmark
                    let storageId = "restic.repository." + UUID().uuidString
                    
                    // Create the bookmark
                    let result = await bookmarkManager.createBookmark(
                        for: url,
                        readOnly: false,
                        storageIdentifier: storageId
                    )
                    
                    switch result {
                    case .success(_):
                        // We need to convert the identifier to actual bookmark data
                        // In a real implementation, we would retrieve the bookmark data
                        // from the secure storage using the identifier
                        // For now, we'll just use a placeholder
                        bookmarkData = Data() // Placeholder
                        await log(.debug, "Created bookmark with ID: \(storageId)")
                    case .failure(let error):
                        throw RepositoryError.bookmarkCreationFailed(
                            "Failed to create security bookmark: \(error.localizedDescription)"
                        )
                    }
                } catch {
                    throw RepositoryError.bookmarkCreationFailed(
                        "Failed to create security bookmark: \(error.localizedDescription)"
                    )
                }
            }
            
            // Store the repository info (without sensitive data)
            availableRepositories[url] = RepositoryAccessInfo(
                url: url,
                bookmarkData: bookmarkData,
                isAccessible: false
            )
        } else {
            // For remote repositories, we don't need bookmarks
            availableRepositories[url] = RepositoryAccessInfo(
                url: url,
                bookmarkData: nil,
                isAccessible: true
            )
        }
    }
    
    /**
     Starts accessing a repository, activating security-scoped bookmarks if needed.
     
     - Parameter url: The repository URL
     
     - Returns: A boolean indicating if access was granted
     - Throws: RepositoryError if access cannot be granted
     */
    public func startAccessingRepository(_ url: URL) async throws -> Bool {
        await log(.debug, "Starting access to repository: \(url)")
        
        // If it's not a file URL, no need for security access
        guard url.isFileURL else { return true }
        
        // Retrieve the repository info
        guard var repoInfo = availableRepositories[url] else {
            // If we don't have it registered, attempt to register it now
            do {
                // Generate a unique identifier for the bookmark
                let storageId = "restic.repository." + UUID().uuidString
                
                // Create the bookmark with the proper API
                let result = await bookmarkManager.createBookmark(
                    for: url, 
                    readOnly: false,
                    storageIdentifier: storageId
                )
                
                switch result {
                case .success(_):
                    // We'll use a placeholder for bookmark data
                    let bookmarkData = Data() // Placeholder
                    try await registerRepository(url: url, bookmark: bookmarkData)
                    return try await startAccessingRepository(url)
                case .failure(let error):
                    throw RepositoryError.bookmarkCreationFailed(
                        "Failed to create security bookmark: \(error.localizedDescription)"
                    )
                }
            } catch {
                throw RepositoryError.repositoryNotRegistered(
                    "Repository not registered and auto-registration failed: \(error.localizedDescription)"
                )
            }
        }
        
        // Already accessible
        if repoInfo.isAccessible { return true }
        
        // Need to resolve the bookmark and start accessing
        guard repoInfo.bookmarkData != nil else {
            throw RepositoryError.bookmarkMissing("Repository has no associated bookmark data")
        }
        
        do {
            // In a real implementation, we would have stored the bookmark identifier
            // and used it to resolve the bookmark
            // For now, we'll simulate a successful resolution
            
            // Create a mock URL that simulates the resolved URL
            let resolvedURL = url
            
            guard resolvedURL.startAccessingSecurityScopedResource() else {
                throw RepositoryError.accessDenied("Could not access security-scoped resource")
            }
            
            // Update the access state
            repoInfo.isAccessible = true
            availableRepositories[url] = repoInfo
            
            return true
        } catch {
            throw RepositoryError.bookmarkResolutionFailed(
                "Failed to resolve bookmark: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Stops accessing a repository, releasing security-scoped bookmarks.
     
     - Parameter url: The repository URL
     */
    public func stopAccessingRepository(_ url: URL) async {
        await log(.debug, "Stopping access to repository: \(url)")
        
        // Only file URLs need security-scoped resource management
        guard url.isFileURL else { return }
        
        // Retrieve the repository info
        guard var repoInfo = availableRepositories[url], repoInfo.isAccessible else {
            return
        }
        
        // Stop accessing the resource
        url.stopAccessingSecurityScopedResource()
        
        // Update the access state
        repoInfo.isAccessible = false
        availableRepositories[url] = repoInfo
    }
    
    /**
     Validates a repository path, checking if it's accessible and a valid Restic repository.
     
     - Parameter path: The repository path to validate
     
     - Returns: True if the repository is valid and accessible
     - Throws: RepositoryError if validation fails
     */
    public func validateRepository(_ path: String) async throws -> Bool {
        await log(.info, "Validating repository: \(path)")
        
        // Get the repository URL with proper access
        let url = try await getRepositoryURL(path)
        
        // For local repositories, ensure we have access
        if url.isFileURL {
            guard try await startAccessingRepository(url) else {
                throw RepositoryError.accessDenied("Could not access repository directory")
            }
            
            defer {
                Task {
                    await stopAccessingRepository(url)
                }
            }
            
            // For local repositories, check if the directory exists and has the right structure
            let fileManager = FileManager.default
            
            if !fileManager.fileExists(atPath: url.path) {
                return false
            }
            
            // Check for the config file which indicates a valid Restic repository
            let configURL = url.appendingPathComponent("config")
            return fileManager.fileExists(atPath: configURL.path)
        } else {
            // For remote repositories, we'll need to check using the Restic service
            // This would typically be done through an XPC call to the Restic service
            // For now, we'll just return true and assume the repository is valid
            // In the full implementation, this would make an XPC call to validate
            return true
        }
    }
    
    /**
     Returns all registered repositories.
     
     - Returns: An array of repository URLs
     */
    public func getRegisteredRepositories() async -> [URL] {
        return Array(availableRepositories.keys)
    }
    
    /**
     Gets a local repository URL with sandbox access enabled.
     
     - Parameter url: The file URL
     
     - Returns: A URL with sandbox access enabled
     - Throws: RepositoryError if access cannot be granted
     */
    private func getLocalRepositoryURL(_ url: URL) async throws -> URL {
        await log(.debug, "Getting local repository URL: \(url)")
        
        // Ensure it's a file URL
        guard url.isFileURL else {
            throw RepositoryError.invalidRepositoryPath("Not a file URL: \(url)")
        }
        
        // Check if the repository is already registered
        if let info = availableRepositories[url] {
            if info.bookmarkData != nil {
                // In a real implementation, we would have stored the bookmark identifier
                // and used it to resolve the bookmark properly
                // For now, we'll just return the original URL
                return url
            } else {
                // No bookmark but registered - likely a remote repository
                return url
            }
        }
        
        // If the repository isn't registered, just return the URL
        // It will be properly resolved when access is requested
        return url
    }
    
    /**
     Gets the password for a repository if available.
     
     - Parameter url: The repository URL
     
     - Returns: The repository password if available
     - Throws: RepositoryError if retrieving the password fails
     */
    public func getRepositoryPassword(for url: URL) async throws -> String? {
        let passwordKey = passwordKeyPrefix + url.absoluteString
        
        let retrieveResult = await secureStorage.retrieveData(withIdentifier: passwordKey)
        
        switch retrieveResult {
        case .success(let passwordData):
            guard let password = String(bytes: passwordData, encoding: .utf8) else {
                throw RepositoryError.passwordRetrievalFailed("Invalid password data format")
            }
            return password
        case .failure(let error):
            // If the error is related to item not found, just return nil
            if error.localizedDescription.contains("not found") {
                return nil
            }
            
            await log(.error, "Failed to retrieve repository password: \(error)")
            throw RepositoryError.passwordRetrievalFailed(
                "Failed to retrieve password: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Updates the password for a repository.
     
     - Parameters:
        - url: The repository URL
        - password: The new password
     
     - Throws: RepositoryError if updating the password fails
     */
    public func updateRepositoryPassword(for url: URL, password: String) async throws {
        let passwordKey = passwordKeyPrefix + url.absoluteString
        let passwordData = Array(password.utf8)
        
        let storeResult = await secureStorage.storeData(
            passwordData,
            withIdentifier: passwordKey
        )
        
        switch storeResult {
        case .success:
            await log(.debug, "Successfully updated repository password")
        case .failure(let error):
            await log(.error, "Failed to update repository password: \(error)")
            throw RepositoryError.passwordStorageFailed(
                "Failed to securely store password: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Removes a repository and its associated data.
     
     - Parameter url: The repository URL
     
     - Returns: True if the repository was successfully removed
     */
    public func removeRepository(_ url: URL) async -> Bool {
        await log(.info, "Removing repository: \(url)")
        
        // Remove from the available repositories
        availableRepositories.removeValue(forKey: url)
        
        // Delete the password from secure storage
        let passwordKey = passwordKeyPrefix + url.absoluteString
        let deleteResult = await secureStorage.deleteData(withIdentifier: passwordKey)
        
        switch deleteResult {
        case .success:
            await log(.debug, "Successfully removed repository password")
            return true
        case .failure(let error):
            await log(.warning, "Failed to remove repository password: \(error)")
            return false
        }
    }
    
    /**
     Logs a message with the specified level.
     
     - Parameters:
        - level: The log level
        - message: The message to log
     */
    private func log(_ level: LogLevel, _ message: String) async {
        await logger?.log(level, message, metadata: nil, source: "ResticRepositoryManager")
    }
}

/**
 Information about a repository's access state.
 */
private struct RepositoryAccessInfo {
    /// The repository URL
    let url: URL
    
    /// Security bookmark data for file URLs
    let bookmarkData: Data?
    
    /// Whether the repository is currently accessible
    var isAccessible: Bool
}

/**
 Errors related to repository management.
 */
public enum RepositoryError: Error, LocalizedError {
    /// The repository path is invalid
    case invalidRepositoryPath(String)
    
    /// The repository is not registered
    case repositoryNotRegistered(String)
    
    /// Creating a security bookmark failed
    case bookmarkCreationFailed(String)
    
    /// Resolving a security bookmark failed
    case bookmarkResolutionFailed(String)
    
    /// No bookmark data is available
    case bookmarkMissing(String)
    
    /// Access to the repository was denied
    case accessDenied(String)
    
    /// Failed to store password securely
    case passwordStorageFailed(String)
    
    /// Failed to retrieve password
    case passwordRetrievalFailed(String)
    
    /// Error description
    public var errorDescription: String? {
        switch self {
        case .invalidRepositoryPath(let message),
             .repositoryNotRegistered(let message),
             .bookmarkCreationFailed(let message),
             .bookmarkResolutionFailed(let message),
             .bookmarkMissing(let message),
             .accessDenied(let message),
             .passwordStorageFailed(let message),
             .passwordRetrievalFailed(let message):
            return message
        }
    }
}
