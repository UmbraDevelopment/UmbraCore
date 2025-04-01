/// CoreVersionDTO
///
/// Represents version information for the UmbraCore framework.
/// This DTO contains semantic versioning details and additional
/// metadata for framework version identification and compatibility checking.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
import DateTimeTypes

public struct CoreVersionDTO: Sendable, Equatable {
    /// Major version component (breaking changes)
    public let major: UInt
    
    /// Minor version component (non-breaking feature additions)
    public let minor: UInt
    
    /// Patch version component (bug fixes)
    public let patch: UInt
    
    /// Optional build identifier
    public let buildIdentifier: String?
    
    /// Optional build timestamp
    public let buildTimestamp: TimePointDTO?
    
    /// Creates a string representation of the version in semver format
    public var versionString: String {
        var result = "\(major).\(minor).\(patch)"
        if let buildIdentifier = buildIdentifier {
            result += "-\(buildIdentifier)"
        }
        return result
    }
    
    /// Creates a new CoreVersionDTO instance
    /// - Parameters:
    ///   - major: Major version component
    ///   - minor: Minor version component
    ///   - patch: Patch version component
    ///   - buildIdentifier: Optional build identifier
    ///   - buildTimestamp: Optional build timestamp
    public init(
        major: UInt,
        minor: UInt,
        patch: UInt,
        buildIdentifier: String? = nil,
        buildTimestamp: TimePointDTO? = nil
    ) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.buildIdentifier = buildIdentifier
        self.buildTimestamp = buildTimestamp
    }
    
    /// Checks if this version is compatible with the specified minimum version
    /// - Parameter minVersion: The minimum version to check against
    /// - Returns: True if this version is compatible, false otherwise
    public func isCompatible(with minVersion: CoreVersionDTO) -> Bool {
        // Major version must match exactly for compatibility
        if major != minVersion.major {
            return false
        }
        
        // Minor version must be equal or higher
        if minor < minVersion.minor {
            return false
        }
        
        // If minor version is exactly the same, patch version must be equal or higher
        if minor == minVersion.minor && patch < minVersion.patch {
            return false
        }
        
        return true
    }
}
