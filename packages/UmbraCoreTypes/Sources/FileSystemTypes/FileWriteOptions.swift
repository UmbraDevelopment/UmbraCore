import Foundation

/**
 # File Write Options

 Options for controlling file write operations.
 This type provides a Foundation-independent abstraction for file write
 operations, allowing for consistent behaviour across different implementations.

 ## Thread Safety

 This type is designed to be thread-safe and can be safely used across
 actor boundaries as it is a value type with no shared state.

 ## British Spelling

 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public struct FileWriteOptions: OptionSet, Sendable, Equatable {
  public let rawValue: UInt

  public init(rawValue: UInt) {
    self.rawValue=rawValue
  }

  /// Create the file if it doesn't exist
  public static let createIfNeeded=FileWriteOptions(rawValue: 1 << 0)

  /// Replace the file if it already exists
  public static let replaceExisting=FileWriteOptions(rawValue: 1 << 1)

  /// Append to the file instead of replacing its contents
  public static let append=FileWriteOptions(rawValue: 1 << 2)

  /// Write atomically (write to a temporary file and then replace the original)
  public static let atomic=FileWriteOptions(rawValue: 1 << 3)

  /// Ensure the file is synced to disk after writing
  public static let synchronous=FileWriteOptions(rawValue: 1 << 4)

  /// Set file protection level to complete until first user authentication
  public static let completeFileProtection=FileWriteOptions(rawValue: 1 << 5)

  /**
   Converts to Foundation's Data writing options.

   - Returns: The equivalent Data.WritingOptions
   */
  public func toFoundationOptions() -> Data.WritingOptions {
    var options: Data.WritingOptions=[]

    if contains(.atomic) {
      options.insert(.atomic)
    }

    if contains(.completeFileProtection) {
      options.insert(.completeFileProtectionUntilFirstUserAuthentication)
    }

    // Note: Some of our options don't have direct equivalents in Foundation
    // and would need to be handled separately in the implementation

    return options
  }

  /**
   Creates FileWriteOptions from Foundation's Data.WritingOptions.

   - Parameter foundationOptions: The Data.WritingOptions to convert
   - Returns: The equivalent FileWriteOptions
   */
  public static func fromFoundationOptions(
    _ foundationOptions: Data
      .WritingOptions
  ) -> FileWriteOptions {
    var options: FileWriteOptions=[]

    if foundationOptions.contains(.atomic) {
      options.insert(.atomic)
    }

    if foundationOptions.contains(.completeFileProtectionUntilFirstUserAuthentication) {
      options.insert(.completeFileProtection)
    }

    return options
  }
}
