import Foundation

/// Data transfer object representing version information for the security service.
///
/// This type provides comprehensive version information about the security service
/// implementation, including semantic versioning details and compatibility information.
public struct SecurityVersionDTO: Sendable, Equatable {
    /// The semantic version string (e.g., "1.2.3")
    public let semanticVersion: String
    
    /// The major version number
    public let majorVersion: Int
    
    /// The minor version number
    public let minorVersion: Int
    
    /// The patch version number
    public let patchVersion: Int
    
    /// The build identifier, if available
    public let buildIdentifier: String?
    
    /// The minimum supported platform version
    public let minimumSupportedPlatformVersion: String
    
    /// The provider implementation name
    public let providerImplementationName: String
    
    /// The cryptographic libraries in use
    public let cryptographicLibraries: [String]
    
    /// Creates a new security version information object
    /// - Parameters:
    ///   - semanticVersion: The semantic version string
    ///   - majorVersion: The major version number
    ///   - minorVersion: The minor version number
    ///   - patchVersion: The patch version number
    ///   - buildIdentifier: The build identifier, if available
    ///   - minimumSupportedPlatformVersion: The minimum supported platform version
    ///   - providerImplementationName: The provider implementation name
    ///   - cryptographicLibraries: The cryptographic libraries in use
    public init(
        semanticVersion: String,
        majorVersion: Int,
        minorVersion: Int,
        patchVersion: Int,
        buildIdentifier: String? = nil,
        minimumSupportedPlatformVersion: String,
        providerImplementationName: String,
        cryptographicLibraries: [String]
    ) {
        self.semanticVersion = semanticVersion
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.patchVersion = patchVersion
        self.buildIdentifier = buildIdentifier
        self.minimumSupportedPlatformVersion = minimumSupportedPlatformVersion
        self.providerImplementationName = providerImplementationName
        self.cryptographicLibraries = cryptographicLibraries
    }
    
    /// Returns true if this version is compatible with the specified minimum version
    /// - Parameter minimumVersion: The minimum version to check against
    /// - Returns: True if compatible, false otherwise
    public func isCompatible(withMinimumVersion minimumVersion: SecurityVersionDTO) -> Bool {
        if majorVersion > minimumVersion.majorVersion {
            return true
        }
        if majorVersion < minimumVersion.majorVersion {
            return false
        }
        
        // Same major version, check minor
        if minorVersion > minimumVersion.minorVersion {
            return true
        }
        if minorVersion < minimumVersion.minorVersion {
            return false
        }
        
        // Same minor version, check patch
        return patchVersion >= minimumVersion.patchVersion
    }
}
