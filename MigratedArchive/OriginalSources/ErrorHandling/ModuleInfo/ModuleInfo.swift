import Foundation

/// Represents semantic version information for a module
public struct SemanticVersion: Equatable, Comparable, Sendable {
  /// Major version component (breaking changes)
  public let major: Int

  /// Minor version component (backwards-compatible additions)
  public let minor: Int

  /// Patch version component (backwards-compatible fixes)
  public let patch: Int

  /// Optional build metadata
  public let buildMetadata: String?

  /// Optional pre-release identifier
  public let preRelease: String?

  /// Creates a new semantic version
  /// - Parameters:
  ///   - major: Major version component (breaking changes)
  ///   - minor: Minor version component (backwards-compatible additions)
  ///   - patch: Patch version component (backwards-compatible fixes)
  ///   - buildMetadata: Optional build metadata
  ///   - preRelease: Optional pre-release identifier
  public init(
    major: Int,
    minor: Int,
    patch: Int,
    buildMetadata: String?=nil,
    preRelease: String?=nil
  ) {
    self.major=major
    self.minor=minor
    self.patch=patch
    self.buildMetadata=buildMetadata
    self.preRelease=preRelease
  }

  /// String representation of the version (e.g., "1.2.3-beta+exp.sha.5114f85")
  public var versionString: String {
    var result="\(major).\(minor).\(patch)"
    if let preRelease {
      result += "-\(preRelease)"
    }
    if let buildMetadata {
      result += "+\(buildMetadata)"
    }
    return result
  }

  /// Compares two versions according to semantic versioning rules
  public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
    if lhs.major != rhs.major {
      return lhs.major < rhs.major
    }
    if lhs.minor != rhs.minor {
      return lhs.minor < rhs.minor
    }
    if lhs.patch != rhs.patch {
      return lhs.patch < rhs.patch
    }

    // Pre-release has lower precedence than release version
    switch (lhs.preRelease, rhs.preRelease) {
      case (nil, nil):
        return false // Equal
      case (nil, _):
        return false // rhs is pre-release, lhs is release
      case (_, nil):
        return true // lhs is pre-release, rhs is release
      case let (lpr?, rpr?):
        return lpr < rpr // Compare pre-release strings
    }
  }
}

/// Module-specific errors
public enum ModuleError: Error, Sendable, Equatable {
  /// Module version mismatch error
  case versionMismatch(
    moduleName: String,
    expected: String,
    found: String
  )

  /// Module not found error
  case moduleNotFound(moduleName: String)

  /// Feature not supported in this module version
  case featureNotSupported(feature: String, minimumVersion: SemanticVersion)
}

/// Protocol for module information
public protocol ModuleInformation: Sendable {
  /// Module name
  static var name: String { get }

  /// Module version
  static var version: SemanticVersion { get }

  /// Module description
  static var description: String { get }

  /// Build date
  static var buildDate: Date { get }

  /// Compatible module versions
  static var compatibleVersions: [String: ClosedRange<SemanticVersion>] { get }
}

/// Default implementation
extension ModuleInformation {
  /// Default empty compatible versions
  public static var compatibleVersions: [String: ClosedRange<SemanticVersion>] {
    [:]
  }

  /// Checks if this module is compatible with another module
  /// - Parameters:
  ///   - moduleName: The name of the module to check compatibility with
  ///   - version: The version of the module to check
  /// - Returns: True if compatible, false otherwise
  public static func isCompatible(with moduleName: String, version: SemanticVersion) -> Bool {
    guard let compatibleRange=compatibleVersions[moduleName] else {
      return true // No compatibility requirements specified
    }

    return compatibleRange.contains(version)
  }

  /// Validates compatibility with another module, throwing an error if incompatible
  /// - Parameters:
  ///   - moduleName: The name of the module to validate against
  ///   - version: The version to validate
  /// - Throws: ModuleError.versionMismatch if incompatible
  public static func validateCompatibility(
    with moduleName: String,
    version: SemanticVersion
  ) throws {
    if !isCompatible(with: moduleName, version: version) {
      guard let expectedRange=compatibleVersions[moduleName] else {
        return // No compatibility requirements
      }

      throw ModuleError.versionMismatch(
        moduleName: moduleName,
        expected: "Range \(expectedRange.lowerBound.versionString) to \(expectedRange.upperBound.versionString)",
        found: version.versionString
      )
    }
  }
}
