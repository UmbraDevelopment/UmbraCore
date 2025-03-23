/// A Foundation-free representation of a point in time.
///
/// This type provides a replacement for Foundation's Date type without any
/// Foundation dependencies. It uses a simple Unix timestamp (seconds since
/// January 1, 1970) as its internal representation.
@frozen
public struct TimePoint: Sendable, Equatable, Hashable, Comparable {
  // MARK: - Properties

  /// The time interval since January 1, 1970 at 00:00:00 UTC
  public let timeIntervalSince1970: Double

  // MARK: - Initialization

  /// Create a new TimePoint with the specified time interval since 1970
  /// - Parameter timeIntervalSince1970: Seconds since January 1, 1970 at 00:00:00 UTC
  public init(timeIntervalSince1970: Double) {
    self.timeIntervalSince1970 = timeIntervalSince1970
  }

  /// Create a TimePoint representing the current time
  public static func now() -> TimePoint {
    // Implementation note: In a truly Foundation-free module, we would
    // need to use platform-specific APIs to get the current time.
    // For simplicity, we're defining the API, but the actual implementation
    // would need to be injected or bridged from Foundation.
    TimePoint(timeIntervalSince1970: 0)
  }

  // MARK: - Operators

  /// Add a time interval to a TimePoint
  /// - Parameters:
  ///   - lhs: The TimePoint
  ///   - rhs: Time interval in seconds to add
  /// - Returns: A new TimePoint representing the sum
  public static func + (lhs: TimePoint, rhs: Double) -> TimePoint {
    TimePoint(timeIntervalSince1970: lhs.timeIntervalSince1970 + rhs)
  }

  /// Subtract a time interval from a TimePoint
  /// - Parameters:
  ///   - lhs: The TimePoint
  ///   - rhs: Time interval in seconds to subtract
  /// - Returns: A new TimePoint representing the difference
  public static func - (lhs: TimePoint, rhs: Double) -> TimePoint {
    TimePoint(timeIntervalSince1970: lhs.timeIntervalSince1970 - rhs)
  }

  /// Get the time interval between two TimePoints
  /// - Parameters:
  ///   - lhs: The first TimePoint
  ///   - rhs: The second TimePoint
  /// - Returns: Time interval in seconds between the two points
  public static func - (lhs: TimePoint, rhs: TimePoint) -> Double {
    lhs.timeIntervalSince1970 - rhs.timeIntervalSince1970
  }

  // MARK: - Comparable

  public static func < (lhs: TimePoint, rhs: TimePoint) -> Bool {
    lhs.timeIntervalSince1970 < rhs.timeIntervalSince1970
  }
}
