/// APIVersionDTO
///
/// Represents version information for the UmbraCore API service.
/// This DTO contains semantic versioning details and additional
/// metadata for API version identification and compatibility checking.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
public struct APIVersionDTO: Sendable, Equatable {
  /// Major version component (breaking changes)
  public let major: UInt

  /// Minor version component (non-breaking feature additions)
  public let minor: UInt

  /// Patch version component (bug fixes)
  public let patch: UInt

  /// Optional build identifier
  public let buildIdentifier: String?

  /// Creates a string representation of the version in semver format
  public var versionString: String {
    var result="\(major).\(minor).\(patch)"
    if let buildIdentifier {
      result += "-\(buildIdentifier)"
    }
    return result
  }

  /// Creates a new APIVersionDTO instance
  /// - Parameters:
  ///   - major: Major version component
  ///   - minor: Minor version component
  ///   - patch: Patch version component
  ///   - buildIdentifier: Optional build identifier
  public init(
    major: UInt,
    minor: UInt,
    patch: UInt,
    buildIdentifier: String?=nil
  ) {
    self.major=major
    self.minor=minor
    self.patch=patch
    self.buildIdentifier=buildIdentifier
  }

  /// Parses a version string into an APIVersionDTO
  /// - Parameter versionString: A string in semver format (e.g., "1.2.3" or "1.2.3-beta")
  /// - Returns: A populated APIVersionDTO if parsing succeeds
  public static func parse(from versionString: String) -> APIVersionDTO? {
    // Simple semver parsing logic
    let components=versionString.split(separator: "-")
    let versionComponents=components[0].split(separator: ".")

    guard
      versionComponents.count >= 3,
      let major=UInt(versionComponents[0]),
      let minor=UInt(versionComponents[1]),
      let patch=UInt(versionComponents[2])
    else {
      return nil
    }

    let buildIdentifier=components.count > 1 ? String(components[1]) : nil

    return APIVersionDTO(
      major: major,
      minor: minor,
      patch: patch,
      buildIdentifier: buildIdentifier
    )
  }
}
