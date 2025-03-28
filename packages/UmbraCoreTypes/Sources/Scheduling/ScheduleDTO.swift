import Foundation

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

  /// Create a simple one-time schedule
  /// - Parameters:
  ///   - id: Unique identifier
  ///   - name: Human-readable name
  ///   - runTime: When to run as Unix timestamp
  ///   - metadata: Additional metadata
  /// - Returns: A new schedule configured to run once at the specified time
  public static func oneTime(
    id: String=UUID().uuidString,
    name: String,
    runTime: UInt64,
    metadata: [String: String]=[:]
  ) -> ScheduleDTO {
    ScheduleDTO(
      id: id,
      name: name,
      frequency: .once,
      nextRunTime: runTime,
      createdAt: UInt64(Date().timeIntervalSince1970),
      metadata: metadata
    )
  }

  /// Create a daily schedule
  /// - Parameters:
  ///   - id: Unique identifier
  ///   - name: Human-readable name
  ///   - interval: Every X days
  ///   - startTimeOfDay: Time to run (seconds since midnight), defaults to 9am
  ///   - metadata: Additional metadata
  /// - Returns: A new schedule configured to run daily
  public static func daily(
    id: String=UUID().uuidString,
    name: String,
    interval: Int=1,
    startTimeOfDay: Int=9 * 3600, // 9:00 AM
    metadata: [String: String]=[:]
  ) -> ScheduleDTO {
    ScheduleDTO(
      id: id,
      name: name,
      frequency: .daily,
      interval: interval,
      startTimeOfDay: startTimeOfDay,
      createdAt: UInt64(Date().timeIntervalSince1970),
      metadata: metadata
    )
  }

  /// Create a weekly schedule
  /// - Parameters:
  ///   - id: Unique identifier
  ///   - name: Human-readable name
  ///   - daysOfWeek: Days of week to run on
  ///   - startTimeOfDay: Time to run (seconds since midnight), defaults to 9am
  ///   - metadata: Additional metadata
  /// - Returns: A new schedule configured to run on the specified days of the week
  public static func weekly(
    id: String=UUID().uuidString,
    name: String,
    daysOfWeek: [DayOfWeek]=[.monday, .wednesday, .friday],
    startTimeOfDay: Int=9 * 3600, // 9:00 AM
    metadata: [String: String]=[:]
  ) -> ScheduleDTO {
    ScheduleDTO(
      id: id,
      name: name,
      frequency: .daysOfWeek,
      startTimeOfDay: startTimeOfDay,
      daysOfWeek: daysOfWeek,
      createdAt: UInt64(Date().timeIntervalSince1970),
      metadata: metadata
    )
  }

  // MARK: - Helper Methods

  /// Create a copy of this schedule with updated properties
  /// - Parameters:
  ///   - isEnabled: New enabled state
  ///   - nextRunTime: New next run time
  ///   - lastRunTime: New last run time
  ///   - runCount: New run count
  /// - Returns: A new schedule with the updated properties
  public func with(
    isEnabled: Bool?=nil,
    nextRunTime: UInt64?=nil,
    lastRunTime: UInt64?=nil,
    runCount: Int?=nil,
    metadata: [String: String]?=nil
  ) -> ScheduleDTO {
    ScheduleDTO(
      id: id,
      name: name,
      isEnabled: isEnabled ?? self.isEnabled,
      frequency: frequency,
      interval: interval,
      startTimeOfDay: startTimeOfDay,
      endTimeOfDay: endTimeOfDay,
      daysOfWeek: daysOfWeek,
      daysOfMonth: daysOfMonth,
      cronExpression: cronExpression,
      nextRunTime: nextRunTime ?? self.nextRunTime,
      lastRunTime: lastRunTime ?? self.lastRunTime,
      runMissedSchedule: runMissedSchedule,
      maxRuns: maxRuns,
      runCount: runCount ?? self.runCount,
      createdAt: createdAt,
      metadata: metadata ?? self.metadata
    )
  }

  // MARK: - Helper Properties

  /// Human-readable description of the schedule's frequency
  public var frequencyDescription: String {
    switch frequency {
      case .once:
        return "Once only"
      case .minutely:
        let plural=interval > 1 ? "s" : ""
        return "Every \(interval) minute\(plural)"
      case .hourly:
        let plural=interval > 1 ? "s" : ""
        return "Every \(interval) hour\(plural)"
      case .daily:
        let plural=interval > 1 ? "s" : ""
        return "Every \(interval) day\(plural)"
      case .weekly:
        let plural=interval > 1 ? "s" : ""
        return "Every \(interval) week\(plural)"
      case .monthly:
        let plural=interval > 1 ? "s" : ""
        return "Every \(interval) month\(plural)"
      case .daysOfWeek:
        if let days=daysOfWeek, !days.isEmpty {
          if days.count == 7 {
            return "Every day of the week"
          }
          let dayNames=days.map(\.shortName).joined(separator: ", ")
          return "Every \(dayNames)"
        }
        return "On specific days of the week"
      case .daysOfMonth:
        if let days=daysOfMonth, !days.isEmpty {
          // Format for readability
          if days.count > 5 {
            return "Multiple days each month"
          }
          let dayNames=days.map { String($0) }.joined(separator: ", ")
          return "Day\(days.count > 1 ? "s" : "") \(dayNames) of each month"
        }
        return "On specific days of the month"
      case .custom:
        if let cron=cronExpression {
          return "Custom schedule: \(cron)"
        }
        return "Custom schedule"
    }
  }
}
