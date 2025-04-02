import Foundation

/// A secure model for storing and retrieving Restic repository credentials
public struct ResticCredentials: Sendable, Equatable {
    /// The unique identifier or path for the repository
    public let repositoryIdentifier: String
    
    /// The password for the repository
    public let password: String
    
    /// Optional additional environment variables required for repository access
    public let additionalEnvironment: [String: String]
    
    /// Creates a new set of credentials for a Restic repository
    /// 
    /// - Parameters:
    ///   - repositoryIdentifier: The unique identifier or path for the repository
    ///   - password: The password for accessing the repository
    ///   - additionalEnvironment: Optional additional environment variables required for repository access
    public init(
        repositoryIdentifier: String,
        password: String,
        additionalEnvironment: [String: String] = [:]
    ) {
        self.repositoryIdentifier = repositoryIdentifier
        self.password = password
        self.additionalEnvironment = additionalEnvironment
    }
}
