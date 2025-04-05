import Foundation
import os.log

/// A builder for a collection of metadata entries with privacy annotations
///
/// This structure provides a convenient way to build a collection of
/// privacy-aware metadata entries for logging.
public struct LogMetadataDTOCollection: Sendable, Equatable {
  /// The collection of metadata entries
  public private(set) var entries: [LogMetadataDTO]

  /// Creates a new empty collection of metadata entries
  public init() {
    entries=[]
  }

  /// Creates a collection with the specified entries
  ///
  /// - Parameter entries: The initial metadata entries
  public init(entries: [LogMetadataDTO]) {
    self.entries=entries
  }

  /// Adds a public metadata entry to the collection
  ///
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: The updated collection
  public func withPublic(key: String, value: String) -> LogMetadataDTOCollection {
    var result=self
    result.entries.append(.publicEntry(key: key, value: value))
    return result
  }

  /// Adds a private metadata entry to the collection
  ///
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: The updated collection
  public func withPrivate(key: String, value: String) -> LogMetadataDTOCollection {
    var result=self
    result.entries.append(.privateEntry(key: key, value: value))
    return result
  }

  /// Adds a sensitive metadata entry to the collection
  ///
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: The updated collection
  public func withSensitive(key: String, value: String) -> LogMetadataDTOCollection {
    var result=self
    result.entries.append(.sensitiveEntry(key: key, value: value))
    return result
  }

  /// Adds a hashed metadata entry to the collection
  ///
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: The updated collection
  public func withHashed(key: String, value: String) -> LogMetadataDTOCollection {
    var result=self
    result.entries.append(.hashedEntry(key: key, value: value))
    return result
  }

  /// Adds a custom privacy-classified metadata entry to the collection
  ///
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  ///   - privacyLevel: The privacy classification for this entry
  /// - Returns: The updated collection
  public func with(
    key: String,
    value: String,
    privacyLevel: PrivacyClassification
  ) -> LogMetadataDTOCollection {
    var result=self
    result.entries.append(LogMetadataDTO(key: key, value: value, privacyLevel: privacyLevel))
    return result
  }

  /// Adds an automatically privacy-classified metadata entry to the collection
  ///
  /// This will use the system's built-in heuristics to determine the appropriate
  /// privacy level based on the value's content in runtime.
  ///
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: The updated collection
  public func withAuto(key: String, value: String) -> LogMetadataDTOCollection {
    var result=self
    result.entries.append(.autoClassifiedEntry(key: key, value: value))
    return result
  }

  /// Combines this collection with another collection
  ///
  /// - Parameter other: The collection to combine with
  /// - Returns: A new collection containing entries from both collections
  public func merging(with other: LogMetadataDTOCollection) -> LogMetadataDTOCollection {
    LogMetadataDTOCollection(entries: entries + other.entries)
  }

  /// Indicates whether the collection has no entries
  public var isEmpty: Bool {
    entries.isEmpty
  }

  /// Converts this collection to a PrivacyMetadata instance for
  /// compatibility with legacy logging systems.
  ///
  /// - Returns: A PrivacyMetadata instance with the appropriate privacy classifications
  public func toPrivacyMetadata() -> PrivacyMetadata {
    var result=PrivacyMetadata()

    // Convert each entry to the corresponding PrivacyMetadata format
    for entry in entries {
      // Create a PrivacyMetadataValue with the appropriate privacy level
      let logPrivacyLevel: LogPrivacyLevel

        // Map the PrivacyClassification to LogPrivacyLevel
        = switch entry.privacyLevel
      {
        case .public:
          .public
        case .private:
          .private
        case .sensitive:
          .sensitive
        case .hash:
          .hash
        case .auto:
          .auto
      }

      // Create the metadata value with the correct privacy level
      let metadataValue=PrivacyMetadataValue(
        value: entry.value,
        privacy: logPrivacyLevel
      )

      // Add to the PrivacyMetadata using subscript syntax
      result[entry.key]=metadataValue
    }

    return result
  }

  /// Creates a dictionary representation of the metadata collection
  ///
  /// - Returns: A dictionary containing all the metadata entries
  public func toDictionary() -> [String: String] {
    var result: [String: String]=[:]
    for entry in entries {
      result[entry.key]=entry.value
    }
    return result
  }
}

// MARK: - Privacy Metadata Conversion

extension LogMetadataDTOCollection {
  /// Converts privacy classification to LogPrivacyLevel
  ///
  /// - Parameter level: The privacy classification level
  /// - Returns: The corresponding LogPrivacyLevel value
  private func convertPrivacyLevel(_ level: PrivacyClassification) -> LogPrivacyLevel {
    switch level {
      case .public:
        .public
      case .private:
        .private
      case .sensitive:
        .sensitive
      case .hash:
        .private // Use private as fallback for hash
      case .auto:
        .auto
    }
  }
}
