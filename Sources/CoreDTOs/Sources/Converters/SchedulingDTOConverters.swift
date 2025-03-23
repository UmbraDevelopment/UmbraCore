import Foundation
import UmbraCoreTypes

// MARK: - Date Extensions for ScheduleDTO

extension Date {
  /// Convert a Date to a UInt64 timestamp (seconds since 1970)
  public var timestampInSeconds: UInt64 {
    UInt64(timeIntervalSince1970)
  }

  /// Create a Date from a UInt64 timestamp (seconds since 1970)
  /// - Parameter timestamp: The timestamp in seconds
  /// - Returns: A Date object
  public static func fromTimestamp(_ timestamp: UInt64) -> Date {
    Date(timeIntervalSince1970: TimeInterval(timestamp))
  }
}

// MARK: - Foundation Date Extensions for ScheduleDTO

extension ScheduleDTO {
  /// Create a ScheduleDTO from Foundation Date objects
  /// - Parameters:
  ///   - calendar: The Calendar to use
  ///   - startDate: Start date for the schedule
  ///   - endDate: Optional end date for the schedule
  ///   - repeatType: Repeat frequency type
  ///   - repeatInterval: Repeat interval
  ///   - daysOfWeek: Specific days of week (for weekly schedules)
  ///   - daysOfMonth: Specific days of month (for monthly schedules)
  ///   - windowStartTime: Optional start time of day window
  ///   - windowEndTime: Optional end time of day window
  ///   - enabled: Whether the schedule is enabled
  ///   - maxRuns: Maximum number of runs
  /// - Returns: A configured ScheduleDTO
  public static func fromCalendarComponents(
    calendar: Calendar,
    startDate _: Date,
    endDate _: Date?=nil,
    repeatType: Frequency,
    repeatInterval: Int=1,
    daysOfWeek: [DayOfWeek]?=nil,
    daysOfMonth: [Int]?=nil,
    windowStartTime: Date?=nil,
    windowEndTime: Date?=nil,
    enabled: Bool=true,
    maxRuns: Int?=nil
  ) -> ScheduleDTO {
    // Convert window times to seconds since midnight
    var windowStart: Int?
    if let windowStartTime {
      let components=calendar.dateComponents([.hour, .minute, .second], from: windowStartTime)
      let seconds=(components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 +
        (components.second ?? 0)
      windowStart=seconds
    }

    var windowEnd: Int?
    if let windowEndTime {
      let components=calendar.dateComponents([.hour, .minute, .second], from: windowEndTime)
      let seconds=(components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 +
        (components.second ?? 0)
      windowEnd=seconds
    }

    return ScheduleDTO(
      id: UUID().uuidString,
      name: "Schedule created at \(Date())",
      isEnabled: enabled,
      frequency: repeatType,
      interval: repeatInterval,
      startTimeOfDay: windowStart,
      endTimeOfDay: windowEnd,
      daysOfWeek: daysOfWeek,
      daysOfMonth: daysOfMonth,
      cronExpression: nil,
      nextRunTime: nil,
      lastRunTime: nil,
      runMissedSchedule: true,
      maxRuns: maxRuns,
      runCount: 0,
      createdAt: UInt64(Date().timeIntervalSince1970),
      metadata: [:]
    )
  }

  /// Convert the timestamps in this DTO to Foundation Date objects
  /// - Returns: A tuple containing dates derived from timestamps
  public func toDates() -> (start: Date, end: Date?, lastRun: Date?, nextRun: Date?) {
    let start=Date(timeIntervalSince1970: TimeInterval(createdAt))
    let end=nextRunTime.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    let lastRun=lastRunTime.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    let nextRun=nextRunTime.map { Date(timeIntervalSince1970: TimeInterval($0)) }

    return (start, end, lastRun, nextRun)
  }
}

extension ScheduledTaskDTO {
  /// Create a task from a schedule
  /// - Parameters:
  ///   - schedule: The schedule to create a task for
  ///   - taskId: Task identifier (auto-generated if nil)
  ///   - status: Initial task status
  ///   - configData: Task configuration data
  ///   - lastRunTimestamp: Timestamp of the last run
  ///   - nextRunTimestamp: Timestamp of the next run
  /// - Returns: A ScheduledTaskDTO
  static func fromSchedule(
    _ schedule: ScheduleDTO,
    taskID: String?=nil,
    status: TaskStatus = .pending,
    configData: String="{}",
    lastRunTimestamp _: UInt64?=nil,
    nextRunTimestamp _: UInt64?=nil
  ) -> ScheduledTaskDTO {
    let id=taskID ?? UUID().uuidString

    return ScheduledTaskDTO(
      id: id,
      scheduleID: schedule.id,
      name: schedule.name,
      taskType: .custom,
      status: status,
      configData: configData,
      createdAt: UInt64(Date().timeIntervalSince1970),
      startedAt: nil,
      completedAt: nil,
      duration: nil,
      errorMessage: nil,
      resultData: nil,
      metadata: [:]
    )
  }

  /// Create a task with specified parameters
  /// - Parameters:
  ///   - id: Task identifier
  ///   - scheduleId: Schedule identifier
  ///   - name: Task name
  ///   - type: Task type
  ///   - status: Task status
  ///   - configData: Configuration data
  ///   - lastRun: Last run timestamp
  ///   - nextRun: Next run timestamp
  ///   - startedAt: Start timestamp
  ///   - completedAt: Completion timestamp
  ///   - duration: Duration in seconds
  ///   - errorMessage: Error message if failed
  /// - Returns: A new ScheduledTaskDTO
  static func create(
    id: String?=nil,
    scheduleID: String,
    name: String,
    type: TaskType,
    status: TaskStatus = .pending,
    configData: String="{}",
    lastRun _: UInt64?=nil,
    nextRun _: UInt64?=nil,
    startedAt: UInt64?=nil,
    completedAt: UInt64?=nil,
    duration: UInt64?=nil,
    errorMessage: String?=nil
  ) -> ScheduledTaskDTO {
    let taskID=id ?? UUID().uuidString

    return ScheduledTaskDTO(
      id: taskID,
      scheduleID: scheduleID,
      name: name,
      taskType: type,
      status: status,
      configData: configData,
      createdAt: UInt64(Date().timeIntervalSince1970),
      startedAt: startedAt,
      completedAt: completedAt,
      duration: duration,
      errorMessage: errorMessage,
      resultData: nil,
      metadata: [:]
    )
  }

  /// Update a task with a new status and timing information
  /// - Parameters:
  ///   - status: The new status
  ///   - scheduleDTO: The associated schedule
  ///   - startedAt: Timestamp when started
  ///   - completedAt: Timestamp when completed
  ///   - duration: Duration in seconds
  ///   - errorMessage: Error message if failed
  ///   - configData: Configuration data
  /// - Returns: A new ScheduledTaskDTO with updated status
  func updateStatus(
    status: TaskStatus,
    scheduleDTO: ScheduleDTO,
    startedAt: UInt64?=nil,
    completedAt: UInt64?=nil,
    duration: UInt64?=nil,
    errorMessage: String?=nil,
    configData: String?=nil
  ) -> ScheduledTaskDTO {
    ScheduledTaskDTO(
      id: id,
      scheduleID: scheduleDTO.id,
      name: name,
      taskType: taskType,
      status: status,
      configData: configData ?? self.configData,
      createdAt: createdAt,
      startedAt: startedAt ?? self.startedAt,
      completedAt: completedAt ?? self.completedAt,
      duration: duration ?? self.duration,
      errorMessage: errorMessage ?? self.errorMessage,
      resultData: resultData,
      metadata: metadata
    )
  }
}

// MARK: - Date Extensions

// Removed duplicate Date extension that was causing redeclaration errors
