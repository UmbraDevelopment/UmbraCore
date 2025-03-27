/// A Foundation-free time representation for logging
public struct TimePointAdapter: Sendable, Equatable, Hashable, Comparable {
  /// The time interval since January 1, 1970 at 00:00:00 UTC
  public let timeIntervalSince1970: Double

  /// Create a new TimePointAdapter with the specified time interval since 1970
  /// - Parameter timeIntervalSince1970: Seconds since January 1, 1970 at 00:00:00 UTC
  public init(timeIntervalSince1970: Double) {
    self.timeIntervalSince1970 = timeIntervalSince1970
  }

  /// Create a TimePointAdapter representing the current time
  public static func now() -> TimePointAdapter {
    // In a production environment, we would use a platform-specific
    // implementation to get the current time since 1970.
    // For now, we're using a placeholder value of 0 to break the dependency,
    // which will be replaced with proper time handling later.
    // This allows us to compile without Foundation dependencies.
    TimePointAdapter(timeIntervalSince1970: 0)
  }

  // MARK: - Comparable implementation

  public static func < (lhs: TimePointAdapter, rhs: TimePointAdapter) -> Bool {
    lhs.timeIntervalSince1970 < rhs.timeIntervalSince1970
  }
}
