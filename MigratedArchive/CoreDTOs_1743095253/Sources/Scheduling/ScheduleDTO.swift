import UmbraCoreTypes

/// FoundationIndependent representation of a schedule.
/// This data transfer object encapsulates schedule information
/// without using any Foundation types.
public struct ScheduleDTO: Sendable, Equatable {
  // MARK: - Types

  /// The type of scheduling frequency
  public enum Frequency: String, Sendable, Equatable {
    /// Run once only
    case once
    /// Run every X minutes
    case minutely
    /// Run every X hours
    case hourly
    /// Run every X days
    case daily
    /// Run every X weeks
    case weekly
    /// Run every X months
    case monthly
    /// Run on specific days of week
    case daysOfWeek
    /// Run on specific days of month
    case daysOfMonth
    /// Run according to a custom cron expression
    case custom
  }

  /// Days of the week for scheduling
  public enum DayOfWeek: Int, Sendable, Equatable, CaseIterable {
    case sunday=0
    case monday=1
    case tuesday=2
    case wednesday=3
    case thursday=4
    case friday=5
    case saturday=6

    /// String representation of the day
    public var name: String {
      switch self {
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
      }
    }

    /// Short string representation of the day
    public var shortName: String {
      switch self {
        case .sunday: "Sun"
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
      }
    }
  }

  // MARK: - Properties

  /// Unique identifier for the schedule
  public let id: String

  /// Human-readable name of the schedule
  public let name: String

  /// Whether the schedule is enabled
  public let isEnabled: Bool

  /// The frequency of the schedule
  public let frequency: Frequency

  /// Interval for the frequency (e.g., every 2 hours for hourly)
  public let interval: Int

  /// Start time of day in seconds since midnight
  public let startTimeOfDay: Int?

  /// End time of day in seconds since midnight (for time window)
  public let endTimeOfDay: Int?

  /// Specific days of week to run on (for daysOfWeek frequency)
  public let daysOfWeek: [DayOfWeek]?

  /// Specific days of month to run on (for daysOfMonth frequency)
  public let daysOfMonth: [Int]?

  /// Custom cron expression (for custom frequency)
  public let cronExpression: String?

  /// Unix timestamp of the next scheduled run time in seconds
  public let nextRunTime: UInt64?

  /// Unix timestamp of the last run time in seconds
  public let lastRunTime: UInt64?

  /// Whether the schedule should run as soon as possible if a scheduled time was missed
  public let runMissedSchedule: Bool

  /// Maximum number of times to run the schedule (nil = no limit)
  public let maxRuns: Int?

  /// Number of times the schedule has already run
  public let runCount: Int

  /// Creation time as Unix timestamp in seconds
  public let createdAt: UInt64

  /// Additional metadata for the schedule
  public let metadata: [String: String]

  // MARK: - Initializers

  /// Full initializer with all schedule properties
  /// - Parameters:
  ///   - id: Unique identifier for the schedule
  ///   - name: Human-readable name of the schedule
  ///   - isEnabled: Whether the schedule is enabled
  ///   - frequency: The frequency of the schedule
  ///   - interval: Interval for the frequency
  ///   - startTimeOfDay: Start time of day in seconds since midnight
  ///   - endTimeOfDay: End time of day in seconds since midnight
  ///   - daysOfWeek: Specific days of week to run on
  ///   - daysOfMonth: Specific days of month to run on
  ///   - cronExpression: Custom cron expression
  ///   - nextRunTime: Unix timestamp of the next scheduled run time
  ///   - lastRunTime: Unix timestamp of the last run time
  ///   - runMissedSchedule: Whether to run missed schedules
  ///   - maxRuns: Maximum number of times to run
  ///   - runCount: Number of times already run
  ///   - createdAt: Creation time as Unix timestamp
  ///   - metadata: Additional metadata
  public init(
    id: String,
    name: String,
    isEnabled: Bool=true,
    frequency: Frequency,
    interval: Int=1,
    startTimeOfDay: Int?=nil,
    endTimeOfDay: Int?=nil,
    daysOfWeek: [DayOfWeek]?=nil,
    daysOfMonth: [Int]?=nil,
    cronExpression: String?=nil,
    nextRunTime: UInt64?=nil,
    lastRunTime: UInt64?=nil,
    runMissedSchedule: Bool=true,
    maxRuns: Int?=nil,
    runCount: Int=0,
    createdAt: UInt64,
    metadata: [String: String]=[:]
  ) {
    self.id=id
    self.name=name
    self.isEnabled=isEnabled
    self.frequency=frequency
    // Ensure interval is at least 1
    self.interval=max(1, interval)
    self.startTimeOfDay=startTimeOfDay
    self.endTimeOfDay=endTimeOfDay

    // Validate days of week
    if let daysOfWeek, frequency == .daysOfWeek {
      self.daysOfWeek=daysOfWeek.isEmpty ? [.monday] : daysOfWeek
    } else {
      self.daysOfWeek=daysOfWeek
    }

    // Validate days of month, ensure values are between 1-31
    if let daysOfMonth, frequency == .daysOfMonth {
      let validDays=daysOfMonth.filter { $0 >= 1 && $0 <= 31 }
      self.daysOfMonth=validDays.isEmpty ? [1] : validDays
    } else {
      self.daysOfMonth=daysOfMonth
    }

    // Validate cron expression
    if frequency == .custom {
      self.cronExpression=cronExpression ?? "0 0 * * *" // Default to daily at midnight
    } else {
      self.cronExpression=cronExpression
    }

    self.nextRunTime=nextRunTime
    self.lastRunTime=lastRunTime
    self.runMissedSchedule=runMissedSchedule
    self.maxRuns=maxRuns
    self.runCount=max(0, runCount)
    self.createdAt=createdAt
    self.metadata=metadata
  }

  // MARK: - Factory Methods

  /// Create a daily schedule
  /// - Parameters:
  ///   - id: Unique identifier for the schedule
  ///   - name: Human-readable name of the schedule
  ///   - timeOfDay: Time of day in seconds since midnight
  ///   - createdAt: Creation time as Unix timestamp
  /// - Returns: A ScheduleDTO configured for daily execution
  public static func daily(
    id: String,
    name: String,
    timeOfDay: Int,
    createdAt: UInt64
  ) -> ScheduleDTO {
    ScheduleDTO(
      id: id,
      name: name,
      frequency: .daily,
      interval: 1,
      startTimeOfDay: timeOfDay,
      createdAt: createdAt
    )
  }

  /// Create a weekly schedule
  /// - Parameters:
  ///   - id: Unique identifier for the schedule
  ///   - name: Human-readable name of the schedule
  ///   - timeOfDay: Time of day in seconds since midnight
  ///   - daysOfWeek: Days of the week to run on
  ///   - createdAt: Creation time as Unix timestamp
  /// - Returns: A ScheduleDTO configured for weekly execution
  public static func weekly(
    id: String,
    name: String,
    timeOfDay: Int,
    daysOfWeek: [DayOfWeek],
    createdAt: UInt64
  ) -> ScheduleDTO {
    ScheduleDTO(
      id: id,
      name: name,
      frequency: .daysOfWeek,
      interval: 1,
      startTimeOfDay: timeOfDay,
      daysOfWeek: daysOfWeek,
      createdAt: createdAt
    )
  }

  /// Create a monthly schedule
  /// - Parameters:
  ///   - id: Unique identifier for the schedule
  ///   - name: Human-readable name of the schedule
  ///   - timeOfDay: Time of day in seconds since midnight
  ///   - daysOfMonth: Days of the month to run on
  ///   - createdAt: Creation time as Unix timestamp
  /// - Returns: A ScheduleDTO configured for monthly execution
  public static func monthly(
    id: String,
    name: String,
    timeOfDay: Int,
    daysOfMonth: [Int],
    createdAt: UInt64
  ) -> ScheduleDTO {
    ScheduleDTO(
      id: id,
      name: name,
      frequency: .daysOfMonth,
      interval: 1,
      startTimeOfDay: timeOfDay,
      daysOfMonth: daysOfMonth,
      createdAt: createdAt
    )
  }

  /// Create a custom schedule using cron expression
  /// - Parameters:
  ///   - id: Unique identifier for the schedule
  ///   - name: Human-readable name of the schedule
  ///   - cronExpression: Cron expression for scheduling
  ///   - createdAt: Creation time as Unix timestamp
  /// - Returns: A ScheduleDTO configured with a custom cron expression
  public static func custom(
    id: String,
    name: String,
    cronExpression: String,
    createdAt: UInt64
  ) -> ScheduleDTO {
    ScheduleDTO(
      id: id,
      name: name,
      frequency: .custom,
      cronExpression: cronExpression,
      createdAt: createdAt
    )
  }

  /// Create a one-time schedule
  /// - Parameters:
  ///   - id: Unique identifier for the schedule
  ///   - name: Human-readable name of the schedule
  ///   - runTime: Unix timestamp of when to run
  ///   - createdAt: Creation time as Unix timestamp
  /// - Returns: A ScheduleDTO configured for one-time execution
  public static func oneTime(
    id: String,
    name: String,
    runTime: UInt64,
    createdAt: UInt64
  ) -> ScheduleDTO {
    ScheduleDTO(
      id: id,
      name: name,
      frequency: .once,
      interval: 1,
      nextRunTime: runTime,
      maxRuns: 1,
      createdAt: createdAt
    )
  }

  // MARK: - Computed Properties

  /// Whether the schedule has reached its maximum run count
  public var isComplete: Bool {
    if let maxRuns {
      return runCount >= maxRuns
    }
    return false
  }

  /// Whether the schedule is one-time only
  public var isOneTimeOnly: Bool {
    frequency == .once || maxRuns == 1
  }

  /// Human-readable description of the schedule's frequency
  public var frequencyDescription: String {
    switch frequency {
      case .once:
        return "Once only"
      case .minutely:
        return interval == 1 ? "Every minute" : "Every \(interval) minutes"
      case .hourly:
        return interval == 1 ? "Every hour" : "Every \(interval) hours"
      case .daily:
        return interval == 1 ? "Daily" : "Every \(interval) days"
      case .weekly:
        return interval == 1 ? "Weekly" : "Every \(interval) weeks"
      case .monthly:
        return interval == 1 ? "Monthly" : "Every \(interval) months"
      case .daysOfWeek:
        if let days=daysOfWeek {
          let dayNames=days.map(\.shortName).joined(separator: ", ")
          return "Weekly on \(dayNames)"
        }
        return "Weekly on specific days"
      case .daysOfMonth:
        if let days=daysOfMonth {
          let dayNumbers=days.map { String($0) }.joined(separator: ", ")
          return "Monthly on day\(days.count > 1 ? "s" : "") \(dayNumbers)"
        }
        return "Monthly on specific days"
      case .custom:
        return "Custom schedule"
    }
  }

  // MARK: - Utility Methods

  /// Create a copy of this schedule with updated enabled status
  /// - Parameter enabled: New enabled status
  /// - Returns: A new ScheduleDTO with updated enabled status
  public func withEnabled(_ enabled: Bool) -> ScheduleDTO {
    ScheduleDTO(
      id: id,
      name: name,
      isEnabled: enabled,
      frequency: frequency,
      interval: interval,
      startTimeOfDay: startTimeOfDay,
      endTimeOfDay: endTimeOfDay,
      daysOfWeek: daysOfWeek,
      daysOfMonth: daysOfMonth,
      cronExpression: cronExpression,
      nextRunTime: nextRunTime,
      lastRunTime: lastRunTime,
      runMissedSchedule: runMissedSchedule,
      maxRuns: maxRuns,
      runCount: runCount,
      createdAt: createdAt,
      metadata: metadata
    )
  }

  /// Create a copy of this schedule with updated next run time
  /// - Parameter nextRun: New next run time
  /// - Returns: A new ScheduleDTO with updated next run time
  public func withNextRunTime(_ nextRun: UInt64?) -> ScheduleDTO {
    ScheduleDTO(
      id: id,
      name: name,
      isEnabled: isEnabled,
      frequency: frequency,
      interval: interval,
      startTimeOfDay: startTimeOfDay,
      endTimeOfDay: endTimeOfDay,
      daysOfWeek: daysOfWeek,
      daysOfMonth: daysOfMonth,
      cronExpression: cronExpression,
      nextRunTime: nextRun,
      lastRunTime: lastRunTime,
      runMissedSchedule: runMissedSchedule,
      maxRuns: maxRuns,
      runCount: runCount,
      createdAt: createdAt,
      metadata: metadata
    )
  }

  /// Create a copy of this schedule with updated last run time and incremented run count
  /// - Parameter lastRun: New last run time
  /// - Returns: A new ScheduleDTO with updated last run time and run count
  public func markAsRun(at lastRun: UInt64) -> ScheduleDTO {
    ScheduleDTO(
      id: id,
      name: name,
      isEnabled: isEnabled,
      frequency: frequency,
      interval: interval,
      startTimeOfDay: startTimeOfDay,
      endTimeOfDay: endTimeOfDay,
      daysOfWeek: daysOfWeek,
      daysOfMonth: daysOfMonth,
      cronExpression: cronExpression,
      nextRunTime: isOneTimeOnly ? nil : nextRunTime,
      lastRunTime: lastRun,
      runMissedSchedule: runMissedSchedule,
      maxRuns: maxRuns,
      runCount: runCount + 1,
      createdAt: createdAt,
      metadata: metadata
    )
  }

  /// Create a copy of this schedule with updated metadata
  /// - Parameter additionalMetadata: The metadata to add or update
  /// - Returns: A new ScheduleDTO with updated metadata
  public func withUpdatedMetadata(_ additionalMetadata: [String: String]) -> ScheduleDTO {
    var newMetadata=metadata
    for (key, value) in additionalMetadata {
      newMetadata[key]=value
    }

    return ScheduleDTO(
      id: id,
      name: name,
      isEnabled: isEnabled,
      frequency: frequency,
      interval: interval,
      startTimeOfDay: startTimeOfDay,
      endTimeOfDay: endTimeOfDay,
      daysOfWeek: daysOfWeek,
      daysOfMonth: daysOfMonth,
      cronExpression: cronExpression,
      nextRunTime: nextRunTime,
      lastRunTime: lastRunTime,
      runMissedSchedule: runMissedSchedule,
      maxRuns: maxRuns,
      runCount: runCount,
      createdAt: createdAt,
      metadata: newMetadata
    )
  }
}
