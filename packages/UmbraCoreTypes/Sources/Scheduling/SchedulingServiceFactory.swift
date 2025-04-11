import Foundation
import UmbraErrors

/// Factory for creating scheduling service implementations
public enum SchedulingServiceFactory {
  /// Create the default scheduling service implementation
  /// - Returns: An object conforming to the SchedulingServiceProtocol
  public static func createDefault() -> SchedulingServiceProtocol {
    DefaultSchedulingService()
  }

  /// Create a scheduling service with a custom calendar
  /// - Parameter calendar: The calendar to use for scheduling calculations
  /// - Returns: An object conforming to the SchedulingServiceProtocol
  public static func createService(with calendar: Calendar) -> SchedulingServiceProtocol {
    DefaultSchedulingService(calendar: calendar)
  }
}

/// Default implementation of the SchedulingServiceProtocol using an actor for thread safety
private actor SchedulingActor {
  /// The calendar used for date calculations
  let calendar: Calendar
  /// Internal storage for schedules (would be replaced with persistent storage in a real
  /// implementation)
  var schedules: [String: ScheduleDTO]=[:]
  /// Internal storage for tasks (would be replaced with persistent storage in a real
  /// implementation)
  var tasks: [String: ScheduledTaskDTO]=[:]
  /// Task update callbacks
  var taskUpdateCallbacks: [String: (
    taskID: String,
    callback: @Sendable (ScheduledTaskDTO) -> Void
  )]=[:]

  /// Initialize with a calendar
  init(calendar: Calendar) {
    self.calendar=calendar
  }

  /// Get a schedule by ID
  func getSchedule(withID scheduleID: String) -> ScheduleDTO? {
    schedules[scheduleID]
  }

  /// Get all schedules
  func getAllSchedules() -> [ScheduleDTO] {
    Array(schedules.values)
  }

  /// Get all schedules with a specific frequency
  func getSchedules(withFrequency frequency: ScheduleDTO.Frequency) -> [ScheduleDTO] {
    schedules.values.filter { $0.frequency == frequency }
  }

  /// Add or update a schedule
  func setSchedule(_ schedule: ScheduleDTO) {
    schedules[schedule.id]=schedule
  }

  /// Remove a schedule by ID
  func removeSchedule(withID scheduleID: String) -> Bool {
    guard schedules[scheduleID] != nil else {
      return false
    }
    schedules.removeValue(forKey: scheduleID)
    return true
  }

  /// Get a task by ID
  func getTask(withID taskID: String) -> ScheduledTaskDTO? {
    tasks[taskID]
  }

  /// Get all tasks
  func getAllTasks() -> [ScheduledTaskDTO] {
    Array(tasks.values)
  }

  /// Get all tasks with a specific status
  func getTasks(withStatus status: ScheduledTaskDTO.TaskStatus) -> [ScheduledTaskDTO] {
    tasks.values.filter { $0.status == status }
  }

  /// Get all tasks for a specific schedule
  func getTasks(forSchedule scheduleID: String) -> [ScheduledTaskDTO] {
    tasks.values.filter { $0.scheduleID == scheduleID }
  }

  /// Add or update a task
  func setTask(_ task: ScheduledTaskDTO) {
    tasks[task.id]=task
  }

  /// Remove a task by ID
  func removeTask(withID taskID: String) -> ScheduledTaskDTO? {
    guard let task=tasks[taskID] else {
      return nil
    }
    tasks.removeValue(forKey: taskID)
    return task
  }

  /// Register a callback for task updates
  func registerCallback(
    for taskID: String,
    callback: @Sendable @escaping (ScheduledTaskDTO) -> Void
  ) -> String {
    let registrationID=UUID().uuidString
    taskUpdateCallbacks[registrationID]=(taskID: taskID, callback: callback)
    return registrationID
  }

  /// Unregister a callback
  func unregisterCallback(registrationID: String) {
    taskUpdateCallbacks.removeValue(forKey: registrationID)
  }

  /// Get callbacks for a specific task
  func getCallbacks(for taskID: String) -> [(String, @Sendable (ScheduledTaskDTO) -> Void)] {
    taskUpdateCallbacks
      .filter { $0.value.taskID == taskID }
      .map { ($0.key, $0.value.callback) }
  }

  /// Get the calendar (non-isolated property)
  nonisolated var currentCalendar: Calendar {
    calendar
  }
}

/// Default implementation of the SchedulingServiceProtocol
private actor DefaultSchedulingService: SchedulingServiceProtocol {
  /// The actor that handles all data access in a thread-safe manner
  private let actor: SchedulingActor

  /// Initialise with the default calendar
  init() {
    var calendar=Calendar.current
    calendar.timeZone=TimeZone.current
    actor=SchedulingActor(calendar: calendar)
  }

  /// Initialise with a custom calendar
  /// - Parameter calendar: The calendar to use
  init(calendar: Calendar) {
    actor=SchedulingActor(calendar: calendar)
  }

  // MARK: - Schedule Management

  /// Create a new schedule
  /// - Parameter schedule: The schedule configuration to create
  /// - Returns: Result containing the created schedule with assigned ID or an error
  public func createSchedule(_ schedule: ScheduleDTO) async
  -> Result<ScheduleDTO, UmbraErrors.ErrorDTO> {
    // Generate a UUID if one wasn't provided
    let scheduleID=schedule.id.isEmpty ? UUID().uuidString : schedule.id

    // Calculate timestamp for creation time
    let createdAt=UInt64(Date().timeIntervalSince1970)

    // Create a new schedule with the provided parameters
    let newSchedule=ScheduleDTO(
      id: scheduleID,
      name: schedule.name,
      isEnabled: schedule.isEnabled,
      frequency: schedule.frequency,
      interval: schedule.interval,
      startTimeOfDay: schedule.startTimeOfDay,
      endTimeOfDay: schedule.endTimeOfDay,
      daysOfWeek: schedule.daysOfWeek,
      daysOfMonth: schedule.daysOfMonth,
      cronExpression: schedule.cronExpression,
      nextRunTime: schedule.nextRunTime,
      lastRunTime: schedule.lastRunTime,
      runMissedSchedule: schedule.runMissedSchedule,
      maxRuns: schedule.maxRuns,
      runCount: schedule.runCount,
      createdAt: createdAt,
      metadata: schedule.metadata
    )

    await actor.setSchedule(newSchedule)

    return .success(newSchedule)
  }

  /// Update an existing schedule
  /// - Parameter schedule: The schedule to update
  /// - Returns: Result containing the updated schedule or an error
  public func updateSchedule(_ schedule: ScheduleDTO) async
  -> Result<ScheduleDTO, UmbraErrors.ErrorDTO> {
    guard !schedule.id.isEmpty else {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Cannot update schedule with empty ID",
        code: 1001
      ))
    }

    if await actor.getSchedule(withID: schedule.id) == nil {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Schedule not found with ID: \(schedule.id)",
        code: 1002
      ))
    }

    await actor.setSchedule(schedule)
    return .success(schedule)
  }

  /// Delete a schedule by ID
  /// - Parameter scheduleID: The ID of the schedule to delete
  /// - Returns: Success or error result
  public func deleteSchedule(withID scheduleID: String) async
  -> Result<Void, UmbraErrors.ErrorDTO> {
    let success=await actor.removeSchedule(withID: scheduleID)

    if success {
      return .success(())
    } else {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Schedule not found with ID: \(scheduleID)",
        code: 1002
      ))
    }
  }

  /// Get a schedule by ID
  /// - Parameter scheduleID: The ID of the schedule to retrieve
  /// - Returns: Result containing the schedule or an error
  public func getSchedule(withID scheduleID: String) async
  -> Result<ScheduleDTO, UmbraErrors.ErrorDTO> {
    guard let schedule=await actor.getSchedule(withID: scheduleID) else {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Schedule not found with ID: \(scheduleID)",
        code: 1002
      ))
    }

    return .success(schedule)
  }

  /// List all schedules
  /// - Returns: Result containing array of schedules or an error
  public func listSchedules() async -> Result<[ScheduleDTO], UmbraErrors.ErrorDTO> {
    let allSchedules=await actor.getAllSchedules()
    return .success(allSchedules)
  }

  /// List all schedules of a specific frequency
  /// - Parameter frequency: The frequency to filter by
  /// - Returns: Result containing filtered schedules or an error
  public func listSchedules(
    withFrequency frequency: ScheduleDTO
      .Frequency
  ) async -> Result<[ScheduleDTO], UmbraErrors.ErrorDTO> {
    let filteredSchedules=await actor.getSchedules(withFrequency: frequency)
    return .success(filteredSchedules)
  }

  /// Enable a schedule
  /// - Parameter scheduleID: The ID of the schedule to enable
  /// - Returns: Success or error result
  public func enableSchedule(withID scheduleID: String) async
  -> Result<Void, UmbraErrors.ErrorDTO> {
    guard let schedule=await actor.getSchedule(withID: scheduleID) else {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Schedule not found with ID: \(scheduleID)",
        code: 1002
      ))
    }

    // Get the current timestamp
    let createdAt=schedule.createdAt

    let updatedSchedule=ScheduleDTO(
      id: schedule.id,
      name: schedule.name,
      isEnabled: true,
      frequency: schedule.frequency,
      interval: schedule.interval,
      startTimeOfDay: schedule.startTimeOfDay,
      endTimeOfDay: schedule.endTimeOfDay,
      daysOfWeek: schedule.daysOfWeek,
      daysOfMonth: schedule.daysOfMonth,
      cronExpression: schedule.cronExpression,
      nextRunTime: schedule.nextRunTime,
      lastRunTime: schedule.lastRunTime,
      runMissedSchedule: schedule.runMissedSchedule,
      maxRuns: schedule.maxRuns,
      runCount: schedule.runCount,
      createdAt: createdAt,
      metadata: schedule.metadata
    )

    await actor.setSchedule(updatedSchedule)
    return .success(())
  }

  /// Disable a schedule
  /// - Parameter scheduleID: The ID of the schedule to disable
  /// - Returns: Success or error result
  public func disableSchedule(withID scheduleID: String) async
  -> Result<Void, UmbraErrors.ErrorDTO> {
    guard let schedule=await actor.getSchedule(withID: scheduleID) else {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Schedule not found with ID: \(scheduleID)",
        code: 1002
      ))
    }

    // Get the current timestamp
    let createdAt=schedule.createdAt

    let updatedSchedule=ScheduleDTO(
      id: schedule.id,
      name: schedule.name,
      isEnabled: false,
      frequency: schedule.frequency,
      interval: schedule.interval,
      startTimeOfDay: schedule.startTimeOfDay,
      endTimeOfDay: schedule.endTimeOfDay,
      daysOfWeek: schedule.daysOfWeek,
      daysOfMonth: schedule.daysOfMonth,
      cronExpression: schedule.cronExpression,
      nextRunTime: schedule.nextRunTime,
      lastRunTime: schedule.lastRunTime,
      runMissedSchedule: schedule.runMissedSchedule,
      maxRuns: schedule.maxRuns,
      runCount: schedule.runCount,
      createdAt: createdAt,
      metadata: schedule.metadata
    )

    await actor.setSchedule(updatedSchedule)
    return .success(())
  }

  // MARK: - Task Management

  /// Create a new scheduled task
  /// - Parameter task: The task configuration to create
  /// - Returns: Result containing the created task or an error
  public func createTask(_ task: ScheduledTaskDTO) async
  -> Result<ScheduledTaskDTO, UmbraErrors.ErrorDTO> {
    // Validate schedule exists if scheduleID is provided
    if !task.scheduleID.isEmpty {
      let scheduleExists=await actor.getSchedule(withID: task.scheduleID) != nil

      if !scheduleExists {
        return .failure(UmbraErrors.ErrorDTO(
          identifier: UUID().uuidString,
          domain: UmbraErrors.ErrorDomain.scheduling,
          description: "Schedule not found with ID: \(task.scheduleID)",
          code: 1002
        ))
      }
    }

    // Generate a UUID if one wasn't provided
    let taskID=task.id.isEmpty ? UUID().uuidString : task.id

    // Create a timestamp for task creation
    let createdAt=UInt64(Date().timeIntervalSince1970)

    let newTask=ScheduledTaskDTO(
      id: taskID,
      scheduleID: task.scheduleID,
      name: task.name,
      taskType: task.taskType,
      status: task.status,
      configData: task.configData,
      createdAt: createdAt,
      startedAt: task.startedAt,
      completedAt: task.completedAt,
      duration: task.duration,
      errorMessage: task.errorMessage,
      resultData: task.resultData,
      metadata: task.metadata
    )

    await actor.setTask(newTask)

    // Notify any registered callbacks
    await notifyTaskUpdates(newTask)

    return .success(newTask)
  }

  /// Update an existing scheduled task
  /// - Parameter task: The task to update
  /// - Returns: Result containing the updated task or an error
  public func updateTask(_ task: ScheduledTaskDTO) async
  -> Result<ScheduledTaskDTO, UmbraErrors.ErrorDTO> {
    guard !task.id.isEmpty else {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Cannot update task with empty ID",
        code: 1001
      ))
    }

    let taskExists=await actor.getTask(withID: task.id) != nil
    guard taskExists else {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Task not found with ID: \(task.id)",
        code: 1003
      ))
    }

    await actor.setTask(task)

    // Notify any registered callbacks
    await notifyTaskUpdates(task)

    return .success(task)
  }

  /// Delete a task by ID
  /// - Parameter taskID: The ID of the task to delete
  /// - Returns: Success or error result
  public func deleteTask(withID taskID: String) async -> Result<Void, UmbraErrors.ErrorDTO> {
    guard let task=await actor.removeTask(withID: taskID) else {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Task not found with ID: \(taskID)",
        code: 1003
      ))
    }

    // Notify any registered callbacks that the task was deleted
    // by sending a final update with cancelled status
    let finalTask=ScheduledTaskDTO(
      id: task.id,
      scheduleID: task.scheduleID,
      name: task.name,
      taskType: task.taskType,
      status: .cancelled,
      configData: task.configData,
      createdAt: task.createdAt,
      startedAt: task.startedAt,
      completedAt: UInt64(Date().timeIntervalSince1970),
      duration: task.duration,
      errorMessage: nil,
      resultData: "Task deleted",
      metadata: task.metadata
    )

    await notifyTaskUpdates(finalTask)

    return .success(())
  }

  /// Get a task by ID
  /// - Parameter taskID: The ID of the task to retrieve
  /// - Returns: Result containing the task or an error
  public func getTask(withID taskID: String) async
  -> Result<ScheduledTaskDTO, UmbraErrors.ErrorDTO> {
    guard let task=await actor.getTask(withID: taskID) else {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Task not found with ID: \(taskID)",
        code: 1003
      ))
    }

    return .success(task)
  }

  /// List all tasks
  /// - Returns: Result containing array of tasks or an error
  public func listTasks() async -> Result<[ScheduledTaskDTO], UmbraErrors.ErrorDTO> {
    let allTasks=await actor.getAllTasks()
    return .success(allTasks)
  }

  /// List tasks by status
  /// - Parameter status: The status to filter by
  /// - Returns: Result containing filtered tasks or an error
  public func listTasks(
    withStatus status: ScheduledTaskDTO
      .TaskStatus
  ) async -> Result<[ScheduledTaskDTO], UmbraErrors.ErrorDTO> {
    let filteredTasks=await actor.getTasks(withStatus: status)
    return .success(filteredTasks)
  }

  /// List tasks for a specific schedule
  /// - Parameter scheduleID: The ID of the schedule to get tasks for
  /// - Returns: Result containing tasks for the schedule or an error
  public func listTasks(forSchedule scheduleID: String) async
  -> Result<[ScheduledTaskDTO], UmbraErrors.ErrorDTO> {
    let filteredTasks=await actor.getTasks(forSchedule: scheduleID)
    return .success(filteredTasks)
  }

  /// Cancel a running task
  /// - Parameter taskID: The ID of the task to cancel
  /// - Returns: Success or error result
  public func cancelTask(withID taskID: String) async -> Result<Void, UmbraErrors.ErrorDTO> {
    guard let task=await actor.getTask(withID: taskID) else {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Task not found with ID: \(taskID)",
        code: 1003
      ))
    }

    if task.status != .running && task.status != .pending {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Cannot cancel task that is not running or pending",
        code: 1004
      ))
    }

    // Calculate new duration if task was running
    let duration: UInt64?=if let startedAt=task.startedAt {
      UInt64(Date().timeIntervalSince1970) - startedAt
    } else {
      task.duration
    }

    let updatedTask=ScheduledTaskDTO(
      id: task.id,
      scheduleID: task.scheduleID,
      name: task.name,
      taskType: task.taskType,
      status: .cancelled,
      configData: task.configData,
      createdAt: task.createdAt,
      startedAt: task.startedAt,
      completedAt: UInt64(Date().timeIntervalSince1970),
      duration: duration,
      errorMessage: nil,
      resultData: "Task cancelled by user",
      metadata: task.metadata
    )

    await actor.setTask(updatedTask)

    // Notify any registered callbacks
    await notifyTaskUpdates(updatedTask)

    return .success(())
  }

  /// Calculate the next run time for a schedule
  /// - Parameter schedule: The schedule to calculate for
  /// - Returns: Result containing the next run date or an error
  public func calculateNextRunTime(for schedule: ScheduleDTO) async
  -> Result<Date, UmbraErrors.ErrorDTO> {
    // Return error if schedule is disabled
    if !schedule.isEnabled {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Cannot calculate next run time for disabled schedule",
        code: 1005
      ))
    }

    // Start with current date
    let now=Date()

    // Get the actor's calendar
    let calculationCalendar=actor.currentCalendar

    // For 'once' frequency, just return the start date if it's in the future
    if schedule.frequency == .once {
      if let startTime=schedule.startTimeOfDay, startTime > Int(Date().timeIntervalSince1970) {
        return .success(Date(timeIntervalSince1970: TimeInterval(startTime)))
      } else {
        return .failure(UmbraErrors.ErrorDTO(
          identifier: UUID().uuidString,
          domain: UmbraErrors.ErrorDomain.scheduling,
          description: "One-time schedule has already run or has no start date",
          code: 1006
        ))
      }
    }

    // For other frequencies, calculate based on interval and frequency
    var components=DateComponents()

    switch schedule.frequency {
      case .minutely:
        components.minute=schedule.interval
      case .hourly:
        components.hour=schedule.interval
      case .daily:
        components.day=schedule.interval
        if let timeOfDay=schedule.startTimeOfDay {
          let hours=(timeOfDay / 3600) % 24
          let minutes=(timeOfDay / 60) % 60
          components.hour=hours
          components.minute=minutes
          components.second=0
        }
      case .weekly:
        components.weekOfYear=schedule.interval
        if let daysOfWeek=schedule.daysOfWeek, !daysOfWeek.isEmpty {
          // For simplicity, just use the first day of week in the list
          components.weekday=daysOfWeek[0].rawValue + 1 // Convert to Calendar weekday (1-7)
        }
        if let timeOfDay=schedule.startTimeOfDay {
          let hours=(timeOfDay / 3600) % 24
          let minutes=(timeOfDay / 60) % 60
          components.hour=hours
          components.minute=minutes
          components.second=0
        }
      case .monthly:
        components.month=schedule.interval
        if let daysOfMonth=schedule.daysOfMonth, !daysOfMonth.isEmpty {
          // For simplicity, just use the first day of month in the list
          components.day=daysOfMonth[0]
        }
        if let timeOfDay=schedule.startTimeOfDay {
          let hours=(timeOfDay / 3600) % 24
          let minutes=(timeOfDay / 60) % 60
          components.hour=hours
          components.minute=minutes
          components.second=0
        }
      case .daysOfWeek, .daysOfMonth, .custom:
        // These require more complex calculations beyond this example
        return .failure(UmbraErrors.ErrorDTO(
          identifier: UUID().uuidString,
          domain: UmbraErrors.ErrorDomain.scheduling,
          description: "Complex schedule calculation not implemented for this frequency",
          code: 1007
        ))
      case .once:
        // Already handled above
        break
    }

    // Calculate next date from now
    guard
      let nextDate=calculationCalendar.nextDate(
        after: now,
        matching: components,
        matchingPolicy: .nextTime
      )
    else {
      return .failure(UmbraErrors.ErrorDTO(
        identifier: UUID().uuidString,
        domain: UmbraErrors.ErrorDomain.scheduling,
        description: "Could not calculate next run time",
        code: 1008
      ))
    }

    // Check against end date if it exists
    if let endTimeOfDay=schedule.endTimeOfDay, endTimeOfDay > 0 {
      let endDate=Date(timeIntervalSince1970: TimeInterval(endTimeOfDay))
      if nextDate > endDate {
        return .failure(UmbraErrors.ErrorDTO(
          identifier: UUID().uuidString,
          domain: UmbraErrors.ErrorDomain.scheduling,
          description: "Next run would be after schedule end date",
          code: 1009
        ))
      }
    }

    return .success(nextDate)
  }

  // MARK: - Task Update Notifications

  /// Register a callback for task status changes
  /// - Parameters:
  ///   - taskID: The ID of the task to monitor
  ///   - callback: Function to call when status changes
  /// - Returns: Registration ID to use for unregistering
  public nonisolated func registerForTaskUpdates(
    taskID: String,
    callback: @Sendable @escaping (ScheduledTaskDTO) -> Void
  ) -> String {
    let registrationID=UUID().uuidString

    // Use a Task to bridge between nonisolated and isolated contexts
    Task {
      await actor.registerCallback(
        for: taskID,
        callback: callback
      )
    }

    return registrationID
  }

  /// Unregister a previously registered callback
  /// - Parameter registrationID: The registration ID to remove
  public nonisolated func unregisterTaskUpdates(registrationID: String) {
    Task {
      await actor.unregisterCallback(registrationID: registrationID)
    }
  }

  /// Notify all registered callbacks for a task
  /// - Parameter task: The updated task
  private func notifyTaskUpdates(_ task: ScheduledTaskDTO) async {
    let callbacks=await actor.getCallbacks(for: task.id)

    for (_, callback) in callbacks {
      callback(task)
    }
  }
}

/// Error domains for scheduling
extension UmbraErrors.ErrorDomain {
  /// Scheduling error domain
  public static let scheduling="Scheduling"
}
