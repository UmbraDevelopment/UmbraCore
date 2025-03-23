/// Protocol that defines the minimal interface needed for Foundation.URL operations
/// This allows us to break circular dependencies between Foundation and other modules
public protocol URLBridgeProtocol {
  /// The string representation of the URL
  var stringValue: String { get }

  /// Initialize with a string
  init?(string: String)
}

/// Type-erased wrapper for Foundation.URL
/// This allows modules to reference URLs without directly depending on Foundation
public struct URLBridge: Sendable {
  /// The string representation of the URL
  public let stringValue: String

  /// Initialize with a string
  public init?(string: String) {
    // Basic validation that this is a valid URL format
    // This is a simplified version of URL validation
    guard string.contains("://") || string.hasPrefix("/") else {
      return nil
    }
    stringValue=string
  }

  /// Initialize with a file path
  public init(fileURLWithPath path: String) {
    stringValue="file://" + path
  }
}

/// Extension to provide additional functionality
extension URLBridge {
  /// Get the last path component
  public var lastPathComponent: String {
    let components=stringValue.split(separator: "/")
    return components.last.map(String.init) ?? ""
  }

  /// Get the path extension
  public var pathExtension: String {
    let components=lastPathComponent.split(separator: ".")
    return components.count > 1 ? String(components.last!) : ""
  }

  /// Append a path component
  public func appendingPathComponent(_ pathComponent: String) -> URLBridge {
    var newString=stringValue
    if !newString.hasSuffix("/") {
      newString += "/"
    }
    newString += pathComponent
    return URLBridge(string: newString)!
  }
}
