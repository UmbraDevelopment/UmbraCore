import Foundation

/// Options for directory enumeration operations
public struct DirectoryEnumerationOptions: OptionSet, Sendable {
  public let rawValue: UInt

  public init(rawValue: UInt) {
    self.rawValue=rawValue
  }

  /// Skip hidden files during enumeration
  public static let skipsHiddenFiles=DirectoryEnumerationOptions(rawValue: 1 << 0)

  /// Skip package contents during enumeration
  public static let skipsPackageDescendants=DirectoryEnumerationOptions(rawValue: 1 << 1)

  /// Skip subdirectory recursion during enumeration
  public static let skipsSubdirectoryDescendants=DirectoryEnumerationOptions(rawValue: 1 << 2)

  /// Default options (no customisations)
  public static let none: DirectoryEnumerationOptions = []

  /// Maps to Foundation's FileManager.DirectoryEnumerationOptions
  public var toFoundationOptions: FileManager.DirectoryEnumerationOptions {
    var options: FileManager.DirectoryEnumerationOptions=[]

    if contains(.skipsHiddenFiles) {
      options.insert(.skipsHiddenFiles)
    }

    if contains(.skipsPackageDescendants) {
      options.insert(.skipsPackageDescendants)
    }

    if contains(.skipsSubdirectoryDescendants) {
      options.insert(.skipsSubdirectoryDescendants)
    }

    return options
  }

  /// Creates options from Foundation's FileManager.DirectoryEnumerationOptions
  public static func fromFoundationOptions(
    _ options: FileManager
      .DirectoryEnumerationOptions
  ) -> DirectoryEnumerationOptions {
    var result: DirectoryEnumerationOptions = .none

    if options.contains(.skipsHiddenFiles) {
      result.insert(.skipsHiddenFiles)
    }

    if options.contains(.skipsPackageDescendants) {
      result.insert(.skipsPackageDescendants)
    }

    if options.contains(.skipsSubdirectoryDescendants) {
      result.insert(.skipsSubdirectoryDescendants)
    }

    return result
  }
}
