import UmbraCoreTypes

/// FoundationIndependent representation of a backup retention policy.
/// This data transfer object encapsulates retention policy options
/// without using any Foundation types.
public struct RetentionPolicyDTO: Sendable, Equatable {
  // MARK: - Properties

  /// Number of most recent snapshots to keep
  public let keepLast: Int?

  /// Number of hourly snapshots to keep
  public let keepHourly: Int?

  /// Number of daily snapshots to keep
  public let keepDaily: Int?

  /// Number of weekly snapshots to keep
  public let keepWeekly: Int?

  /// Number of monthly snapshots to keep
  public let keepMonthly: Int?

  /// Number of yearly snapshots to keep
  public let keepYearly: Int?

  /// Keep snapshots within this duration (seconds)
  public let keepWithinDuration: UInt64?

  // MARK: - Initializers

  /// Full initializer with all retention policy options
  /// - Parameters:
  ///   - keepLast: Number of most recent snapshots to keep
  ///   - keepHourly: Number of hourly snapshots to keep
  ///   - keepDaily: Number of daily snapshots to keep
  ///   - keepWeekly: Number of weekly snapshots to keep
  ///   - keepMonthly: Number of monthly snapshots to keep
  ///   - keepYearly: Number of yearly snapshots to keep
  ///   - keepWithinDuration: Keep snapshots within this duration (seconds)
  public init(
    keepLast: Int?=nil,
    keepHourly: Int?=nil,
    keepDaily: Int?=nil,
    keepWeekly: Int?=nil,
    keepMonthly: Int?=nil,
    keepYearly: Int?=nil,
    keepWithinDuration: UInt64?=nil
  ) {
    self.keepLast=keepLast.map { max(0, $0) }
    self.keepHourly=keepHourly.map { max(0, $0) }
    self.keepDaily=keepDaily.map { max(0, $0) }
    self.keepWeekly=keepWeekly.map { max(0, $0) }
    self.keepMonthly=keepMonthly.map { max(0, $0) }
    self.keepYearly=keepYearly.map { max(0, $0) }
    self.keepWithinDuration=keepWithinDuration
  }

  // MARK: - Factory Methods

  /// Create a default retention policy
  /// Keeps: last 7 daily, 4 weekly, 6 monthly, 1 yearly
  /// - Returns: A RetentionPolicyDTO with default settings
  public static func defaultPolicy() -> RetentionPolicyDTO {
    RetentionPolicyDTO(
      keepLast: nil,
      keepHourly: nil,
      keepDaily: 7,
      keepWeekly: 4,
      keepMonthly: 6,
      keepYearly: 1,
      keepWithinDuration: nil
    )
  }

  /// Create a minimal retention policy that keeps only a specific number of snapshots
  /// - Parameter count: Number of most recent snapshots to keep
  /// - Returns: A RetentionPolicyDTO configured to keep only recent snapshots
  public static func keepLastOnly(_ count: Int) -> RetentionPolicyDTO {
    RetentionPolicyDTO(keepLast: count)
  }

  /// Create a duration-based retention policy
  /// - Parameter seconds: Keep snapshots within this many seconds
  /// - Returns: A RetentionPolicyDTO configured to keep snapshots within a duration
  public static func keepWithinTime(_ seconds: UInt64) -> RetentionPolicyDTO {
    RetentionPolicyDTO(keepWithinDuration: seconds)
  }

  // MARK: - Computed Properties

  /// Whether this policy will keep any snapshots
  /// Returns false if all keep values are nil or 0
  public var willKeepSnapshots: Bool {
    [keepLast, keepHourly, keepDaily, keepWeekly, keepMonthly, keepYearly]
      .compactMap(\.self)
      .contains { $0 > 0 } || keepWithinDuration != nil
  }

  // MARK: - Utility Methods

  /// Create a copy of this policy with updated keepLast value
  /// - Parameter count: The new keepLast value
  /// - Returns: A new RetentionPolicyDTO with updated keepLast
  public func withKeepLast(_ count: Int?) -> RetentionPolicyDTO {
    RetentionPolicyDTO(
      keepLast: count,
      keepHourly: keepHourly,
      keepDaily: keepDaily,
      keepWeekly: keepWeekly,
      keepMonthly: keepMonthly,
      keepYearly: keepYearly,
      keepWithinDuration: keepWithinDuration
    )
  }

  /// Create a copy of this policy with updated keepHourly value
  /// - Parameter count: The new keepHourly value
  /// - Returns: A new RetentionPolicyDTO with updated keepHourly
  public func withKeepHourly(_ count: Int?) -> RetentionPolicyDTO {
    RetentionPolicyDTO(
      keepLast: keepLast,
      keepHourly: count,
      keepDaily: keepDaily,
      keepWeekly: keepWeekly,
      keepMonthly: keepMonthly,
      keepYearly: keepYearly,
      keepWithinDuration: keepWithinDuration
    )
  }

  /// Create a copy of this policy with updated keepDaily value
  /// - Parameter count: The new keepDaily value
  /// - Returns: A new RetentionPolicyDTO with updated keepDaily
  public func withKeepDaily(_ count: Int?) -> RetentionPolicyDTO {
    RetentionPolicyDTO(
      keepLast: keepLast,
      keepHourly: keepHourly,
      keepDaily: count,
      keepWeekly: keepWeekly,
      keepMonthly: keepMonthly,
      keepYearly: keepYearly,
      keepWithinDuration: keepWithinDuration
    )
  }

  /// Create a copy of this policy with updated keepWeekly value
  /// - Parameter count: The new keepWeekly value
  /// - Returns: A new RetentionPolicyDTO with updated keepWeekly
  public func withKeepWeekly(_ count: Int?) -> RetentionPolicyDTO {
    RetentionPolicyDTO(
      keepLast: keepLast,
      keepHourly: keepHourly,
      keepDaily: keepDaily,
      keepWeekly: count,
      keepMonthly: keepMonthly,
      keepYearly: keepYearly,
      keepWithinDuration: keepWithinDuration
    )
  }

  /// Create a copy of this policy with updated keepMonthly value
  /// - Parameter count: The new keepMonthly value
  /// - Returns: A new RetentionPolicyDTO with updated keepMonthly
  public func withKeepMonthly(_ count: Int?) -> RetentionPolicyDTO {
    RetentionPolicyDTO(
      keepLast: keepLast,
      keepHourly: keepHourly,
      keepDaily: keepDaily,
      keepWeekly: keepWeekly,
      keepMonthly: count,
      keepYearly: keepYearly,
      keepWithinDuration: keepWithinDuration
    )
  }

  /// Create a copy of this policy with updated keepYearly value
  /// - Parameter count: The new keepYearly value
  /// - Returns: A new RetentionPolicyDTO with updated keepYearly
  public func withKeepYearly(_ count: Int?) -> RetentionPolicyDTO {
    RetentionPolicyDTO(
      keepLast: keepLast,
      keepHourly: keepHourly,
      keepDaily: keepDaily,
      keepWeekly: keepWeekly,
      keepMonthly: keepMonthly,
      keepYearly: count,
      keepWithinDuration: keepWithinDuration
    )
  }

  /// Create a copy of this policy with updated keepWithinDuration value
  /// - Parameter seconds: The new keepWithinDuration value in seconds
  /// - Returns: A new RetentionPolicyDTO with updated keepWithinDuration
  public func withKeepWithinDuration(_ seconds: UInt64?) -> RetentionPolicyDTO {
    RetentionPolicyDTO(
      keepLast: keepLast,
      keepHourly: keepHourly,
      keepDaily: keepDaily,
      keepWeekly: keepWeekly,
      keepMonthly: keepMonthly,
      keepYearly: keepYearly,
      keepWithinDuration: seconds
    )
  }
}
