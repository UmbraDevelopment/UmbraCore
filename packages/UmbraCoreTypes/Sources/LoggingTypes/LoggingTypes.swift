/// LoggingTypes Module
///
/// Provides core type definitions for the logging system, following the Alpha Dot Five
/// architecture principle of separation between types, interfaces, and implementations.
///
/// This module contains:
/// - Log level definitions
/// - Log entry structures
/// - Log metadata models
/// - Foundation-independent time representation
/// - Privacy level controls for sensitive data
///
/// Following Alpha Dot Five principles, this module:
/// - Contains only type definitions
/// - Has minimal dependencies
/// - Avoids implementation details
/// - Is Foundation-independent where possible

/// Standard log levels representing the severity of log entries.
public enum LogLevel: String, Sendable, Equatable, CaseIterable, Comparable, Hashable, Codable {
  case trace
  case debug
  case info
  case warning
  case error
  case critical

  /// Compares log levels by severity with trace being the lowest and critical the highest.
  public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
    let order: [LogLevel]=[.trace, .debug, .info, .warning, .error, .critical]
    guard
      let lhsIndex=order.firstIndex(of: lhs),
      let rhsIndex=order.firstIndex(of: rhs)
    else {
      return false
    }
    return lhsIndex < rhsIndex
  }
}

/// Privacy levels for controlling how information is logged.
/// Used to annotate data that requires special handling when logged.
public enum LogPrivacyLevel: Sendable, Equatable, Hashable {
  /// Public information that can be logged without redaction
  case `public`

  /// Private information that should be redacted in logs
  /// but may be visible in debug builds
  case `private`

  /// Sensitive information that requires special handling
  /// and should always be redacted or processed before logging
  case sensitive

  /// Information that should be hashed before logging
  /// to allow correlation without revealing the actual value
  case hash

  /// Auto-redacted content based on type analysis
  /// This is the default for unannotated values
  case auto
}

/// A value wrapper that includes privacy metadata
public struct PrivacyMetadataValue: Sendable, Equatable, Hashable {
  /// The underlying value as a string representation
  public let valueString: String

  /// The privacy level for this value
  public let privacy: LogPrivacyLevel

  /// String value accessor for privacy-aware code
  public var stringValue: String {
    valueString
  }

  /// Privacy classification accessor
  public var privacyClassification: LogPrivacyLevel {
    privacy
  }

  /// Create a new privacy metadata value
  /// - Parameters:
  ///   - value: The underlying value
  ///   - privacy: The privacy level for this value
  public init(value: CustomStringConvertible, privacy: LogPrivacyLevel = .auto) {
    valueString=String(describing: value)
    self.privacy=privacy
  }

  /// Create a new privacy metadata value from a string
  /// - Parameters:
  ///   - value: The string value
  ///   - privacy: The privacy level to apply
  public init(value: String, privacy: LogPrivacyLevel = .auto) {
    valueString=value
    self.privacy=privacy
  }

  /// Create a new privacy metadata value from any value
  /// - Parameters:
  ///   - value: Any value that will be converted to a string
  ///   - privacy: The privacy level to apply
  public init(anyValue value: Any, privacy: LogPrivacyLevel = .auto) {
    valueString=String(describing: value)
    self.privacy=privacy
  }

  /// Creates a string representation of this value
  public var description: String {
    switch privacy {
      case .public:
        return valueString
      case .private:
        return "<private>"
      case .sensitive:
        return "<sensitive>"
      case .hash:
        // Use a string representation of the hash value
        return String(describing: valueString.hashValue)
      case .auto:
        #if DEBUG
          return valueString
        #else
          return "<redacted>"
        #endif
    }
  }

  /// Required for Hashable conformance
  public func hash(into hasher: inout Hasher) {
    hasher.combine(valueString)
    hasher.combine(privacy)
  }
}

/// Collection of key-value metadata with privacy controls
public struct PrivacyMetadata: Sendable, Equatable, Hashable {
  /// The underlying key-value storage
  var storage: [String: PrivacyMetadataValue]

  /// Creates an empty metadata collection
  public init() {
    storage=[:]
  }

  /// Creates a metadata collection from the provided dictionary
  /// - Parameter initial: Initial values to populate the metadata
  public init(_ initial: [String: (value: Any, privacy: LogPrivacyLevel)]) {
    storage=[:]
    for (key, valueTuple) in initial {
      storage[key]=PrivacyMetadataValue(anyValue: valueTuple.value, privacy: valueTuple.privacy)
    }
  }

  /// Access metadata values by key
  public subscript(key: String) -> PrivacyMetadataValue? {
    get {
      storage[key]
    }
    set {
      if let newValue {
        storage[key]=newValue
      } else {
        storage.removeValue(forKey: key)
      }
    }
  }

  /// Get value for key
  /// - Parameter key: The key to look up
  /// - Returns: The metadata value if found
  public func value(forKey key: String) -> PrivacyMetadataValue? {
    storage[key]
  }

  /// Get all entries in the metadata
  /// - Returns: A sequence of keys
  public func entries() -> Dictionary<String, PrivacyMetadataValue>.Keys {
    storage.keys
  }

  /// Get a dictionary of all entries
  /// - Returns: A copy of the internal storage dictionary
  public func entriesDict() -> [String: PrivacyMetadataValue] {
    storage
  }

  /// Returns true if the metadata contains no key-value pairs
  public var isEmpty: Bool {
    storage.isEmpty
  }

  /// Returns a collection containing just the keys
  public var keys: Dictionary<String, PrivacyMetadataValue>.Keys {
    storage.keys
  }

  /// Returns the key-value pairs as an array
  public var entriesArray: [(key: String, value: String, privacy: LogPrivacyLevel)] {
    storage.map { (key, value) in
      (key: key, value: value.valueString, privacy: value.privacy)
    }
  }

  /// Merges the given metadata into this metadata
  /// - Parameter other: The metadata to merge
  public mutating func merge(_ other: PrivacyMetadata) {
    for (key, value) in other.storage {
      storage[key]=value
    }
  }

  /// Creates a new metadata by merging with the given metadata
  /// - Parameter other: The metadata to merge
  /// - Returns: A new metadata containing the combined entries
  public func merging(_ other: PrivacyMetadata) -> PrivacyMetadata {
    var result=self
    result.merge(other)
    return result
  }

  /// Required for Hashable conformance
  public func hash(into hasher: inout Hasher) {
    hasher.combine(storage)
  }

  /// Required for Equatable conformance
  public static func == (lhs: PrivacyMetadata, rhs: PrivacyMetadata) -> Bool {
    lhs.storage == rhs.storage
  }
}

/// Private actor to manage thread-safe timestamp generation
private actor LogTimestampGenerator {
  /// Internal counter for generating sequential timestamps
  private var counter: UInt64=0

  /// Generate the next counter value in a thread-safe manner
  func nextValue() -> UInt64 {
    counter += 1
    return counter
  }
}

/// Represents a timestamp for logging purposes without requiring Foundation
public struct LogTimestamp: Sendable, Equatable, Hashable {
  /// Seconds since Unix epoch (1970-01-01 00:00:00 UTC)
  public let secondsSinceEpoch: Double

  /// Static actor instance for thread-safe counter access
  private static let generator=LogTimestampGenerator()

  /// Creates a timestamp representing the current time
  /// This is now an async function since it needs to access the actor
  public static func now() async -> LogTimestamp {
    // This implementation uses a simplistic approach that doesn't require
    // system time APIs. It guarantees monotonically increasing timestamps
    // but isn't tied to actual wall clock time.

    // Base timestamp (January 1, 2021)
    let baseTimestamp=1_609_459_200.0

    // Thread-safe counter access via the actor
    let currentCounter=await generator.nextValue()

    // Add a millisecond offset for each call
    let offset=Double(currentCounter) / 1000.0

    return LogTimestamp(secondsSinceEpoch: baseTimestamp + offset)
  }

  /// Creates a timestamp with the specified seconds since epoch
  public init(secondsSinceEpoch: Double) {
    self.secondsSinceEpoch=secondsSinceEpoch
  }

  /// Required for Hashable conformance
  public func hash(into hasher: inout Hasher) {
    hasher.combine(secondsSinceEpoch)
  }
}

/// Foundation-independent identifier for correlation
public struct LogIdentifier: Sendable, Equatable, Hashable, CustomStringConvertible {
  /// The underlying identifier string
  private let value: String

  /// Creates a unique identifier
  public static func unique() -> LogIdentifier {
    // Create a random identifier without Foundation
    var randomBytes=[UInt8](repeating: 0, count: 16)
    for i in 0..<randomBytes.count {
      randomBytes[i]=UInt8.random(in: 0...255)
    }

    // Format as a UUID-like string
    let segments=[
      formatHex(from: randomBytes[0..<4]),
      formatHex(from: randomBytes[4..<6]),
      formatHex(from: randomBytes[6..<8]),
      formatHex(from: randomBytes[8..<10]),
      formatHex(from: randomBytes[10..<16])
    ]

    return LogIdentifier(value: segments.joined(separator: "-"))
  }

  /// Helper to format hex strings from bytes
  private static func formatHex(from bytes: ArraySlice<UInt8>) -> String {
    bytes.map { byteToHexString($0) }.joined()
  }

  /// Convert a byte to a hex string
  private static func byteToHexString(_ byte: UInt8) -> String {
    let digits: [Character]=[
      "0",
      "1",
      "2",
      "3",
      "4",
      "5",
      "6",
      "7",
      "8",
      "9",
      "a",
      "b",
      "c",
      "d",
      "e",
      "f"
    ]
    let highIndex=Int(byte >> 4)
    let lowIndex=Int(byte & 0x0F)
    return String([digits[highIndex], digits[lowIndex]])
  }

  /// Creates an identifier with the given value
  public init(value: String) {
    self.value=value
  }

  /// String representation of the identifier
  public var description: String {
    value
  }
}

/// Represents the context for a log entry
///
/// This structure encapsulates contextual information for logging,
/// including domain name, source, metadata, and correlation ID.
public struct LogContext: Sendable, Equatable, Hashable, LogContextDTO {
  /// Source information (e.g., file, class, function)
  public let source: String?

  /// Metadata collection for the log entry
  private let metadataCollection: LogMetadataDTOCollection?

  /// Domain name identifying the log scope
  public let domainName: String

  /// The operation being performed
  public let operation: String

  /// The category for the log entry
  public let category: String

  /// Correlation ID for tracing related logs
  public let correlationID: String?

  /// Timestamp when this context was created
  public let timestamp: LogTimestamp

  /// Access to the metadata for this context as a DTO collection
  public var metadata: LogMetadataDTOCollection {
    metadataCollection ?? LogMetadataDTOCollection()
  }

  /// Initialiser with default values
  ///
  /// Note: This overload is for non-async contexts. The timestamp
  /// is pre-generated to avoid async initialisation.
  ///
  /// - Parameters:
  ///   - source: Source component identifier
  ///   - metadata: Optional metadata collection
  ///   - correlationId: Unique identifier for correlating related logs
  ///   - timestamp: Timestamp (defaults to a pre-generated value)
  ///   - operation: The operation being performed
  ///   - category: The category for this log entry
  public init(
    source: String,
    metadata: LogMetadataDTOCollection?=nil,
    correlationID: LogIdentifier=LogIdentifier.unique(),
    timestamp: LogTimestamp=LogTimestamp(secondsSinceEpoch: 1_609_459_200.0),
    domainName: String="DefaultDomain",
    operation: String="default",
    category: String="General"
  ) {
    self.source=source
    metadataCollection=metadata
    self.correlationID=correlationID.description
    self.timestamp=timestamp
    self.domainName=domainName
    self.operation=operation
    self.category=category
  }

  /// Async initialiser that generates a current timestamp
  ///
  /// - Parameters:
  ///   - source: Source component identifier
  ///   - metadata: Optional metadata collection
  ///   - correlationId: Unique identifier for correlating related logs
  ///   - operation: The operation being performed
  ///   - category: The category for this log entry
  public static func create(
    source: String,
    metadata: LogMetadataDTOCollection?=nil,
    correlationID: LogIdentifier=LogIdentifier.unique(),
    domainName: String="DefaultDomain",
    operation: String="default",
    category: String="General"
  ) async -> LogContext {
    let timestamp=await LogTimestamp.now()
    return LogContext(
      source: source,
      metadata: metadata,
      correlationID: correlationID,
      timestamp: timestamp,
      domainName: domainName,
      operation: operation,
      category: category
    )
  }

  /// Get the source information
  /// - Returns: Source information for logs, or a default if not available
  public func getSource() -> String {
    source ?? "UnknownSource"
  }

  /// Creates a new context with additional metadata merged with the existing metadata
  /// - Parameter additionalMetadata: Additional metadata to include
  /// - Returns: New context with merged metadata
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> LogContext {
    let combinedMetadata=metadataCollection?.merging(with: additionalMetadata) ?? additionalMetadata

    return LogContext(
      source: getSource(),
      metadata: combinedMetadata,
      correlationID: LogIdentifier(value: correlationID ?? ""),
      timestamp: timestamp,
      domainName: domainName,
      operation: operation,
      category: category
    )
  }

  /// Create a new context with updated metadata
  /// - Parameter newMetadata: The metadata to add to the existing metadata
  /// - Returns: A new context with combined metadata
  public func withUpdatedMetadata(_ newMetadata: LogMetadataDTOCollection) -> LogContext {
    let combinedMetadata=metadataCollection?.merging(with: newMetadata) ?? newMetadata

    return LogContext(
      source: getSource(),
      metadata: combinedMetadata,
      correlationID: LogIdentifier(value: correlationID ?? ""),
      timestamp: timestamp,
      domainName: domainName,
      operation: operation,
      category: category
    )
  }

  /// Create a new context with updated metadata from a DTO collection
  /// - Parameter metadata: The metadata collection to add to the context
  /// - Returns: A new log context with the updated metadata
  public func toBaseLogContextDTO(withMetadata metadata: LogMetadataDTOCollection?=nil)
  -> BaseLogContextDTO {
    // Create a new BaseLogContextDTO with merged metadata
    let finalMetadata=metadata != nil ? self.metadata.merging(with: metadata!) : self.metadata

    return BaseLogContextDTO(
      domainName: domainName,
      operation: operation,
      category: category,
      source: source,
      metadata: finalMetadata,
      correlationID: correlationID
    )
  }

  /// Create a new context with a different source
  /// - Parameter newSource: The new source component identifier
  /// - Returns: A new context with the updated source
  public func withSource(_ newSource: String) -> LogContext {
    LogContext(
      source: newSource,
      metadata: metadataCollection,
      correlationID: LogIdentifier(value: correlationID ?? ""),
      timestamp: timestamp,
      domainName: domainName,
      operation: operation,
      category: category
    )
  }

  /// Required for Hashable conformance
  public func hash(into hasher: inout Hasher) {
    hasher.combine(source)
    hasher.combine(metadataCollection)
    hasher.combine(correlationID)
    hasher.combine(timestamp)
    hasher.combine(domainName)
    hasher.combine(operation)
    hasher.combine(category)
  }

  /// Required for Equatable conformance
  public static func == (lhs: LogContext, rhs: LogContext) -> Bool {
    lhs.source == rhs.source &&
      lhs.metadataCollection == rhs.metadataCollection &&
      lhs.correlationID == rhs.correlationID &&
      lhs.timestamp == rhs.timestamp &&
      lhs.domainName == rhs.domainName &&
      lhs.operation == rhs.operation &&
      lhs.category == rhs.category
  }
}

/// A string interpolation type that supports privacy annotations for interpolated values
@frozen
public struct PrivacyString: Sendable, Hashable {
  /// The resulting message with privacy annotations embedded
  public let rawValue: String

  /// Privacy annotations for different parts of the string
  public let privacyAnnotations: [Range<String.Index>: LogPrivacyLevel]

  /// The content of the privacy string
  public var content: String {
    rawValue
  }

  /// The overall privacy level for the string
  public var privacy: LogPrivacyLevel {
    // Default to private if no annotations exist
    guard !privacyAnnotations.isEmpty else {
      return .private
    }

    // Find the most restrictive privacy level
    return privacyAnnotations.values.reduce(.public) { result, level in
      switch (result, level) {
        case (.sensitive, _), (_, .sensitive):
          .sensitive
        case (.private, _), (_, .private):
          .private
        case (.hash, _), (_, .hash):
          .hash
        default:
          .public
      }
    }
  }

  /// Creates a new PrivacyString with the given value and privacy annotations
  public init(rawValue: String, privacyAnnotations: [Range<String.Index>: LogPrivacyLevel]=[:]) {
    self.rawValue=rawValue
    self.privacyAnnotations=privacyAnnotations
  }

  /// Required for Hashable conformance
  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
    for (range, level) in privacyAnnotations {
      hasher.combine(range.lowerBound.utf16Offset(in: rawValue))
      hasher.combine(range.upperBound.utf16Offset(in: rawValue))
      hasher.combine(level)
    }
  }

  /// Required for Equatable conformance
  public static func == (lhs: PrivacyString, rhs: PrivacyString) -> Bool {
    lhs.rawValue == rhs.rawValue && lhs.privacyAnnotations == rhs.privacyAnnotations
  }
}

/// String interpolation implementation for PrivacyString
extension PrivacyString: ExpressibleByStringInterpolation {
  public struct StringInterpolation: StringInterpolationProtocol {
    // In order for PrivacyString.init(stringInterpolation:) to access these properties,
    // they need to be internal or public
    var resultString=""
    var annotations: [Range<String.Index>: LogPrivacyLevel]=[:]

    public init(literalCapacity: Int, interpolationCount _: Int) {
      resultString.reserveCapacity(literalCapacity)
    }

    public mutating func appendLiteral(_ literal: String) {
      resultString.append(literal)
    }

    public mutating func appendInterpolation(_ value: some Any) {
      // Default to auto privacy level for unannotated values
      appendInterpolation(value, privacy: .auto)
    }

    public mutating func appendInterpolation(_ value: some Any, privacy: LogPrivacyLevel) {
      let startIndex=resultString.endIndex
      let valueString=String(describing: value)
      resultString.append(valueString)
      let endIndex=resultString.endIndex
      annotations[startIndex..<endIndex]=privacy
    }

    public mutating func appendInterpolation(public value: some Any) {
      appendInterpolation(value, privacy: .public)
    }

    public mutating func appendInterpolation(private value: some Any) {
      appendInterpolation(value, privacy: .private)
    }

    public mutating func appendInterpolation(sensitive value: some Any) {
      appendInterpolation(value, privacy: .sensitive)
    }

    public mutating func appendInterpolation(hash value: some Any) {
      appendInterpolation(value, privacy: .hash)
    }
  }

  public init(stringLiteral value: String) {
    rawValue=value
    privacyAnnotations=[:]
  }

  public init(stringInterpolation: StringInterpolation) {
    rawValue=stringInterpolation.resultString
    privacyAnnotations=stringInterpolation.annotations
  }
}

/// Helper methods for manipulating privacy-annotated strings
extension PrivacyString {
  /// Converts the string to a plain string with appropriate redaction based on build configuration
  /// - Returns: A processed string with sensitive information properly handled
  public func processForLogging() -> String {
    var result=rawValue

    // Sort ranges in reverse order to avoid index shifting during replacement
    let sortedRanges=privacyAnnotations.keys.sorted { $0.upperBound > $1.upperBound }

    for range in sortedRanges {
      guard let privacyLevel=privacyAnnotations[range] else { continue }

      // Apply different redaction strategies based on privacy level
      switch privacyLevel {
        case .public:
          // No redaction for public information
          continue

        case .private:
          #if DEBUG
            // In debug builds, mark private data but don't redact
            let value=String(result[range])
            result.replaceSubrange(range, with: "🔒[\(value)]")
          #else
            // In release builds, redact private data
            result.replaceSubrange(range, with: "🔒[REDACTED]")
          #endif

        case .sensitive:
          // Always redact sensitive information
          result.replaceSubrange(range, with: "🔐[SENSITIVE]")

        case .hash:
          // Hash the value instead of showing it directly
          let value=String(result[range])
          let hashedValue=simpleHash(value)
          result.replaceSubrange(range, with: "🔏[\(hashedValue)]")

        case .auto:
          // Auto-redaction based on content analysis
          #if DEBUG
            let value=String(result[range])
            result.replaceSubrange(range, with: "🔍[\(value)]")
          #else
            result.replaceSubrange(range, with: "🔍[AUTO-REDACTED]")
          #endif
      }
    }

    return result
  }

  /// Creates a simple hash representation of a string
  /// - Parameter value: The string to hash
  /// - Returns: A simple hash string
  private func simpleHash(_ value: String) -> String {
    // Simple hash implementation without Foundation
    var hashValue=0

    for char in value {
      let asciiValue=char.asciiValue ?? 0
      hashValue=((hashValue << 5) &+ hashValue) &+ Int(asciiValue)
    }

    // Convert to hex string without Foundation
    return intToHexString(abs(hashValue), padLength: 8)
  }

  /// Converts an integer to a hex string
  /// - Parameters:
  ///   - value: The integer to convert
  ///   - padLength: The desired length with zero padding
  /// - Returns: A hexadecimal string representation
  private func intToHexString(_ value: Int, padLength: Int) -> String {
    let digits: [Character]=[
      "0",
      "1",
      "2",
      "3",
      "4",
      "5",
      "6",
      "7",
      "8",
      "9",
      "a",
      "b",
      "c",
      "d",
      "e",
      "f"
    ]
    var result=""
    var remainingValue=value

    repeat {
      let digit=remainingValue & 0xF
      result=String(digits[digit]) + result
      remainingValue >>= 4
    } while
      remainingValue > 0

    // Add zero padding if needed
    while result.count < padLength {
      result="0" + result
    }

    return result
  }
}
