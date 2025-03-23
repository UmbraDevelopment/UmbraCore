import UmbraCoreTypes_CoreErrors

/// A Foundation-free representation of a resource location.
///
/// This type provides a replacement for Foundation's URL type without any
/// Foundation dependencies. It implements the core functionality needed
/// for identifying and locating resources within the UmbraCore ecosystem.
@frozen
public struct ResourceLocator: Sendable, Equatable, Hashable {
  // MARK: - Properties

  /// The scheme component of the locator (e.g., "file", "https")
  public let scheme: String

  /// The path component of the locator
  public let path: String

  /// Optional query parameters
  public let query: String?

  /// Optional fragment identifier
  public let fragment: String?

  /// Returns true if this locator points to a local file system resource
  public var isFileResource: Bool {
    scheme == "file"
  }

  // MARK: - Initialization

  /// Create a new ResourceLocator
  /// - Parameters:
  ///   - scheme: The scheme component (e.g., "file", "https")
  ///   - path: The path component
  ///   - query: Optional query parameters
  ///   - fragment: Optional fragment identifier
  /// - Throws: ResourceLocatorError.invalidPath if the path is empty
  public init(scheme: String, path: String, query: String?=nil, fragment: String?=nil) throws {
    guard !path.isEmpty else {
      throw ResourceLocatorError.invalidPath
    }

    self.scheme=scheme
    self.path=path
    self.query=query
    self.fragment=fragment
  }

  /// Create a file system ResourceLocator
  /// - Parameter path: The file system path
  /// - Returns: A ResourceLocator with "file" scheme
  /// - Throws: ResourceLocatorError.invalidPath if the path is empty
  public static func fileLocator(path: String) throws -> ResourceLocator {
    try ResourceLocator(scheme: "file", path: path)
  }

  /// Create an HTTP ResourceLocator
  /// - Parameters:
  ///   - host: The host component
  ///   - path: The path component
  ///   - query: Optional query parameters
  /// - Returns: A ResourceLocator with "http" scheme
  /// - Throws: ResourceLocatorError.invalidPath if the host or path is invalid
  public static func httpLocator(
    host: String,
    path: String,
    query: String?=nil
  ) throws -> ResourceLocator {
    guard !host.isEmpty else {
      throw ResourceLocatorError.invalidPath
    }

    let fullPath=host + (path.hasPrefix("/") ? path : "/" + path)
    return try ResourceLocator(scheme: "http", path: fullPath, query: query)
  }

  /// Create an HTTPS ResourceLocator
  /// - Parameters:
  ///   - host: The host component
  ///   - path: The path component
  ///   - query: Optional query parameters
  /// - Returns: A ResourceLocator with "https" scheme
  /// - Throws: ResourceLocatorError.invalidPath if the host or path is invalid
  public static func httpsLocator(
    host: String,
    path: String,
    query: String?=nil
  ) throws -> ResourceLocator {
    guard !host.isEmpty else {
      throw ResourceLocatorError.invalidPath
    }

    let fullPath=host + (path.hasPrefix("/") ? path : "/" + path)
    return try ResourceLocator(scheme: "https", path: fullPath, query: query)
  }

  // MARK: - String Representation

  /// Returns a string representation of the ResourceLocator
  /// - Returns: String representation in the format "scheme://path?query#fragment"
  public func toString() -> String {
    var result="\(scheme)://\(path)"

    if let query, !query.isEmpty {
      result += "?\(query)"
    }

    if let fragment, !fragment.isEmpty {
      result += "#\(fragment)"
    }

    return result
  }

  // MARK: - Resource Validation

  /// Validates that the resource exists and is accessible
  /// - Returns: true if the resource exists and is accessible
  /// - Throws: ResourceLocatorError if the resource does not exist or is not accessible
  public func validate() throws -> Bool {
    // This is a placeholder implementation that would need to be
    // implemented with platform-specific code for actual resource validation

    // For demonstration purposes, we'll throw errors for certain patterns
    if path.contains("nonexistent") {
      throw ResourceLocatorError.resourceNotFound
    }

    if path.contains("restricted") {
      throw ResourceLocatorError.accessDenied
    }

    return true
  }
}
